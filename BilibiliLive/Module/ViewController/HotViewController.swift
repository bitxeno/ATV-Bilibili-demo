//
//  HotViewController.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/10/26.
//

import SnapKit
import UIKit

// MARK: - Custom Header View

class HotHeaderView: UICollectionReusableView {
    static let reuseIdentifier = "HotHeaderView"

    private let rankingButton = UIButton(type: .system)
    private let weeklyButton = UIButton(type: .system)
    private let stackView = UIStackView()

    var onRankingTapped: (() -> Void)?
    var onWeeklyTapped: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        // 配置排行榜按钮
        var rankingConfig = UIButton.Configuration.filled()
        rankingConfig.title = "排行榜"
        rankingConfig.image = UIImage(systemName: "chart.bar.fill")
        rankingConfig.imagePlacement = .leading
        rankingConfig.imagePadding = 12
        rankingConfig.baseBackgroundColor = .systemPink
        rankingConfig.baseForegroundColor = .white
        rankingConfig.cornerStyle = .medium
        rankingConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 32, weight: .medium)
            return outgoing
        }
        rankingButton.configuration = rankingConfig
        rankingButton.addTarget(self, action: #selector(rankingButtonTapped), for: .primaryActionTriggered)

        // 配置每周必看按钮
        var weeklyConfig = UIButton.Configuration.filled()
        weeklyConfig.title = "每周必看"
        weeklyConfig.image = UIImage(systemName: "star.fill")
        weeklyConfig.imagePlacement = .leading
        weeklyConfig.imagePadding = 12
        weeklyConfig.baseBackgroundColor = .systemOrange
        weeklyConfig.baseForegroundColor = .white
        weeklyConfig.cornerStyle = .medium
        weeklyConfig.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 32, weight: .medium)
            return outgoing
        }
        weeklyButton.configuration = weeklyConfig
        weeklyButton.addTarget(self, action: #selector(weeklyButtonTapped), for: .primaryActionTriggered)

        // 配置 StackView
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = 60

        addSubview(stackView)
        stackView.addArrangedSubview(rankingButton)
        stackView.addArrangedSubview(weeklyButton)

        stackView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(32)
            make.top.equalToSuperview().offset(20)
            make.bottom.equalToSuperview().offset(-30)
            make.height.equalTo(100)
        }
    }

    @objc private func rankingButtonTapped() {
        onRankingTapped?()
    }

    @objc private func weeklyButtonTapped() {
        onWeeklyTapped?()
    }
}

// MARK: - HotViewController

class HotViewController: StandardVideoCollectionViewController<VideoDetail.Info> {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCustomHeader()
    }

    override func request(page: Int) async throws -> [VideoDetail.Info] {
        return try await WebRequest.requestHotVideo(page: page).list
    }

    private func setupCustomHeader() {
        // 配置自定义 header
        let headerConfig = FeedHeaderConfig(
            viewType: HotHeaderView.self,
            estimatedHeight: 160
        ) { [weak self] (headerView: HotHeaderView, indexPath) in
            headerView.onRankingTapped = {
                self?.showRanking()
            }
            headerView.onWeeklyTapped = {
                self?.showWeeklyMustWatch()
            }
        }

        collectionVC.customHeaderConfig = headerConfig
        collectionVC.showHeader = true
    }

    private func showRanking() {
        let rankingVC = RankingViewController()
        present(rankingVC, animated: true)
    }

    private func showWeeklyMustWatch() {
        let weeklyVC = WeeklyWatchViewController()
        present(weeklyVC, animated: true)
    }
}

extension WebRequest {
    static func requestHotVideo(page: Int) async throws -> HotData {
        try await request(url: EndPoint.hot, parameters: ["pn": page, "ps": 40], noCookie: Settings.requestHotWithoutCookie)
    }
}

extension WebRequest.EndPoint {
    static let hot = "https://api.bilibili.com/x/web-interface/popular"
}

struct HotData: Codable {
    let no_more: Bool
    let list: [VideoDetail.Info]
}
