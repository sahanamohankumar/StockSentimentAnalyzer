
### Core Components

- **FirestoreManager**  
  Handles storing and retrieving user watchlist data from Firestore.

- **NewsFetcher**  
  Sends requests to the GNews API and decodes article data.

- **SentimentFetcher**  
  Fetches sentiment results from the Cloud Function, processes them through the OpenAI-based analyzer, and publishes results to the UI.

- **SuggestionFetcher**  
  Fetches the user's watchlist, retrieves sentiment for each ticker, computes scores, and returns sorted recommendation data.

### Data Models
- `SentimentResult`
- `Article`
- `StockSentiment`
- `NewsResponse`

## Technologies Used

| Technology | Purpose |
|-----------|---------|
| SwiftUI | Application UI and layout |
| FirebaseAuth | User authentication |
| Firestore | Watchlist data storage |
| Cloud Functions | Backend sentiment processing |
| OpenAI | GPT-based sentiment refinement |
| Swift Charts | Visualization of sentiment data |
| URLSession | Networking |

## Setup and Installation

1. Clone the repository.
2. Open the Xcode project file.
3. Add your `GoogleService-Info.plist` file to enable Firebase.
4. Replace API keys:
   - Insert your GNews API key in `NewsFetcher`.
   - Ensure the Cloud Function URL matches your deployment.
5. Build and run the app on a simulator or physical device.

## Usage

1. Launch the app and log in or create an account.
2. Add stock tickers to your watchlist.
3. Tap a ticker to view a sentiment summary and related headlines.
4. Open the Suggestions page to view sentiment-based recommendations across your watchlist.

## Future Enhancements

- Integration with live price data.
- Trending sentiment over time.
- Notifications for sentiment changes.
- Enhanced error handling and retry logic.
- User-customizable preferences for APIs and recommended metrics.

## License

This project is for educational and personal use. A license may be added in the future.
