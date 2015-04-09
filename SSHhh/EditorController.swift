//
//  EditorController.swift
//  SSHhh
//
//  Created by Maddison Joyce on 2/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Cocoa

class EditorController: NSViewController {
    @IBOutlet weak var enableField: NSButton!
    @IBOutlet weak var nameField: NSTextField!
    @IBOutlet weak var hostField: NSTextField!
    @IBOutlet weak var userField: NSTextField!
    @IBOutlet weak var portField: NSTextField!
    @IBOutlet weak var portStepper: NSStepper!
    @IBOutlet weak var keyPopup: NSPopUpButton!
    
    var appDel: AppDelegate
    var context: NSManagedObjectContext
    dynamic var keys: [AnyObject] = []
    
    required init?(coder: NSCoder) {
        appDel = NSApplication.sharedApplication().delegate as! AppDelegate
        context = appDel.managedObjectContext!
        super.init(coder: coder)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "handleModelDataChange:", name: NSManagedObjectContextObjectsDidChangeNotification, object: context)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        handleModelDataChange(nil)
    }
    
    func handleModelDataChange(note: NSNotification?) {
        var identities = context.executeFetchRequest(NSFetchRequest(entityName: "Identities"), error: nil)! as! [NSManagedObject]
        keys = []
        for identity in identities {
            if identity.valueForKey("name") != nil {
                keys.append(identity.valueForKey("name")!)
            }
        }
    }
    
    @IBAction func testSSHKey(sender: AnyObject?) {
        var config = representedObject as! Config
        
        config.testingImage = config.TestingTesting
        
        var task = NSTask()
        task.launchPath = "/usr/bin/ssh"
        task.arguments = ["-q", "-F", "/dev/null", "-p", String(config.port), "-l", config.user, "-i", config.keyPath, config.host, "exit"]
        
        task.launch()
        task.waitUntilExit()
        
        if (task.terminationStatus == 0) {
            config.testingImage = config.TestingSuccess
        } else {
            config.testingImage = config.TestingFailure
        }
    }
}