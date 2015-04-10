//
//  ViewController.swift
//  SSHhh
//
//  Created by Maddison Joyce on 2/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Cocoa

private var searchContext = 1
private var fileContext   = 3
private var importContext = 4

class ViewController: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate {
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var sideBar: Sidebar!
    
    var configFile: ConfigFile
    var editor: EditorController
    var window: WindowController?
    
    required init?(coder: NSCoder) {
        editor = NSStoryboard(name: "Main", bundle: nil)!.instantiateControllerWithIdentifier("EditorController") as! EditorController
        configFile = ConfigFile()
        window = nil
        super.init(coder: coder)
        
        representedObject = configFile
        configFile.addObserver(self, forKeyPath: "search", options: .New, context: &searchContext)
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
        
        sideBar?.expandItem(nil, expandChildren: true)
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
        if (item == nil) {
            return configFile.filteredConfigs.count
        } else {
            if (item is Config && (item as! Config).isFolder) {
                return (item as! Config).filteredConfigs.count
            } else {
                return 0
            }
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return item is Config && (item as! Config).isFolder
    }
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if (item is Config && (item as! Config).isFolder) {
            return (item as! Config).filteredConfigs[index]
        } else {
            return configFile.filteredConfigs[index]
        }
    }
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        var config = (item as! Config)
        var view = outlineView.makeViewWithIdentifier("DataCell", owner: self) as! SidebarCell
        
        view.config = config
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
    
    func indexArrayFromConfig(initialConfig: Config?) -> [Int] {
        var c:Config? = initialConfig
        var indexes:[Int] = []
        
        while c != nil {
            if c!.parent != nil {
                indexes.insert(find(c!.parent!.configs, c!)!, atIndex: 0)
            } else {
                indexes.insert(find(configFile.configs, c!)!, atIndex: 0)
            }
            c = c!.parent
        }
        
        return indexes
    }
    func removeConfigfromArray(inout parentArray: [Config], inout indexes: [Int]) -> Config {
        if (indexes.count > 1) {
            return removeConfigfromArray(&parentArray[indexes.removeAtIndex(0)].configs, indexes: &indexes)
        } else {
            return parentArray.removeAtIndex(indexes[0])
        }
    }
    func insertConfigIntoArray(inout parentArray: [Config], index: Int, config: Config) {
        if index < 0 || index > parentArray.count {
            parentArray.append(config)
        } else {
            parentArray.insert(config, atIndex: index)
        }
    }
    
    func outlineView(outlineView: NSOutlineView, writeItems items: [AnyObject], toPasteboard pasteboard: NSPasteboard) -> Bool {
        var c = items.first as! Config?
        
        var data:NSData = NSKeyedArchiver.archivedDataWithRootObject(indexArrayFromConfig(c))
        
        var registeredTypes:[String] = [NSStringPboardType]
        pasteboard.declareTypes(registeredTypes, owner: self)
        pasteboard.setData(data, forType: NSStringPboardType)
        return true
    }
    
    func outlineView(outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: AnyObject?, proposedChildIndex index: Int) -> NSDragOperation {
        return ((item == nil) || (item is Config && (item as! Config).isFolder)) ? .Move : .None
    }
    
    func outlineView(outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: AnyObject?, childIndex index: Int) -> Bool {
        var data:NSData = info.draggingPasteboard().dataForType(NSStringPboardType)!
        var oldIndexes:[Int] = NSKeyedUnarchiver.unarchiveObjectWithData(data) as! [Int]
        var config: Config? = removeConfigfromArray(&configFile.configs, indexes: &oldIndexes)
        
        var trueIndex = index
        if (config!.parent === item && trueIndex > oldIndexes.last!) {
            trueIndex -= 1
        }
        
        if item is Config {
            insertConfigIntoArray(&(item as! Config).configs, index: trueIndex, config: config!)
            config!.parent = item as! Config?
        } else {
            insertConfigIntoArray(&configFile.configs, index: trueIndex, config: config!)
            config!.parent = nil
        }
        
        sideBar.reloadData()
        sideBar.selectRowIndexes(NSIndexSet(index: sideBar.rowForItem(editor.representedObject)), byExtendingSelection: false)
        return true
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        if context == &searchContext {
            var config: Config? = editor.representedObject as! Config?
            sideBar.reloadData()

            sideBar.selectRowIndexes(NSIndexSet(index: sideBar.rowForItem(config)), byExtendingSelection: false)
            if sideBar.selectedRow == -1 {
                sideBar.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
            }
            if sideBar.selectedRow == -1 {
                editor.representedObject = nil
                canRemoveHost = false
            }
        } else if context == &fileContext {
            revertHosts(object)
        } else if context == &importContext {
            var appDel = NSApplication.sharedApplication().delegate as! AppDelegate
            if appDel.importedConfigs.count > 0 {
                for config in appDel.importedConfigs {
                    configFile.configs.append(config)
                    config.edited = true
                }
                sideBar.reloadData()
                for config in appDel.importedConfigs {
                    sideBar.expandItem(config, expandChildren: true)
                }
                sideBar.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
                appDel.importedConfigs = []
            }
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    @IBAction func launchSSHSession(sender: AnyObject?) {
        self.editor.launchSSHSession(sender)
    }
    
    @IBAction func addGroup(AnyObject) {
        var config = Config(name: "New Group")
        config.isFolder = true
        
        var current = self.editor.representedObject as! Config?
        
        if current != nil && current!.isFolder {
            current!.configs.append(config)
            config.parent = current!
            sideBar.expandItem(current!)
        } else if current != nil && current!.parent != nil {
            current!.parent!.configs.append(config)
            config.parent = current!.parent!
            sideBar.expandItem(current!.parent!)
        } else {
            configFile.configs.append(config)
        }
        
        window?.searchField.stringValue = ""
        window?.filterHosts(window!.searchField)
        window?.searchField.window?.makeFirstResponder(sideBar)
        sideBar?.reloadData()
        sideBar.selectRowIndexes(NSIndexSet(index: sideBar.rowForItem(config)), byExtendingSelection: false)
    }
    
    @IBAction func addHost(AnyObject) {
        var config = Config(name: "")
    
        var current = self.editor.representedObject as! Config?
        
        if current != nil && current!.isFolder {
            current!.configs.append(config)
            config.parent = current!
            sideBar.expandItem(current!)
        } else if current != nil && current!.parent != nil {
            current!.parent!.configs.append(config)
            config.parent = current!.parent!
            sideBar.expandItem(current!.parent!)
        } else {
            configFile.configs.append(config)
        }
        
        window?.searchField.stringValue = ""
        window?.filterHosts(window!.searchField)
        window?.searchField.window?.makeFirstResponder(sideBar)
        sideBar?.reloadData()
        sideBar.selectRowIndexes(NSIndexSet(index: sideBar.rowForItem(config)), byExtendingSelection: false)
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
        if self.editor.representedObject != nil {
            var alert = NSAlert()
            alert.messageText = "Are you sure?"
            alert.informativeText = "Are you sure you want to remove this host? If deleted, this host will remain active until you save your changes."
            alert.addButtonWithTitle("Yes")
            alert.addButtonWithTitle("No")
            alert.beginSheetModalForWindow(view.window!, completionHandler: {
                (response: NSModalResponse) in
                if response == NSAlertFirstButtonReturn {
                    var config = self.editor.representedObject as! Config
                    var oldIndex = self.sideBar.rowForItem(config)
                    
                    if config.parent != nil {
                        config.parent!.configs.removeAtIndex(find(config.parent!.configs, config)!)
                    } else {
                        self.configFile.configs.removeAtIndex(find(self.configFile.configs, config)!)
                    }
                    self.editor.representedObject = nil
                    self.canRemoveHost = false
                    self.sideBar.reloadData()
                    
                    self.sideBar.selectRowIndexes(NSIndexSet(index: oldIndex), byExtendingSelection: false)
                    if self.sideBar.selectedRow == -1 {
                        self.sideBar.selectRowIndexes(NSIndexSet(index: oldIndex - 1), byExtendingSelection: false)
                    }
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
        editor.representedObject = nil
        canRemoveHost = false
        configFile.reload()
        sideBar.reloadData()
        sideBar.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
    }
}

