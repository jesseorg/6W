/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared
import Storage
import XCGLogger
import Deferred
import SwiftyJSON

private let log = Logger.syncLogger
let PasswordsStorageVersion = 1

private func makeDeletedLoginRecord(_ guid: GUID) -> Record<LoginPayload> {
    // Local modified time is ignored in upload serialization.
    let modified: Timestamp = 0

    // Arbitrary large number: deletions sync down first.
    let sortindex = 5_000_000

    let json: JSON = JSON([
        "id": guid,
        "deleted": true,
        ])
    let payload = LoginPayload(json)
    return Record<LoginPayload>(id: guid, payload: payload, modified: modified, sortindex: sortindex)
}

func makeLoginRecord(_ login: Login) -> Record<LoginPayload> {
    let id = login.guid
    let modified: Timestamp = 0    // Ignored in upload serialization.
    let sortindex = 1

    let tLU = NSNumber(value: login.timeLastUsed / 1000)
    let tPC = NSNumber(value: login.timePasswordChanged / 1000)
    let tC = NSNumber(value: login.timeCreated / 1000)

    let dict: [String: Any] = [
        "id": id,
        "hostname": login.hostname,
        "httpRealm": login.httpRealm as Any,
        "formSubmitURL": login.formSubmitURL as Any,
        "username": login.username ?? "",
        "password": login.password ,
        "usernameField": login.usernameField ?? "",
        "passwordField": login.passwordField ?? "",
        "timesUsed": login.timesUsed,
        "timeLastUsed": tLU,
        "timePasswordChanged": tPC,
        "timeCreated": tC,
    ]

    let payload = LoginPayload(JSON(dict))
    return Record<LoginPayload>(id: id, payload: payload, modified: modified, sortindex: sortindex)
}

/**
 * Our current local terminology ("logins") has diverged from the terminology in
 * use when Sync was built ("passwords"). I've done my best to draw a reasonable line
 * between the server collection/record format/etc. and local stuff: local storage
 * works with logins, server records and collection are passwords.
 */
open class LoginsSynchronizer: IndependentRecordSynchronizer, Synchronizer {
    public required init(scratchpad: Scratchpad, delegate: SyncDelegate, basePrefs: Prefs) {
        super.init(scratchpad: scratchpad, delegate: delegate, basePrefs: basePrefs, collection: "passwords")
    }

    override var storageVersion: Int {
        return PasswordsStorageVersion
    }

    func getLogin(_ record: Record<LoginPayload>) -> ServerLogin {
        let guid = record.id
        let payload = record.payload
        let modified = record.modified

        let login = ServerLogin(guid: guid, hostname: payload.hostname, username: payload.username, password: payload.password, modified: modified)
        login.formSubmitURL = payload.formSubmitURL
        login.httpRealm = payload.httpRealm
        login.usernameField = payload.usernameField
        login.passwordField = payload.passwordField

        // Microseconds locally, milliseconds remotely. We should clean this up.
        login.timeCreated = 1000 * (payload.timeCreated ?? 0)
        login.timeLastUsed = 1000 * (payload.timeLastUsed ?? 0)
        login.timePasswordChanged = 1000 * (payload.timePasswordChanged ?? 0)
        login.timesUsed = payload.timesUsed ?? 0
        return login
    }

    func applyIncomingToStorage(_ storage: SyncableLogins, records: [Record<LoginPayload>], fetched: Timestamp) -> Success {
        return self.applyIncomingToStorage(records, fetched: fetched) { rec in
            let guid = rec.id
            let payload = rec.payload

            guard payload.isValid() else {
                log.warning("Login record \(guid) is invalid. Skipping.")
                return succeed()
            }

            // We apply deletions immediately. That might not be exactly what we want -- perhaps you changed
            // a password locally after deleting it remotely -- but it's expedient.
            if payload.deleted {
                return storage.deleteByGUID(guid, deletedAt: rec.modified)
            }

            return storage.applyChangedLogin(self.getLogin(rec))
        }
    }

    fileprivate func uploadChangedRecords<T>(_ deleted: Set<GUID>, modified: Set<GUID>, records: [Record<T>], lastTimestamp: Timestamp, storage: SyncableLogins, withServer storageClient: Sync15CollectionClient<T>) -> Success {

        let onUpload: (POSTResult, Timestamp?) -> DeferredTimestamp = { result, lastModified in
            let uploaded = Set(result.success)
            return storage.markAsDeleted(uploaded.intersection(deleted)) >>> { storage.markAsSynchronized(uploaded.intersection(modified), modified: lastModified ?? lastTimestamp) }
        }

        return uploadRecords(records,
                             lastTimestamp: lastTimestamp,
                             storageClient: storageClient,
                             onUpload: onUpload) >>> succeed
    }

    // Find any records for which a local overlay exists. If we want to be really precise,
    // we can find the original server modified time for each record and use it as
    // If-Unmodified-Since on a PUT, or just use the last fetch timestamp, which should
    // be equivalent.
    // We will already have reconciled any conflicts on download, so this upload phase should
    // be as simple as uploading any changed or deleted items.
    fileprivate func uploadOutgoingFromStorage(_ storage: SyncableLogins, lastTimestamp: Timestamp, withServer storageClient: Sync15CollectionClient<LoginPayload>) -> Success {
        let deleted: () -> Deferred<Maybe<(Set<GUID>, [Record<LoginPayload>])>> = {
            return storage.getDeletedLoginsToUpload() >>== { guids in
                let records = guids.map(makeDeletedLoginRecord)
                return deferMaybe((Set(guids), records))
            }
        }

        let modified: () -> Deferred<Maybe<(Set<GUID>, [Record<LoginPayload>])>> = {
            return storage.getModifiedLoginsToUpload() >>== { logins in
                let guids = Set(logins.map { $0.guid })
                let records = logins.map(makeLoginRecord)
                return deferMaybe((guids, records))
            }
        }

        return accumulate([deleted, modified]) >>== { result in
            let (deletedGUIDs, deletedRecords) = result[0]
            let (modifiedGUIDs, modifiedRecords) = result[1]
            let allRecords = deletedRecords + modifiedRecords

            return self.uploadChangedRecords(deletedGUIDs, modified: modifiedGUIDs, records: allRecords,
                                             lastTimestamp: lastTimestamp, storage: storage, withServer: storageClient)
        }
    }

    open func synchronizeLocalLogins(_ logins: SyncableLogins, withServer storageClient: Sync15StorageClient, info: InfoCollections) -> SyncResult {
        if let reason = self.reasonToNotSync(storageClient) {
            return deferMaybe(.notStarted(reason))
        }

        let encoder = RecordEncoder<LoginPayload>(decode: { LoginPayload($0) }, encode: { $0.json })
        guard let passwordsClient = self.collectionClient(encoder, storageClient: storageClient) else {
            log.error("Couldn't make logins factory.")
            return deferMaybe(FatalError(message: "Couldn't make logins factory."))
        }

        let since: Timestamp = self.lastFetched
        log.debug("Synchronizing \(self.collection). Last fetched: \(since).")

        let applyIncomingToStorage: (StorageResponse<[Record<LoginPayload>]>) -> Success = { response in
            let ts = response.metadata.timestampMilliseconds
            let lm = response.metadata.lastModifiedMilliseconds!
            log.debug("Applying incoming password records from response timestamped \(ts), last modified \(lm).")
            log.debug("Records header hint: \(response.metadata.records ??? "nil")")
            return self.applyIncomingToStorage(logins, records: response.value, fetched: lm) >>> effect {
                NotificationCenter.default.post(name: NotificationDataRemoteLoginChangesWereApplied, object: nil)
            }
        }

        statsSession.start()
        return passwordsClient.getSince(since)
            >>== applyIncomingToStorage
            // TODO: If we fetch sorted by date, we can bump the lastFetched timestamp
            // to the last successfully applied record timestamp, no matter where we fail.
            // There's no need to do the upload before bumping -- the storage of local changes is stable.
            >>> { self.uploadOutgoingFromStorage(logins, lastTimestamp: 0, withServer: passwordsClient) }
            >>> { return deferMaybe(self.completedWithStats) }
    }
}
