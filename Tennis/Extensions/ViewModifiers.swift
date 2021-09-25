//
//  ViewModifiers.swift
//  ViewModifiers
//
//  Created by Stephen Byatt on 11/9/21.
//

import SwiftUI

extension View {
    func roundedBackground() -> some View {
        self.modifier(RoundedBackgroundModifier())
    }
}

struct RoundedBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color("secondbg"))
            .cornerRadius(8)
            .shadow(radius: 4, x: 0, y: 3)
            .padding(.vertical, 4)
    }
}

extension View {
    /// Applies the given transform if the given condition evaluates to `true`.
    /// - Parameters:
    ///   - condition: The condition to evaluate.
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: Either the original `View` or the modified `View` if the condition is `true`.
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
