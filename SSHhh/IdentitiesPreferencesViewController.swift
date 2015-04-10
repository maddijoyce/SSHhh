//
//  IdentitiesPreferencesViewController.swift
//  SSHhh
//
//  Created by Maddison Joyce on 7/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Cocoa

private var identityNameContext = 2
private var identityContentContext = 3
class IdentitiesPreferencesViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @IBOutlet weak var identityList: NSOutlineView!
    @IBOutlet var privateKeyField: NSTextView!
    
    var results: [AnyObject] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        privateKeyField.automaticQuoteSubstitutionEnabled = false
        privateKeyField.automaticDashSubstitutionEnabled = false
    }
    
    override func viewDidAppear() {
        var appDel: AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        results = context.executeFetchRequest(NSFetchRequest(entityName: "Identities"), error: nil)!
        for identity in results {
            identity.addObserver(self, forKeyPath: "name", options: .Old, context: &identityNameContext)
            identity.addObserver(self, forKeyPath: "privateKey", options: .New, context: &identityContentContext)
        }
        identityList.reloadData()
        identityList.selectRowIndexes(NSIndexSet(index: identityList.rowForItem(representedObject)), byExtendingSelection: false)
    }
    
    @IBAction func generatePublicKey(sender: AnyObject) {
        if representedObject != nil {
            var identity = representedObject as! NSManagedObject
            var path = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first! as! String).stringByAppendingPathComponent(NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"]! as! String).stringByAppendingPathComponent(identity.valueForKey("name") as! String)

            var task = NSTask()
            task.launchPath = "/usr/bin/ssh-keygen"
            task.arguments = ["-q", "-y", "-f", path]
            var output = NSPipe()
            task.standardOutput = output
            task.launch()
            task.waitUntilExit()
            var publicKey = NSString(data: output.fileHandleForReading.availableData, encoding: NSUTF8StringEncoding)!

            var pb = NSPasteboard(name: NSGeneralPboard)
            pb.clearContents()
            pb.writeObjects([publicKey])
        }
    }

    @IBAction func addIdentity(sender: AnyObject) {
        var appDel: AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        
        var identity = NSEntityDescription.insertNewObjectForEntityForName("Identities", inManagedObjectContext: context) as! NSManagedObject
        
        var path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first! as! String
        path = path.stringByAppendingPathComponent((NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"]! as! String))
        NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: nil)
        
        var temp = path.stringByAppendingPathComponent("temp")
        var task = NSTask()
        task.launchPath = "/usr/bin/ssh-keygen"
        task.arguments = ["-q", "-t", "rsa", "-N", "", "-f", temp]
        task.launch()
        task.waitUntilExit()

        identity.setValue(NSString(data: NSData(contentsOfFile: temp)!, encoding:NSUTF8StringEncoding) as! String, forKey: "privateKey")
        NSFileManager.defaultManager().removeItemAtPath(temp, error: nil)
        NSFileManager.defaultManager().removeItemAtPath(temp + ".pub", error: nil)
        
        context.save(nil)
        
        identity.addObserver(self, forKeyPath: "name", options: .Old, context: &identityNameContext)
        identity.addObserver(self, forKeyPath: "privateKey", options: .New, context: &identityContentContext)
        results.append(identity)
        
        identityList.reloadData()
        identityList.selectRowIndexes(NSIndexSet(index: identityList.rowForItem(identity)), byExtendingSelection: false)
    }
    @IBAction func importIdentity(sender: AnyObject) {
        var panel = NSOpenPanel()
        panel.title = "Select a private key file"
        panel.showsResizeIndicator = true
        panel.showsHiddenFiles = true
        panel.canChooseDirectories = false
        panel.canCreateDirectories = false
        panel.allowsMultipleSelection = false
        
        panel.beginSheetModalForWindow(view.window!, completionHandler: {
            (response: Int) in
            if response == NSFileHandlingPanelOKButton {
                var file = panel.URLs[0] as! NSURL
                var privateKey = NSString(data: NSData(contentsOfURL: file)!, encoding:NSUTF8StringEncoding)!
                
                var appDel: AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
                var context: NSManagedObjectContext = appDel.managedObjectContext!
                
                var identity = NSEntityDescription.insertNewObjectForEntityForName("Identities", inManagedObjectContext: context) as! NSManagedObject
                
                var path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first! as! String
                path = path.stringByAppendingPathComponent((NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"]! as! String))
                NSFileManager.defaultManager().createDirectoryAtPath(path, withIntermediateDirectories: true, attributes: nil, error: nil)
                
                identity.setValue(file.lastPathComponent, forKey: "name")
                identity.setValue(privateKey, forKey: "privateKey")
                
                context.save(nil)
                var newPath = path.stringByAppendingPathComponent(file.lastPathComponent!)
                NSFileManager.defaultManager().createFileAtPath(newPath, contents: privateKey.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
                NSFileManager.defaultManager().setAttributes([NSFilePosixPermissions: NSNumber(short: 256)], ofItemAtPath: newPath, error: nil)
                
                identity.addObserver(self, forKeyPath: "name", options: .Old, context: &identityNameContext)
                identity.addObserver(self, forKeyPath: "privateKey", options: .New, context: &identityContentContext)
                self.results.append(identity)
                
                self.identityList.reloadData()
                self.identityList.selectRowIndexes(NSIndexSet(index: self.identityList.rowForItem(identity)), byExtendingSelection: false)
            }
        })
    }
    
    dynamic var canRemoveIdentity: Bool = false
    @IBAction func removeIdentity(sender: AnyObject) {
        var appDel: AppDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        var context: NSManagedObjectContext = appDel.managedObjectContext!
        
        var index = identityList.selectedRow
        if index >= 0 {
            var alert = NSAlert()
            alert.messageText = "Are you sure?"
            alert.informativeText = "Are you sure you want to remove this identity? Any hosts using this identity will no longer have access."
            alert.addButtonWithTitle("Yes")
            alert.addButtonWithTitle("No")
            alert.beginSheetModalForWindow(view.window!, completionHandler: {
                (response: NSModalResponse) in
                if response == NSAlertFirstButtonReturn {
                    var identity = self.results.removeAtIndex(index) as! NSManagedObject
                    
                    if identity.valueForKey("name") != nil {
                        var path = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first! as! String).stringByAppendingPathComponent(NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"]! as! String).stringByAppendingPathComponent(identity.valueForKey("name") as! String)
                        NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
                    }
                    
                    context.deleteObject(identity)
                    if self.results.count == 0 {
                        identity.removeObserver(self, forKeyPath: "name", context: &identityNameContext)
                        identity.removeObserver(self, forKeyPath: "privateKey", context: &identityContentContext)
                        
                        self.representedObject = nil
                        self.canRemoveIdentity = false
                    }
                    self.identityList.reloadData()
                    self.identityList.selectRowIndexes(NSIndexSet(index: index), byExtendingSelection: false)
                    if self.identityList.selectedRow == -1 {
                        self.identityList.selectRowIndexes(NSIndexSet(index: index - 1), byExtendingSelection: false)
                    }
                }
            })
        }

    }
    
    // Outline View Delegate & Data Source
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        return (item == nil) ? results.count : 0
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return false
    }
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        return results[index]
    }
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        var identity = item as! NSManagedObject
        var view = outlineView.makeViewWithIdentifier("IdentityCell", owner: self) as! NSTableCellView
        
        view.textField!.bind("value", toObject: identity, withKeyPath: "name", options: nil)
        
        return view
    }
    func outlineView(outlineView: NSOutlineView,
        heightOfRowByItem item: AnyObject) -> CGFloat {
        return 30
    }
    func outlineViewSelectionDidChange(notification: NSNotification) {
        if identityList.selectedRow != -1 {
            var c = identityList.itemAtRow(identityList.selectedRow) as! NSManagedObject
            representedObject = c
            canRemoveIdentity = true
        } else {
            representedObject = nil
            canRemoveIdentity = false
        }
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        var path = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first! as! String
        path = path.stringByAppendingPathComponent((NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"]! as! String))
        
        if context == &identityNameContext {
            var oldName: String? = change["old"] is NSNull ? nil : change["old"] as! String?
            var newName = (object as! NSManagedObject).valueForKey("name") as! String?
            var privateKey = (object as! NSManagedObject).valueForKey("privateKey") as! String?

            if oldName != nil && newName != nil {
                var oldPath = path.stringByAppendingPathComponent(oldName!)
                var newPath = path.stringByAppendingPathComponent(newName!)
                NSFileManager.defaultManager().moveItemAtPath(oldPath, toPath: newPath, error: nil)
            } else if newName != nil {
                var newPath = path.stringByAppendingPathComponent(newName!)
                NSFileManager.defaultManager().createFileAtPath(newPath, contents: privateKey?.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
                NSFileManager.defaultManager().setAttributes([NSFilePosixPermissions: NSNumber(short: 256)], ofItemAtPath: newPath, error: nil)
            } else if oldName != nil {
                var oldPath = path.stringByAppendingPathComponent(oldName!)
                NSFileManager.defaultManager().removeItemAtPath(oldPath, error: nil)
            }
        } else if context == &identityContentContext {
            var name = (object as! NSManagedObject).valueForKey("name") as! String?
            var privateKey = (object as! NSManagedObject).valueForKey("privateKey") as! String?
            
            if name != nil {
                path = path.stringByAppendingPathComponent(name!)
                
                NSFileManager.defaultManager().removeItemAtPath(path, error: nil)
                NSFileManager.defaultManager().createFileAtPath(path, contents: privateKey?.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
                NSFileManager.defaultManager().setAttributes([NSFilePosixPermissions: NSNumber(short: 256)], ofItemAtPath: path, error: nil)
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }

    }
}