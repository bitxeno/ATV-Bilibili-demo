//
//  HistoryViewController.swift
//  BilibiliLive
//
//  Created by whw on 2021/4/15.
//

import Alamofire
import SwiftyJSON
import UIKit

class HistoryViewController: StandardVideoCollectionViewController<HistoryData> {
    private var cursor: HistoryResp.Cursor = .init(max: 0, ps: 20, view_at: 0)

    override func setupCollectionView() {
        super.setupCollectionView()
        collectionVC.styleOverride = .sideBar
    }

    override func request(page: Int) async throws -> [HistoryData] {
        if page == 1 {
            cursor = .init(max: 0, ps: 20, view_at: 0)
        }
        let resp = try await WebRequest.requestHistory(max: cursor.max, viewAt: cursor.view_at, pageSize: cursor.ps)
        cursor = resp.cursor
        return resp.list
    }

    override func goDetail(with record: HistoryData) {
        if record.history.business == "live" {
            let playerVC = LivePlayerViewController()
            playerVC.room = LiveRoom(title: record.title, room_id: Int(record.history.oid), uname: record.author_name, area_v2_name: nil, keyframe: record.cover?.absoluteString, face: record.avatar, cover_from_user: nil)
            present(playerVC, animated: true, completion: nil)
        } else {
            super.goDetail(with: record)
        }
    }
}
