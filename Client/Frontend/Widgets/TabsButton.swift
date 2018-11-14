/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import SnapKit
import Shared
import XCGLogger

private let log = Logger.browserLogger

struct TabsButtonUX {
    static let TitleColor: UIColor = UIColor.black
    static let TitleBackgroundColor: UIColor = UIColor.white
    static let CornerRadius: CGFloat = 2
    static let TitleFont: UIFont = UIConstants.DefaultChromeSmallFontBold
    static let BorderStrokeWidth: CGFloat = 1
    static let BorderColor: UIColor = UIColor.clear
    static let TitleInsets = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)

    static let Themes: [String: Theme] = {
        var themes = [String: Theme]()
        var theme = Theme()
        theme.borderColor = UIConstants.PrivateModePurple
        theme.borderWidth = BorderStrokeWidth
        theme.font = UIConstants.DefaultChromeBoldFont
        theme.backgroundColor = UIConstants.AppBackgroundColor
        theme.textColor = UIConstants.PrivateModePurple
        theme.insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        theme.highlightButtonColor = UIConstants.PrivateModePurple
        theme.highlightTextColor = TabsButtonUX.TitleColor
        theme.highlightBorderColor = UIConstants.PrivateModePurple
        themes[Theme.PrivateMode] = theme

        theme = Theme()
        theme.borderColor = BorderColor
        theme.borderWidth = BorderStrokeWidth
        theme.font = TitleFont
        theme.backgroundColor = TitleBackgroundColor
        theme.textColor = TitleColor
        theme.insets = TitleInsets
        theme.highlightButtonColor = TabsButtonUX.TitleColor
        theme.highlightTextColor = TabsButtonUX.TitleBackgroundColor
        theme.highlightBorderColor = TabsButtonUX.TitleBackgroundColor
        themes[Theme.NormalMode] = theme

        return themes
    }()
}

class TabsButton: UIControl {
    fileprivate var theme: Theme = TabsButtonUX.Themes[Theme.NormalMode]!
    
    override var isHighlighted: Bool {
        didSet {
            if isHighlighted {
                borderColor = theme.highlightBorderColor!
                titleBackgroundColor = theme.highlightButtonColor
                textColor = theme.highlightTextColor
            } else {
                borderColor = theme.borderColor!
                titleBackgroundColor = theme.backgroundColor
                textColor = theme.textColor
            }
        }
    }
    
    override var transform: CGAffineTransform {
        didSet {
            clonedTabsButton?.transform = transform
        }
    }

    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = TabsButtonUX.TitleFont
        label.layer.cornerRadius = TabsButtonUX.CornerRadius
        label.textAlignment = NSTextAlignment.center
        label.isUserInteractionEnabled = false
        return label
    }()

    lazy var insideButton: UIView = {
        let view = UIView()
        view.clipsToBounds = false
        view.isUserInteractionEnabled = false
        return view
    }()

    fileprivate lazy var labelBackground: UIView = {
        let background = UIView()
        background.layer.cornerRadius = TabsButtonUX.CornerRadius
        background.isUserInteractionEnabled = false
        return background
    }()

    fileprivate lazy var borderView: InnerStrokedView = {
        let border = InnerStrokedView()
        border.strokeWidth = TabsButtonUX.BorderStrokeWidth
        border.cornerRadius = TabsButtonUX.CornerRadius
        border.isUserInteractionEnabled = false
        return border
    }()

    fileprivate var buttonInsets: UIEdgeInsets = TabsButtonUX.TitleInsets
    
    // Used to temporarily store the cloned button so we can respond to layout changes during animation
    fileprivate weak var clonedTabsButton: TabsButton?

    override init(frame: CGRect) {
        super.init(frame: frame)
        insideButton.addSubview(labelBackground)
        insideButton.addSubview(borderView)
        insideButton.addSubview(titleLabel)
        addSubview(insideButton)
        isAccessibilityElement = true
        accessibilityTraits |= UIAccessibilityTraitButton
    }

    override func updateConstraints() {
        super.updateConstraints()
        labelBackground.snp.remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        borderView.snp.remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        titleLabel.snp.remakeConstraints { (make) -> Void in
            make.edges.equalTo(insideButton)
        }
        insideButton.snp.remakeConstraints { (make) -> Void in
            make.edges.equalTo(self).inset(insets)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func clone() -> UIView {
        let button = TabsButton()

        button.accessibilityLabel = accessibilityLabel
        button.titleLabel.text = titleLabel.text

        button.theme = theme

        // Copy all of the styable properties over to the new TabsButton
        button.titleLabel.font = titleLabel.font
        button.titleLabel.textColor = titleLabel.textColor
        button.titleLabel.layer.cornerRadius = titleLabel.layer.cornerRadius

        button.labelBackground.backgroundColor = labelBackground.backgroundColor
        button.labelBackground.layer.cornerRadius = labelBackground.layer.cornerRadius

        button.borderView.strokeWidth = borderView.strokeWidth
        button.borderView.color = borderView.color
        button.borderView.cornerRadius = borderView.cornerRadius

        return button
    }
    
    func updateTabCount(_ count: Int, animated: Bool = true) {
        let currentCount = self.titleLabel.text
        let infinity = "\u{221E}"
        let countToBe = (count < 100) ? count.description : infinity
        // only animate a tab count change if the tab count has actually changed
        if currentCount != count.description || (clonedTabsButton?.titleLabel.text ?? count.description) != count.description {
            if let _ = self.clonedTabsButton {
                self.clonedTabsButton?.layer.removeAllAnimations()
                self.clonedTabsButton?.removeFromSuperview()
                insideButton.layer.removeAllAnimations()
            }
            
            // make a 'clone' of the tabs button
            let newTabsButton = clone() as! TabsButton
            self.clonedTabsButton = newTabsButton
            newTabsButton.addTarget(self, action: #selector(TabsButton.cloneDidClickTabs), for: UIControlEvents.touchUpInside)
            newTabsButton.titleLabel.text = countToBe
            newTabsButton.accessibilityValue = countToBe
            superview?.addSubview(newTabsButton)
            newTabsButton.snp.makeConstraints { make in
                make.centerY.equalTo(self)
                make.trailing.equalTo(self)
                make.size.equalTo(UIConstants.ToolbarHeight)
            }
            
            newTabsButton.frame = self.frame
            newTabsButton.insets = insets
            
            // Instead of changing the anchorPoint of the CALayer, lets alter the rotation matrix math to be
            // a rotation around a non-origin point
            let frame = self.insideButton.frame
            let halfTitleHeight = frame.height / 2
            
            var newFlipTransform = CATransform3DIdentity
            newFlipTransform = CATransform3DTranslate(newFlipTransform, 0, halfTitleHeight, 0)
            newFlipTransform.m34 = -1.0 / 200.0 // add some perspective
            newFlipTransform = CATransform3DRotate(newFlipTransform, CGFloat(-(Double.pi / 2)), 1.0, 0.0, 0.0)
            newTabsButton.insideButton.layer.transform = newFlipTransform
            
            var oldFlipTransform = CATransform3DIdentity
            oldFlipTransform = CATransform3DTranslate(oldFlipTransform, 0, halfTitleHeight, 0)
            oldFlipTransform.m34 = -1.0 / 200.0 // add some perspective
            oldFlipTransform = CATransform3DRotate(oldFlipTransform, CGFloat(-(Double.pi / 2)), 1.0, 0.0, 0.0)
            
            let animate = {
                newTabsButton.insideButton.layer.transform = CATransform3DIdentity
                self.insideButton.layer.transform = oldFlipTransform
                self.insideButton.layer.opacity = 0
            }
            
            let completion: (Bool) -> Void = { _ in
                // Remove the clone and setup the actual tab button
                newTabsButton.removeFromSuperview()
                
                self.insideButton.layer.opacity = 1
                self.insideButton.layer.transform = CATransform3DIdentity
                self.accessibilityLabel = NSLocalizedString("Show Tabs", comment: "Accessibility label for the tabs button in the (top) tab toolbar")
                self.titleLabel.text = countToBe
                self.accessibilityValue = countToBe
            }
            
            if animated {
                UIView.animate(withDuration: 1.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.0, options: UIViewAnimationOptions(), animations: animate, completion: completion)
            } else {
                completion(true)
            }
        }
    }
    func cloneDidClickTabs() {
        sendActions(for: UIControlEvents.touchUpInside)
    }
}

extension TabsButton: Themeable {
    func applyTheme(_ themeName: String) {

        guard let theme = TabsButtonUX.Themes[themeName] else {
            log.error("Unable to apply unknown theme \(themeName)")
            return
        }

        borderColor = theme.borderColor!
        borderWidth = theme.borderWidth!
        titleFont = theme.font
        titleBackgroundColor = theme.backgroundColor
        textColor = theme.textColor
        insets = theme.insets!

        self.theme = theme
    }
}

// MARK: UIAppearance
extension TabsButton {
    dynamic var borderColor: UIColor {
        get { return borderView.color }
        set { borderView.color = newValue }
    }

    dynamic var borderWidth: CGFloat {
        get { return borderView.strokeWidth }
        set { borderView.strokeWidth = newValue }
    }

    dynamic var textColor: UIColor? {
        get { return titleLabel.textColor }
        set { titleLabel.textColor = newValue }
    }

    dynamic var titleFont: UIFont? {
        get { return titleLabel.font }
        set { titleLabel.font = newValue }
    }

    dynamic var titleBackgroundColor: UIColor? {
        get { return labelBackground.backgroundColor }
        set { labelBackground.backgroundColor = newValue }
    }

    dynamic var insets: UIEdgeInsets {
        get { return buttonInsets }
        set {
            buttonInsets = newValue
            setNeedsUpdateConstraints()
        }
    }
}
