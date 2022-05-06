//
//  TwoDWangLandau.swift
//  Wang-Landau-Sampling
//
//  Created by Katelyn Lydeen on 4/21/22.
//

import Foundation
import SwiftUI

class TwoDWangLandau: IsingModel {
    var twoDSpinArray: [[Int]] = []
    var S: [Double] = [] // Entropy
    var g: [Double] = [] // Density of states
    var gNorm: [Double] = []
    var MjMatrix: [Double] = []
    var Mji = 0.0
    
    var hist: [Double] = [] // Histogram of energies
    var prevHist: [Double] = []
    var height = 0.0
    var histAvg = 0.0
    var histHeight = 0.0
    var Hmin = 0.0
    var Hmax = 1.0e10
    var histPercent = 0.0
    
    var energy = 0
    var factor = 1.1
    var tol = 1.0e-8
    var iter = 0
    var M = 5*5 // Number of particles on one side
    
    func initializeTwoDSpin(startType: String) async {
        twoDSpinArray = []
        Mji = 0.0
        for _ in 0..<N {
            await initializeSpin(startType: startType)
            twoDSpinArray.append(mySpin.spinArray)
            for i in 0..<mySpin.spinArray.count {
                Mji += Double(mySpin.spinArray[i])
            }
        }
    }
    
    override func runSimulation(startType: String) async {
        factor = 1.1
        while(abs(factor - 1.0) > tol) {
            await iterateWangLandau(startType: startType)
        }
        await normalizeG()
        await calculateProperties()
        await addSpinCoordinates(twoDSpinConfig: twoDSpinArray)
    }
    
    func normalizeG() async {
        gNorm = []
        let gSum = g.reduce(0, +)
        for Ei in 0..<g.count {
            gNorm.append(pow(2.0, Double(M)) * g[Ei] / gSum)
        }
    }
    
    func calculateProperties() async {
        var Unum = 0.0
        var denom = 0.0
        var ESquaredNum = 0.0
        var Mnum = 0.0
        for Ei in 0..<gNorm.count {
            Unum += Double(Ei) * gNorm[Ei] * exp(-Double(Ei) / (kB*temp))
            ESquaredNum += Double(Ei)*Double(Ei) * gNorm[Ei] * exp(-Double(Ei) / (kB*temp))
            Mnum += Double(MjMatrix[Ei]) * gNorm[Ei] * exp(-Double(Ei) / (kB*temp))
            denom += gNorm[Ei] * exp(-Double(Ei) / (kB*temp))
        }
        Mj = Mnum / denom
        let ESquaredAvg = ESquaredNum / denom
        U = Unum / denom
        C = (ESquaredAvg - U*U) / (temp*temp)
        
        await updateInternalEnergyString(text: "\(U)")
        await updateMagnetizationString(text: "\(Mj)")
        await updateSpecificHeatString(text: "\(C)")
    }
    
    /// We index the spin matrix as [i][j]
    /// Following [row, column] notation means i should represent the y-axis and j should represent the x-axis
    func addSpinCoordinates(twoDSpinConfig: [[Int]]) async {
        for i in 0..<twoDSpinConfig.count {
            for j in 0..<twoDSpinConfig[i].count {
                if (twoDSpinConfig[i][j] < 0) {
                    newSpinDownPoints.append((xPoint: Double(j), yPoint: Double(i)))
                }
                else {
                    newSpinUpPoints.append((xPoint: Double(j), yPoint: Double(i)))
                }
            }
        }
    }
    
    func iterateWangLandau(startType: String) async {
        newSpinDownPoints = []
        newSpinUpPoints = []
        
        // Initialize values if needed
        if (twoDSpinArray.isEmpty) {
            g = []
            S = []
            MjMatrix = []
            hist = []
            M = N*N
            
            await initializeTwoDSpin(startType: startType)
            energy = -2 * M
            for _ in 0...M {
                g.append(0.01)
                MjMatrix.append(0.0)
                hist.append(0)
            }
            iter = 0
            height = abs(Hmin - Hmax) / 2.0
            histAvg = (Hmin + Hmax) / 2.0
            histPercent = height / histAvg
        }

        // Run the Wang Landau algorithm
        twoDSpinArray = await wangLandau(twoDSpinConfig: twoDSpinArray)
        if printSpins {
            await printSpin(spinConfig: twoDSpinArray)
        }
        await addSpinCoordinates(twoDSpinConfig: twoDSpinArray)
    }
    
    func wangLandau(twoDSpinConfig: [[Int]]) async -> [[Int]] {
        iter += 1
        
        // Pick one random particle and flip its spin
        var spinToFlip: (i: Int, j: Int)
        spinToFlip.i = Int.random(in: 0..<twoDSpinConfig.count)
        spinToFlip.j = Int.random(in: 0..<twoDSpinConfig.count)
        var newConfig = twoDSpinConfig
        
        // Get the energy difference between the configurations
        let deltaE = await getConfigEnergyDiff(spinToFlip: spinToFlip)
        let ETrial = energy + deltaE
        let EPrimeTrial = (ETrial + 2*M) / 4
        var EPrime = (energy + 2*M) / 4
        
        let gTrial = g[EPrimeTrial]
        let gPrev = g[EPrime]
        // S[Int(EPrimeOld)] += fac; // Change the entropy
        
        let R = gPrev / gTrial
        let r = Double.random(in: 0...1)
        if (gTrial <= gPrev || R >= r) {
            // Accept the trial
            newConfig[spinToFlip.i][spinToFlip.j] *= -1 // Flip the spin of the random particle
            Mji += Double(2*newConfig[spinToFlip.i][spinToFlip.j])
            energy = ETrial
            EPrime = EPrimeTrial
        }
        
        MjMatrix[EPrime] = Mji
        g[EPrime] *= factor // Change the density of states
        // print(g[EPrime])
        hist[EPrime] += 1
        
        // Check for histogram flatness
        if (iter % 10000 == 0) {
            await checkHistFlatness()
        }
        
        return newConfig
    }
    
    func checkHistFlatness() async {
        // Adjust the histogram
        for j in 0...M {
            if (j == 0) {
                Hmin = 0
                Hmax = 1.0e10
            }
            if (hist[j] == 0) { continue }
            if (hist[j] > Hmin) { Hmin = hist[j] }
            if (hist[j] < Hmax) { Hmax = hist[j] }
        }
        height = Hmin - Hmax
        histAvg = Hmin + Hmax
        histPercent = height/histAvg
        
        if (histPercent < 0.2) { // Flatness reached?
            factor = sqrt(factor)
            //print("New factor: \(factor)")
            prevHist = hist
            for i in 0..<hist.count {
                hist[i] = 0.0
            }
        }
    }
    
    func getConfigEnergyDiff(spinToFlip: (i: Int, j: Int)) async -> Int {
        // 2σ    * | σ     + σ     + σ     + σ      |
        //   i,j   |  i+1,j   i-1,j   i,j+1   i,j-1 |
        // We use Born-von Karman boundary conditions
        
        var energyDiff = 2*twoDSpinArray[spinToFlip.i][spinToFlip.j]
        
        // Tuple of tuples that store the indexes i+1, i-1, j+1, j-1 using the boundary conditions
        let BC = await handleBCs(spinLoc: spinToFlip)
        
        energyDiff *= (twoDSpinArray[BC.i.next][spinToFlip.j] + twoDSpinArray[BC.i.prev][spinToFlip.j] + twoDSpinArray[spinToFlip.i][BC.j.next] + twoDSpinArray[spinToFlip.i][BC.j.prev])
        
        return energyDiff
    }
    
    /// The last element in the array is coupled with the first element in it
    func handleBCs(spinLoc: (i: Int, j: Int)) async -> (i: (next: Int, prev: Int), j: (next: Int, prev: Int)) {
        // Handle boundary conditions for index i
        var iNext = spinLoc.i + 1
        var iPrev = spinLoc.i - 1
        if (iNext >= twoDSpinArray.count) { iNext = 0 }
        else if (iPrev < 0) { iPrev = twoDSpinArray.count - 1 }
        
        // Handle boundary conditions for index j
        var jNext = spinLoc.j + 1
        var jPrev = spinLoc.j - 1
        if (jNext >= twoDSpinArray.count) { jNext = 0 }
        else if (jPrev < 0) { jPrev = twoDSpinArray.count - 1 }
        
        return (i: (next: iNext, prev: iPrev), j: (next: jNext, prev: jPrev))
    }
    
    func printSpin(spinConfig: [[Int]]) async {
        for i in 0..<spinConfig.count {
            await printSpin(spinConfig: spinConfig[i])
        }
    }
}
