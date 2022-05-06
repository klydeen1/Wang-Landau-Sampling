//
//  IsingModel.swift
//  Wang-Landau-Sampling
//
//  Created by Katelyn Lydeen on 4/21/22.
//

import Foundation
import SwiftUI

class IsingModel: NSObject, ObservableObject {
    @Published var OneDSpins: [Int] = []
    @Published var enableButton = true
    
    @Published var magString = ""
    @Published var spHeatString = ""
    @Published var energyString = ""
    
    var mySpin = OneDSpin()
    var N = 100 // Number of particles
    var numIterations = 1000
    
    var Mj = 0.0 // Magnetization
    var C = 0.0 // Specific heat
    var U = 0.0 // Internal energy
    var temp = 273.15 // Temperature in Kelvin
    let J = 1.0 // The exchange energy in units 1e-21 Joules
    let kB = 0.01380649 // Boltzmann constant in units 1e-21 Joules/Kelvin
    
    var printSpins = false
    
    var newSpinUpPoints: [(xPoint: Double, yPoint: Double)] = []
    var newSpinDownPoints: [(xPoint: Double, yPoint: Double)] = []
    
    /// iterateMetropolis
    /// Runs the 1D Metropolis algorithm once and prints the resulting configuration
    /// Also sets and prints the initial spin array if the array is empty
    /// - Parameters:
    ///   - startType: the starting configuration for the spin array. value "hot" means we start with random spins. "cold" means the spins are ordered
    func iterateMetropolis(startType: String) async {
        if (mySpin.spinArray.isEmpty) {
            await initializeSpin(startType: startType)
        }

        let newSpinArray = await metropolis(spinConfig: mySpin.spinArray)
        if printSpins {
            await printSpin(spinConfig: newSpinArray)
        }
        mySpin.spinArray = newSpinArray
    }
    
    func runSimulation(startType: String) async {
        newSpinUpPoints = []
        newSpinDownPoints = []
        
        for x in 1...numIterations {
            await iterateMetropolis(startType: startType)
            await addSpinCoordinates(spinConfig: mySpin.spinArray, xCoord: Double(x))
        }
    }
    
    /// initializeSpin
    /// Sets the initial spin array in either a "hot" or "cold" configuration and prints that starting configuration
    /// - Parameters:
    ///   - startType: the starting configuration for the spin array. value "hot" means we start with random spins. "cold" means the spins are ordered
    func initializeSpin(startType: String) async {
        switch(startType.lowercased()) {
        case "hot":
            await mySpin.hotStart(N: N)
            
        case "cold":
            await mySpin.coldStart(N: N)
            
        default:
            await mySpin.hotStart(N: N)
        }
        if printSpins {
            await printSpin(spinConfig: mySpin.spinArray) // Print the starting spin array
        }
        await addSpinCoordinates(spinConfig: mySpin.spinArray, xCoord: 0.0)
    }
    
    /// metropolis
    /// Function to run the 1D Metropolis algorithm once
    /// - Parameters:
    ///   - spinConfig: the 1D spin configuration with positive values representing spin up and negative representing spin down
    /// - returns: the new spin configuration which is either the original configuration or a new one where one random spin is flipped
    func metropolis(spinConfig: [Int]) async -> [Int] {
        // var newSpinConfig: [Double] = []
        let spinToFlip = Int.random(in: 0..<spinConfig.count) // Pick a random particle
        var trialConfig = spinConfig
        trialConfig[spinToFlip] *= -1 // Flip the spin of the random particle
        
        // Get the energies of the configurations
        let trialEnergy = await getConfigEnergy(spinConfig: trialConfig)
        let prevEnergy = await getConfigEnergy(spinConfig: spinConfig)
        
        if (trialEnergy <= prevEnergy) {
            // Accept the trial
            return trialConfig
        }
        else {
            // Accept with relative probability R = exp(-ΔE/kB T)
            let R = exp((-1.0*abs(trialEnergy - prevEnergy))/(kB * temp))
            let r = Double.random(in: 0...1)
            // print("r is \(r) and R is \(R)")
            if (R >= r) { return trialConfig } // Accept the trial
            else { return spinConfig } // Reject the trial and keep the original spin config
        }
    }
    
    /// getConfigEnergy
    /// Gets the energy value of a spin configuration assuming that B = 0. Also applies Born-von Karman boundary conditions
    /// - Parameters:
    ///   - spinConfig: the 1D spin configuration with positive values representing spin up and negative representing spin down
    func getConfigEnergy(spinConfig: [Int]) async -> Double {
        //          /   |  --      |    \           --                     --
        // E    =  / a  |  \    V  | a   \  =  - J  \   s  * s     - B μ   \    s
        //   ak    \  k |  /__   i |  k  /          /__  i    i+1        b /__   i
        
        // But for simplicity, we assume B = 0 so the second term drops out
        // We also use Born-von Karman boundary conditions
        
        var energy = 0.0
        for i in 0..<spinConfig.count {
            if (i == (spinConfig.count-1)) {
                // Couple the last particle in the array to the first particle in it
                energy += -J * Double(spinConfig[0]) * Double(spinConfig[i])
            }
            else {
                // Couple the current particle (index i) with the next one (index i+1)
                energy += -J * Double(spinConfig[i]) * Double(spinConfig[i+1])
            }
        }
        return energy
    }
    
    /// printSpin
    /// Prints the current spin configuration with + representing a spin up particle and - representing a spin down particle
    /// - Parameters:
    ///   - spinConfig: the 1D spin configuration with positive values representing spin up and negative representing spin down
    func printSpin(spinConfig: [Int]) async {
        var spinString = ""
        for i in 0..<spinConfig.count {
            if (spinConfig[i] < 0) { spinString += "-" }
            else { spinString += "+" }
        }
        print(spinString)
    }
    
    /// addSpinCoordinates
    /// Determines whether each particle in a 1D configuration is spin up or spin down. Adds a coordinate point for each particle to either
    /// newSpinUpPoints or newSpinDownPoints depending on the spin.
    /// - Parameters:
    ///    - spinConfig: the 1D spin configuration with positive values representing spin up and negative representing spin down
    ///    - xCoord: the x-coordinate to use for all particles in the configuration spinConfig
    func addSpinCoordinates(spinConfig: [Int], xCoord: Double) async {
        for i in 0..<spinConfig.count {
            if (spinConfig[i] < 0) {
                newSpinDownPoints.append((xPoint: xCoord, yPoint: Double(i)))
            }
            else {
                newSpinUpPoints.append((xPoint: xCoord, yPoint: Double(i)))
            }
        }
    }
    
    /// updateMagnetizationString
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter text: contains the string containing the current value of the magnetization
    @MainActor func updateMagnetizationString(text:String) async {
        self.magString = text
    }
    
    /// updateSpecificHeatString
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter text: contains the string containing the current value of the specific heat
    @MainActor func updateSpecificHeatString(text:String) async {
        self.spHeatString = text
    }
    
    /// updateInternalEnergyString
    /// The function runs on the main thread so it can update the GUI
    /// - Parameter text: contains the string containing the current value of the internal energy
    @MainActor func updateInternalEnergyString(text:String) async {
        self.energyString = text
    }
    
    /// setButton Enable
    /// Toggles the state of the Enable Button on the Main Thread
    /// - Parameter state: Boolean describing whether the button should be enabled.
    @MainActor func setButtonEnable(state: Bool) {
        if state {
            Task.init {
                await MainActor.run { self.enableButton = true }
            }
        }
        else{
            Task.init { await MainActor.run { self.enableButton = false }
            }
        }
    }
}
