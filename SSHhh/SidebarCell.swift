//
//  SidebarTextField.swift
//  SSHhh
//
//  Created by Maddison Joyce on 9/04/2015.
//  Copyright (c) 2015 Maddison Joyce. All rights reserved.
//

import Cocoa

private var editContext = 1

class SidebarCell: NSTableCellView {
    var config: Config? {
        didSet {
            if (config != nil) {
                self.bind("name", toObject: config!, withKeyPath: "name", options: nil)
                self.config!.bind("name", toObject: self, withKeyPath: "name", options: nil)
                self.config!.addObserver(self, forKeyPath: "edited", options: .New, context: &editContext)
                self.image = self.config!.image
            }
        }
        willSet {
            if (config != nil) {
                self.unbind("name")
                self.config!.unbind("name")
                self.config!.removeObserver(self, forKeyPath: "edited", context: &editContext)
            }
        }
    }
    dynamic var image: NSImage = NSImage(named: NSImageNameActionTemplate)!
    dynamic var name: String = ""
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &editContext {
            image = (object as! Config).image
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }

}