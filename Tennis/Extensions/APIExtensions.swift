//
//  APIExtensions.swift
//  Tennis
//
//  Created by Stephen Byatt on 3/9/21.
//

import SwiftUI
import TennisAPI
import Combine


extension Player {
    public func fullName() -> String {
        
        guard let f = firstName else {
            return "Player"
        }
        
        if let l = lastName {
            return "\(f) \(l)"
        }
        else {
            return f
        }
    }
}

extension Competition {
    public func formatPosition() -> String {
        
        var i = 1
        if let pos = self.pos {
            i = pos
        }
        
        let j = i % 10,
            k = i % 100;
        if (j == 1 && k != 11) {
            return "\(i)st";
        }
        if (j == 2 && k != 12) {
            return "\(i)nd";
        }
        if (j == 3 && k != 13) {
            return "\(i)rd";
        }
        return "\(i)th";
    }
}

extension Match {
    public func getFormattedStartDate() -> String?{
        if let date = startDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "E d MMM yyyy h:mm a"
            return formatter.string(from: date)
        }
        
        return nil
    }
    
    public func getFormattedEndDate() -> String?{
        if let date = endDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "E d MMM yyyy h:mm a"
            return formatter.string(from: date)
        }
        
        return nil
    }
    
    public func getMatchDuration() -> String? {
        if let startDate = startDate, let endDate = endDate {
            let duration = endDate.timeIntervalSinceReferenceDate - startDate.timeIntervalSinceReferenceDate
            let formatter = DateComponentsFormatter()
            formatter.unitsStyle = .brief
            return formatter.string(from: duration)
        }
        return nil
        
    }
}


