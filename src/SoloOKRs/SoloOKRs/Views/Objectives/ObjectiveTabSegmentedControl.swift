import SwiftUI

struct ObjectiveTabSegmentedControl: View {
    @Binding var selection: ObjectiveListView.ObjectiveTab
    
    @Namespace private var namespace
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(ObjectiveListView.ObjectiveTab.allCases, id: \.self) { tab in
                let isSelected = selection == tab
                
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selection = tab
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: icon(for: tab))
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                            .foregroundStyle(isSelected ? .white : .secondary)
                        
                        if isSelected {
                            Text(tab.rawValue)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity).combined(with: .scale(scale: 0.8)),
                                    removal: .move(edge: .leading).combined(with: .opacity).combined(with: .scale(scale: 0.8))
                                ))
                        }
                    }
                    .padding(.horizontal, isSelected ? 12 : 8)
                    .padding(.vertical, 6)
                    .background {
                        if isSelected {
                            ZStack {
                                Capsule()
                                    .fill(color(for: tab))
                                    .shadow(color: color(for: tab).opacity(0.3), radius: 4, y: 2)
                                
                                Capsule()
                                    .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                            }
                            .matchedGeometryEffect(id: "TabBackground", in: namespace)
                        } else {
                            Capsule()
                                .fill(Color.secondary.opacity(0.1))
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color.secondary.opacity(0.05))
        .clipShape(Capsule())
    }
    
    private func icon(for tab: ObjectiveListView.ObjectiveTab) -> String {
        switch tab {
        case .draft: return "doc.text"
        case .active: return "bolt.fill"
        case .achieved: return "trophy.fill"
        case .archived: return "archivebox.fill"
        }
    }
    
    private func color(for tab: ObjectiveListView.ObjectiveTab) -> Color {
        switch tab {
        case .draft: return Color(red: 0.00, green: 0.48, blue: 1.00)
        case .active: return Color(red: 0.20, green: 0.80, blue: 0.20)
        case .achieved: return Color(red: 1.00, green: 0.58, blue: 0.00)
        case .archived: return Color(red: 0.69, green: 0.32, blue: 0.87)
        }
    }
}
