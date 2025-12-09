//
//  SearchContainerViewController.swift
//  BilibiliLive
//
//  Created by AI Assistant on 2025/11/30.
//

import UIKit

class SearchContainerViewController: UIViewController {
    private var searchController: UISearchController!
    private var searchContainerViewController: UISearchContainerViewController!
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

        searchContainerViewController = UISearchContainerViewController(searchController: searchController)

        // 在 tvOS 上需要手动将搜索栏添加到视图层次
        addChild(searchContainerViewController)
        searchContainerViewController.view.frame = view.bounds
        view.addSubview(searchContainerViewController.view)
        searchContainerViewController.didMove(toParent: self)
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
}
