//
//  Service.swift
//  Fuse
//
//  Created by Britton Katnich on 2016-12-11.
//  Copyright © 2016 Stratum Dynamics Corp. All rights reserved.
//

import UIKit


/**
 * A Service represents a container of processes for a specific domain.  Based on 
 * loose interpretation of a micro services model.  For example a single service
 * could be responsible for netoworking tasks, bluetooth connectivity or configuration
 * handling.  It could be anything the application developer desires.
 *
 * It is expected this is subclassed to handle those specific use cases.
 */
class Service: NSObject
{
    // MARK: Properties
    
    /**
     * The current runtime state of a Service instance.  It defaults to
     * 'unknown'.
     * 
     * Possible values are:
     *
     *     unknown
     *     initialized
     *     isStarting
     *     started
     *     isStopped
     *     stopped
     */
    var state: ServiceState = .unknown
    
    
    // MARK: Actions
    
    /**
     * The state action callback for parent objects to receive updates
     * when a Service state change takes place.
     *
     * @param ServiceState that the Service has changed to.
     * @param String description of the change, if any.
     */
    var stateAction: ((ServiceState, String) throws -> Void)?
    
    
    // MARK: Public
    
    /**
     * This will return a String value showing the current state of the
     * Service instance.  It is handy for debugging purposes.
     *
     * @return String
     */
    func stateDescription() -> String
    {
        return self.stateDescription(indent: "")
    }


    /**
     * This will return a String value showing the current state of the
     * Service instance.  It is handy for debugging purposes.
     *
     * @param String with empty spaces to use for indentation, if any.
     * @return String
     */
    func stateDescription(indent: String) -> String
    {
        let indentValue = indent + "  "
        
        let desc: String = "\n" + indent + String(describing: type(of: self)) + "\n" +
            "\n" + indentValue + "state: " + state.rawValue
    
        return desc
    }
}


/**
 * The ServiceProtocol is present to allow for each Service to be detected at runtime
 * generically, instantiated and then put their their complete lifecycle by the
 * ServiceRegistry.
 */
@objc protocol ServiceProtocol
{
    // MARK: Service
    
    @objc static func service() -> ServiceProtocol
    
    
    // MARK: Lifecycle
    
    /**
     * Service lifecycle method indicating the service is in a 'started' state.
     *
     * When this is called by the ServiceRegistry it guarantees that all services 
     * are now also in a 'started' state.  The Service can then call any other
     * service which it is dependent upon.
     *
     * Can throw Errors.
     */
    func serviceDidStart() throws -> Void
    
    
    /**
     * Service lifecycle method indicating the service is in a 'isStarting' state.
     *
     * This is where any processes requiring intialization take place before the
     * Service can indicate it is ready to go to 'started' state to the ServiceRegistry.
     *
     * Can throw Errors.
     */
    func serviceWillStart() throws -> Void
    
    
    /**
     * Service lifecycle method indicating the service is in a 'stopped' state.
     *
     * When this is called by the ServiceRegistry it guarantees that all services 
     * are now also in a 'stopped' state and are no longer available.
     *
     * Can throw Errors.
     */
    func serviceDidStop() throws -> Void
    
    
    /**
     * Service lifecycle method indicating the service is in a 'isStopping' state.
     *
     * This is where any processes requiring shutodown or resources requiring deallocation
     * take place before the Service can indicate it is ready to go to 'stopped' state to 
     * the ServiceRegistry.
     *
     * Can throw Errors.
     */
    func serviceWillStop() throws -> Void
}


/**
 * The enumerated state values the Service can be in at any given time.
 */
enum ServiceState: String
{
    case unknown
    case initialized
    case isStarting
    case started
    case isStopping
    case stopped
}
