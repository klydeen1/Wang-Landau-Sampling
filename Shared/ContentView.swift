//
//  ContentView.swift
//  Shared
//
//  Created by Katelyn Lydeen on 4/15/22.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var myModel = TwoDWangLandau()
    @ObservedObject var drawingData = DrawingData(withData: true)
    
    @State var NString = "5" // Number of particles on one side
    @State var tempString = "100.0" // Temperature
    @State var tolString = "100" // Tolerance for the simulation divided by 1e-10
    
    @State var magString = ""
    @State var spHeatString = ""
    @State var energyString = ""
    
    @State var selectedStart = "Cold"
    var startOptions = ["Cold", "Hot"]
    
    var body: some View {
        HStack {
            VStack {
                HStack {
                    VStack(alignment: .center) {
                        Text("# Particles on One Side")
                            .font(.callout)
                            .bold()
                        TextField("# Particles on One Side", text: $NString)
                    }
                    
                    VStack(alignment: .center) {
                        Text("System Temperature (K)")
                            .font(.callout)
                            .bold()
                        TextField("# Temperature (K)", text: $tempString)
                    }
                    
                    VStack(alignment: .center) {
                        Text("Tolerance (Order of e-10)")
                            .font(.callout)
                            .bold()
                        TextField("# Tolerance", text: $tolString)
                    }
                }
                /*
                VStack {
                    Text("Start Type")
                        .font(.callout)
                        .bold()
                    Picker("", selection: $selectedStart) {
                        ForEach(startOptions, id: \.self) {
                            Text($0)
                        }
                    }
                }
                 */
                
                HStack {
                    Button("Run Algorithm Once", action: {Task.init{await self.runAlgorithmOnce()}})
                        .padding()
                        .disabled(myModel.enableButton == false)
                    
                    Button("Run Simulation", action: {Task.init{await self.runMany()}})
                        .padding()
                        .disabled(myModel.enableButton == false)
                    
                    Button("Recalculate Properties", action: {Task.init{await self.getThermoProperties()}})
                        .padding()
                        .disabled(myModel.enableButton == false)
                }
                
                Button("Reset", action: {Task.init{self.reset()}})
                    .padding()
                    .disabled(myModel.enableButton == false)
                
                VStack {
                    Text("Results")
                        .padding()
                    
                    HStack {
                        Spacer()
                        VStack(alignment: .center) {
                            Text("Internal Energy")
                                .font(.callout)
                                .bold()
                            TextField("# Internal Energy", text: $energyString)
                        }
                        
                        VStack(alignment: .center) {
                            Text("Magnetization")
                                .font(.callout)
                                .bold()
                            TextField("# Magnetization", text: $magString)
                        }
                        
                        VStack(alignment: .center) {
                            Text("Specific Heat")
                                .font(.callout)
                                .bold()
                            TextField("# Specific Heat", text: $spHeatString)
                        }
                    }
                }
            }
            
            .padding()
            //DrawingField
            drawingView(redLayer: $drawingData.spinUpData, blueLayer: $drawingData.spinDownData, N: myModel.N, n: myModel.numIterations)
                .padding()
                .aspectRatio(1, contentMode: .fit)
                .drawingGroup()
            // Stop the window shrinking to zero.
            Spacer()
            
        }
        // Stop the window shrinking to zero.
        Spacer()
        Divider()
    }
    
    @MainActor func runAlgorithmOnce() async {
        checkNChange()
        
        myModel.setButtonEnable(state: false)
        
        myModel.printSpins = true
        myModel.N = Int(NString)!
        myModel.temp = Double(tempString)!
        await iterate()
        
        myModel.setButtonEnable(state: true)
    }
    
    @MainActor func runMany() async{
        checkNChange()
        self.reset()
        
        myModel.setButtonEnable(state: false)
        
        myModel.printSpins = false
        
        myModel.temp = Double(tempString)!
        myModel.tol = Double(tolString)! * 1.0e-10
        
        myModel.newSpinUpPoints = []
        myModel.newSpinDownPoints = []
        
        await myModel.runSimulation(startType: selectedStart)
        drawingData.spinUpData = myModel.newSpinUpPoints
        drawingData.spinDownData = myModel.newSpinDownPoints
        
        magString = myModel.magString
        spHeatString = myModel.spHeatString
        energyString = myModel.energyString
        
        myModel.setButtonEnable(state: true)
    }
    
    @MainActor func iterate() async {
        await myModel.iterateWangLandau(startType: selectedStart)
        drawingData.spinUpData = myModel.newSpinUpPoints
        drawingData.spinDownData = myModel.newSpinDownPoints
    }
    
    @MainActor func getThermoProperties() async {
        myModel.temp = Double(tempString)!
        await myModel.calculateProperties()
    }
    
    func checkNChange() {
        let prevN = myModel.N
        myModel.N = Int(NString)!
        if (prevN != myModel.N) {
            self.reset()
        }
    }
    
    @MainActor func reset() {
        myModel.setButtonEnable(state: false)
        
        myModel.mySpin.spinArray = []
        myModel.twoDSpinArray = []
        if(myModel.printSpins) {
            print("\nNew Config")
        }
        
        drawingData.clearData()
        
        myModel.setButtonEnable(state: true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
