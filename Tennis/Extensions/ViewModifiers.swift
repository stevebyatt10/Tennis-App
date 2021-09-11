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
            .padding(.vertical)
    }
}
