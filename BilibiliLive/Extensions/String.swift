//
//  String.swift
//  BilibiliLive
//
//  Created by whw on 2022/10/31.
//

import Foundation

extension String {
    static func += (lhs: inout String, rhs: Int) {
        if let number = Int(lhs) {
            lhs = String(number + rhs)
        }
    }

    static func -= (lhs: inout String, rhs: Int) {
        if let number = Int(lhs) {
            lhs = String(number - rhs)
        }
    }

    func isMatch(pattern: String) -> Bool {
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        return regex.firstMatch(in: self, options: [], range: NSMakeRange(0, utf16.count)) != nil
    }

    func removingHTMLTags() -> String {
        return replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }

    func decodeJWT() -> [String: Any]? {
        let segments = components(separatedBy: ".")
        guard segments.count > 1 else { return nil }

        let jwtPart = segments[1]
        guard let bodyData = base64UrlDecode(jwtPart),
              let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any]
        else {
            return nil
        }
        return json
    }

    private func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let length = Double(base64.lengthOfBytes(using: .utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        return Data(base64Encoded: base64)
    }
}
