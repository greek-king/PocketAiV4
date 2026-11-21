import Foundation

struct ChatMessage: Identifiable, Codable {
    enum Role: String, Codable { case user, assistant }
    let id: UUID
    let role: Role
    var text: String
    let createdAt: Date

    init(role: Role, text: String) {
        self.id = UUID()
        self.role = role
        self.text = text
        self.createdAt = Date()
    }
}

struct ChatRequest: Encodable {
    let message: String
    let history: [HistoryItem]

    struct HistoryItem: Encodable {
        let role: String
        let content: String
    }
}

struct ChatResponse: Decodable {
    let reply: String
}

enum AssistantError: LocalizedError {
    case invalidURL
    case server(String)
    case emptyResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Enter a valid backend URL in Settings."
        case .server(let message): return message
        case .emptyResponse: return "The assistant returned an empty response."
        }
    }
}
