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
        for config in configs {
            config.search = self.search
        }
        return configs.filter() { self.search == nil || $0.name.lowercaseString.rangeOfString(self.search!.lowercaseString) != nil || $0.filteredConfigs.count > 0 }
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
    
    func fromString(string: String?, edited: Bool) -> ([Config], String) {
        var myConfigs: [Config] = []
        var surroundingData: [String] = []
        
        if string != nil {
            var myConfig = false
            var config: Config?
            var folder: Config?
            
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
                            config = Config(name: c[1])
                            config?.enabled = (c[0] == "Host")
                        case "#EndHost":
                            if config != nil {
                                config?.edited = edited
                                if folder != nil {
                                    folder!.configs.append(config!)
                                    config!.parent = folder
                                } else {
                                    myConfigs.append(config!)
                                }
                            }
                        case "HostName", "#HostName":
                            config?.host = " ".join(c[1..<c.count])
                        case "User", "#User":
                            config?.user = " ".join(c[1..<c.count])
                        case "Port", "#Port":
                            config?.port = c[1].toInt()!
                        case "IdentityFile", "#IdentityFile":
                            config?.keyString = " ".join(c[1..<c.count]).stringByReplacingOccurrencesOfString("\"", withString: "").lastPathComponent
                        case "#Folder":
                            var newFolder = Config(name: " ".join(c[1..<c.count]))
                            newFolder.isFolder = true
                            newFolder.parent = folder
                            folder = newFolder
                        case "#EndFolder":
                            if folder != nil {
                                myConfigs.append(folder!)
                                folder = folder?.parent
                            }
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
        }
        
        return (myConfigs, "\n".join(surroundingData))
    }
    
    func openFile() -> ([Config], String) {
        let data: NSData? = NSData(contentsOfFile: expandedPath)
        return fromString(NSString(data: data!, encoding:NSUTF8StringEncoding) as? String, edited: false)
    }
    
    func toString() -> String {
        var path = (NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first! as! String).stringByAppendingPathComponent(NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"]! as! String)
        var string: String = ""
        
        (_, string) = openFile()
        
        string += (string != "") ? "\n" : ""
        
        string += "\(myConfigStart)\n"
        
        string += configArrayToString(configs)
        
        string += "\(myConfigEnd)\n"
        return string
    }
    
    func configArrayToString(configs: [Config]) -> String {
        var useMultipleAliases: Bool = NSUserDefaults.standardUserDefaults().boolForKey("useMultipleAliases")
        var string = ""
        
        for config in configs {
            var e = config.enabled && config.validated ? "" : "#"
            
            var multipleAlias = ""
            if (useMultipleAliases) {
                multipleAlias = " \(config.host)"
            }
            
            if config.isFolder {
                string += "#Folder \(config.name)\n"
                string += configArrayToString(config.configs)
                string += "#EndFolder\n"
            } else {
                string += "\(e)Host \(config.name)\(multipleAlias)\n" +
                          "\(e)\tHostName \(config.host)\n" +
                          "\(e)\tUser \(config.user)\n" +
                          "\(e)\tPort \(config.port)\n"
                if config.keyString != "" {
                    var keyPath = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.ApplicationSupportDirectory, NSSearchPathDomainMask.UserDomainMask, true).first! as! String
                    keyPath = keyPath.stringByAppendingPathComponent((NSBundle.mainBundle().infoDictionary?["CFBundleIdentifier"]! as! String))
                    keyPath = keyPath.stringByAppendingPathComponent(config.keyString)
                    string += "\(e)\tIdentityFile \"\(keyPath)\"\n"
                }
                string += "#EndHost\n"
            }
            config.edited = false
        }
        return string
    }
    
    func saveToFile() {
        toString().writeToFile(expandedPath, atomically: false, encoding: NSUTF8StringEncoding, error: nil)
    }
}