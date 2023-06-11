//
//  StoryViewModel.swift
//  StoryUI (iOS)
//
//  Created by Tolga İskender on 28.04.2022.
//

import Foundation

class StoryViewModel: ObservableObject {
    
    @Published var currentStoryUser: String = ""
    @Published var stories: [StoryUIModel] = []

    @Published var animationDelay: Double  = 1.0 
    
    func getVideoProgressBarFrame(duration: Double) -> Double {
        return duration * 0.1 // convert any second to  between 0 - 1 second
    }
}
