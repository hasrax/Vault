import SwiftUI

struct FloatingSpeakButton: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var speechManager = SpeechManager.shared
    let textToSpeak: String
    
    var body: some View {
        if appState.inAppVoiceEnabled {
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        if speechManager.isSpeaking {
                            speechManager.stop()
                        } else {
                            speechManager.speak(textToSpeak)
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.uniBlue)
                                .frame(width: 56, height: 56)
                                .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                            
                            Image(systemName: speechManager.isSpeaking ? "stop.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 20) // Extra padding for tab bar if present
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .animation(.spring(), value: appState.inAppVoiceEnabled)
        }
    }
}
