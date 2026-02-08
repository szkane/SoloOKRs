// AnimatedProgressBar.swift
// SoloOKRs
//
// Animated progress bar with gradient fill

import SwiftUI

struct AnimatedProgressBar: View {
    let progress: Double
    var height: CGFloat = 8
    var cornerRadius: CGFloat = 4
    var showLabel: Bool = false
    
    @State private var animatedProgress: Double = 0
    
    private var gradientColors: [Color] {
        if progress >= 1.0 {
            return [.green, .green]
        } else if progress >= 0.7 {
            return [.blue, .green]
        } else if progress >= 0.3 {
            return [.orange, .blue]
        } else {
            return [.red, .orange]
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.quaternary)
                
                // Fill
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * animatedProgress)
                
                // Label
                if showLabel {
                    Text("\(Int(progress * 100))%")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .shadow(radius: 1)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .frame(height: height)
        .onAppear {
            withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
                animatedProgress = min(max(progress, 0), 1)
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.spring(duration: 0.4, bounce: 0.15)) {
                animatedProgress = min(max(newValue, 0), 1)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AnimatedProgressBar(progress: 0.2)
        AnimatedProgressBar(progress: 0.5, height: 12, showLabel: true)
        AnimatedProgressBar(progress: 0.8)
        AnimatedProgressBar(progress: 1.0, height: 16, showLabel: true)
    }
    .padding()
    .frame(width: 300)
}
