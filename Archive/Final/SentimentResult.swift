//
//  SentimentResult.swift
//  Final
//
//  Created by Sahana Mohankumar on 6/2/25.
//


import SwiftUI
import Charts


struct SentimentResult: Identifiable, Decodable {
    let id = UUID()
    let headline: String
    let sentiment: String
    var gptSentiment: String?

    enum CodingKeys: String, CodingKey {
        case headline
        case sentiment
    }
}


struct Article: Identifiable, Decodable {
    let id = UUID()
    let title: String
    let description: String?
}

struct NewsResponse: Decodable {
    let articles: [Article]
}


struct StockSentiment: Identifiable {
    var id: String { ticker }
    let ticker: String
    let positiveCount: Int
    let totalCount: Int
    let sentimentScore: Double
    let sentimentLabel: String
    let sentimentColor: Color
 
}

struct SentimentCount: Identifiable {
    let id = UUID()
    let type: String
    let count: Int
    let color: Color
} 
