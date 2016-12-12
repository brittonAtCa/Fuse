//
//  Fuse.swift
//  Fuse
//
//  Created by Britton Katnich on 2016-12-11.
//  Copyright © 2016 Stratum Dynamics Corp. All rights reserved.
//

import KumulosSDK
import UIKit


/**
 * The Fuse service platform provides a safe startup cycle for the myriad
 * possible mobile micro services that an application using the platform might
 * require.
 *
 * It is not instantiated but used via public, static functions.
 */
public class Fuse
{
    // MARK: ** Properties **
    
    // todo
    
    
    // MARK: Lifecycle
    
    /**
     * Private init method to enforce inability to instantiate.
     */
    private init()
    {
        // do nothing
    }
    
    
    /**
     * Start the platform with the appropriate api key and secret key.
     *
     * @param apiKey String api key that is required for access to the API.
     * @param secretKeyu String secret key that is required for access to the API.
     */
    public class func start(apiKey: String, secretKey: String) throws -> Void
    {
        print("start called with apiKey: " + apiKey + " secretKey: " + secretKey)
        
        //
        // Kumulos
        //
        Kumulos.initialize(apiKey, secretKey: secretKey)
        
        //
        // Retrieve the service registry
        //
        let registry: ServiceRegistry = ServiceRegistry.registry()
        
        //
        // Start the service registry
        //
        try registry.start()
    }
    
    
    // MARK: ** Public **
    
    /**
     * This will return a String value showing the current state of various
     * parts of the platform.  It is handy for debugging purposes.
     *
     * @return String.
     */
    public class func stateDescription() -> String
    {
        let indentValue: String = "  "
        
        return "\n\n\n**************** Fuse ****************\n" +
        
            "\n" + indentValue + ServiceRegistry.registry().stateDescription(indent: indentValue) +
            
            "\n\n**************************************\n\n"
    }
}
