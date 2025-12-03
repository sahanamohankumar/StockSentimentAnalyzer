Stock sent
Stocksent is an IOS app that allows users to track stock tickers, analyze news-based sentiment using AI, and recieve personalized stock suggestions. Built using Swift UI and Firebase.

Add and manage a perosanl stock watchlist
AI-powered sentiment analysis of recent stock news
Recieve stock suggestions based on positive sentiment
Email/password user authentication
Visual sentiment comparison using bar charts 

Technologies:
Swift UI- UI framework
Firebase Authentication 
Firebase Firestore - Cloud data storage
GNews API - News Source for sentiment analysis
Custom OpenAI-based sentimen API - Classified headline sentiment 
Data visualizaiton in SwiftUI

Setup Instruction:
Open in Xcode 
Go to Firebase Console 
    Create a project and enable Firestore + Authetication
    Download GoogleService-Info.plist and drag into project root
Open FirestoreManager.swift
Replace YOUR_API_KEY in NewsFetcher class within ContentView.swift
Replace URLS in SentimentFethcer and SuggestinFetcher with your own backend function 

Backend function:
Download Node.js
In terminal follow commands:
    sudo npm install -g firebase-tools
    firebase init functions
    cd functions
    sudo npm install axios
    firebase use --add 
        select your project, follow along commands with your preferred choices 
    firebase use <project>
    firebase deploy --only functions

Copy URL from output it will look like: https://us-central1-YOUR_PROJECT.cloudfunctions.net/getStockNewsSentiment
Paste URL into your app



Sahana Mohankumar 
June 2025
