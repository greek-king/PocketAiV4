import SwiftUI
import UserNotifications

struct SettingsView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @State private var reminderStatus = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("AI connection") {
                    Toggle("Demo Mode", isOn: $settings.demoMode)
                    TextField("https://your-backend.example", text: $settings.backendURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                    Text("Demo Mode uses sample replies. Turn it off after deploying your secure backend.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Daily reminder") {
                    Button("Schedule a daily 9:00 AM reminder") {
                        scheduleReminder()
                    }
                    if !reminderStatus.isEmpty {
                        Text(reminderStatus).font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Privacy") {
                    Label("Your AI provider key stays on your backend", systemImage: "lock.shield")
                    Text("Only send documents and messages you are comfortable processing through your configured AI service. Add a privacy policy before public release.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("About") {
                    HStack { Text("Version"); Spacer(); Text("1.0.0").foregroundStyle(.secondary) }
                    Link("Project documentation", destination: URL(string: "https://github.com/")!)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.035, green: 0.045, blue: 0.075))
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func scheduleReminder() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            guard granted, error == nil else {
                DispatchQueue.main.async { reminderStatus = "Notification permission was not granted." }
                return
            }
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let content = UNMutableNotificationContent()
            content.title = "A moment with PocketAI"
            content.body = "Have a question or a plan to work on today?"
            content.sound = .default
            let request = UNNotificationRequest(identifier: "daily-pocketai", content: content, trigger: trigger)
            center.add(request) { addError in
                DispatchQueue.main.async {
                    reminderStatus = addError == nil ? "Daily reminder scheduled." : "Couldn't schedule the reminder."
                }
            }
        }
    }
}
