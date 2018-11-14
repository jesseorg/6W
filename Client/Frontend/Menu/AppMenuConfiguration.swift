/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import Shared

enum AppMenuAction: String {
    case openNewNormalTab = "OpenNewNormalTab"
    case openNewPrivateTab = "OpenNewPrivateTab"
    case findInPage = "FindInPage"
    case toggleBrowsingMode = "ToggleBrowsingMode"
    case toggleBookmarkStatus = "ToggleBookmarkStatus"
    case openSettings = "OpenSettings"
    case closeAllTabs = "CloseAllTabs"
    case openHomePage = "OpenHomePage"
    case setHomePage = "SetHomePage"
    case sharePage = "SharePage"
    case openTopSites = "OpenTopSites"
    case openBookmarks = "OpenBookmarks"
    case openHistory = "OpenHistory"
    case openReadingList = "OpenReadingList"
    case showImageMode = "ShowImageMode"
    case hideImageMode = "HideImageMode"
    case showNightMode = "ShowNightMode"
	case showWX = "ShowWX" //jesse
    case hideNightMode = "HideNightMode"
}

struct AppMenuConfiguration: MenuConfiguration {

    internal fileprivate(set) var menuItems = [MenuItem]()
    internal fileprivate(set) var menuToolbarItems: [MenuToolbarItem]?
    internal fileprivate(set) var numberOfItemsInRow: Int = 0

    fileprivate(set) var isPrivateMode: Bool = false

    init(appState: AppState) {
        menuItems = menuItemsForAppState(appState)
        menuToolbarItems = menuToolbarItemsForAppState(appState)
        numberOfItemsInRow = numberOfMenuItemsPerRowForAppState(appState)
        isPrivateMode = appState.ui.isPrivate()
    }

    func menuForState(_ appState: AppState) -> MenuConfiguration {
        return AppMenuConfiguration(appState: appState)
    }

    func toolbarColor() -> UIColor {

        return isPrivateMode ? UIConstants.MenuToolbarBackgroundColorPrivate : UIConstants.MenuToolbarBackgroundColorNormal
    }

    func toolbarTintColor() -> UIColor {
        return isPrivateMode ? UIConstants.MenuToolbarTintColorPrivate : UIConstants.MenuToolbarTintColorNormal
    }

    func menuBackgroundColor() -> UIColor {
        return isPrivateMode ? UIConstants.MenuBackgroundColorPrivate : UIConstants.MenuBackgroundColorNormal
    }

    func menuTintColor() -> UIColor {
        return isPrivateMode ? UIConstants.MenuToolbarTintColorPrivate : UIConstants.MenuBackgroundColorPrivate
    }

    func menuFont() -> UIFont {
        return UIFont.systemFont(ofSize: 11)
    }

    func menuIcon() -> UIImage? {
        return isPrivateMode ? UIImage(named:"bottomNav-menu-pbm") : UIImage(named:"bottomNav-menu")
    }

    func minMenuRowHeight() -> CGFloat {
        return 65.0
    }

    func shadowColor() -> UIColor {
        return isPrivateMode ? UIColor.darkGray : UIColor.lightGray
    }

    func selectedItemTintColor() -> UIColor {
        return UIConstants.MenuSelectedItemTintColor
    }
    
    func disabledItemTintColor() -> UIColor {
        return UIConstants.MenuDisabledItemTintColor
    }

    fileprivate func numberOfMenuItemsPerRowForAppState(_ appState: AppState) -> Int {
        switch appState.ui {
        case .tabTray:
            return 4
        default:
            return 3
        }
    }

    // the items should be added to the array according to desired display order
    fileprivate func menuItemsForAppState(_ appState: AppState) -> [MenuItem] {
        var menuItems = [MenuItem]()
        switch appState.ui {
        case .tab(let tabState):
            menuItems.append(AppMenuConfiguration.FindInPageMenuItem)
            menuItems.append(tabState.desktopSite ? AppMenuConfiguration.RequestMobileMenuItem : AppMenuConfiguration.RequestDesktopMenuItem)

            if !HomePageAccessors.isButtonInMenu(appState) {
                menuItems.append(AppMenuConfiguration.SharePageMenuItem)
            } else if HomePageAccessors.hasHomePage(appState) {
                menuItems.append(AppMenuConfiguration.OpenHomePageMenuItem)
            } else {
                var homePageMenuItem = AppMenuConfiguration.SetHomePageMenuItem
                if let url = tabState.url, !url.isWebPage(includeDataURIs: true) || url.isLocal {
                    homePageMenuItem.isDisabled = true
                }
                menuItems.append(homePageMenuItem)
            }
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            var bookmarkMenuItem = tabState.isBookmarked ? AppMenuConfiguration.RemoveBookmarkMenuItem : AppMenuConfiguration.AddBookmarkMenuItem
            if let url = tabState.url, !url.isWebPage(includeDataURIs: true) || url.isLocal {
                bookmarkMenuItem.isDisabled = true
            }
            menuItems.append(bookmarkMenuItem)
            if NoImageModeHelper.isNoImageModeAvailable(appState) {
                if NoImageModeHelper.isNoImageModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowImageModeMenuItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideImageModeMenuItem)
                }
            }
            if NightModeAccessors.isNightModeAvailable(appState) {
                if NightModeAccessors.isNightModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowNightModeItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideNightModeItem)
                }
            }
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        case .homePanels:
		menuItems.append(AppMenuConfiguration.ShowWXItem)//jesse
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            if HomePageAccessors.isButtonInMenu(appState) && HomePageAccessors.hasHomePage(appState) {
                menuItems.append(AppMenuConfiguration.OpenHomePageMenuItem)
            }
            if NoImageModeHelper.isNoImageModeAvailable(appState) {
                if NoImageModeHelper.isNoImageModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowImageModeMenuItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideImageModeMenuItem)
                }
            }
            if NightModeAccessors.isNightModeAvailable(appState) {
                if NightModeAccessors.isNightModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowNightModeItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideNightModeItem)
                }
            }
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        case .emptyTab, .loading:
		menuItems.append(AppMenuConfiguration.ShowWXItem)//jesse
            //menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            if HomePageAccessors.isButtonInMenu(appState) && HomePageAccessors.hasHomePage(appState) {
                menuItems.append(AppMenuConfiguration.OpenHomePageMenuItem)
            }
            if NoImageModeHelper.isNoImageModeAvailable(appState) {
                if NoImageModeHelper.isNoImageModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowImageModeMenuItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideImageModeMenuItem)
                }
            }
            if NightModeAccessors.isNightModeAvailable(appState) {
                if NightModeAccessors.isNightModeActivated(appState) {
                    menuItems.append(AppMenuConfiguration.ShowNightModeItem)
                } else {
                    menuItems.append(AppMenuConfiguration.HideNightModeItem)
                }
            }
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
        case .tabTray:
            menuItems.append(AppMenuConfiguration.NewTabMenuItem)
            menuItems.append(AppMenuConfiguration.NewPrivateTabMenuItem)
            menuItems.append(AppMenuConfiguration.CloseAllTabsMenuItem)
            menuItems.append(AppMenuConfiguration.SettingsMenuItem)
			//menuItems.append(AppMenuConfiguration.ShowWXItem)
        }
        return menuItems
    }

    // the items should be added to the array according to desired display order
    fileprivate func menuToolbarItemsForAppState(_ appState: AppState) -> [MenuToolbarItem]? {
        let menuToolbarItems: [MenuToolbarItem]?
        switch appState.ui {
        case .tab, .tabTray:
            menuToolbarItems = [AppMenuConfiguration.TopSitesMenuToolbarItem,
                                AppMenuConfiguration.BookmarksMenuToolbarItem,
                                AppMenuConfiguration.HistoryMenuToolbarItem,
                                AppMenuConfiguration.ReadingListMenuToolbarItem]
        default:
            menuToolbarItems = nil
        }
        return menuToolbarItems
    }
}

// MARK: Static helper access function

extension AppMenuConfiguration {

    fileprivate static var NewTabMenuItem: MenuItem {
        return AppMenuItem(title: NewTabTitleString, accessibilityIdentifier: "NewTabMenuItem", action: MenuAction(action: AppMenuAction.openNewNormalTab.rawValue), icon: "menu-NewTab", privateModeIcon: "menu-NewTab-pbm")
    }

    fileprivate static var NewPrivateTabMenuItem: MenuItem {
        return AppMenuItem(title: NewPrivateTabTitleString, accessibilityIdentifier: "NewPrivateTabMenuItem", action:  MenuAction(action: AppMenuAction.openNewPrivateTab.rawValue), icon: "menu-NewPrivateTab", privateModeIcon: "menu-NewPrivateTab-pbm")
    }

    fileprivate static var AddBookmarkMenuItem: MenuItem {
        return AppMenuItem(title: AddBookmarkTitleString, accessibilityIdentifier: "AddBookmarkMenuItem", action:  MenuAction(action: AppMenuAction.toggleBookmarkStatus.rawValue), icon: "menu-Bookmark", privateModeIcon: "menu-Bookmark-pbm", selectedIcon: "menu-RemoveBookmark", animation: JumpAndSpinAnimator())
    }

    fileprivate static var RemoveBookmarkMenuItem: MenuItem {
        return AppMenuItem(title: RemoveBookmarkTitleString, accessibilityIdentifier: "RemoveBookmarkMenuItem", action:  MenuAction(action: AppMenuAction.toggleBookmarkStatus.rawValue), icon: "menu-RemoveBookmark", privateModeIcon: "menu-RemoveBookmark")
    }

    fileprivate static var FindInPageMenuItem: MenuItem {
        return AppMenuItem(title: FindInPageTitleString, accessibilityIdentifier: "FindInPageMenuItem", action:  MenuAction(action: AppMenuAction.findInPage.rawValue), icon: "menu-FindInPage", privateModeIcon: "menu-FindInPage-pbm")
    }

    fileprivate static var RequestDesktopMenuItem: MenuItem {
        return AppMenuItem(title: ViewDesktopSiteTitleString, accessibilityIdentifier: "RequestDesktopMenuItem", action:  MenuAction(action: AppMenuAction.toggleBrowsingMode.rawValue), icon: "menu-RequestDesktopSite", privateModeIcon: "menu-RequestDesktopSite-pbm")
    }

    fileprivate static var RequestMobileMenuItem: MenuItem {
        return AppMenuItem(title: ViewMobileSiteTitleString, accessibilityIdentifier: "RequestMobileMenuItem", action:  MenuAction(action: AppMenuAction.toggleBrowsingMode.rawValue), icon: "menu-ViewMobile", privateModeIcon: "menu-ViewMobile-pbm")
    }

    fileprivate static var HideImageModeMenuItem: MenuItem {
        return AppMenuItem(title: Strings.MenuNoImageModeTurnOnLabel, accessibilityIdentifier: "HideImageModeMenuItem", action:  MenuAction(action: AppMenuAction.hideImageMode.rawValue), icon: "menu-NoImageMode", privateModeIcon: "menu-NoImageMode-pbm")
    }

    fileprivate static var ShowImageModeMenuItem: MenuItem {
        return AppMenuItem(title: Strings.MenuNoImageModeTurnOffLabel, accessibilityIdentifier: "ShowImageModeMenuItem", action:  MenuAction(action: AppMenuAction.showImageMode.rawValue), icon: "menu-NoImageMode-Engaged", privateModeIcon: "menu-NoImageMode-Engaged")
   }
 
    fileprivate static var HideNightModeItem: MenuItem {
        return AppMenuItem(title: Strings.MenuNightModeTurnOnLabel, accessibilityIdentifier: "HideNightModeItem", action:  MenuAction(action: AppMenuAction.hideNightMode.rawValue), icon: "menu-NightMode", privateModeIcon: "menu-NightMode-pbm")
    }

    fileprivate static var ShowNightModeItem: MenuItem {
        return AppMenuItem(title: Strings.MenuNightModeTurnOffLabel, accessibilityIdentifier: "ShowNightModeItem", action:  MenuAction(action: AppMenuAction.showNightMode.rawValue), icon: "menu-NightMode-Engaged", privateModeIcon: "menu-NightMode-Engaged")
    }
	
	fileprivate static var ShowWXItem: MenuItem { //jesse
        return AppMenuItem(title: Strings.MenuWXLabel, accessibilityIdentifier: "showWX", action:  MenuAction(action: AppMenuAction.showWX.rawValue), icon: "menu-NightMode-Engaged", privateModeIcon: "menu-NightMode-Engaged")
    }

    fileprivate static var SettingsMenuItem: MenuItem {
        return AppMenuItem(title: SettingsTitleString, accessibilityIdentifier: "SettingsMenuItem", action:  MenuAction(action: AppMenuAction.openSettings.rawValue), icon: "menu-Settings", privateModeIcon: "menu-Settings-pbm")
    }

    fileprivate static var CloseAllTabsMenuItem: MenuItem {
        return AppMenuItem(title: CloseAllTabsTitleString, accessibilityIdentifier: "CloseAllTabsMenuItem", action:  MenuAction(action: AppMenuAction.closeAllTabs.rawValue), icon: "menu-CloseTabs", privateModeIcon: "menu-CloseTabs-pbm")
    }

    fileprivate static var OpenHomePageMenuItem: MenuItem {
        return AppMenuItem(title: OpenHomePageTitleString, accessibilityIdentifier: "OpenHomePageMenuItem", action: MenuAction(action: AppMenuAction.openHomePage.rawValue), icon: "menu-Home", privateModeIcon: "menu-Home-pbm", selectedIcon: "menu-Home-Engaged")
    }

    fileprivate static var SetHomePageMenuItem: MenuItem {
        return AppMenuItem(title: SetHomePageTitleString, accessibilityIdentifier: "SetHomePageMenuItem", action: MenuAction(action: AppMenuAction.setHomePage.rawValue), icon: "menu-Home", privateModeIcon: "menu-Home-pbm", selectedIcon: "menu-Home-Engaged")
    }

    fileprivate static var SharePageMenuItem: MenuItem {
        return AppMenuItem(title: SharePageTitleString, accessibilityIdentifier: "SharePageMenuItem", action: MenuAction(action: AppMenuAction.sharePage.rawValue), icon: "menu-Send", privateModeIcon: "menu-Send-pbm", selectedIcon: "menu-Send-Engaged")
    }

    fileprivate static var TopSitesMenuToolbarItem: MenuToolbarItem {
        return AppMenuToolbarItem(title: TopSitesTitleString, accessibilityIdentifier: "TopSitesMenuToolbarItem", action:  MenuAction(action: AppMenuAction.openTopSites.rawValue), icon: "menu-panel-TopSites")
    }

    fileprivate static var BookmarksMenuToolbarItem: MenuToolbarItem {
        return AppMenuToolbarItem(title: BookmarksTitleString, accessibilityIdentifier: "BookmarksMenuToolbarItem", action:  MenuAction(action: AppMenuAction.openBookmarks.rawValue), icon: "menu-panel-Bookmarks")
    }

    fileprivate static var HistoryMenuToolbarItem: MenuToolbarItem {
        return AppMenuToolbarItem(title: HistoryTitleString, accessibilityIdentifier: "HistoryMenuToolbarItem", action:  MenuAction(action: AppMenuAction.openHistory.rawValue), icon: "menu-panel-History")
    }

    fileprivate static var ReadingListMenuToolbarItem: MenuToolbarItem {
        return  AppMenuToolbarItem(title: ReadingListTitleString, accessibilityIdentifier: "ReadingListMenuToolbarItem", action:  MenuAction(action: AppMenuAction.openReadingList.rawValue), icon: "menu-panel-ReadingList")
    }

    static let NewTabTitleString = NSLocalizedString("Menu.NewTabAction.Title", tableName: "Menu", value: "New Tab", comment: "Label for the button, displayed in the menu, used to open a new tab")
    static let NewPrivateTabTitleString = NSLocalizedString("Menu.NewPrivateTabAction.Title", tableName: "Menu", value: "New Private Tab", comment: "Label for the button, displayed in the menu, used to open a new private tab.")
    static let AddBookmarkTitleString = NSLocalizedString("Menu.AddBookmarkAction.Title", tableName: "Menu", value: "Add Bookmark", comment: "Label for the button, displayed in the menu, used to create a bookmark for the current website.")
    static let RemoveBookmarkTitleString = NSLocalizedString("Menu.RemoveBookmarkAction.Title", tableName: "Menu", value: "Remove Bookmark", comment: "Label for the button, displayed in the menu, used to delete an existing bookmark for the current website.")
    static let FindInPageTitleString = NSLocalizedString("Menu.FindInPageAction.Title", tableName: "Menu", value: "Find In Page", comment: "Label for the button, displayed in the menu, used to open the toolbar to search for text within the current page.")
    static let ViewDesktopSiteTitleString = NSLocalizedString("Menu.ViewDekstopSiteAction.Title", tableName: "Menu", value: "Request Desktop Site", comment: "Label for the button, displayed in the menu, used to request the desktop version of the current website.")
    static let ViewMobileSiteTitleString = NSLocalizedString("Menu.ViewMobileSiteAction.Title", tableName: "Menu", value: "Request Mobile Site", comment: "Label for the button, displayed in the menu, used to request the mobile version of the current website.")
    static let SettingsTitleString = NSLocalizedString("Menu.OpenSettingsAction.Title", tableName: "Menu", value: "Settings", comment: "Label for the button, displayed in the menu, used to open the Settings menu.")
    static let CloseAllTabsTitleString = NSLocalizedString("Menu.CloseAllTabsAction.Title", tableName: "Menu", value: "Close All Tabs", comment: "Label for the button, displayed in the menu, used to close all tabs currently open.")
    static let OpenHomePageTitleString = NSLocalizedString("Menu.OpenHomePageAction.Title", tableName: "Menu", value: "Home", comment: "Label for the button, displayed in the menu, used to navigate to the home page.")
    static let SetHomePageTitleString = NSLocalizedString("Menu.SetHomePageAction.Title", tableName: "Menu", value: "Set Homepage", comment: "Label for the button, displayed in the menu, used to set the homepage if none is currently set.")
    static let SharePageTitleString = NSLocalizedString("Menu.SendPageAction.Title", tableName: "Menu", value: "Send", comment: "Label for the button, displayed in the menu, used to open the share dialog.")
    static let TopSitesTitleString = NSLocalizedString("Menu.OpenTopSitesAction.AccessibilityLabel", tableName: "Menu", value: "Top Sites", comment: "Accessibility label for the button, displayed in the menu, used to open the Top Sites home panel.")
    static let BookmarksTitleString = NSLocalizedString("Menu.OpenBookmarksAction.AccessibilityLabel", tableName: "Menu", value: "Bookmarks", comment: "Accessibility label for the button, displayed in the menu, used to open the Bbookmarks home panel.")
    static let HistoryTitleString = NSLocalizedString("Menu.OpenHistoryAction.AccessibilityLabel", tableName: "Menu", value: "History", comment: "Accessibility label for the button, displayed in the menu, used to open the History home panel.")
    static let ReadingListTitleString = NSLocalizedString("Menu.OpenReadingListAction.AccessibilityLabel", tableName: "Menu", value: "Reading List", comment: "Accessibility label for the button, displayed in the menu, used to open the Reading list home panel.")
    static let MenuButtonAccessibilityLabel = NSLocalizedString("Toolbar.Menu.AccessibilityLabel", value: "Menu", comment: "Accessibility label for the Menu button.")
}
