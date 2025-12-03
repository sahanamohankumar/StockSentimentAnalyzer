StockSent

StockSent is an iOS application built with SwiftUI. It allows users to track stock tickers, fetch recent news, and view sentiment analysis based on news headlines. The app uses Firebase Authentication, Cloud Firestore, a Cloud Function for sentiment processing, and a GPT-based sentiment analyzer for further refinement.

Overview

Users can log in or sign up, add stock tickers to a personal watchlist, and view sentiment results for each ticker. The app processes sentiment using both a backend Cloud Function and an additional AI pass. A suggestions page ranks the user’s watchlist based on sentiment scores.

Features

Authentication:
Users can create an account or log in with email and password. Anonymous login is used as a fallback.

Watchlist:
Users can add stock tickers to their watchlist. The list is stored in Firestore and reloaded whenever it is updated.

News Fetching:
The app uses the GNews API to fetch up to ten recent news articles for each stock symbol. Headlines and descriptions are displayed in the interface.

Sentiment Analysis:
A Firebase Cloud Function analyzes headlines and returns sentiment labels. A custom GPT-based analyzer refines these results. The app then displays counts of positive, neutral, and negative sentiment using Swift Charts.

Suggestions:
The app evaluates every stock in the user’s watchlist, computes sentiment scores, assigns a recommendation label such as Buy, Neutral, or Avoid, and displays top-ranked stocks along with a comparison chart.

Architecture

LoginView handles authentication.
ContentView manages the watchlist.
SentimentViewtwo shows sentiment data for a selected ticker.
SuggestionsView provides ranked sentiment results for the entire watchlist.
FirestoreManager handles read and write operations for Firestore.
NewsFetcher retrieves external news articles.
SentimentFetcher calls the Cloud Function and performs the AI sentiment pass.
SuggestionFetcher combines sentiment results for all watchlist items.

Setup Instructions

1. Clone or download the project folder.
2. Open the project in Xcode.
3. Add your GoogleService-Info.plist file to enable Firebase.
4. Replace the GNews API key inside NewsFetcher.
5. Add your Firebase Cloud Function URL where sentiment is fetched.

Important Cloud Function Step:

After deploying the Cloud Function, copy the URL from the deployment output. It will look like this:

https://us-central1-YOUR_PROJECT.cloudfunctions.net/getStockNewsSentiment

Paste this URL into your app wherever the sentiment endpoint is referenced.

Running the App

1. Build and run in Xcode.
2. Log in or create an account.
3. Add stock tickers such as TSLA or AAPL.
4. Select a ticker to view sentiment details.
5. Open Suggestions to see rankings based on sentiment.

Future Improvements

- Integration with real-time stock price data
- Historical sentiment graphs
- Push notifications for sentiment changes
- User-adjustable recommendation settings
- Improved error handling

License

This project is intended for personal and educational use.
