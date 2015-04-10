//
//  Config.swift
//  SSHhh
//
//  Created by Maddison Joyce on 2/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Cocoa

class Config: NSObject {
    var sideBarView: NSTableCellView?
    
    dynamic var edited: Bool = false
    dynamic var keyChanged: Bool = false

    dynamic var isFolder: Bool = false
    
    dynamic var parent: Config?
    dynamic var configs: [Config] = []
    dynamic var search: String? = nil
    var filteredConfigs: [Config] {
        return configs.filter() { self.search == nil || $0.name.lowercaseString.rangeOfString(self.search!.lowercaseString) != nil }
    }
    
    let minPort: Int = 1
    let maxPort: Int = 65535
    
    var enabled: Bool = true {
        didSet {
            edited = true
        }
    }
    dynamic var name: String {
        didSet {
            edited = true
        }
    }
    var user: String = "" {
        didSet {
            edited = true
        }
    }
    var host: String = "" {
        didSet {
            edited = true
        }
    }
    dynamic var port: Int = 22 {
        didSet {
            edited = true
        }
    }
    var keyString: String = "" {
        didSet {
            edited = true
            keyChanged = true
        }
    }
    var keyPath: String {
        return (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first! as! String).stringByAppendingPathComponent(NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"]! as! String).stringByAppendingPathComponent(keyString)
    }
    
    let TestingUnknown = NSImage(named: NSImageNameStatusNone)!
    let TestingTesting = NSImage(named: NSImageNameStatusPartiallyAvailable)!
    let TestingSuccess = NSImage(named: NSImageNameStatusAvailable)!
    let TestingFailure = NSImage(named: NSImageNameStatusUnavailable)!
    dynamic var testingImage: NSImage = NSImage(named: NSImageNameStatusNone)!
    dynamic var testButtonText = "Test SSH Key"
    
    init(name: String) {
        self.name = name
        super.init()
    }
    
    override var description: String {
        return "<Config: \(name)>"
    }
    
    var validated: Bool {
        return name != "" && user != "" && host != "" && port >= minPort  && port <= maxPort
    }
    
    dynamic var image: NSImage {
        var imageName = NSImageNameStatusAvailable
        if isFolder {
            imageName = NSImageNameFolder
        } else {
            if edited {
                imageName = NSImageNameStatusPartiallyAvailable
            }
            if !validated {
                imageName = NSImageNameStatusUnavailable
            }
            if !enabled {
                imageName = NSImageNameStatusNone
            }
        }
        return NSImage(named: imageName)!
    }
}