//
//  SearchContainerViewController.swift
//  BilibiliLive
//
//  Created by AI Assistant on 2025/11/30.
//

import UIKit

class SearchContainerViewController: UIViewController {
    private var searchController: UISearchController!
    private var resultVC: SearchResultViewController!

    override func viewDidLoad() {
        super.viewDidLoad()

        // 创建搜索结果控制器
        resultVC = SearchResultViewController()

        // 创建搜索控制器
        searchController = UISearchController(searchResultsController: resultVC)
        searchController.searchResultsUpdater = resultVC
        searchController.obscuresBackgroundDuringPresentation = false

        // 配置搜索栏
        searchController.searchBar.placeholder = "搜索"

        definesPresentationContext = true

        // 在 tvOS 上需要手动将搜索栏添加到视图层次
        view.addSubview(searchController.searchBar)
        searchController.searchBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchController.searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchController.searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchController.searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 在视图显示后激活搜索控制器
        if !searchController.isActive {
            DispatchQueue.main.async { [weak self] in
                self?.searchController.isActive = true
            }
        }
    }

    // MARK: - Focus Management

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        // 优先聚焦到搜索栏
        if let searchBar = searchController.searchBar as UIFocusEnvironment? {
            return [searchBar]
        }
        return super.preferredFocusEnvironments
    }
}
