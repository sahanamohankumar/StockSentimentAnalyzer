import SwiftUI
import FirebaseAuth
import Charts


struct ContentView: View {
    @StateObject var firestoreManager = FirestoreManager()
    @State private var ticker = ""
    @State private var watchlist: [String] = []

    var userID: String {
        if let uid = Auth.auth().currentUser?.uid {
            return uid
        } else {
            return "unknown"
        }
    }


    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("My Watchlist")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)

                NavigationLink(destination: SuggestionsView()) {
                    Text("View Suggestions")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }

                HStack {
                    TextField("Add ticker (e.g. TSLA)", text: $ticker)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)

                    Button(action: {
                        let trimmed = ticker.uppercased().trimmingCharacters(in: .whitespaces)
                        if !trimmed.isEmpty {
                            firestoreManager.addStockToWatchlist(userID: userID, ticker: trimmed)
                            ticker = ""
                            fetchWatchlist()
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }

                if watchlist.isEmpty {
                    Text("No stocks in your watchlist.")
                        .foregroundColor(.gray)
                        .padding()
                }

                List(watchlist, id:\.self) { stock in
                    NavigationLink(destination: SentimentViewtwo(ticker: stock)) {
                        HStack {
                            Text(stock)
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)

                Spacer()
            }
            .padding()
            .onAppear {
                if Auth.auth().currentUser == nil {
                    Auth.auth().signInAnonymously { _, error in
                        if let error = error {
                            print("Failed to sign in: \(error.localizedDescription)")
                        } else {
                            fetchWatchlist()
                        }
                    }
                } else {
                    fetchWatchlist()
                }
            }
        }
    }

    func fetchWatchlist() {
        firestoreManager.fetchWatchlist(userID: userID) { list in
            watchlist = list
        }
    }
}

struct SentimentData: Identifiable {
    let id = UUID()
    let type: String
    let count: Int
    let color: Color
}

struct SentimentViewtwo: View {
    let ticker: String
    @StateObject var fetcher = SentimentFetcher()

    var sentimentSummary: [SentimentData] {
        let grouped = Dictionary(grouping: fetcher.results) { $0.sentiment.lowercased() }

        return [
            SentimentData(type: "Positive", count: grouped["positive"]?.count ?? 0, color: .green),
            SentimentData(type: "Neutral", count: grouped["neutral"]?.count ?? 0, color: .gray),
            SentimentData(type: "Negative", count: grouped["negative"]?.count ?? 0, color: .red)
        ].filter { $0.count > 0 }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Sentiment Analysis")
                    .font(.title)
                    .bold()
                    .padding(.top)

                if fetcher.isLoading {
                    ProgressView("Fetching sentiment...")
                        .padding()
                } else if let error = fetcher.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else {
                    if !sentimentSummary.isEmpty {
                        Chart(sentimentSummary) { item in
                            BarMark(
                                x: .value("Sentiment", item.type),
                                y: .value("Count", item.count)
                            ).foregroundStyle(item.color)
                        }
                        .frame(height: 250)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(radius: 2)
                        )
                        .padding(.horizontal)
                    }

                    if fetcher.results.isEmpty {
                        Text("No recent headlines available.")
                            .foregroundColor(.gray)
                    } else {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Related Headlines")
                                .font(.headline)
                                .padding(.leading)

                            ForEach(fetcher.results) { result in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(result.headline)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    Text("Sentiment: \(result.sentiment.capitalized)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(10)
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom)
                    }
                }
            }
        }
        .navigationTitle(ticker.uppercased())
        .onAppear {
            fetcher.fetch(for: ticker)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct SuggestionsView: View {
    @StateObject private var fetcher = SuggestionFetcher()
    private var userID: String {
        Auth.auth().currentUser?.uid ?? "unknown"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Stock Suggestions")
                    .font(.title)
                    .bold()

                if fetcher.sentimentData.isEmpty {
                    ProgressView("Analyzing watchlist...")
                        .onAppear {
                            fetcher.fetchWatchlistAndSentiment(userID: userID)
                        }
                } else {
                    Text("Top Picks")
                        .font(.headline)

                    ForEach(fetcher.sentimentData.prefix(3)) { stock in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(stock.ticker)
                                    .font(.headline)
                                Text(stock.sentimentLabel)
                                    .foregroundColor(stock.sentimentColor)
                            }
                            Spacer()
                            Text("\(Int(stock.sentimentScore * 100))% Positive")
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }

                    Text("Sentiment Comparison")
                        .font(.headline)
                        .padding(.top)

                    Chart(fetcher.sentimentData) { stock in
                        BarMark(
                            x: .value("Ticker", stock.ticker),
                            y: .value("Positive Sentiment %", stock.sentimentScore * 100)
                        )
                        .foregroundStyle(stock.sentimentColor)
                    }
                    .frame(height: 250)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(radius: 2)
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Suggestions")
    }
}

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoggedIn = false

    var body: some View {
        if isLoggedIn {
            ContentView()
        } else {
            VStack(spacing: 20) {
                Text("StockSent")
                    .font(.largeTitle)
                    .bold()

                TextField("Email", text: $email)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                SecureField("Password", text: $password)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)

                Button("Login") {
                    login()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)

                Button("Sign Up") {
                    signUp()
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }

    func login() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Login error: \(error.localizedDescription)"
            } else {
                isLoggedIn = true
            }
        }
    }

    func signUp() {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = "Sign up error: \(error.localizedDescription)"
            } else {
                isLoggedIn = true
            }
        }
    }
    
}
