//
//  ViewExtensions.swift
//  Tennis
//
//  Created by Stephen Byatt on 31/8/21.
//

import SwiftUI

extension View {
    @ViewBuilder
    func flipColorScheme(_ scheme: ColorScheme) -> some View {
        if scheme == .dark{
            self.environment(\.colorScheme, .light)
        } else {
            self.environment(\.colorScheme, .dark)
        }
    }
}

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}
