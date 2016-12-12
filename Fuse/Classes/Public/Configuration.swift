//
//  Configuration.swift
//  Fuse
//
//  Created by Britton Katnich on 2016-12-11.
//  Copyright © 2016 Stratum Dynamics Corp. All rights reserved.
//

import UIKit


/**
 * The public model representing the configuration.
 */
public class Configuration: NSObject
{
    /** 
     * The base url the application will be communicating with over the network, if any.
     *
     * @return String.
     */
    public var baseUrl: String?
    {
        get
        {
            return (ConfigurationService.configurationService().configPropertyForKey(
                key: ConfigurationConstants.PropertyKey.baseUrl) as! String?)!
        }
    }
    
    
    /** 
     * The configuration version.
     * 
     * @return String.
     */
    public var version: String
    {
        get
        {
            return (ConfigurationService.configurationService().configPropertyForKey(
                key: ConfigurationConstants.PropertyKey.version) as! String?)!
        }
    }
    
    
    // MARK: ** Private Properties **
    
    /**
     *
     */
    private static let sharedInstance: Configuration = Configuration()
    
    
    // MARK: ** Lifecycle **
    
    /** 
     * Retrieves the singleton instance of the Configuration.
     */
    @objc static func configuration() -> Configuration
    {
        return sharedInstance;
    }
    
    
    /**
     * Private init to enforce the singleton behaviour.
     */
    private override init()
    {
        super.init()
    }
    
    
    // MARK: ** Public **
    
    /**
     * Retrieve a configuration property by the given key value.  It could be nil
     * if no such key value exists.
     *
     * @return Any? This could be a String or other primitive value.
     */
    public func configPropertyForKey(key: String) -> Any?
    {
        return ConfigurationService.configurationService().configPropertyForKey(key: key)
    }
    
    
    /**
     * This will return a String value showing the current state of the Configuration.  
     * It is handy for debugging purposes.
     *
     * @return String.
     */
    public func stateDescription() -> String
    {
        var desc: String = "\n" + "version: " + self.version
        
        desc += "\n" + "baseUrl: " + (self.baseUrl ?? "<none found>")
        
        return desc
    }
    
    
    /**
     * This will return a String value showing the current state of the Configuration.  
     * It is handy for debugging purposes.
     *
     * @param String with empty spaces to use for indentation, if any.
     * @return String.
     */
    public func stateDescription(indent: String) -> String
    {
        var desc: String = "\n" + indent + "version: " + self.version
        
        desc += "\n" + indent + "baseUrl: " + (self.baseUrl ?? "<none found>")
        
        return desc
    }
}


// MARK: ** Constants **

/** 
 * The configuration specific constants structure.
 */
public struct ConfigurationConstants
{
    static let appName: String = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    
    /** 
     * The configuration property key value constants structure.
     */
    struct PropertyKey
    {
        static let baseUrl: String = "baseUrl"
        static let version: String = "version"
    }
}
