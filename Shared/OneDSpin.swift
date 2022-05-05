//
//  OneDSpin.swift
//  1D-Metropolis-Algorithm
//
//  Created by Katelyn Lydeen on 4/1/22.
//

import Foundation
import SwiftUI

class OneDSpin: NSObject, ObservableObject {
    var spinArray: [Int] = []
    
    /// hotStart
    /// Construct a 1D spin array with random spins
    /// Value -1 represens spin down and 1 represents spin up
    /// - Parameters:
    ///   - N: the number of particles for the spin array
    func hotStart(N: Int) async {
        spinArray = []
        for _ in 0..<N {
            let rand = Int.random(in: 0...1)
            if (rand == 0) { spinArray.append(-1) }
            else { spinArray.append(1) }
        }
    }
    
    /// coldStart
    /// Construct a 1D spin array with all spins up
    /// Value -1 represens spin down and 1 represents spin up
    /// - Parameters:
    ///   - N: the number of particles for the spin array
    func coldStart(N: Int) async {
        spinArray = []
        for _ in 0..<N {
            spinArray.append(1)
        }
    }
}
