import Foundation
import Combine

final class PushTokenStore: ObservableObject {
    static let shared = PushTokenStore()

    @Published private(set) var fcmToken: String = ""
    @Published private(set) var apnsToken: String = ""

    private let fcmKey = "fcm_token"
    private let apnsKey = "apns_token"

    private init() {
        fcmToken = UserDefaults.standard.string(forKey: fcmKey) ?? ""
        apnsToken = UserDefaults.standard.string(forKey: apnsKey) ?? ""
    }

    func updateFcmToken(_ token: String) {
        fcmToken = token
        UserDefaults.standard.set(token, forKey: fcmKey)
    }

    func updateApnsToken(_ token: String) {
        apnsToken = token
        UserDefaults.standard.set(token, forKey: apnsKey)
    }
}
