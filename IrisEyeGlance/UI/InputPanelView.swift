//
//  InputPanelView.swift
//  IrisEyeGlance
//
//  Draws the 4x4 input grid from `InputPanelLayoutModel`, highlights the region under the
//  cursor and shows the four glance characters for that region. Replaces the PNG panels.
//

import UIKit
import IrisEyeGlanceCore

final class InputPanelView: UIView {
    static let highlightColor = UIColor(red: 26/255, green: 128/255, blue: 133/255, alpha: 1)

    var layout: KeyboardLayout = .japanese {
        didSet {
            guard layout != oldValue else { return }
            setNeedsDisplay()
            updateHint()
            accessibilityValue = layout.isAlphabet ? "アルファベット" : "日本語"
        }
    }

    var preset: PanelSizePreset = .standard {
        didSet { setNeedsDisplay(); updateHint() }
    }

    private(set) var highlightedRegion = 0
    private let hintView = GlanceHintView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        contentMode = .redraw
        addSubview(hintView)
        hintView.isHidden = true
        isAccessibilityElement = true
        accessibilityLabel = "入力パネル"
        accessibilityHint = "ドラッグで移動、ダブルタップで大きさを変更"
        accessibilityValue = "日本語"
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Panel geometry in the coordinate space of the superview, for the region resolver.
    var panelFrame: InputPanelFrame {
        InputPanelFrame(center: center, width: bounds.width, height: bounds.height)
    }

    private var localFrame: InputPanelFrame {
        InputPanelFrame(center: CGPoint(x: bounds.midX, y: bounds.midY), width: bounds.width, height: bounds.height)
    }

    private var model: InputPanelLayoutModel {
        InputPanelLayoutModel(layout: layout, frame: localFrame)
    }

    func setHighlightedRegion(_ region: Int) {
        guard region != highlightedRegion else { return }
        highlightedRegion = region
        setNeedsDisplay()
        updateHint()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setNeedsDisplay()
        updateHint()
    }

    override func draw(_ rect: CGRect) {
        let model = self.model

        UIColor.systemBackground.withAlphaComponent(0.85).setFill()
        UIBezierPath(roundedRect: bounds, cornerRadius: 6).fill()

        for cell in model.cells {
            if cell.isSpecial {
                UIColor.systemGray4.withAlphaComponent(0.9).setFill()
                UIRectFill(cell.rect)
            }
            let border = UIBezierPath(rect: cell.rect)
            border.lineWidth = 0.5
            UIColor.systemGray2.setStroke()
            border.stroke()

            let fontSize = min(cell.rect.width, cell.rect.height) * 0.5
            if let title = cell.title {
                let scale: CGFloat = title.count > 1 ? 0.55 : 1
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: fontSize * scale, weight: .medium),
                    .foregroundColor: UIColor.label,
                ]
                let size = (title as NSString).size(withAttributes: attributes)
                let origin = CGPoint(x: cell.rect.midX - size.width / 2, y: cell.rect.midY - size.height / 2)
                (title as NSString).draw(at: origin, withAttributes: attributes)
            } else if let symbol = cell.symbolName,
                      let image = UIImage(systemName: symbol, withConfiguration: UIImage.SymbolConfiguration(pointSize: fontSize * 0.8, weight: .medium))?
                        .withTintColor(.label, renderingMode: .alwaysOriginal) {
                let origin = CGPoint(x: cell.rect.midX - image.size.width / 2, y: cell.rect.midY - image.size.height / 2)
                image.draw(at: origin)
            }
        }

        if let cell = model.cell(forRegion: highlightedRegion) {
            let highlight = UIBezierPath(rect: cell.rect.insetBy(dx: preset.lineWidth / 2, dy: preset.lineWidth / 2))
            highlight.lineWidth = preset.lineWidth * 2
            InputPanelView.highlightColor.setStroke()
            highlight.stroke()
        }
    }

    private func updateHint() {
        let model = self.model
        guard let hints = model.glanceHints(forRegion: highlightedRegion), let cell = model.cell(forRegion: highlightedRegion) else {
            hintView.isHidden = true
            return
        }
        hintView.update(hints)
        hintView.bounds.size = preset.hintSize
        hintView.center = CGPoint(x: cell.rect.midX, y: cell.rect.midY)
        hintView.isHidden = false
    }
}

/// Four rounded labels showing the characters reachable by glancing to each corner.
final class GlanceHintView: UIView {
    private let labels: [UILabel] = (0..<4).map { _ in
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.backgroundColor = UIColor.systemTeal.withAlphaComponent(0.9)
        label.layer.cornerRadius = 6
        label.layer.borderWidth = 1
        label.layer.borderColor = UIColor.systemGray.cgColor
        label.clipsToBounds = true
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        label.adjustsFontSizeToFitWidth = true
        return label
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        labels.forEach(addSubview)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    /// Order: upper-left, upper-right, lower-left, lower-right.
    func update(_ hints: [String]) {
        for (label, hint) in zip(labels, hints) {
            label.text = hint
            label.isHidden = hint.isEmpty
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = CGSize(width: bounds.width * 0.38, height: bounds.height * 0.38)
        let positions = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: bounds.width - size.width, y: 0),
            CGPoint(x: 0, y: bounds.height - size.height),
            CGPoint(x: bounds.width - size.width, y: bounds.height - size.height),
        ]
        for (label, origin) in zip(labels, positions) {
            label.frame = CGRect(origin: origin, size: size)
            label.font = UIFont.systemFont(ofSize: size.height * 0.55, weight: .semibold)
        }
    }
}
