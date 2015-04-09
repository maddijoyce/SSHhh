//
//  ViewController.swift
//  SSHhh
//
//  Created by Maddison Joyce on 2/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Cocoa

private var configContext = 0
private var windowContext = 1
private var keyContext    = 2
private var fileContext   = 3
private var importContext = 4

class ViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var sideBar: NSOutlineView!
    
    var configFile: ConfigFile
    var editor: EditorController
    var window: WindowController?
    
    required init?(coder: NSCoder) {
        editor = NSStoryboard(name: "Main", bundle: nil)!.instantiateControllerWithIdentifier("EditorController") as! EditorController
        configFile = ConfigFile()
        window = nil
        super.init(coder: coder)
        
        representedObject = configFile
        configFile.addObserver(self, forKeyPath: "search", options: .New, context: &windowContext)
        for config in configFile.configs {
            config.addObserver(self, forKeyPath: "edited", options: .New, context: &configContext)
            config.addObserver(self, forKeyPath: "keyChanged", options: .New, context: &keyContext)
        }
        NSUserDefaults.standardUserDefaults().addObserver(self, forKeyPath: "filePath", options: .New, context: &fileContext)
        
        var appDel = NSApplication.sharedApplication().delegate as! AppDelegate
        appDel.addObserver(self, forKeyPath: "importedConfigs", options: .New, context: &importContext)
    }
    
    override var representedObject: AnyObject? {
        didSet {
            sideBar?.reloadData()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        var registeredTypes:[String] = [NSStringPboardType]
        sideBar.registerForDraggedTypes(registeredTypes)
        
        sideBar.rowSizeStyle = NSTableViewRowSizeStyle.Default
        splitView.subviews[1].removeFromSuperview()
        var v: NSView = editor.view
        v.frame = splitView.bounds
        v.autoresizingMask = NSAutoresizingMaskOptions.ViewWidthSizable | NSAutoresizingMaskOptions.ViewHeightSizable
        splitView.addSubview(v)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        canRemoveHost = false
        window = (view.window!.windowController() as! WindowController)
        window?.configFile = configFile
        window?.addOrRemoveClosure = addOrRemoveHost
        sideBar.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
    }

    // Outline View Delegate & Data Source
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        return (item == nil) ? configFile.filteredConfigs.count : 0
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return false
    }
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        return configFile.filteredConfigs[index]
    }
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        var config = (item as! Config)
        var view = outlineView.makeViewWithIdentifier("DataCell", owner: self) as! NSTableCellView
        
        view.imageView!.image = config.image
        view.textField!.stringValue = config.name
        config.sideBarView = view
        
        return view
    }
    func outlineViewSelectionDidChange(notification: NSNotification) {
        if sideBar.selectedRow != -1 {
            var c = sideBar.itemAtRow(sideBar.selectedRow) as! Config
            editor.representedObject = c
            canRemoveHost = true
        }
    }
    
    func outlineView(outlineView: NSOutlineView, writeItems items: [AnyObject], toPasteboard pasteboard: NSPasteboard) -> Bool {
        var index:Int? = find(configFile.configs, items.first as! Config)
        var data:NSData = NSKeyedArchiver.archivedDataWithRootObject(index!)
        
        var registeredTypes:[String] = [NSStringPboardType]
        pasteboard.declareTypes(registeredTypes, owner: self)
        pasteboard.setData(data, forType: NSStringPboardType)
        return true
    }
    
    func outlineView(outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: AnyObject?, proposedChildIndex index: Int) -> NSDragOperation {
        var data:NSData = info.draggingPasteboard().dataForType(NSStringPboardType)!
        var oldIndex:Int = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Int
        
        if item == nil && index != oldIndex && index != oldIndex + 1 && index != -1 {
            return .Move
        }
        return .None
    }
    
    func outlineView(outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: AnyObject?, childIndex index: Int) -> Bool {
        if item == nil {
            var data:NSData = info.draggingPasteboard().dataForType(NSStringPboardType)!
            var oldIndex:Int = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! Int
            
            if (index == oldIndex || index == oldIndex + 1 || index == -1) {
                return false
            } else {
                var config = configFile.configs.removeAtIndex(oldIndex)
                configFile.configs.insert(config, atIndex: index > oldIndex ? index - 1 : index)
                self.sideBar.reloadData()
                
                return true
            }
        }
        return false
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &configContext {
            (object as! Config).sideBarView?.imageView!.image = (object as! Config).image
            (object as! Config).sideBarView?.textField!.stringValue = (object as! Config).name
        } else if context == &keyContext {
            (object as! Config).testButtonText = "Test SSH Key"
            (object as! Config).testingImage = (object as! Config).TestingUnknown
        } else if context == &windowContext {
            var config: Config! = nil
            if sideBar.selectedRow != -1 {
                config = sideBar.itemAtRow(sideBar.selectedRow) as! Config
            }
            sideBar.reloadData()
            if config != nil && contains(configFile.filteredConfigs, config) {
                sideBar.selectRowIndexes(NSIndexSet(index: sideBar.rowForItem(config)), byExtendingSelection: false)
            } else if configFile.filteredConfigs.count == 0 {
                editor.representedObject = nil
                canRemoveHost = false
            } else {
                sideBar.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
            }
        } else if context == &fileContext {
            revertHosts(object)
        } else if context == &importContext {
            var appDel = NSApplication.sharedApplication().delegate as! AppDelegate
            if appDel.importedConfigs.count > 0 {
                for config in appDel.importedConfigs {
                    configFile.configs.append(config)
                    config.edited = true
                    config.addObserver(self, forKeyPath: "edited", options: .New, context: &configContext)
                    config.addObserver(self, forKeyPath: "keyChanged", options: .New, context: &keyContext)
                }
                sideBar.reloadData()
                sideBar.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
                appDel.importedConfigs = []
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    @IBAction func addHost(AnyObject) {
        var config = Config(name: "")
        configFile.configs.append(config)
        window?.searchField.stringValue = ""
        window?.filterHosts(window!.searchField)
        window?.searchField.window?.makeFirstResponder(sideBar)
        sideBar?.reloadData()
        sideBar.selectRowIndexes(NSIndexSet(index: sideBar.rowForItem(config)), byExtendingSelection: false)
        config.addObserver(self, forKeyPath: "edited", options: .New, context: &configContext)
    }
    var canRemoveHost: Bool = false {
        didSet {
            (window?.addRemoveButton as NSSegmentedControl?)?.setEnabled(canRemoveHost, forSegment: 1)
        }
    }
    override func validateMenuItem(item: NSMenuItem) -> Bool {
        if (item.title == "Delete") {
            return canRemoveHost
        }
        return true
    }
    @IBAction func removeHost(AnyObject) {
        var index = sideBar.selectedRow
        if index >= 0 {
            var alert = NSAlert()
            alert.messageText = "Are you sure?"
            alert.informativeText = "Are you sure you want to remove this host? If deleted, this host will remain active until you save your changes."
            alert.addButtonWithTitle("Yes")
            alert.addButtonWithTitle("No")
            alert.beginSheetModalForWindow(view.window!, completionHandler: {
                (response: NSModalResponse) in
                if response == NSAlertFirstButtonReturn {
                    var trueIndex = find(self.configFile.configs, self.configFile.filteredConfigs[index])
                    var config = self.configFile.configs.removeAtIndex(trueIndex!)
                    config.removeObserver(self, forKeyPath: "edited", context: &configContext)
                    config.removeObserver(self, forKeyPath: "keyChanged", context: &keyContext)
                    var newIndex = index == 0 ? 0 : index - 1
                    if self.configFile.filteredConfigs.count == 0 {
                        newIndex = -1
                        self.editor.representedObject = nil
                        self.canRemoveHost = false
                    }
                    self.sideBar.reloadData()
                    self.sideBar.selectRowIndexes(NSIndexSet(index: newIndex), byExtendingSelection: false)
                }
            })
        }
    }
    @IBAction func addOrRemoveHost(object: AnyObject) {
        switch (object as! NSSegmentedControl).selectedSegment {
        case 0:
            addHost(object)
        case 1:
            removeHost(object)
        default:
            NSLog("Untracked Segment Clicked")
        }
    }
    @IBAction func saveHosts(AnyObject) {
        configFile.saveToFile()
    }
    @IBAction func revertHosts(AnyObject) {
        for config in configFile.configs {
            config.removeObserver(self, forKeyPath: "edited", context: &configContext)
            config.removeObserver(self, forKeyPath: "keyChanged", context: &keyContext)
        }
        editor.representedObject = nil
        canRemoveHost = false
        configFile.reload()
        for config in configFile.configs {
            config.addObserver(self, forKeyPath: "edited", options: .New, context: &configContext)
            config.addObserver(self, forKeyPath: "keyChanged", options: .New, context: &keyContext)
        }
        sideBar.reloadData()
        sideBar.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
    }
}

