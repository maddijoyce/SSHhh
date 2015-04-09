//
//  Window.swift
//  SSHhh
//
//  Created by Maddison Joyce on 2/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {
    @IBOutlet weak var addRemoveButton: NSSegmentedControl!
    @IBOutlet weak var searchField: NSSearchField!
    
    var configFile: ConfigFile!
    var addOrRemoveClosure: (AnyObject) -> ()
    
    required init?(coder: NSCoder) {
        addOrRemoveClosure = { (AnyObject) -> () in
            NSLog("No Closure")
        }
        super.init(coder: coder)
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
        self.window!.titleVisibility = NSWindowTitleVisibility.Hidden
    }
    
    @IBAction func filterHosts(sender: AnyObject) {
        var searchString = (sender as! NSSearchField).stringValue
        if configFile != nil {
            configFile!.search = (searchString == "") ? nil : searchString
        }
    }
    @IBAction func saveHosts(AnyObject) {
        configFile?.saveToFile()
    }
    @IBAction func addOrRemoveHost(object: AnyObject) {
        addOrRemoveClosure(object)
    }
}