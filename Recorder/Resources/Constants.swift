//
//  Constants.swift
//  Recorder
//
//  Created by Artur Feshchenko on 6/13/19.
//  Copyright © 2019 home. All rights reserved.
//

import Foundation

enum Constants {
    static let maxRecordingDuration = 30.0
    static let checkInterval = 0.01
    
    static var tempDirectory: URL = {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentDirectory = urls.first!
        return documentDirectory.appendingPathComponent("tempRecording").appendingPathExtension("m4a")
    }()
}
