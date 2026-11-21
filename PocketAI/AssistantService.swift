import Foundation

struct AssistantService {
    func reply(to message: String, history: [ChatMessage], settings: AppSettings) async throws -> String {
        // Snapshot MainActor-isolated properties before leaving the main actor context.
        let demoMode = await settings.demoMode
        let backendURL = await settings.backendURL

        if demoMode {
            try await Task.sleep(nanoseconds: 650_000_000)
            return demoReply(for: message)
        }

        guard let baseURL = URL(string: backendURL),
              let url = URL(string: "/api/chat", relativeTo: baseURL) else {
            throw AssistantError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 60
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let context = history.suffix(12).map {
            ChatRequest.HistoryItem(
                role: $0.role == .user ? "user" : "assistant",
                content: $0.text
            )
        }
        request.httpBody = try JSONEncoder().encode(ChatRequest(message: message, history: context))

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AssistantError.server("Unexpected server response.")
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "Request failed."
            throw AssistantError.server(body)
        }
        let decoded = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard !decoded.reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw AssistantError.emptyResponse
        }
        return decoded.reply
    }

    private func demoReply(for message: String) -> String {
        let lower = message.lowercased()
        if lower.contains("plan") || lower.contains("organize") {
            return "Absolutely. Let's break this into manageable steps. First, tell me your main goal and deadline. I'll help you create a practical plan with clear priorities."
        }
        if lower.contains("write") || lower.contains("email") {
            return "I can help draft that. Tell me who it's for, the key points, and the tone you want—professional, friendly, or concise."
        }
        if lower.contains("hello") || lower.contains("hi") {
            return "Hey! I'm PocketAI. I can help you brainstorm, write, learn, plan your day, and work through questions. What would you like to do?"
        }
        return "Thanks for sharing that. I'm running in Demo Mode, so my responses are sample replies. Connect a private backend in Settings to enable real AI responses. I can still help you shape the idea—what outcome are you hoping for?"
    }
}
