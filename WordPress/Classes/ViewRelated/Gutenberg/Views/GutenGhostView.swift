import UIKit

class GutenGhostView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    @IBOutlet weak var toolbarTopBorderView: UIView! {
        didSet {
            if #available(iOS 12.0, *) {
                let isDarkStyle = traitCollection.userInterfaceStyle == .dark
                toolbarTopBorderView.isHidden = isDarkStyle
            }
        }
    }

    @IBOutlet var blockElementViews: [UIView]! {
        didSet {
            blockElementViews.forEach { (view) in
                view.backgroundColor = .ghostBlockBackground
            }
        }
    }


    @IBOutlet var buttonsViews: [UIView]! {
        didSet {
            buttonsViews.forEach { (view) in
                view.backgroundColor = .clear
            }
        }
    }

    @IBOutlet weak private var inserterView: UIView! {
        didSet {
            inserterView.layer.cornerRadius = inserterView.frame.height / 2
            inserterView.clipsToBounds = true
        }
    }

    @IBOutlet private var roundedCornerViews: [UIView]! {
        didSet {
            roundedCornerViews.forEach { (view) in
                view.layer.cornerRadius = 6
                view.clipsToBounds = true
            }
        }
    }

    @IBOutlet weak var toolbarBackgroundView: UIView! {
        didSet {
            toolbarBackgroundView.isGhostableDisabled = true
            toolbarBackgroundView.backgroundColor = .ghostToolbarBackground
        }
    }

    func startAnimation() {
        let style = GhostStyle(beatDuration: GhostStyle.Defaults.beatDuration,
                               beatStartColor: .placeholderElement,
                               beatEndColor: .beatEndColor)
        startGhostAnimation(style: style)
    }

    private func commonInit() {
        let bundle = Bundle(for: GutenGhostView.self)
        guard
            let nibViews = bundle.loadNibNamed("GutenGhostView", owner: self, options: nil),
            let contentView = nibViews.first as? UIView
        else {
            return
        }

        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate(
            contentView.constrainToSuperViewEdges()
        )

        backgroundColor = .background
    }
}

private extension UIColor {
    static var ghostToolbarBackground: UIColor {
        if #available(iOS 13, *) {
            return UIColor(light: .clear, dark: UIColor.colorFromHex("2e2e2e"))
        }
        return .clear
    }

    static var ghostBlockBackground: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(light: .clear, dark: .systemGray5)
        } else {
            return .clear
        }
    }

    static var beatEndColor: UIColor {
        if #available(iOS 13.0, *) {
            return UIColor(light: .systemGray6, dark: .clear)
        } else {
            return .placeholderElementFaded
        }
    }

    static var background: UIColor {
        if #available(iOS 13.0, *) {
            return .systemBackground
        } else {
            return .white
        }
    }
}