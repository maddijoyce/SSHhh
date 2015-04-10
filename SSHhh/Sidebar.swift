//
//  Sidebar.swift
//  SSHhh
//
//  Created by Maddison Joyce on 9/04/2015.
//  Copyright (c) 2015 Maddison Joyce. All rights reserved.
//

import Cocoa

class Sidebar: NSOutlineView {
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        
        if (theEvent.clickCount < 2) {
            return
        }
        
        var localPoint:NSPoint = convertPoint(theEvent.locationInWindow, fromView: nil)
        var row = rowAtPoint(localPoint)
        
        if (row < 0) {
            return
        }
        
        var view:SidebarCell = viewAtColumn(0, row: row, makeIfNecessary: false) as! SidebarCell
        if (view.textField!.editable) {
            view.window?.makeFirstResponder(view.textField)
        }
    }
    
    override func reloadData() {
        super.reloadData()
        expandItem(nil, expandChildren: true)
    }
}