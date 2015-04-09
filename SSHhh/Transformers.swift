//
//  EmptyStringTransformer.swift
//  SSHhh
//
//  Created by Maddison Joyce on 2/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Foundation
import Cocoa

class EmptyStringTransformer: NSValueTransformer {
    func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(object: AnyObject?) -> AnyObject? {
        if object != nil {
            return object
        } else {
            return ""
        }
    }
}

class CapitalizeTransformer: EmptyStringTransformer {
    override func transformedValue(object: AnyObject?) -> AnyObject? {
        return super.transformedValue(object)?.uppercaseString
    }
}

class EnabledColorTransformer: NSValueTransformer {
    func transformedValueClass() -> AnyClass {
        return NSColor.self
    }
    
    func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(object: AnyObject?) -> AnyObject? {
        if object != nil && (!(object is Bool) || (object as! Bool)) {
            return NSColor.labelColor()
        } else {
            return NSColor.tertiaryLabelColor()
        }
    }
}

class IsNotEmpty: NSValueTransformer {
    
    func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override func transformedValue(object: AnyObject?) -> AnyObject? {
        return !(object == nil || object! as! String == "")
    }
}