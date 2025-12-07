//
//  BLTextOnlyCollectionViewCell.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/10/24.
//

import Foundation
import UIKit

class BLTextOnlyCollectionViewCell: BLMotionCollectionViewCell {
    private let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let selectedWhiteView = UIView()
    let titleLabel = UILabel()

    // Badge view components
    private let badgeView = UIView()
    private let badgeLabel = UILabel()

    // Press event handler
    var onPressEnded: ((UIPress.PressType) -> Void)?

    override func setup() {
        super.setup()
        scaleFactor = 1.15
        contentView.addSubview(effectView)
        effectView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        effectView.contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(20)
            make.top.bottom.lessThanOrEqualToSuperview().inset(8)
        }
        titleLabel.textColor = .white
        titleLabel.numberOfLines = 2
        titleLabel.font = UIFont.systemFont(ofSize: 26, weight: .medium)
        effectView.layer.cornerRadius = 16
        effectView.clipsToBounds = true

        // Setup badge view
        effectView.contentView.addSubview(badgeView)
        badgeView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
        }
        badgeView.layer.cornerRadius = 12
        badgeView.layer.maskedCorners = [.layerMinXMaxYCorner]
        badgeView.layer.masksToBounds = true
        badgeView.isHidden = true

        badgeView.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8))
        }
        badgeLabel.textColor = .white
        badgeLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        badgeLabel.textAlignment = .center
    }

    // Configure badge with text and background color
    func configureBadge(text: String?, backgroundColor: UIColor = .systemRed) {
        if let text = text, !text.isEmpty {
            badgeLabel.text = text
            badgeView.backgroundColor = backgroundColor
            badgeView.isHidden = false
        } else {
            badgeView.isHidden = true
        }
    }

    override func didUpdateFocus(in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        super.didUpdateFocus(in: context, with: coordinator)
        selectedWhiteView.isHidden = !isFocused
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)

        if let press = presses.first {
            onPressEnded?(press.type)
        }
    }
}
