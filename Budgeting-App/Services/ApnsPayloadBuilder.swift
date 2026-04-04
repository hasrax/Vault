import Foundation

enum ApnsPayloadBuilder {
    static func writePayload(
        title: String,
        body: String,
        bundleId: String,
        link: String? = nil,
        type: String? = nil,
        filePrefix: String
    ) throws -> URL {
        var payload: [String: Any] = [
            "Simulator Target Bundle": bundleId,
            "aps": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "sound": "default"
            ]
        ]

        if let link, !link.isEmpty {
            payload["link"] = link
        }

        if let type, !type.isEmpty {
            payload["type"] = type
        }

        let data = try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let timestamp = timestampString()
        let fileURL = dir.appendingPathComponent("\(filePrefix)_\(timestamp).apns")
        try data.write(to: fileURL, options: .atomic)
        return fileURL
    }

    private static func timestampString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyyMMdd_HHmmss"
        return fmt.string(from: Date())
    }
}
