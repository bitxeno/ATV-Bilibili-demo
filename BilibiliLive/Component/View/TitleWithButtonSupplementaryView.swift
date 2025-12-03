//
//  TitleWithButtonSupplementaryView.swift
//  BilibiliLive
//
//  Created by AI Assistant on 2025/12/03.
//

import SnapKit
import UIKit

class TitleWithButtonSupplementaryView: UICollectionReusableView {
    let label = UILabel()
    let chevronButton = UIButton(type: .system)
    let containerView = UIView()
    static let reuseIdentifier = "title-with-button-supplementary-reuse-identifier"

    var onButtonTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }

    private func configure() {
        addSubview(containerView)
        containerView.addSubview(label)
        containerView.addSubview(chevronButton)

        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        label.font = UIFont.preferredFont(forTextStyle: .title3)
        label.adjustsFontForContentSizeCategory = true
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
        }

        // 配置箭头按钮
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.right")
        config.baseForegroundColor = .white
        config.background.backgroundColor = UIColor(white: 0.3, alpha: 0.8)
        config.background.cornerRadius = 22
        config.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        chevronButton.configuration = config
        chevronButton.addTarget(self, action: #selector(buttonTapped), for: .primaryActionTriggered)
        chevronButton.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(10)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(44)
            make.trailing.lessThanOrEqualToSuperview().offset(-20)
        }
    }

    @objc private func buttonTapped() {
        onButtonTapped?()
    }
}
