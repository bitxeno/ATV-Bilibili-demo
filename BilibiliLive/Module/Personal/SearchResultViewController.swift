//
//  SearchResultViewController.swift
//  BilibiliLive
//
//  Created by whw on 2022/11/2.
//

import Combine
import Kingfisher
import SnapKit
import UIKit

class SearchResultViewController: UIViewController {
    var collectionView: UICollectionView!
    var dataSource: UICollectionViewDiffableDataSource<SearchList, Item>!
    var currentSnapshot: NSDiffableDataSourceSnapshot<SearchList, Item>!
    static let titleElementKind = "titleElementKind"

    enum Item: Hashable {
        case video(SearchResult.Video)
        case bangumi(SearchResult.Bangumi)
        case user(SearchResult.User)
        case liveRoom(SearchLiveResult.Result.LiveRoom)
        case rankVideo(VideoDetail.Info)
        case weeklyVideo(VideoDetail.Info)
    }

    @Published var searchText: String = ""
    var cancellable: Cancellable?
    private let suggestDelayWork = DelayWork(delay: 1.0)
    private var showHistorySuggest = false
    private var isShowingDefaultContent = false
    // 用于防止并发执行 showDefaultContent()
    private var isShowingDefaultContentInProgress = false

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        tabBarObservedScrollView = collectionView
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        configureDataSource()

        cancellable = $searchText
            .filter({ $0.count > 0 })
            .debounce(for: 0.8, scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] key in
                guard let self else { return }
                Task { @MainActor in
                    await self.performSearch(key: key)
                }
            }
    }

    @MainActor
    private func performSearch(key: String) async {
        // 使用 async let 并行请求
        async let searchResultTask = WebRequest.requestSearchResult(key: key)
        async let liveResultTask = WebRequest.requestSearchLiveResult(key: key)

        let searchResult = try? await searchResultTask
        let liveResult = try? await liveResultTask

        // 搜索词已清空，放弃此次结果
        if searchText.isEmpty {
            return
        }

        updateSnapshot(searchResult: searchResult, liveResult: liveResult)
    }

    @MainActor
    private func updateSnapshot(searchResult: SearchResult?, liveResult: SearchLiveResult?) {
        currentSnapshot.deleteAllItems()
        dataSource.apply(currentSnapshot)

        let defaultHeight = NSCollectionLayoutDimension.fractionalWidth(Settings.displayStyle == .large ? 0.26 : 0.2)

        // 添加综合搜索结果
        if let searchResult {
            for section in searchResult.result {
                switch section {
                case let .video(data):
                    let list = SearchList(title: "视频", height: defaultHeight, scrollingBehavior: .continuous)
                    currentSnapshot.appendSections([list])
                    currentSnapshot.appendItems(data.map { .video($0) }, toSection: list)
                case let .bangumi(data):
                    let list = SearchList(title: "番剧", height: defaultHeight, scrollingBehavior: .continuous)
                    currentSnapshot.appendSections([list])
                    currentSnapshot.appendItems(data.map { .bangumi($0) }, toSection: list)
                case let .movie(data):
                    let list = SearchList(title: "影视", height: defaultHeight, scrollingBehavior: .none)
                    currentSnapshot.appendSections([list])
                    currentSnapshot.appendItems(data.map { .bangumi($0) }, toSection: list)
                case let .user(data):
                    let list = SearchList(title: "用户", height: .estimated(140), scrollingBehavior: .continuous)
                    currentSnapshot.appendSections([list])
                    currentSnapshot.appendItems(data.map { .user($0) }, toSection: list)
                case .none:
                    break
                }
            }
        }

        // 添加直播搜索结果
        if let liveResult, let liveRooms = liveResult.result.live_room, !liveRooms.isEmpty {
            let list = SearchList(title: "直播", height: defaultHeight, scrollingBehavior: .continuous)
            currentSnapshot.appendSections([list])
            currentSnapshot.appendItems(liveRooms.map { .liveRoom($0) }, toSection: list)
        }

        dataSource.apply(currentSnapshot)
    }

    @MainActor
    private func showDefaultContent() async {
        // 防止并发调用导致的重入问题
        guard !isShowingDefaultContentInProgress else { return }
        isShowingDefaultContentInProgress = true
        defer { isShowingDefaultContentInProgress = false }

        isShowingDefaultContent = true
        currentSnapshot.deleteAllItems()
        await dataSource.apply(currentSnapshot)

        let defaultHeight = NSCollectionLayoutDimension.fractionalWidth(Settings.displayStyle == .large ? 0.26 : 0.2)

        // 获取排行榜数据（取前20条）
        if let rankVideos = try? await WebRequest.requestRank(for: 0) {
            let list = SearchList(title: "排行榜", height: defaultHeight, scrollingBehavior: .continuous)
            currentSnapshot.appendSections([list])
            let videos = Array(rankVideos.prefix(20))
            currentSnapshot.appendItems(videos.map { .rankVideo($0) }, toSection: list)
        }

        // 获取一周必看数据（取前20条）
        if let weeklyList = try? await WebRequest.requestWeeklyWatchList(),
           let firstWeek = weeklyList.first,
           let weeklyVideos = try? await WebRequest.requestWeeklyWatch(wid: firstWeek.number)
        {
            let list = SearchList(title: "一周必看", height: defaultHeight, scrollingBehavior: .continuous)
            currentSnapshot.appendSections([list])
            let videos = Array(weeklyVideos.prefix(20))
            currentSnapshot.appendItems(videos.map { .weeklyVideo($0) }, toSection: list)
        }

        await dataSource.apply(currentSnapshot)
    }

    func reloadData() {
        // 如果正在显示默认内容，刷新默认内容
        if isShowingDefaultContent {
            Task { @MainActor in
                await showDefaultContent()
            }
        } else if !searchText.isEmpty {
            // 如果有搜索内容，重新执行搜索
            Task { @MainActor in
                await performSearch(key: searchText)
            }
        }
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        guard let buttonPress = presses.first?.type else { return }
        if buttonPress == .playPause {
            reloadData()
        }
    }
}

extension SearchResultViewController {
    private func createLayout() -> UICollectionViewLayout {
        let sectionProvider = { [self]
            (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
                let sectionIdentifier = dataSource.snapshot().sectionIdentifiers[sectionIndex]

                let section: NSCollectionLayoutSection
                if sectionIdentifier.scrollingBehavior == .none {
                    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                           heightDimension: sectionIdentifier.height)
                    let itemSize = NSCollectionLayoutSize(widthDimension: sectionIdentifier.width,
                                                          heightDimension: .fractionalHeight(1))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    let hSpacing: CGFloat = Settings.displayStyle == .large ? 35 : 30
                    item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: hSpacing, bottom: 0, trailing: hSpacing)
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                    group.edgeSpacing = .init(leading: .fixed(0), top: .fixed(40), trailing: .fixed(0), bottom: .fixed(-60))
                    section = NSCollectionLayoutSection(group: group)
                } else {
                    let groupSize = NSCollectionLayoutSize(widthDimension: sectionIdentifier.width,
                                                           heightDimension: sectionIdentifier.height)
                    let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                                          heightDimension: .fractionalHeight(1))
                    let item = NSCollectionLayoutItem(layoutSize: itemSize)
                    let hSpacing: CGFloat = Settings.displayStyle == .large ? 35 : 30
                    item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: hSpacing, bottom: 0, trailing: hSpacing)
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                    group.edgeSpacing = .init(leading: .fixed(0), top: .fixed(40), trailing: .fixed(0), bottom: .fixed(0))
                    section = NSCollectionLayoutSection(group: group)
                    section.orthogonalScrollingBehavior = sectionIdentifier.scrollingBehavior
                }

                let titleSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .estimated(44))
                let titleSupplementary = NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: titleSize,
                    elementKind: FavoriteViewController.titleElementKind,
                    alignment: .top
                )
                section.boundarySupplementaryItems = [titleSupplementary]
                return section
        }

        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.interSectionSpacing = 20

        let layout = UICollectionViewCompositionalLayout(
            sectionProvider: sectionProvider, configuration: config
        )
        return layout
    }

    private func configureDataSource() {
        let displayCell = UICollectionView.CellRegistration<FeedCollectionViewCell, any DisplayData> {
            $0.setup(data: $2)
        }
        let userCell = UICollectionView.CellRegistration<UpCell, SearchResult.User> {
            $0.nameLabel.text = $2.uname
            $0.despLabel.text = $2.usign
            $0.imageView.kf.setImage(with: $2.upic.addSchemeIfNeed(), options: [.processor(DownsamplingImageProcessor(size: CGSize(width: 80, height: 80))), .processor(RoundCornerImageProcessor(radius: .widthFraction(0.5))), .cacheSerializer(FormatIndicatedCacheSerializer.png)])
        }
        let rankVideoCell = UICollectionView.CellRegistration<FeedCollectionViewCell, VideoDetail.Info> {
            $0.setup(data: $2)
        }
        let weeklyVideoCell = UICollectionView.CellRegistration<FeedCollectionViewCell, VideoDetail.Info> {
            $0.setup(data: $2)
        }
        dataSource = UICollectionViewDiffableDataSource<SearchList, Item>(collectionView: collectionView) {
            collectionView, indexPath, item in
            switch item {
            case let .video(item):
                return collectionView.dequeueConfiguredReusableCell(using: displayCell, for: indexPath, item: item)
            case let .bangumi(item):
                return collectionView.dequeueConfiguredReusableCell(using: displayCell, for: indexPath, item: item)
            case let .user(item):
                return collectionView.dequeueConfiguredReusableCell(using: userCell, for: indexPath, item: item)
            case let .liveRoom(item):
                return collectionView.dequeueConfiguredReusableCell(using: displayCell, for: indexPath, item: item)
            case let .rankVideo(item):
                return collectionView.dequeueConfiguredReusableCell(using: rankVideoCell, for: indexPath, item: item)
            case let .weeklyVideo(item):
                return collectionView.dequeueConfiguredReusableCell(using: weeklyVideoCell, for: indexPath, item: item)
            }
        }

        let supplementaryRegistration = UICollectionView.SupplementaryRegistration<TitleSupplementaryView>(elementKind: FavoriteViewController.titleElementKind) {
            supplementaryView, string, indexPath in
            if let snapshot = self.currentSnapshot {
                let videoCategory = snapshot.sectionIdentifiers[indexPath.section]
                supplementaryView.label.text = videoCategory.title
            }
        }

        let titleWithButtonRegistration = UICollectionView.SupplementaryRegistration<TitleWithButtonSupplementaryView>(elementKind: FavoriteViewController.titleElementKind) {
            supplementaryView, string, indexPath in
            if let snapshot = self.currentSnapshot {
                let videoCategory = snapshot.sectionIdentifiers[indexPath.section]
                supplementaryView.label.text = videoCategory.title

                // 为排行榜和一周必看添加按钮响应
                if videoCategory.title == "排行榜" {
                    supplementaryView.onButtonTapped = { [weak self] in
                        let rankVC = RankingViewController()
                        self?.present(rankVC, animated: true)
                    }
                } else if videoCategory.title == "一周必看" {
                    supplementaryView.onButtonTapped = { [weak self] in
                        let weeklyVC = WeeklyWatchViewController()
                        self?.present(weeklyVC, animated: true)
                    }
                } else {
                    supplementaryView.onButtonTapped = nil
                }
            }
        }

        dataSource.supplementaryViewProvider = { [weak self] view, kind, index in
            guard let self = self else { return nil }

            // 判断是否为排行榜或一周必看 section
            let section = self.currentSnapshot.sectionIdentifiers[index.section]
            if section.title == "排行榜" || section.title == "一周必看" {
                return self.collectionView.dequeueConfiguredReusableSupplementary(
                    using: titleWithButtonRegistration, for: index
                )
            } else {
                return self.collectionView.dequeueConfiguredReusableSupplementary(
                    using: supplementaryRegistration, for: index
                )
            }
        }

        currentSnapshot = NSDiffableDataSourceSnapshot<SearchList, Item>()
    }
}

extension SearchResultViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let data = dataSource.itemIdentifier(for: indexPath) else { return }
        switch data {
        case let .video(data):
            let detailVC = VideoDetailViewController.create(aid: data.aid, cid: 0)
            detailVC.present(from: self)
        case let .bangumi(data):
            let detailVC = VideoDetailViewController.create(seasonId: data.season_id)
            detailVC.present(from: self)
        case let .user(data):
            let upSpaceVC = UpSpaceViewController()
            upSpaceVC.mid = data.mid
            present(upSpaceVC, animated: true)
        case let .liveRoom(data):
            let playerVC = LivePlayerViewController()
            let room = LiveRoom(
                title: data.title,
                room_id: data.roomid,
                uname: data.uname,
                area_v2_name: data.cate_name,
                keyframe: data.cover?.absoluteString,
                face: data.uface,
                cover_from_user: data.user_cover
            )
            playerVC.room = room
            present(playerVC, animated: true)
        case let .rankVideo(data):
            let detailVC = VideoDetailViewController.create(aid: data.aid, cid: data.cid)
            detailVC.present(from: self)
        case let .weeklyVideo(data):
            let detailVC = VideoDetailViewController.create(aid: data.aid, cid: data.cid)
            detailVC.present(from: self)
        }
    }

    func indexPathForPreferredFocusedView(in collectionView: UICollectionView) -> IndexPath? {
        if let section = currentSnapshot.sectionIdentifiers.first, currentSnapshot.numberOfItems(inSection: section) > 0 {
            return IndexPath(item: 0, section: 0)
        }
        return nil
    }

    func collectionView(_ collectionView: UICollectionView, didUpdateFocusIn context: UICollectionViewFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator) {
        // 从搜索框进入结果查看时，认为本搜索词是用户想要的，保存搜索历史
        if context.previouslyFocusedIndexPath == nil && context.nextFocusedIndexPath != nil {
            Settings.addHistory(searchText)
        }
    }
}

extension SearchResultViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.searchBar.text != "清空历史" else { return }
        if let text = searchController.searchBar.text {
            searchText = text
        }

        if let text = searchController.searchBar.text, !text.isEmpty {
            isShowingDefaultContent = false
            showHistorySuggest = false
            suggestDelayWork.submit {
                let result = try await WebRequest.requestSuggest(key: text)
                searchController.searchSuggestions = result.result.tag.map {
                    SuggestEntry(title: $0.term, iconImage: UIImage(systemName: "magnifyingglass"))
                }
            }
        } else {
            suggestDelayWork.cancel()
            guard !isShowingDefaultContent else { return }
            // 显示排行榜和一周必看
            Task { @MainActor in
                await showDefaultContent()
            }
            // 添加 showHistorySuggest 判断避免可能重复执行
            if !showHistorySuggest {
                showHistorySuggest = true
                // 清空搜索词后显示历史搜索词
                var suggests = Settings.searchHistories.map {
                    SuggestEntry(title: $0, iconImage: UIImage(systemName: "clock"))
                }
                if !suggests.isEmpty {
                    suggests.append(SuggestEntry(title: "清空历史", iconImage: UIImage(systemName: "trash")))
                }
                searchController.searchSuggestions = suggests
            }
        }
    }

    func updateSearchResults(for searchController: UISearchController, selecting searchSuggestion: any UISearchSuggestion) {
        // 选中建议词后添加搜索历史
        if searchSuggestion.localizedDescription == "清空历史" {
            Settings.clearHistory()
            searchController.searchSuggestions = []
            searchController.searchBar.text = nil
        } else if let text = searchController.searchBar.text {
            Settings.addHistory(text)
        }
    }
}

extension WebRequest {
    static func requestSearchResult(key: String) async throws -> SearchResult {
        try await request(url: "https://api.bilibili.com/x/web-interface/search/all/v2", parameters: ["keyword": key])
    }

    static func requestSearchLiveResult(key: String) async throws -> SearchLiveResult {
        try await request(url: "https://api.bilibili.com/x/web-interface/wbi/search/type", parameters: ["keyword": key, "search_type": "live"])
    }

    static func requestSuggest(key: String) async throws -> SuggestResult {
        try await request(url: "https://api.bilibili.com/x/web-interface/suggest", parameters: ["term": key])
    }
}

struct SearchResult: Decodable, Hashable {
    struct Video: Codable, Hashable, DisplayData {
        let type: String
        let author: String
        let upic: String
        let aid: Int
        let pubdate: Int
        let danmaku: Int
        let play: Int?
        let duration: String?

        // DisplayData
        var title: String
        var ownerName: String { author }
        let pic: URL?
        var avatar: URL? { URL(string: upic) }
        var date: String? { DateFormatter.stringFor(timestamp: pubdate) }
        var overlay: DisplayOverlay? {
            var leftItems = [DisplayOverlay.DisplayOverlayItem]()
            var rightItems = [DisplayOverlay.DisplayOverlayItem]()
            leftItems.append(DisplayOverlay.DisplayOverlayItem(icon: "play.rectangle", text: play == 0 ? "-" : play?.numberString() ?? "-"))
            leftItems.append(DisplayOverlay.DisplayOverlayItem(icon: "list.bullet.rectangle", text: danmaku == 0 ? "-" : danmaku.numberString()))
            if let duration {
                rightItems.append(DisplayOverlay.DisplayOverlayItem(icon: nil, text: duration))
            }
            return DisplayOverlay(leftItems: leftItems, rightItems: rightItems)
        }
    }

    struct Bangumi: Codable, Hashable, DisplayData {
        let season_id: Int
        let styles: String
        let cover: URL
        let pubtime: Int

        // DisplayData
        var title: String
        var ownerName: String { styles }
        var pic: URL? { cover }
        var date: String? { DateFormatter.stringFor(timestamp: pubtime) }
    }

    struct User: Codable, Hashable {
        let uname: String
        let upic: URL
        let usign: String
        let mid: Int
    }

    enum DataType: String, Codable {
        case video
        case media_bangumi
        case media_ft
        case bili_user
    }

    enum Section: Decodable, Hashable {
        case video(_ video: [Video])
        case bangumi(_ bangumi: [Bangumi])
        case movie(_ movie: [Bangumi])
        case user(_ user: [User])
        case none

        enum CodingKeys: CodingKey {
            case result_type
            case data
        }

        init(from decoder: Decoder) throws {
            let container: KeyedDecodingContainer<SearchResult.Section.CodingKeys> = try decoder.container(keyedBy: SearchResult.Section.CodingKeys.self)
            let result_type = try? container.decode(DataType.self, forKey: .result_type)
            switch result_type {
            case .video:
                var video = try container.decode([Video].self, forKey: .data)
                video.indices.forEach({ video[$0].title = video[$0].title.removingHTMLTags() })
                // 过滤只保留视频类型，去掉直播和课堂等类型
                video = video.filter { $0.type == "video" }
                video = Array(Set(video))
                self = .video(video)
            case .media_bangumi:
                var bangumi = try container.decode([Bangumi].self, forKey: .data)
                if bangumi.count == 0 {
                    self = .none
                    break
                }
                bangumi.indices.forEach({ bangumi[$0].title = bangumi[$0].title.removingHTMLTags() })
                bangumi = Array(Set(bangumi))
                self = .bangumi(bangumi)
            case .media_ft:
                var bangumi = try container.decode([Bangumi].self, forKey: .data)
                if bangumi.count == 0 {
                    self = .none
                    break
                }
                bangumi.indices.forEach({ bangumi[$0].title = bangumi[$0].title.removingHTMLTags() })
                bangumi = Array(Set(bangumi))
                self = .movie(bangumi)
            case .bili_user:
                var user = try container.decode([User].self, forKey: .data)
                if user.count == 0 {
                    self = .none
                    break
                }
                user = Array(Set(user))
                self = .user(user)
            case .none:
                self = .none
            }
        }
    }

    let result: [Section]
}

struct SearchList: Hashable {
    let title: String
    let width = NSCollectionLayoutDimension.fractionalWidth(Settings.displayStyle.fractionalWidth)
    let height: NSCollectionLayoutDimension
    let scrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior

    // 只使用 title 来计算 hash 和判断相等性
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }

    static func == (lhs: SearchList, rhs: SearchList) -> Bool {
        return lhs.title == rhs.title
    }
}

struct SearchLiveResult: Decodable, Hashable {
    struct Result: Codable, Hashable {
        let live_room: [LiveRoom]?

        struct LiveRoom: Codable, Hashable, DisplayData {
            struct WatchedShow: Codable, Hashable {
                var text_small: String
            }

            let uname: String
            let uface: URL?
            let user_cover: URL?
            let cover: URL?
            let roomid: Int
            let cate_name: String
            let titleWithHtml: String
            let watched_show: WatchedShow?

            enum CodingKeys: String, CodingKey {
                case uname, uface, user_cover, cover, roomid, cate_name, watched_show
                case titleWithHtml = "title"
            }

            // DisplayData
            var title: String { titleWithHtml.removingHTMLTags() }
            var ownerName: String { uname.removingHTMLTags() }
            var pic: URL? { cover?.addSchemeIfNeed() }
            var avatar: URL? { uface?.addSchemeIfNeed() }
            var overlay: DisplayOverlay? {
                var leftItems = [DisplayOverlay.DisplayOverlayItem]()
                var rightItems = [DisplayOverlay.DisplayOverlayItem]()
                leftItems.append(DisplayOverlay.DisplayOverlayItem(icon: nil, text: cate_name))
                if let watched_show {
                    rightItems.append(DisplayOverlay.DisplayOverlayItem(icon: "eye", text: watched_show.text_small))
                }
                return DisplayOverlay(leftItems: leftItems, rightItems: rightItems)
            }
        }
    }

    let result: Result
}

struct SuggestResult: Decodable, Hashable {
    struct Result: Codable, Hashable {
        let tag: [Tag]

        struct Tag: Codable, Hashable {
            let term: String
        }
    }

    let result: Result
}

class SuggestEntry: NSObject, UISearchSuggestion {
    var localizedSuggestion: String? {
        return title
    }

    var localizedDescription: String? {
        return title
    }

    var representedObject: Any?

    var title: String
    var iconImage: UIImage? = nil

    init(title: String, iconImage: UIImage? = nil) {
        self.title = title
        self.iconImage = iconImage
    }
}
