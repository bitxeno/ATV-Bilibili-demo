//
//  UpSpaceSeasonSeriesViewController.swift
//  BilibiliLive
//
//  Created by Codex on 2026/4/19.
//

import Foundation
import SnapKit
import UIKit

class UpSpaceSeasonSeriesViewController: CategoryViewController {
    var mid: Int!
    var upName: String?
    private let emptyLabel = UILabel()

    override func viewDidLoad() {
        categories = []
        super.viewDidLoad()
        setupEmptyLabel()

        Task { [weak self] in
            guard let self else { return }
            do {
                let list = try await WebRequest.requestAllUpSpaceSeasonSeries(mid: self.mid)
                    .filter { $0.id > 0 }

                await MainActor.run {
                    if list.isEmpty {
                        self.emptyLabel.isHidden = false
                        return
                    }

                    self.emptyLabel.isHidden = true
                    self.categories = list.map { info in
                        CategoryDisplayModel(
                            title: info.title,
                            contentVC: UpSpaceSeasonSeriesContentViewController(info: info, upName: self.upName)
                        )
                    }
                    self.initTypeCollectionView()
                }
            } catch {
                await MainActor.run {
                    self.showError(error)
                }
            }
        }
    }

    private func setupEmptyLabel() {
        view.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().offset(40)
            make.trailing.lessThanOrEqualToSuperview().offset(-40)
        }
        emptyLabel.text = "该 UP 主暂无合集和系列"
        emptyLabel.font = .systemFont(ofSize: 28, weight: .medium)
        emptyLabel.textColor = UIColor(named: "titleColor") ?? .white
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.isHidden = true
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(title: "Error", message: "\(error)", preferredStyle: .alert)
        alert.addAction(.init(title: "Ok", style: .cancel))
        present(alert, animated: true)
    }
}

class UpSpaceSeasonSeriesContentViewController: StandardVideoCollectionViewController<UpSpaceSeasonSeriesVideoData> {
    private let info: UpSpaceSeasonSeriesCategory
    private let upName: String?

    init(info: UpSpaceSeasonSeriesCategory, upName: String?) {
        self.info = info
        self.upName = upName
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func setupCollectionView() {
        collectionVC.styleOverride = .sideBar
        super.setupCollectionView()
    }

    override func request(page: Int) async throws -> [UpSpaceSeasonSeriesVideoData] {
        var videos: [UpSpaceSeasonSeriesVideoData]
        switch info.type {
        case .season:
            videos = try await WebRequest.requestUpSpaceSeasonArchives(mid: info.mid, seasonId: info.id, page: page)
        case .series:
            videos = try await WebRequest.requestUpSpaceSeriesArchives(mid: info.mid, seriesId: info.id, page: page)
        }
        if let upName, !upName.isEmpty {
            videos = videos.map { data in
                var data = data
                data.ownerNameOverride = upName
                return data
            }
        }
        return videos
    }
}
