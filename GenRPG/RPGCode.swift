//
//  RPGCode.swift
//  GenRPG
//
//  Created by Ryo Tulman on 2/15/25.
//

import SwiftUI
import Combine
import OpenAI

// MARK: - Models

struct Character: Codable {
    var name: String
    var level: Int = 1
    var xp: Int = 0
    var xpToNextLevel: Int = 100
    var gold: Int = 100
    var health: Int = 100
    var maxHealth: Int = 100
    var strength: Int = 10
    var intelligence: Int = 10
    var charisma: Int = 10
    var inventory: [Item] = []
    
    mutating func levelUp() {
        level += 1
        xp = 0
        xpToNextLevel = level * 100
        maxHealth += 10
        strength += 2
        intelligence += 2
        charisma += 2
        health = maxHealth
    }
    
    mutating func gainXP(_ amount: Int) {
        xp += amount
        while xp >= xpToNextLevel {
            xp -= xpToNextLevel
            levelUp()
        }
    }
    
    mutating func gainGold(_ amount: Int) {
        gold += amount
    }
    
    mutating func loseGold(_ amount: Int) {
        gold = max(0, gold - amount)
    }
    
    mutating func addItem(_ item: Item) {
        inventory.append(item)
    }
    
    mutating func removeItem(_ item: Item) {
        inventory.removeAll { $0.id == item.id }
    }
    
    mutating func changeHealth(by amount: Int) {
        health = min(maxHealth, max(0, health + amount))
    }
}

struct GameState: Codable {
    var character: Character
    var currentLocationId: UUID
    var locations: [Location]
    var gameProgress: GameProgress
    var visitedLocationIds: Set<UUID>
    var activeQuests: [Quest]
}

struct GameProgress: Codable {
    var act: Int
    var chapter: Int
}

struct GameEvent: Codable, Identifiable, Hashable, StructuredOutput {
    static func == (lhs: GameEvent, rhs: GameEvent) -> Bool {
        lhs.id.uuidString == rhs.id.uuidString
    }
    
    var id: UUID = UUID()
    let description: String
    let options: [EventOption]
    
    static let example: Self = GameEvent(
        id: UUID(),
        description: "A goblin rushes out of the shadows and confronts you with a large cleaver!",
        options: [
            EventOption(text: "Fight",
                        consequences: [
                            Consequence(type: .changeHealth, amount: -8, item: .example, location: .example),
                            Consequence(type: .gainXP, amount: 10, item: .example, location: .example)]),
            EventOption(text: "Run",
                        consequences: [
                            Consequence(type: .gainXP, amount: -4, item: .example, location: .example)])
        ]
    )
}

struct EventOption: Codable, Identifiable, Hashable, StructuredOutput {
    static func == (lhs: EventOption, rhs: EventOption) -> Bool {
        lhs.id.uuidString == rhs.id.uuidString
    }
    
    var id: UUID = UUID()
    let text: String
    let consequences: [Consequence]
    
    static let example: Self = EventOption(
        id: UUID(),
        text: "Fight",
        consequences: [
            Consequence(type: .changeHealth, amount: -8, item: .example, location: .example),
            Consequence(type: .gainXP, amount: 10, item: .example, location: .example)]
    )
}

struct Consequence: Codable, Identifiable, Hashable, StructuredOutput {
    static func == (lhs: Consequence, rhs: Consequence) -> Bool {
        lhs.id.uuidString == rhs.id.uuidString
    }
    
    var id: UUID = UUID()
    let type: ConsequenceType
    var amount: Int?
    var item: Item?
    var location: Location?
    
    static let example: Self = Consequence(
        id: UUID(),
        type: .gainGold,
        amount: 12,
        item: Item.example,
        location: Location.example
    )
}

enum ConsequenceType: String, Codable, StructuredOutputEnum {
    case gainXP
    case loseXP
    case gainGold
    case loseGold
    case gainItem
    case loseItem
    case changeHealth
    case changeLocation
    
    var caseNames: [String] { Self.allCases.map { $0.rawValue } }
}

struct Item: Codable, Identifiable, Hashable, StructuredOutput {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id.uuidString == rhs.id.uuidString
    }

    var id = UUID()
    let name: String
    let description: String
    let value: Int
    let type: ItemType
    let effect: ItemEffect
    
    static let example: Self = Item(
        id: UUID(),
        name: "Wooden Sword",
        description: "A weather beaten and chipped wooden sword. Splinters aplenty for you and your foe.",
        value: 5,
        type: .weapon,
        effect: ItemEffect.example
    )
}

struct ItemEffect: Codable, Identifiable, Hashable, StructuredOutput {
    static func == (lhs: ItemEffect, rhs: ItemEffect) -> Bool {
        lhs.id.uuidString == rhs.id.uuidString
    }

    var id: UUID = UUID()
    let type: EffectType
    let value: Int
    
    static let example: Self = ItemEffect(
        id: UUID(),
        type: .damage,
        value: 10
    )
}

enum ItemType: String, Codable, StructuredOutputEnum {
    case weapon
    case armor
    case potion
    case quest
    case treasure
    
    var caseNames: [String] { Self.allCases.map { $0.rawValue } }
}

enum EffectType: String, Codable, StructuredOutputEnum {
    case healing
    case damage
    case protection
    
    var caseNames: [String] { Self.allCases.map { $0.rawValue } }
}

struct Location: Codable, Identifiable, Hashable, StructuredOutput {
    static func == (lhs: Location, rhs: Location) -> Bool {
        lhs.id.uuidString == rhs.id.uuidString
    }
    
    var id: UUID = UUID()
    let name: String
    let description: String
    let type: LocationType
    
    static let example: Self = Location(
        id: UUID(),
        name: "Fisherman's Hut Inside",
        description: "A pungent smell wafts from a bait fish barrel. A small table with a few bowls of stew. A wooden chair in the corner.",
        type: .room
    )
}

enum LocationType: String, Codable, StructuredOutputEnum {
    case room
    case village
    case city
    case road
    case shop
    case wilderness
    
    var caseNames: [String] { Self.allCases.map { $0.rawValue } }
}

struct Quest: Codable, Identifiable, Hashable, StructuredOutput {
    static func == (lhs: Quest, rhs: Quest) -> Bool {
        lhs.id.uuidString == rhs.id.uuidString
    }
    
    var id: UUID = UUID()
    let name: String
    let description: String
    var isActive: Bool
    var isCompleted: Bool
    let reward: [Consequence]
    
    static let example: Self = Quest(
        id: UUID(),
        name: "Slay liar bandit",
        description: "The crown almsgiver was discovered to only be a lowly self-serving bandit!",
        isActive: true,
        isCompleted: false,
        reward: [
            Consequence(type: .gainItem, amount: 1, item: .example, location: .example),
            Consequence(type: .gainGold, amount: 30, item: .example, location: .example),
            Consequence(type: .gainXP, amount: 50, item: .example, location: .example)]
    )
}

// MARK: - ViewModel

class GameViewModel: ObservableObject {
    @Published var gameState: GameState
    @Published var currentEvent: GameEvent?
    @Published var generatedImage: Image?
    @Published var errorMessage: String?
    
    private let openAIService: OpenAIService
    private let veniceAI: OpenAI

    var currentLocation: Location? {
        gameState.locations.first { $0.id == gameState.currentLocationId }
    }
    
    init() {
        let configuration = OpenAI.Configuration(
            token: "U58jHAOFzyP2FD8RMiajLY_EHwwB2RPcvW58pHAdIt",
            host: "api.venice.ai",
            basePath: "api/v1",
            timeoutInterval: 30.0)
        self.veniceAI = OpenAI(configuration: configuration)
        
        self.openAIService = OpenAIService()
        if let loadedState = Self.loadGameState() {
            self.gameState = loadedState
        } else {
            self.gameState = Self.createInitialGameState()
            self.saveGameState()
        }
        Task {
            await generateLocationEvent()
        }
    }
    
    static func createInitialGameState() -> GameState {
        let character = Character(name: "Hero")
        let startingLocation = Location(
            name: "Lake Village",
            description: "A quaint village with cobblestone paths and friendly faces.",
            type: .village
        )
        return GameState(
            character: character,
            currentLocationId: startingLocation.id,
            locations: [startingLocation],
            gameProgress: GameProgress(act: 1, chapter: 1),
            visitedLocationIds: [],
            activeQuests: []
        )
    }
    
    // Generate an event for the current location
    func generateLocationEvent() async {
        guard let currentLocation = currentLocation else { return }
        
        let prompt = """
        
        You are creating an event for an RPG game. The event should be appropriate for a player in a \(currentLocation.type.rawValue) named "\(currentLocation.name)". The location description is "\(currentLocation.description)". The player's level is \(gameState.character.level). The player's stats are: Strength: \(gameState.character.strength), Intelligence: \(gameState.character.intelligence), Charisma: \(gameState.character.charisma).

        The event should be engaging, encourage exploration, and offer 2-4 quantified multiple-choice options. Each option should have at least one or more clear consequences, such as gaining XP, gold, items, or affecting health.

        """

        let query = ChatQuery(
            messages: [.system(.init(content: prompt))],
            model: "mistral-31-24b",
            responseFormat: .jsonSchema(name: "event", type: GameEvent.self)
        )
        
        do {
            let result = try await veniceAI.chats(query: query)
//            result.object
//            let response = try await openAIService.generateContent(prompt: prompt)
            if let event = parseJSONEvent(result.object) {
                DispatchQueue.main.async {
                    self.currentEvent = event
                }
                await generateEventImage(description: event.description)
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to parse event."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error generating event: \(error.localizedDescription)"
            }
        }
    }
    
    // Parse the JSON event generated by the LLM
    func parseJSONEvent(_ jsonString: String) -> GameEvent? {
        let eventDict = convertStringToDictionary(text: jsonString)!
        print(String(data: try! JSONSerialization.data(withJSONObject: eventDict, options: .prettyPrinted), encoding: .utf8)!)
        
        guard let data = jsonString.data(using: .utf8) else { return nil }
        do {
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .useDefaultKeys
            let event = try decoder.decode(GameEvent.self, from: data)
            return event
        } catch {
            print("Parsing error: \(error)")
            return nil
        }
    }
    
    func convertStringToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }
    
    // Generate an image based on the event description
    func generateEventImage(description: String) async {
        let prompt = """
        Create a 2D pixel art scene in the style of Final Fantasy IX depicting: \(description). Use vibrant colors and an isometric view. The image should be campy, fun, and visually engaging.
        """
        
        do {
            let imgStr = try await openAIService.generateImage(prompt: prompt)
            if let imgStr, let imgData = Data(base64Encoded: imgStr), let uiImage = UIImage(data: imgData) {
                DispatchQueue.main.async {
                    self.generatedImage = Image(uiImage: uiImage)
                }
            } else {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to decode image."
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Error generating image: \(error.localizedDescription)"
            }
        }
    }
    
    // Handle the user's selection
    func handleOptionSelected(_ option: EventOption) async {
        for consequence in option.consequences {
            applyConsequence(consequence)
        }
        
        if gameState.character.xp >= gameState.character.xpToNextLevel {
            gameState.character.levelUp()
        }
        
        saveGameState()
        
        // Generate a new event if the location hasn't changed
        if !option.consequences.contains(where: { $0.type == .changeLocation }) {
            await generateLocationEvent()
        } else {
            // If location changed, reset image and event
            DispatchQueue.main.async {
                self.generatedImage = nil
                self.currentEvent = nil
            }
            // Generate event for new location
            await generateLocationEvent()
        }
    }
    
    private func applyConsequence(_ consequence: Consequence) {
        switch consequence.type {
        case .gainXP:
            if let amount = consequence.amount {
                gameState.character.gainXP(amount)
            }
        case .loseXP:
            if let amount = consequence.amount {
                gameState.character.xp = max(0, gameState.character.xp - amount)
            }
        case .gainGold:
            if let amount = consequence.amount {
                gameState.character.gainGold(amount)
            }
        case .loseGold:
            if let amount = consequence.amount {
                gameState.character.loseGold(amount)
            }
        case .gainItem:
            if let item = consequence.item {
                gameState.character.addItem(item)
            }
        case .loseItem:
            if let item = consequence.item {
                gameState.character.removeItem(item)
            }
        case .changeHealth:
            if let amount = consequence.amount {
                gameState.character.changeHealth(by: amount)
            }
        case .changeLocation:
            if let newLocationId = consequence.location?.id {
                gameState.currentLocationId = newLocationId
            }
        default:
            break
        }
    }
    
    // MARK: - Saving and Loading Game State
    
    func saveGameState() {
        if let data = try? JSONEncoder().encode(gameState) {
            UserDefaults.standard.set(data, forKey: "gameState")
        }
    }
    
    static func loadGameState() -> GameState? {
        if let data = UserDefaults.standard.data(forKey: "gameState"),
           let gameState = try? JSONDecoder().decode(GameState.self, from: data) {
            return gameState
        }
        return nil
    }
}

// MARK: - Views

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            VStack(spacing: 15) {
                if let error = viewModel.errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                }
                CharacterStatusView(character: viewModel.gameState.character)
                if let image = viewModel.generatedImage {
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                        .cornerRadius(10)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .cornerRadius(10)
                }
                if let location = viewModel.currentLocation {
                    LocationDescriptionView(location: location)
                }
                if let event = viewModel.currentEvent {
                    EventView(event: event) { option in
                        Task {
                            await viewModel.handleOptionSelected(option)
                        }
                    }
                } else if viewModel.errorMessage == nil {
                    ProgressView("Generating Event...")
                        .foregroundColor(.white)
                        .padding()
                }
                Spacer()
            }
            .padding()
        }
    }
}

struct CharacterStatusView: View {
    let character: Character
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Level \(character.level)")
                    .foregroundColor(.yellow)
                Spacer()
                Text("\(character.gold) Gold")
                    .foregroundColor(.yellow)
            }
            ProgressBar(value: Float(character.xp), total: Float(character.xpToNextLevel))
                .frame(height: 10)
            HStack {
                Text("HP: \(character.health)/\(character.maxHealth)")
                    .foregroundColor(.red)
                Spacer()
                Text("XP: \(character.xp)/\(character.xpToNextLevel)")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct LocationDescriptionView: View {
    let location: Location
    
    var body: some View {
        Text(location.description)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue.opacity(0.2))
            .cornerRadius(10)
    }
}

struct EventView: View {
    let event: GameEvent
    let onOptionSelected: (EventOption) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(event.description)
                .foregroundColor(.white)
                .font(.headline)
                .lineLimit(5, reservesSpace: true)
            List {
                ForEach(event.options, id: \.self) { option in
                    Button(action: {
                        onOptionSelected(option)
                    }) {
                        Text(option.text)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

struct ProgressBar: View {
    var value: Float
    var total: Float
    
    var body: some View {
        GeometryReader { geometry in
            let width = min(CGFloat(value / total) * geometry.size.width, geometry.size.width)
            ZStack(alignment: .leading) {
                Rectangle()
                    .frame(width: geometry.size.width,
                           height: geometry.size.height)
                    .opacity(0.3)
                    .foregroundColor(Color.gray)
                Rectangle()
                    .frame(width: width,
                           height: geometry.size.height)
                    .foregroundColor(value / total > 0.5 ? Color.green : Color.red)
            }
            .cornerRadius(4.0)
        }
    }
}

// MARK: - OpenAI Service

class OpenAIService {
    private let apiKey: String = "U58jHAOFzyP2FD8RMiajLY_EHwwB2RPcvW58pHAdIt" // Replace with your OpenAI API key
    private let baseURL = "https://api.venice.ai/api/v1"
    
    init() {}
    
    func generateContent(prompt: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API Key is missing"])
        }
        
        let url = URL(string: "\(baseURL)/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "llama-3.2-3b",
            "messages": [["role": "user", "content": prompt]],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        if let content = response.choices.first?.message.content {
            return content
        } else if let error = response.error {
            throw NSError(domain: "OpenAIService", code: 0, userInfo: [NSLocalizedDescriptionKey: error.message])
        } else {
            throw NSError(domain: "OpenAIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
        }
    }
    
    func generateImage(prompt: String) async throws -> String? {
        guard !apiKey.isEmpty else {
            throw NSError(domain: "OpenAIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "API Key is missing"])
        }
        
        let url = URL(string: "\(baseURL)/image/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "fluently-xl",
            "prompt": prompt,
            "width": 1024,
            "height": 1024,
            "steps": 6,
            "safe_mode": true,
            "hide_watermark": true,
            "cfg_scale": 7.0,
            "style_preset": "Pixel Art",
            "negative_prompt": "abstract",
            "return_binary": false
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = convertStringToDictionary(text: String(data: data, encoding: .utf8)!)
        if let response, let images = response["images"] as? [String], let imageData = images.first {
            return imageData
        }
//        else if let error = response.error {
//            throw NSError(domain: "OpenAIService", code: 0, userInfo: [NSLocalizedDescriptionKey: error.message])
//        } else {
//            throw NSError(domain: "OpenAIService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])
//        }
        return nil
    }
    
    func convertStringToDictionary(text: String) -> [String: Any]? {
        if let data = text.data(using: .utf8) {
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any]
                return json
            } catch {
                print("Something went wrong")
            }
        }
        return nil
    }
    
}

// MARK: - OpenAI API Response Models

struct OpenAIChatResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
    let error: OpenAIError?
}

struct OpenAIImageResponse: Decodable {
    let images: [String]
//    let request:
    let error: OpenAIError?
}

struct OpenAIError: Decodable, Error {
    let message: String
    let type: String?
    let param: String?
    let code: Int?
}

// MARK: - App Entry Point

@main
struct RPGGameApp: App {
    var body: some Scene {
        WindowGroup {
            GameView()
        }
    }
}
