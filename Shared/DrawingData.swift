//
//  DrawingData.swift
//  1D-Metropolis-Algorithm
//
//  Created by Katelyn Lydeen on 4/8/22.
//

import Foundation
import SwiftUI

class DrawingData: NSObject, ObservableObject {
    @MainActor @Published var spinUpData = [(xPoint: Double, yPoint: Double)]()
    @MainActor @Published var spinDownData = [(xPoint: Double, yPoint: Double)]()
    
    @MainActor init(withData data: Bool) {
        super.init()
        spinUpData = []
        spinDownData = []
    }
    
    @MainActor func clearData() {
        spinUpData.removeAll()
        spinDownData.removeAll()
    }
    
}
