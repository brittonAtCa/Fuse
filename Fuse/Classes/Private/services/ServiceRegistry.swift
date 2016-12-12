//
//  ServiceRegistry.swift
//  Fuse
//
//  Created by Britton Katnich on 2016-12-11.
//  Copyright © 2016 Stratum Dynamics Corp. All rights reserved.
//

import UIKit


/**
 * The ServiceRegistry represents a coordinator of all Services in use by the platform.
 * Upon startup it detects all Services that are marked as ServiceProtocols within the
 * application space, instantiates them and puts them through their startup lifecycle.
 *
 * It is a singleton instance.
 */
class ServiceRegistry: NSObject
{
    // MARK: Public Properties
    
    /**
     * The current runtime state of the ServiceRegistry.  It defaults to
     * 'unknown'.
     * 
     * Possible values are:
     *
     *     unknown
     *     initialized
     *     started
     *     stopped
     */
    var state: ServiceRegistryState = .unknown
    
    
    // MARK: Private Properties
    
    /**
     * Retrieve the singleton instance of the ServiceRegistry
     */
    private static let sharedInstance: ServiceRegistry = ServiceRegistry()
    
    
    /**
     * The list of all available Services.
     */
     private var services: [Service] = []
    
    
    // MARK: Registry
    
    /**
     * Retrieve the singleton instance of the ServiceRegistry.
     *
     * @return ServiceRegistry
     */
    static func registry() -> ServiceRegistry
    {
        return sharedInstance
    }
    
    
    /**
     * Private initialization to enforce the singleton nature of the ServiceRegistry.
     */
    private override init()
    {
        super.init()
        
        //
        // Initialize the service instances
        //
        initServices()
    }
    
    
    // MARK: Lifecycle
    
    /**
     * Called to indicate the ServiceRegistry is being requested to startup all
     * Service processes and enter the 'started' state.
     */
    func start() throws
    {
        //
        // If the registry is not in a fully initialized OR stopped state, stop here
        //
        if (state != .initialized && state != .stopped)
        {
            return
        }
        
        //
        // Will start the services
        //
        try registryWillStartServices()
    }
    
    
    /**
     * Called to indicate the ServiceRegistry is being requested to shutdown all
     * Service processes and enter the 'stopped' state.
     */
    func stop() throws
    {
        //
        // If the registry is NOT in a fully started state, stop here
        //
        if (state != .started)
        {
            return
        }
        
        //
        // Will stop the services
        //
        try registryWillStopServices()
    }
    
    
    // MARK: Public
    
    /**
     * This will return a String value showing the current state of the
     * ServiceRegistry.  It is handy for debugging purposes.
     *
     * @return String
     */
    func stateDescription() -> String
    {
        return self.stateDescription(indent: "")
    }


    /**
     * This will return a String value showing the current state of the
     * ServiceRegistry.  It is handy for debugging purposes.
     *
     * @param String with empty spaces to use for indentation, if any.
     * @return String
     */
    public func stateDescription(indent: String) -> String
    {
        let indentValue: String = indent + indent
        
        var desc: String = "\n\n" + indent + "***** Service Registry *****\n" +
            "\n" + indentValue + "state: " + state.rawValue +
            "\n" + indentValue + "services: "
        
        let nextIndentValue = indent + indentValue
        
        for service in services
        {
            desc += "\n" + nextIndentValue +
                service.stateDescription(indent: nextIndentValue)
        }
        
        return desc
    }
    
    
    // MARK: Private
    
    /**
     * Private method encapsulating the steps needed to detect the Services available
     * in the current application state, instaniate them and listen for lifceycle state
     * updates and respond appropriately
     */
    private func initServices() -> Void
    {
        //
        // Obtain all class information
        //
        let expectedClassCount = objc_getClassList(nil, 0)
        let allClasses = UnsafeMutablePointer<AnyClass?>.allocate(capacity: Int(expectedClassCount))
        let autoreleasingAllClasses = AutoreleasingUnsafeMutablePointer<AnyClass?>(allClasses)
        let actualClassCount:Int32 = objc_getClassList(autoreleasingAllClasses, expectedClassCount)

        //
        // Iterate all discovered classes
        //
        for i in 0 ..< actualClassCount
        {
            //
            // Retrieve each class
            //
            if let currentClass: AnyClass = allClasses[Int(i)]
            {
                //
                // Detect if the class comforms to the ServiceProtocol
                //
                if class_conformsToProtocol(currentClass, ServiceProtocol.self)
                {
                    //
                    // Instantiate the discovered service
                    //
                    let serviceProtocol: ServiceProtocol.Type = currentClass as! ServiceProtocol.Type
                    let service: Service = serviceProtocol.service() as! Service
                
                    //
                    // Service Lifecycle Action Callback
                    //
                    service.stateAction =
                    
                        { (state: ServiceState, serviceName: String) -> Void in
    
                            //
                            // Detect state and proceed appropriately
                            //
                            switch state
                            {
                                //
                                // Started
                                //
                                case .started:
                                
                                    //
                                    // Detect if the services are in the correct state to continue
                                    //
                                    if(!self.allServicesAreInState(state: state))
                                    {
                                        return
                                    }
        
                                    //
                                    // Update registry state
                                    //
                                    self.state = .started
                                    
                                    break
                                
                                //
                                // Is Starting
                                //
                                case .isStarting:
                                
                                    try self.registryDidStartServices()
                                    break
                                
                                //
                                // Is Stopping
                                //
                                case .isStopping:
                                
                                    try self.registryDidStopServices()
                                    break
                                
                                //
                                // Stopped
                                //
                                case .stopped:
                                
                                    //
                                    // Detect if the services are in the correct state to continue
                                    //
                                    if(!self.allServicesAreInState(state: state))
                                    {
                                        return
                                    }
                                    
                                    //
                                    // Update registry state
                                    //
                                    self.state = .stopped
                                    
                                    break
                                
                                //
                                // Default
                                //
                                default:
                                
                                    break
                            }
                        }

                    //
                    // If it is the configuration service
                    //
                    if let configurationService = service as? ConfigurationService
                    {
                        //
                        // Guarantee that the configuration service is first in the list so
                        // it will always hit every lifecycle step first
                        //
                        services.insert(configurationService, at: 0)
                    }
                    
                    //
                    // Else this is any other service
                    //
                    else
                    {
                        //
                        // Add newly created services as they are found
                        //
                        services.append(service);
                    }
                }
            }
        }

        allClasses.deallocate(capacity: Int(expectedClassCount))
        
        //
        // Set the lifecycle state
        //
        state = .initialized
    }
    
    
    /**
     * Private function to begin the startup cycle of the available services.
     * If the services are found to have already started the cycle or in a fully
     * 'started' state, this will be ignored.
     */
    private func registryWillStartServices() throws -> Void
    {
        //
        // Detect if the services are in the correct state to continue
        //
        if(!allServicesAreInState(state: .initialized) &&
           !allServicesAreInState(state: .stopped))
        {
            return
        }
        
        //
        // Iterate the services to trigger the lifecycle state change
        //
        for service in services
        {
            try! (service as! ServiceProtocol).serviceWillStart()
        }
    }
    
    
    /**
     * Private function to indicate the end of the startup cycle of the available services.
     * If the services are found to NOT be in 'isStarting' state, this will be ignored.
     */
    private func registryDidStartServices() throws -> Void
    {
        //
        // Detect if the services are in the correct state to continue
        //
        if(!allServicesAreInState(state: .isStarting))
        {
            return
        }
        
        //
        // Iterate the services to trigger the lifecycle state change
        //
        for service in services
        {
            try! (service as! ServiceProtocol).serviceDidStart()
        }
    }
    
    
    /**
     * Private function to begin the stop cycle of the available services.
     * If the services are found to NOT be in fully 'started' state, 
     * this will be ignored.
     */
    private func registryWillStopServices() throws -> Void
    {
        //
        // Detect if the services are in the correct state to continue
        //
        if(!allServicesAreInState(state: .started))
        {
            return
        }
        
        //
        // Iterate the services to trigger the lifecycle state change
        //
        for service in services
        {
            try! (service as! ServiceProtocol).serviceWillStop()
        }
    }
    
    
    /**
     * Private function to indicate the end of the stop cycle of the available services.
     * If the services are found to NOT be in 'isStopping' state, this will be ignored.
     */
    private func registryDidStopServices() throws -> Void
    {
        //
        // Detect if the services are in the correct state to continue
        //
        if(!allServicesAreInState(state: .isStopping))
        {
            return
        }
        
        //
        // Iterate the services to trigger the lifecycle state change
        //
        for service in services
        {
            try! (service as! ServiceProtocol).serviceDidStop()
        }
    }
    
    
    /**
     * Private function to query and detect if all services are showing 
     * to be in the querired ServiceState.
     *
     * @param ServiceState.
     */
    private func allServicesAreInState(state: ServiceState) -> Bool
    {
        for service in services
        {
            if service.state != state
            {
                return false
            }
        }
        
        return true
    }
}


/**
 * The enumerated state values the ServiceRegistry can be in at any given time.
 */
enum ServiceRegistryState: String
{
    case unknown
    case initialized
    case started
    case stopped
}
