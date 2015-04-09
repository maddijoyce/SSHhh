//
//  AboutViewController.swift
//  SSHhh
//
//  Created by Maddison Joyce on 7/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Cocoa

class AboutViewController: NSViewController {
    @IBOutlet weak var image: NSImageView!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var versionField: NSTextField!
    @IBOutlet weak var copyrightField: NSTextField!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nameField.stringValue = NSBundle.mainBundle().infoDictionary?["CFBundleName"]! as! String
        versionField.stringValue = "Version " + (NSBundle.mainBundle().infoDictionary?["CFBundleShortVersionString"]! as! String)
        copyrightField.stringValue = NSBundle.mainBundle().infoDictionary?["NSHumanReadableCopyright"]! as! String
        var icon = NSImage(named: NSBundle.mainBundle().infoDictionary?["CFBundleIconFile"]! as! String)
        image.image = icon
    }
}
