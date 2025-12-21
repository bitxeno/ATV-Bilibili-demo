//
//  DateFormatter.swift
//  BilibiliLive
//
//  Created by yicheng on 2022/10/23.
//

import Foundation

extension DateFormatter {
    static let date = {
        let formater = DateFormatter()
        formater.dateFormat = "yyyy-MM-dd"
        return formater
    }()

    static let time = {
        let formater = DateFormatter()
        formater.dateFormat = "HH:mm"
        return formater
    }()

    static func stringFor(timestamp: Int?) -> String? {
        guard let timestamp = timestamp else { return nil }
        return date.string(from: Date(timeIntervalSince1970: TimeInterval(timestamp)))
    }

    /// 将时间戳转换为用户友好的相对时间格式（如"刚刚"、"3分钟前"、"2天前"）
    /// - Parameter timestamp: Unix时间戳（秒）
    /// - Returns: 格式化后的相对时间字符串，如果timestamp为nil则返回nil
    static func relativeTimeStringFor(timestamp: Int?) -> String? {
        guard let timestamp = timestamp else { return nil }

        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)

        // 如果是未来时间，返回具体日期
        if timeInterval < 0 {
            return self.date.string(from: date)
        }

        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let hours = minutes / 60

        // 小于 1 小时仍显示相对时间
        if seconds < 10 {
            return "刚刚"
        } else if seconds < 60 {
            return "\(seconds)秒前"
        } else if seconds < 3600 {
            return "\(minutes)分钟前"
        }

        // >=1小时 的情况：同一天显示 "今天HH:mm"，昨天显示 "昨天HH:mm"
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天\(time.string(from: date))"
        }

        if calendar.isDateInYesterday(date) {
            return "昨天\(time.string(from: date))"
        }

        // 超过 2 天则使用具体日期显示（yyyy-MM-dd）
        return self.date.string(from: date)
    }
}
