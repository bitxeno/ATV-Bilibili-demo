//
//  TabBarPageFactory.swift
//  BilibiliLive
//
//  Created by yicheng on 2026/3/5.
//

import UIKit

class TabBarPageVCFactory {
    static func createVC(for page: TabBarPage) -> UIViewController {
        let vc: UIViewController
        switch page {
        case .live:
            vc = LiveViewController()
        case .feed:
            vc = FeedViewController()
        case .hot:
            vc = HotViewController()
        case .ranking:
            vc = RankingViewController()
        case .follows:
            vc = FollowsViewController()
        case .favorite:
            vc = FavoriteViewController()
        case .personal:
            let personalVC = PersonalViewController.create()
            personalVC.extendedLayoutIncludesOpaqueBars = true
            vc = personalVC
        case .search:
            let searchContainerVC = SearchContainerViewController()
            vc = searchContainerVC
        case .followBangumi:
            vc = FollowBangumiViewController()
        case .followUps:
            vc = FollowUpsViewController()
        case .toView:
            vc = ToViewViewController()
        case .history:
            vc = HistoryViewController()
        case .weeklyWatch:
            vc = WeeklyWatchViewController()
        }

        switch page {
        case .search:
            vc.tabBarItem.image = UIImage(systemName: "magnifyingglass", withConfiguration: UIImage.SymbolConfiguration(font: .preferredFont(forTextStyle: .body)))
            vc.tabBarItem.title = nil
        default:
            vc.tabBarItem.title = page.title
        }
        vc.tabBarItem.accessibilityIdentifier = page.rawValue
        return vc
    }
}
