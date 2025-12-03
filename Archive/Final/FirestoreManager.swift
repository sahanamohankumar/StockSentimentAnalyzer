import Foundation
import FirebaseFirestore
import SwiftUI

class FirestoreManager: ObservableObject {
    private var db = Firestore.firestore()
    
    func addStockToWatchlist(userID: String, ticker: String) {
        let userRef = db.collection("users").document(userID)
        var dataToAdd: [String: Any] = [:]
        let arrayValue = FieldValue.arrayUnion([ticker])
        dataToAdd["watchlist"] = arrayValue
        userRef.setData(dataToAdd, merge: true)
    }
    
    func fetchWatchlist(userID: String, completion: @escaping ([String]) -> Void) {
        let userRef = db.collection("users").document(userID)
        userRef.getDocument { (document, error) in
            if error != nil {
                print("Error getting document: " + error!.localizedDescription)
                completion([])
                return
            }
            
            if let doc = document, doc.exists,
               let data = doc.data(),
               let watchlist = data["watchlist"] as? [String] {
                completion(watchlist)
            } else {
                completion([])
            }
        }
    }
    
    class NewsFetcher: ObservableObject {
        @Published var articles: [Article] = []
        private let apiKey = "API KEY"
        
        func fetchNews(for ticker: String) {
            let date = getDate()
            let urlString = "https://gnews.io/api/v4/search?q=\(ticker)&token=YOUR_API_KEY&lang=en&max=10"
            let url = URL(string: urlString)
            
            if url == nil {
                print("Invalid URL.")
                return
            }
            
            URLSession.shared.dataTask(with: url!) { data, response, error in
                if error != nil {
                    let errorMessage = error!.localizedDescription
                    print("Error fetching news: " + errorMessage)
                    return
                }
                
                if data != nil {
                    let actualData = data!
                    do {
                        let decoder = JSONDecoder()
                        let result = try decoder.decode(NewsResponse.self, from: actualData)
                        DispatchQueue.main.async {
                            self.articles = result.articles
                        }
                    } catch {
                        let decodingError = error.localizedDescription
                        print("Error decoding data: " + decodingError)
                    }
                } else {
                    print("No data received.")
                }
            }.resume()
        }
        private func getDate() -> String {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let calendar = Calendar.current
            let now = Date()
            let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: now)
            if yesterdayDate != nil {
                return formatter.string(from: yesterdayDate!)
            } else {
                return formatter.string(from: now)
            }
        }
    }
    
}
    
    
    public class SentimentFetcher: ObservableObject {
        @Published var results: [SentimentResult] = []
        @Published var isLoading: Bool = false
        @Published var errorMessage: String?
        var gptSentiment: String?
        
        private let analyzer = OpenAISentimentAnalyzer()
        
        func fetch(for ticker: String) {
            isLoading = true
            errorMessage = nil
            results = []
            let urlString = "https://us-central1-stockproject-4698c.cloudfunctions.net/getStockNewsSentiment?ticker=\(ticker)"
            guard let url = URL(string: urlString) else {
                DispatchQueue.main.async {
                    self.errorMessage = "Invalid URL"
                    self.isLoading = false}
                return
            }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.errorMessage = "Network error: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                    return
                }
                
                guard let data = data else {
                    DispatchQueue.main.async {
                        self.errorMessage = "No data received"
                        self.isLoading = false
                    }
                    return
                }
                
                do {
                    let decoded = try JSONDecoder().decode(Response.self, from: data)
                    self.AIanalyze(decoded.results)
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Decoding error: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }.resume()
        }
        
        private func AIanalyze(_ baseResults: [SentimentResult]) {
            var updatedResults: [SentimentResult] = []
            let group = DispatchGroup()
            
            for var result in baseResults {
                group.enter()
                analyzer.analyzeSentiment(for: result.headline) { sentiment in
                    if let sentiment = sentiment {
                        result.gptSentiment = sentiment
                    } else {
                        result.gptSentiment = "Unknown"
                    }
                    updatedResults.append(result)
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                self.results = updatedResults
                self.isLoading = false
            }
        }
        
        private struct Response: Decodable {
            let ticker: String
            let results: [SentimentResult]
        }
    }
    class SuggestionFetcher: ObservableObject {
        @Published var sentimentData: [StockSentiment] = []
        private let firestore = Firestore.firestore()
        
        func fetchWatchlistAndSentiment(userID: String) {
            let userRef = firestore.collection("users").document(userID)
            userRef.getDocument { document, error in
                guard error == nil else {
                    print("Error fetching watchlist: \(error!.localizedDescription)")
                    return
                }
                
                guard let document = document, let data = document.data() else {
                    print("No document or data found")
                    return
                }
                
                guard let tickers = data["watchlist"] as? [String], !tickers.isEmpty else {
                    print("No tickers found")
                    return
                }
                
                var tempResults: [StockSentiment] = []
                let group = DispatchGroup()
                
                for ticker in tickers {
                    guard let url = URL(string: "https://us-central1-stockproject-4698c.cloudfunctions.net/getStockNewsSentiment?ticker=\(ticker)") else {
                        print("Invalid URL for \(ticker)")
                        continue
                    }
                    
                    var request = URLRequest(url: url)
                    request.timeoutInterval = 10  // Set a 10s timeout
                    
                    group.enter()
                    
                    URLSession.shared.dataTask(with: request) { data, response, error in
                        defer { group.leave() }
                        
                        guard error == nil, let data = data else {
                            print("Network error for \(ticker): \(error?.localizedDescription ?? "Unknown error")")
                            return
                        }
                        
                        struct APIResponse: Decodable {
                            let ticker: String
                            let results: [SentimentResult]
                        }
                        
                        do {
                            let decoded = try JSONDecoder().decode(APIResponse.self, from: data)
                            let positiveCount = decoded.results.filter { $0.sentiment.lowercased() == "positive" }.count
                            let totalCount = decoded.results.count
                            
                            var score: Double = 0
                            var label = "Neutral"
                            var color = Color.gray
                            
                            if totalCount > 0 {
                                score = Double(positiveCount) / Double(totalCount)
                                if score > 0.6 {
                                    label = "Buy"
                                    color = Color.green
                                } else if score < 0.3 {
                                    label = "Avoid"
                                    color = Color.red
                                }
                            }
                            
                            let stockSentiment = StockSentiment(
                                ticker: ticker,
                                positiveCount: positiveCount,
                                totalCount: totalCount,
                                sentimentScore: score,
                                sentimentLabel: label,
                                sentimentColor: color
                            )
                            DispatchQueue.global().async(flags: .barrier) {
                                tempResults.append(stockSentiment)
                            }
                            
                        } catch {
                            print("Failed decoding for \(ticker): \(error.localizedDescription)")
                        }
                        
                    }.resume()
                }
                group.notify(queue: .main) {
                    let sortedResults = tempResults.sorted(by: { $0.sentimentScore > $1.sentimentScore })
                    self.sentimentData = sortedResults
                }
            }
        }
    }


