//
// Created by Yam on 2024/6/9.
//

import Kingfisher
import UIKit

class ReplyCell: UICollectionViewCell {
    class var identifier: String {
        return String(describing: Self.self)
    }

    @IBOutlet var avatarImageView: UIImageView!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var contenLabel: UILabel!
    @IBOutlet var moreLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        moreLabel.font = .preferredFont(forTextStyle: .caption2)
        moreLabel.textColor = .secondaryLabel
        moreLabel.numberOfLines = 1
    }

    func config(replay: Replys.Reply) {
        avatarImageView.kf.setImage(
            with: URL(string: replay.member.avatar),
            options: [
                .processor(DownsamplingImageProcessor(size: CGSize(width: 80, height: 80))),
                .processor(RoundCornerImageProcessor(radius: .widthFraction(0.5))),
                .cacheSerializer(FormatIndicatedCacheSerializer.png),
            ]
        )
        userNameLabel.text = replay.member.uname
        if let attr = replay.createAttributedString(displayView: contenLabel) {
            contenLabel.attributedText = attr
        } else {
            contenLabel.text = replay.content.message
        }

        // 设置底部的回复数和发布时间，优先使用 reply_control 中的描述字段
        var parts = [String]()
        if let subText = replay.reply_control?.sub_reply_entry_text, !subText.isEmpty {
            parts.append(subText)
        }
        if let timeDesc = replay.reply_control?.time_desc, !timeDesc.isEmpty {
            parts.append(timeDesc)
        }
        moreLabel.text = parts.joined(separator: " · ")
    }
}
