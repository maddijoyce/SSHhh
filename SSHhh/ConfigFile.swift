//
//  ConfigFile.swift
//  SSHhh
//
//  Created by Maddison Joyce on 2/10/2014.
//  Copyright (c) 2014 Maddison Joyce. All rights reserved.
//

import Foundation

class ConfigFile: NSObject {
    let myConfigStart = "# SSHHH START"
    let myConfigEnd = "# SSHHH END"
    
    var path: String
    var expandedPath: String {
        return path.stringByExpandingTildeInPath
    }
    var configs: [Config] = []
    dynamic var search: String? = nil
    
    var filteredConfigs: [Config] {
        return configs.filter() { self.search == nil || $0.name.lowercaseString.rangeOfString(self.search!.lowercaseString) != nil }
    }
    
    override init() {
        path = NSUserDefaults.standardUserDefaults().stringForKey("filePath")!
        super.init()
        (configs, _) = openFile()
    }
    func reload() {
        path = NSUserDefaults.standardUserDefaults().stringForKey("filePath")!
        (configs, _) = openFile()
    }
    
    func fromString(string: String?) -> ([Config], String) {
        var myConfigs: [Config] = []
        var surroundingData: [String] = []
        
        if string != nil {
            var myConfig = false
            var config: Config?
            for line in string!.componentsSeparatedByString("\n") {
                switch line {
                case myConfigStart:
                    myConfig = true
                case myConfigEnd:
                    myConfig = false
                default:
                    if myConfig {
                        let l = line.stringByReplacingOccurrencesOfString("\t", withString: "")
                        let c = l.componentsSeparatedByString(" ")
                        switch c[0] {
                        case "Host", "#Host":
                            if config != nil {
                                config?.edited = false
                                myConfigs.append(config!)
                            }
                            config = Config(name: c[1])
                            config?.enabled = (c[0] == "Host")
                        case "HostName", "#HostName":
                            config?.host = " ".join(c[1..<c.count])
                        case "User", "#User":
                            config?.user = " ".join(c[1..<c.count])
                        case "Port", "#Port":
                            config?.port = c[1].toInt()!
                        case "IdentityFile", "#IdentityFile":
                            config?.keyString = " ".join(c[1..<c.count]).stringByReplacingOccurrencesOfString("\"", withString: "").lastPathComponent
                        default:
                            if c[0] != "" && c[0] != "#" {
                                NSLog("Unrecognised Key: \(c[0])")
                            }
                        }
                    } else {
                        surroundingData.append(line)
                    }
                }
            }
            if config != nil {
                config?.edited = false
                myConfigs.append(config!)
            }
        }
        
        return (myConfigs, "\n".join(surroundingData))
    }
    
    func openFile() -> ([Config], String) {
        let data: NSData? = NSData(contentsOfFile: expandedPath)
        return fromString(NSString(data: data!, encoding:NSUTF8StringEncoding) as? String)
    }
    
    func toString() -> String {
        var path = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first! as! String).stringByAppendingPathComponent(NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"]! as! String)
        var useMultipleAliases: Bool = NSUserDefaults.standardUserDefaults().boolForKey("useMultipleAliases")
        var string: String = ""
        
        (_, string) = openFile()
        
        string += (string != "") ? "\n" : ""
        
        string += "\(myConfigStart)\n"
        
        for config in configs {
            var e = config.enabled && config.validated ? "" : "#"
            
            var multipleAlias = ""
            if (useMultipleAliases) {
                multipleAlias = " \(config.host)"
            }
            
            string += "\(e)Host \(config.name)\(multipleAlias)\n" +
                "\(e)\tHostName \(config.host)\n" +
                "\(e)\tUser \(config.user)\n" +
                "\(e)\tPort \(config.port)\n"
            if config.keyString != "" {
                var keyPath = path.stringByAppendingPathComponent(config.keyString)
                string += "\(e)\tIdentityFile \"\(keyPath)\"\n"
            }
            config.edited = false
        }
        
        string += "\(myConfigEnd)\n"
        return string
    }
    
    func saveToFile() {
        toString().writeToFile(expandedPath, atomically: false, encoding: NSUTF8StringEncoding, error: nil)
    }
}