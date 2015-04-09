//
//  GeneralPreferencesViewController.swift
//  SSHhh
//
//  Created by Maddison Joyce on 7/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Cocoa

class GeneralPreferencesViewController: NSViewController {
    static let keyConfigStart = "# SSHHHKEY START"
    static let keyConfigEnd = "# SSHHHKEY END"
    
    @IBAction func changeConfigFile(sender: AnyObject) {
        var panel = NSOpenPanel()
        panel.title = "Select a file location"
        panel.showsResizeIndicator = true
        panel.showsHiddenFiles = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModalForWindow(view.window!, completionHandler: {
            (response: Int) in
            if response == NSFileHandlingPanelOKButton {
                var file = panel.URLs[0] as! NSURL
                NSUserDefaults.standardUserDefaults().setValue(file.path!, forKey: "filePath")
            }
        })
    }
    
    @IBAction func importConfig(sender: AnyObject) {
        var panel = NSOpenPanel()
        panel.title = "Import SSHhh Config"
        panel.showsResizeIndicator = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        panel.extensionHidden = true
        panel.allowedFileTypes = ["sshhh"]
        
        panel.beginSheetModalForWindow(view.window!, completionHandler: {
            (response: Int) in
            if response == NSFileHandlingPanelOKButton {
                var file = panel.URLs[0] as! NSURL
                GeneralPreferencesViewController.importConfigFromURL(file)
            }
        })

    }
    static func importConfigFromURL(file: NSURL) {
        var data: NSData? = NSData(contentsOfFile: file.path!)
        var configs: [Config]
        var remainder: String
        
        (configs, remainder) = ConfigFile().fromString(NSString(data: data!, encoding:NSUTF8StringEncoding) as? String)
        
        var appDel = NSApplication.sharedApplication().delegate as! AppDelegate
        appDel.importedConfigs = configs
        
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        var name: String?
        var privateString: String?
        
        for line in remainder.componentsSeparatedByString("\n") {
            switch line {
            case keyConfigStart:
                name = nil
                privateString = ""
            case keyConfigEnd:
                if (name != nil && privateString != "") {
                    var identity = NSEntityDescription.insertNewObjectForEntityForName("Identities", inManagedObjectContext: context) as! NSManagedObject
                    identity.setValue(name, forKey: "name")
                    identity.setValue(privateString, forKey: "privateKey")
                    context.save(nil)
                }
            default:
                let c = line.componentsSeparatedByString(" ")
                if c[0] == "KeyName" {
                   name = " ".join(c[1..<c.count])
                } else {
                    if (privateString != nil) {
                        privateString! += "\(line)\n"
                    }
                }
            }
        }
    }
    
    @IBAction func exportConfig(sender: AnyObject) {
        var panel = NSSavePanel()
        panel.title = "Export SSHhh Config"
        panel.showsResizeIndicator = true
        panel.canCreateDirectories = true
        panel.extensionHidden = true
        panel.allowedFileTypes = ["sshhh"]
        
        panel.beginSheetModalForWindow(view.window!, completionHandler: {
            (response: Int) in
            if response == NSFileHandlingPanelOKButton {
                var exportString = ConfigFile().toString()
                
                var appDel: AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
                var context: NSManagedObjectContext = appDel.managedObjectContext!
                
                var results = context.executeFetchRequest(NSFetchRequest(entityName: "Identities"), error: nil)! as! [NSManagedObject]
                for identity in results {
                    var name = identity.valueForKey("name")! as! String
                    var privateKey = identity.valueForKey("privateKey")! as! String
                    
                    exportString += "\(GeneralPreferencesViewController.keyConfigStart)\n" +
                                    "KeyName \(name)\n" +
                                    "\(privateKey)\n" +
                                    "\(GeneralPreferencesViewController.keyConfigEnd)\n"
                }
                
                NSFileManager.defaultManager().createFileAtPath(panel.URL!.path!, contents: exportString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true), attributes: [NSFileExtensionHidden: true])
            }
        })
    }
}