//
//  ConfigurationService.swift
//  Fuse
//
//  Created by Britton Katnich on 2016-12-11.
//  Copyright © 2016 Stratum Dynamics Corp. All rights reserved.
//
import KumulosSDK
import UIKit


/**
 * The ConfigurationService is responsible for all processes needed
 * to discover, store and retrieve any configurable values the platform 
 * needs to handle on behalf of a using application.
 *
 * It is a singleton instance.
 */
class ConfigurationService: Service, ServiceProtocol
{
    // MARK: ** Properties **
    
    /**
     * This option is good for debugging purposes when you always
     * want to retreive the configuration from the default source
     * and ignore any stored configuration.  Default to false.
     *
     * Not available for production.  It should never configure 
     * from default except for first execution after installation.
     */
    #if DEBUG
    
    public static var configureFromDefault : Bool = false
    
    #endif
    
    
    /** 
     * The configuration option determines where the service should
     * look to find the json configuration file.
     */
    public static var configurationOption: ConfigurationOption = .local
    
    
    /** 
     * The name of the optional, local configuration file.  It is
     * 'phoenixConfig' by default.
     */
    public static var configurationFile: String = "phoenixConfig"
    
    
    /** 
     * The configuration version.
     */
    public var version: String?
    {
        get
        {
            return self.configPropertyForKey(key: ConfigurationConstants.PropertyKey.version)
                as! String?
        }
    }
    
    
    /** 
     * The base url the application will be communicating with 
     * over the network, if any.  Optional.
     */
    public var baseUrl: String?
    {
        get
        {
            return self.configPropertyForKey(key: ConfigurationConstants.PropertyKey.baseUrl)
                as! String?
        }
    }
    
    
    // MARK: ** Private Properties **
    
    private static let sharedInstance: ConfigurationService = ConfigurationService()
    
    
    // MARK: ** Service **
    
    /** 
     * Retrieves the singleton instance of the ConfigurationService as ServiceProtocol.
     *
     * @return ServiceProtocol.
     */
    @objc static func service() -> ServiceProtocol
    {
        return sharedInstance;
    }
    
    
    /** 
     * Retrieves the singleton instance of the ConfigurationService.
     *
     * @return ConfigurationService.
     */
    static func configurationService() -> ConfigurationService
    {
        return sharedInstance as ConfigurationService;
    }
    
    
    // MARK: ** Lifecycle **
    
    /** 
     * Private init to enforce the singleton behaviour.
     */
    private override init()
    {
        super.init()
        
        //
        // Set the lifecycle state
        //
        state = .initialized
    }
    
    
    /** 
     * @see ServiceProtocol.
     */
    func serviceDidStart() throws -> Void
    {
        //
        // Set lifecycle state
        //
        state = .started
        
        //
        // Notify that lifecycle state action has taken place
        //
        try stateAction!(state, self.description)
    }
    
    
    /** 
     * @see ServiceProtocol.
     */
    func serviceWillStart() throws -> Void
    {
        //
        // Initialize the configuration, error will crash it at runtime
        //
        try configInit()
        
        //
        // Set lifecycle state
        //
        state = .isStarting
        
        //
        // Notify that lifecycle state action has taken place
        //
        try stateAction!(state, self.description)
    }
    
    
    /** 
     * @see ServiceProtocol.
     */
    func serviceDidStop() throws -> Void
    {
        //
        // Set lifecycle state
        //
        state = .stopped
        
        //
        // Notify that lifecycle state action has taken place
        //
        try stateAction!(state, self.description)
    }
    
    
    /** 
     * @see ServiceProtocol.
     */
    func serviceWillStop() throws -> Void
    {
        //
        // Set lifecycle state
        //
        state = .isStopping
        
        //
        // Notify that lifecycle state action has taken place
        //
        try stateAction!(state, self.description)
    }
    
    
    // MARK: ** Public **
    
    /**
     * This will return a String value showing the current state of the
     * Service instance.  It is handy for debugging purposes.
     *
     * @param String with empty spaces to use for indentation, if any.
     * @return String
     */
    public override func stateDescription(indent: String) -> String
    {
        var desc: String = super.stateDescription(indent: indent)
     
        let indentValue = indent + "  "
        
        #if DEBUG
    
        desc += "\n" + indentValue + "configure from default: " + String(ConfigurationService.configureFromDefault)
    
        #endif
    
        desc += "\n" + indentValue + "configuration is stored: " + String(self.configIsStored())
        desc += "\n" + indentValue + "configuration option: " + ConfigurationService.configurationOption.rawValue
        desc += "\n" + indentValue + "configuration file: " + ConfigurationService.configurationFile
        
        //
        // Add the models state as well
        //
        desc += Configuration.configuration().stateDescription(indent: indentValue)
        
        return desc
    }
    
    
    // MARK: ** Configuration Helpers **
    
    /** 
     * Initialize the configuration values
     */
    private func configInit() throws
    {
        #if DEBUG

        //
        // Debug only: If there is a stored configuration AND we do NOT want
        // to use the default configuration file, stop here
        //
        if self.configIsStored() && !ConfigurationService.configureFromDefault
        {
            return
        }
        
        #else
        
        //
        // If there is a stored configuration, do NOT retrieve file and stop here
        //
        if self.configIsStored()
        {
            return
        }
        
        #endif
        
        //
        // Retrieve the configuration dictionary from the embedded file
        //
        if let config: Dictionary<String, Any> = try configFromFile()
        {
            //
            // Store the latest dictionary in the keychain
            //
            do
            {
                try Locksmith.updateData(data: config,
                    forUserAccount: ConfigurationConstants.appName)
                
                return
            }
            catch let error as NSError
            {
                //
                // If it reaches here the file was not found, throw an error
                //
                throw ConfigurationError.configurationFileNotStored(
                    filename: ConfigurationService.configurationFile,
                    error: error)
            }
        }
    }
    
    
    /**
     * Retrieve the configuration from a file that has been preset to be available
     * in the applications Bundle.
     *
     * @return Dictionary<String, Any> of configuration values.
     */
    private func configFromFile() throws -> Dictionary<String, Any>?
    {
        //
        // Check if filename is nil or empty, stop here if so
        //
        if ConfigurationService.configurationFile.isEmpty
        {
            throw ConfigurationError.configurationFilenameNotSet
        }
        
        //
        // Retrieve the file
        //
        if let path = Bundle.main.path(forResource: ConfigurationService.configurationFile,
            ofType: "json")
        {
            //
            // Retrieve the data from the contents of the file
            //
            let jsonData = try? Data(contentsOf: URL(fileURLWithPath: path),
                options: .alwaysMapped)
            
            //
            // Serialize the data to a Dictionary<String, Any>
            //
            do
            {
                let json = try JSONSerialization.jsonObject(with: jsonData!,
                    options: .allowFragments) as! [String:Any]
      
                return json
            }
            catch let error as NSError
            {
                throw ConfigurationError.configurationFileDataNotSerialized(
                    filename: ConfigurationService.configurationFile,
                    error: error)
            }
        }
        
        //
        // If it reaches here the file was not found, throw an error
        //
        throw ConfigurationError.configurationFileNotFound(
            filename: ConfigurationService.configurationFile)
    }
    
    
    /**
     * Retrieve the configuration from a preconfigured endpoint.
     *
     * @return Dictionary<String, Any> of configuration values.
     */
    private func configFromRemote() throws -> Dictionary<String, Any>
    {
        //
        // Call for new configuration
        //
        let operation: KSAPIOperation = Kumulos.call("configuration").success { (response, operation) in
         
            if let value = response.payload as? Array<Any>
            {
                if let body = value[0] as? Dictionary<String, Any>
                {
                    if let content: String = body["content"] as? String
                    {
                        print("content is: " + content)
                    }
                }
            }
            
        }.failure { (error, operation) in
        
            print("failure error: " + (error?.localizedDescription)!)
        
        }
        
        print("operation: " + operation.debugDescription)
        
        return Dictionary<String, Any>();
    }
    
    
    /**
     * Detect if there is stored configuration data.
     *
     * @return True if stored, false if not.
     */
    private func configIsStored() -> Bool
    {
        //
        // Attempt to retrieve the data from the keychain
        //
        if Locksmith.loadDataForUserAccount(userAccount: ConfigurationConstants.appName) != nil
        {
            return true
        }
        
        return false
    }
    
    
    /**
     * Retrieve a configuration property by the given key value.  It could be nil
     * if no such key value exists.
     *
     * @return Any? This could be a String or other primitive value.
     */
    public func configPropertyForKey(key: String) -> Any?
    {
        //
        // Retrieve the data from the keychain
        //
        if let dictionary = Locksmith.loadDataForUserAccount(
            userAccount: ConfigurationConstants.appName)
        {
            //
            // Retrieve the value for the property key
            //
            return dictionary[key] as Any
        }
        
        return nil
    }
}


// MARK: ** Enumerations **

/**
 * The enumerated configuration option.
 */
public enum ConfigurationOption: String
{
    //
    // Unknown
    //
    case unknown
    
    //
    // Local configuration is expected, json from a local file.
    //
    case local
    
    //
    // Remote configuration is expected, a json from a remote endpoint.
    //
    case remote
}


/** 
 * The enumerated configuration related errors.
 */
public enum ConfigurationError: Error
{
    /** 
     * The file's data was not properly serialized.
     *
     * @param filename String name of the file.
     * @param error Native Error that caused the failure.
     */
    case configurationFileDataNotSerialized(filename: String, error: Error)
    
    /** 
     * The file was not found.
     *
     * @param filename String name of the file.
     */
    case configurationFileNotFound(filename: String)
    
    /** 
     * The filename was not set properly, it is nil or empty.
     */
    case configurationFilenameNotSet
    
    /**
     * The data of the file was retrieved in runtime but attempting to
     * store in the Keychain failed.
     *
     * @param filename String name of the file.
     * @param error Native Error that caused the failure.
     */
    case configurationFileNotStored(filename: String, error: Error)
    
    /**
     *
     */
    var localizedDescription: String
    {
        switch self
        {
            case .configurationFileDataNotSerialized:
                
                return NSLocalizedString("\(ConfigurationError.self) File data not properly serialized.",
                    comment: "ConfigurationError")
          
            default:
            
                return NSLocalizedString("Unknown ConfiguarionError.", comment: "ConfigurationError")
        }
    }
}
