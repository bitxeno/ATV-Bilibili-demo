//
//  SegmentViewController.swift
//  BilibiliLive
//
//  Created by bitxeno on 2025/11/29.
//

import Foundation
import SnapKit
import UIKit

class SegmentViewController: UIViewController, BLTabBarContentVCProtocol {
    struct CategoryDisplayModel {
        let title: String
        let contentVC: UIViewController
        var autoSelect: Bool? = true
    }

    var segmentedControl: UISegmentedControl!
    var categories = [CategoryDisplayModel]()
    let contentView = UIView()
    weak var currentViewController: UIViewController?
    let leftSeparator = UIView()
    let rightSeparator = UIView()
    private weak var currentCollectionView: UICollectionView?
    private var originalDelegate: UICollectionViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        if categories.isEmpty {
        } else {
            initSegmentedControl()
        }
    }

    func initSegmentedControl() {
        if segmentedControl != nil {
            return
        }

        let items = categories.map { $0.title }
        segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.addTarget(self, action: #selector(segmentChanged(_:)), for: .valueChanged)
        segmentedControl.backgroundColor = .clear
        // segmentedControl.tintColor = .clear

        // Set font size to body style
        let attributes = [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .body)]
        segmentedControl.setTitleTextAttributes(attributes, for: .normal)
        segmentedControl.setTitleTextAttributes(attributes, for: .selected)

        view.addSubview(segmentedControl)
        segmentedControl.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.centerX.equalToSuperview()
            make.width.lessThanOrEqualToSuperview().inset(40)
        }

        // Add left separator
        leftSeparator.backgroundColor = .separator
        view.addSubview(leftSeparator)
        leftSeparator.snp.makeConstraints { make in
            make.left.equalTo(view.safeAreaLayoutGuide.snp.left).offset(60)
            make.right.equalTo(segmentedControl.snp.left).offset(-40)
            make.centerY.equalTo(segmentedControl)
            make.height.equalTo(1)
        }

        // Add right separator
        rightSeparator.backgroundColor = .separator
        view.addSubview(rightSeparator)
        rightSeparator.snp.makeConstraints { make in
            make.left.equalTo(segmentedControl.snp.right).offset(40)
            make.right.equalTo(view.safeAreaLayoutGuide.snp.right).offset(-60)
            make.centerY.equalTo(segmentedControl)
            make.height.equalTo(1)
        }

        let leftFocusGuide = UIFocusGuide()
        view.addLayoutGuide(leftFocusGuide)
        leftFocusGuide.snp.makeConstraints { make in
            make.top.bottom.equalTo(segmentedControl)
            make.right.equalTo(segmentedControl.snp.left)
            make.left.equalToSuperview()
        }
        leftFocusGuide.preferredFocusEnvironments = [segmentedControl]

        let rightFocusGuide = UIFocusGuide()
        view.addLayoutGuide(rightFocusGuide)
        rightFocusGuide.snp.makeConstraints { make in
            make.top.bottom.equalTo(segmentedControl)
            make.left.equalTo(segmentedControl.snp.right)
            make.right.equalToSuperview()
        }
        rightFocusGuide.preferredFocusEnvironments = [segmentedControl]

        view.addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.right.bottom.top.equalToSuperview()
        }

        // Load initial view controller
        if !categories.isEmpty {
            setViewController(vc: categories[0].contentVC)
        }
    }

    @objc func segmentChanged(_ sender: UISegmentedControl) {
        let index = sender.selectedSegmentIndex
        if index >= 0 && index < categories.count {
            setViewController(vc: categories[index].contentVC)
        }
    }

    func setViewController(vc: UIViewController) {
        // 清理旧的
        currentViewController?.willMove(toParent: nil)
        currentViewController?.view.removeFromSuperview()
        currentViewController?.removeFromParent()
        restoreOriginalDelegate()

        currentViewController = vc
        addChild(vc)
        contentView.addSubview(vc.view)
        vc.view.makeConstraintsToBindToSuperview()
        vc.didMove(toParent: self)

        // 查找并配置 collectionView
        setupCollectionViewHeader(in: vc)
    }

    private func setupCollectionViewHeader(in vc: UIViewController) {
        var targetCollectionView: UICollectionView?

        // 查找 FeedCollectionViewController 中的 collectionView
        if let collectionVC = vc as? FeedCollectionViewController {
            targetCollectionView = collectionVC.collectionView
        } else {
            for child in vc.children {
                if let collectionVC = child as? FeedCollectionViewController {
                    targetCollectionView = collectionVC.collectionView
                    break
                }
            }
        }

        guard let collectionView = targetCollectionView else { return }

        currentCollectionView = collectionView

        // 保存原始 delegate 并设置新的
        originalDelegate = collectionView.delegate
        collectionView.delegate = self
        collectionView.contentInset = UIEdgeInsets(top: 100, left: 0, bottom: 0, right: 0)

        // 设置内容滚动视图
        setContentScrollView(collectionView)
    }

    private func restoreOriginalDelegate() {
        if let collectionView = currentCollectionView,
           let originalDelegate = originalDelegate
        {
            collectionView.delegate = originalDelegate
        }
        currentCollectionView = nil
        originalDelegate = nil
    }

    func reloadData() {
        (currentViewController as? BLTabBarContentVCProtocol)?.reloadData()
    }
}

// MARK: - UICollectionViewDelegate

extension SegmentViewController: UICollectionViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // 转发给原始 delegate
        originalDelegate?.scrollViewDidScroll?(scrollView)

        // 根据滚动位置调整 segmentedControl 的透明度或位置
        let offsetY = scrollView.contentOffset.y + scrollView.contentInset.top
        let alpha = max(0, min(1, 1 - (offsetY / 100)))

        segmentedControl.alpha = alpha
        leftSeparator.alpha = alpha
        rightSeparator.alpha = alpha
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        originalDelegate?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        originalDelegate?.collectionView?(collectionView, willDisplay: cell, forItemAt: indexPath)
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        return (originalDelegate as? UICollectionViewDelegate)?.indexPathForPreferredFocusedView?(in: collectionView)
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        originalDelegate?.scrollViewWillBeginDecelerating?(scrollView)
    }
}
