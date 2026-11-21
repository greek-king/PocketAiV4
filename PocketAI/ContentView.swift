import SwiftUI
import UniformTypeIdentifiers
import PDFKit

struct ContentView: View {
    @EnvironmentObject private var settings: AppSettings
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Hi! I'm PocketAI. Ask me anything, or use the plus button to add a document.")
    ]
    @State private var draft = ""
    @State private var isSending = false
    @State private var showingSettings = false
    @State private var showingImporter = false
    @State private var errorMessage: String?
    @FocusState private var composerFocused: Bool

    private let service = AssistantService()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if settings.demoMode {
                    HStack(spacing: 7) {
                        Image(systemName: "sparkles")
                        Text("DEMO MODE · Connect AI in Settings")
                    }
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(Color.orange.opacity(0.10))
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 18) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            if isSending {
                                HStack {
                                    ProgressView().tint(.cyan)
                                    Text("PocketAI is thinking…")
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                            }
                        }
                        .padding(.vertical, 20)
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let last = messages.last {
                            withAnimation(.easeOut(duration: 0.2)) { proxy.scrollTo(last.id, anchor: .bottom) }
                        }
                    }
                }

                composer
            }
            .background(Color(red: 0.035, green: 0.045, blue: 0.075))
            .navigationTitle("PocketAI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(.cyan)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(.white)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView().environmentObject(settings) }
            .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.pdf, .plainText], allowsMultipleSelection: false, onCompletion: importDocument)
            .alert("Something went wrong", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .tint(.cyan)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button { showingImporter = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: 42, height: 44)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
            }
            .accessibilityLabel("Attach a document")

            TextField("Message PocketAI…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($composerFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 18))

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 44, height: 44)
                    .background(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.cyan, in: RoundedRectangle(cornerRadius: 15))
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func sendMessage() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }
        draft = ""
        composerFocused = false
        let userMessage = ChatMessage(role: .user, text: text)
        messages.append(userMessage)
        isSending = true

        Task {
            do {
                let response = try await service.reply(to: text, history: messages, settings: settings)
                messages.append(ChatMessage(role: .assistant, text: response))
            } catch {
                errorMessage = error.localizedDescription
            }
            isSending = false
        }
    }

    private func importDocument(_ result: Result<[URL], Error>) {
        do {
            guard let url = try result.get().first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer { if accessed { url.stopAccessingSecurityScopedResource() } }
            let content: String
            if url.pathExtension.lowercased() == "pdf" {
                content = PDFTextExtractor.extract(from: url) ?? "I couldn't extract readable text from this PDF."
            } else {
                content = try String(contentsOf: url, encoding: .utf8)
            }
            let excerpt = String(content.prefix(12_000))
            draft = "Please summarize and analyze this document:\n\n\(excerpt)"
            composerFocused = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .user { Spacer(minLength: 48) }
            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.cyan)
                    .frame(width: 30, height: 30)
                    .background(Color.cyan.opacity(0.12), in: Circle())
            }
            Text(message.text)
                .font(.system(size: 15))
                .foregroundStyle(.white)
                .textSelection(.enabled)
                .padding(.horizontal, 15)
                .padding(.vertical, 12)
                .background(
                    message.role == .user ? Color.blue.opacity(0.65) : Color.white.opacity(0.075),
                    in: RoundedRectangle(cornerRadius: 18)
                )
            if message.role == .assistant { Spacer(minLength: 35) }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity)
    }
}

enum PDFTextExtractor {
    static func extract(from url: URL) -> String? {
        guard let document = PDFDocument(url: url) else { return nil }
        return (0..<document.pageCount).compactMap { document.page(at: $0)?.string }.joined(separator: "\n")
    }
}
