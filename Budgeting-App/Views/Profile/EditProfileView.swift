//
//  EditProfileView.swift
//  Budgeting-App
//
//  Created by COBSCCOMP24.2P-023 on 2026-03-30.
//

import SwiftUI
import PhotosUI

struct EditProfileView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var name = ""
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var isSaving = false
    @State private var selectedItem: PhotosPickerItem?
    @State private var selectedImage: UIImage?

    var body: some View {
        Form {
            Section("Profile Photo") {
                HStack(spacing: 16) {
                    profileImage
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                    PhotosPicker(selection: $selectedItem, matching: .images) {
                        Text("Change photo")
                            .scaledFont(size: 15, weight: .semibold, relativeTo: .headline)
                    }
                }
            }

            Section("Details") {
                TextField("Full name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            }

            if !errorMessage.isEmpty {
                Section {
                    Label(errorMessage, systemImage: "exclamationmark.circle")
                        .foregroundStyle(Color.expense)
                }
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel") { dismiss() }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    save()
                } label: {
                    if isSaving { ProgressView() }
                    else { Text("Save") }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            name = appState.currentUser?.name ?? ""
            email = appState.currentUser?.email ?? ""
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem = newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedImage = image
                }
            }
        }
    }

    private var profileImage: some View {
        Group {
            if let selectedImage = selectedImage {
                Image(uiImage: selectedImage)
                    .resizable()
                    .scaledToFill()
            } else if let base64 = appState.currentUser?.photoBase64,
                      let data = Data(base64Encoded: base64),
                      let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if let urlStr = appState.currentUser?.photoURL,
                      let url = URL(string: urlStr) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image): image.resizable().scaledToFill()
                    default: Color(UIColor.secondarySystemBackground)
                    }
                }
            } else {
                ZStack {
                    Color(UIColor.secondarySystemBackground)
                    Text(MockData.userAvatar)
                        .scaledFont(size: 26, relativeTo: .body)
                }
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedName.isEmpty, !trimmedEmail.isEmpty else {
            errorMessage = "Name and email are required."
            return
        }
        isSaving = true
        errorMessage = ""
        appState.updateProfile(name: trimmedName, email: trimmedEmail, photo: selectedImage) { result in
            DispatchQueue.main.async {
                isSaving = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditProfileView().environmentObject(AppState())
    }
}
