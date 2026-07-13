//
//  BikePlayLiveNotifyBundle.swift
//  BikePlayLiveNotify
//
//  Created by Göktuğ Toyguc on 13.07.2026.
//

import WidgetKit
import SwiftUI

@main
struct BikePlayLiveNotifyBundle: WidgetBundle {
    var body: some Widget {
        BikePlayLiveNotify()
        BikePlayLiveNotifyControl()
        BikePlayLiveNotifyLiveActivity()
    }
}
