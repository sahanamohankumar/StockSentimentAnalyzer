
//  Final
//
//  Created by Sahana Mohankumar on 6/3/25.
//


import Foundation

class OpenAISentimentAnalyzer {
    private let apiKey = "API KEY"
    private let endpoint = "https://api.openai.com/v1/chat/completions"

    func analyzeSentiment(for headline: String, completion: @escaping (String?) -> Void) {
        let prompt = """
        Analyze the sentiment of this financial news headline. Return just one word: Buy, Neutral, or Avoid.

        Headline: "\(headline)"
        """

        let payload: [String: Any] = [
            "model": "gpt-4-turbo",
            "messages": [
                ["role": "system", "content": "You are a financial analyst."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.2
        ]

        guard let url = URL(string: endpoint),
              let body = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { data, _, error in
            if let error = error {
                print("OpenAI API error: \(error)")
                completion(nil)
                return
            }

            guard let data = data else {
                completion(nil)
                return
            }

            do {
                let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
                let sentiment = response.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
                completion(sentiment)
            } catch {
                print("Failed to decode OpenAI response: \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("Raw OpenAI response:\n\(raw)")
                }
                completion(nil)
            }
        }.resume()
    }

    private struct OpenAIResponse: Decodable {
        let choices: [Choice]
        struct Choice: Decodable {
            let message: Message
            struct Message: Decodable {
                let content: String
            }
        }
    }
}
