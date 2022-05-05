//
//  DrawingView.swift
//  Wang-Landau-Sampling
//
//  Created by Katelyn Lydeen on 4/21/22.
//

import SwiftUI

struct drawingView: View {
    @Binding var redLayer : [(xPoint: Double, yPoint: Double)]
    @Binding var blueLayer : [(xPoint: Double, yPoint: Double)]
    
    var N: Int
    var n: Int
    
    var body: some View {
        ZStack{
            drawSpins(drawingPoints: redLayer, numParticles: N, numIterations: n)
                .stroke(Color.red)
            
            drawSpins(drawingPoints: blueLayer, numParticles: N, numIterations: n)
                .stroke(Color.blue)
        }
        .background(Color.white)
        .aspectRatio(1, contentMode: .fill)
    }
}

struct DrawingView_Previews: PreviewProvider {
    @State static var redLayer : [(xPoint: Double, yPoint: Double)] = [(-0.5, 0.5), (0.5, 0.5), (0.0, 0.0), (0.0, 1.0)]
    @State static var blueLayer : [(xPoint: Double, yPoint: Double)] = [(-0.5, -0.5), (0.5, -0.5), (0.9, 0.0)]
    @State static var numParticles = 3
    @State static var numIterations = 5
    
    static var previews: some View {
        drawingView(redLayer: $redLayer, blueLayer: $blueLayer, N: numParticles, n: numIterations)
            .aspectRatio(1, contentMode: .fill)
            //.drawingGroup()
    }
}

struct drawSpins: Shape {
    let smoothness : CGFloat = 1.0
    var drawingPoints: [(xPoint: Double, yPoint: Double)]
    var numParticles: Int
    var numIterations: Int
    
    func path(in rect: CGRect) -> Path {
        
        // draw from the center of our rectangle
        let center = CGPoint(x: rect.width / 2, y: rect.height / 2)
        let scale = rect.width

        // Create the Path for the display
        var path = Path()
        
        for item in drawingPoints {
            let boxWidth = 3.0
            let xCoord = item.xPoint/Double(numParticles - 1)*(Double(scale) - boxWidth)
            let yCoord = item.yPoint/Double(numParticles - 1)*(Double(-scale) + boxWidth) + 2.0*Double(center.y) - boxWidth
            path.addRect(CGRect(x: xCoord, y: yCoord, width: boxWidth, height: boxWidth))
        }
        return (path)
    }
}
