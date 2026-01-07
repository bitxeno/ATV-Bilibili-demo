//
//  LineCandidatesPlugin.swift
//  BilibiliLive
//
//  Created by GitHub Copilot on 2026/01/07.
//

import AVKit
import UIKit

class LineCandidatesPlugin: NSObject, CommonPlayerPlugin {
    private weak var playPlugin: URLPlayPlugin?
    private var candidates: [LivePlayUrlInfo]

    init(playPlugin: URLPlayPlugin, candidates: [LivePlayUrlInfo]) {
        self.playPlugin = playPlugin
        self.candidates = candidates
        super.init()
    }

    func updateCandidates(_ new: [LivePlayUrlInfo]) {
        candidates = new
    }

    func addMenuItems(current: inout [UIMenuElement]) -> [UIMenuElement] {
        print("LineCandidatesPlugin: addMenuItems called, candidates count: \(candidates.count)")
        guard !candidates.isEmpty else {
            print("LineCandidatesPlugin: candidates is empty!")
            return []
        }

        let actions = candidates.enumerated().map { idx, info in
            let title = "#\(idx + 1) \(info.formate ?? "") - \(info.codec_name ?? "")"
            return UIAction(title: title, state: self.playPlugin?.isPlaying(urlString: info.url) ?? false ? .on : .off) { [weak self] _ in
                guard let self = self else { return }
                self.playPlugin?.play(urlString: info.url)
            }
        }

        let menu = UIMenu(title: "线路选择", image: UIImage(systemName: "network"), options: [.singleSelection], children: actions)
        return [menu]
    }
}
