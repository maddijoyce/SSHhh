//
//  AboutController.swift
//  SSHhh
//
//  Created by Maddison Joyce on 3/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Cocoa

class AboutWindow: NSWindow {
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override init(contentRect: NSRect, styleMask windowStyle: Int, backing bufferingType: NSBackingStoreType, defer deferCreation: Bool) {
        var newWindowStyle = NSTitledWindowMask | NSTexturedBackgroundWindowMask | NSClosableWindowMask
        super.init(contentRect: contentRect, styleMask: newWindowStyle, backing: bufferingType, defer: deferCreation)
        backgroundColor = NSColor.textBackgroundColor()
        titlebarAppearsTransparent = true
        movableByWindowBackground = true
    }
}

