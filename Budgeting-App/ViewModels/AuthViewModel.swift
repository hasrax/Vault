//
//  AuthViewModel.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-04-02.
//

import Foundation
import Combine
import UIKit

final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var hasCompletedOnboarding = false
    @Published var hasCompletedSetup = false
    @Published var isDarkMode = false
    @Published var isFaceIDEnabled = true
    @Published var notificationsEnabled = true
    @Published var monthlyBudget: Double = 0
    @Published var needsPercent: Double = 0
    @Published var wantsPercent: Double = 0
    @Published var savingsPercent: Double = 0
    @Published var currentUser: UserProfile?
    @Published var sessionTimeoutSeconds: TimeInterval = 30

    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    init(appState: AppState) {
        self.appState = appState
        bindToAppState()
    }

    private func bindToAppState() {
        appState.$isAuthenticated.assign(to: &$isAuthenticated)
        appState.$hasCompletedOnboarding.assign(to: &$hasCompletedOnboarding)
        appState.$hasCompletedSetup.assign(to: &$hasCompletedSetup)
        appState.$isDarkMode.assign(to: &$isDarkMode)
        appState.$isFaceIDEnabled.assign(to: &$isFaceIDEnabled)
        appState.$notificationsEnabled.assign(to: &$notificationsEnabled)
        appState.$monthlyBudget.assign(to: &$monthlyBudget)
        appState.$needsPercent.assign(to: &$needsPercent)
        appState.$wantsPercent.assign(to: &$wantsPercent)
        appState.$savingsPercent.assign(to: &$savingsPercent)
        appState.$currentUser.assign(to: &$currentUser)
        appState.$sessionTimeoutSeconds.assign(to: &$sessionTimeoutSeconds)
    }

    func signIn(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        appState.signIn(email: email, password: password, completion: completion)
    }

    func signUp(name: String, email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        appState.signUp(name: name, email: email, password: password, completion: completion)
    }

    func signOut() {
        appState.signOut()
    }

    func restoreSession() {
        appState.restoreSession()
    }

    func changePassword(newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        appState.changePassword(newPassword: newPassword, completion: completion)
    }

    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {
        appState.deleteAccount(completion: completion)
    }

    func updateProfile(name: String, email: String, photo: UIImage?, completion: @escaping (Result<Void, Error>) -> Void) {
        appState.updateProfile(name: name, email: email, photo: photo, completion: completion)
    }

    func saveBudget(monthly: Double, needs: Double, wants: Double, savings: Double) {
        appState.saveBudget(monthly: monthly, needs: needs, wants: wants, savings: savings)
    }

    func setDarkMode(_ enabled: Bool) {
        appState.isDarkMode = enabled
    }

    func setFaceIDEnabled(_ enabled: Bool) {
        appState.isFaceIDEnabled = enabled
    }

    func setNotificationsEnabled(_ enabled: Bool) {
        appState.notificationsEnabled = enabled
    }

    func setOnboardingCompleted(_ value: Bool) {
        appState.hasCompletedOnboarding = value
    }
}
