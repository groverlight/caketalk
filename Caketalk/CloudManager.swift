//
//  CloudManager.swift
//  iCloudLogin
//
//  Created by Catarina Simões on 16/11/14.
//  Copyright (c) 2014 velouria.org. All rights reserved.
//

import CloudKit
import Mixpanel

class CloudManager: NSObject {
   
    var defaultContainer: CKContainer?
    
    override init() {
        defaultContainer = CKContainer.defaultContainer()
    }

    func requestPermission(completionHandler: (granted: Bool) -> ()) {
        defaultContainer!.requestApplicationPermission(CKApplicationPermissions.UserDiscoverability, completionHandler: { applicationPermissionStatus, error in
            if applicationPermissionStatus == CKApplicationPermissionStatus.Granted {
                completionHandler(granted: true)
            } else {
                // very simple error handling
                completionHandler(granted: false)
            }
        })
    }
    
    func getUser(completionHandler: (success: Bool, user: User?) -> ()) {
        defaultContainer!.fetchUserRecordIDWithCompletionHandler { (userRecordID, error) in
            if error != nil {
                completionHandler(success: false, user: nil)
            } else {
                let privateDatabase = self.defaultContainer!.privateCloudDatabase
                privateDatabase.fetchRecordWithID(userRecordID!, completionHandler: { (userRecord: CKRecord?, anError) -> Void in
                    if (error != nil) {
                        completionHandler(success: false, user: nil)
                    } else {
                        privateDatabase.saveRecord(userRecord!, completionHandler: { record, error in
                                                   })
                        let user = User(userRecordID: userRecordID!, phoneNumber:phoneNumber)
                        completionHandler(success: true, user: user)
                    }
                })
            }
        }
    }

    func getUserInfo(user: User, completionHandler: (success: Bool, user: User?) -> ()) {
        defaultContainer!.discoverUserInfoWithUserRecordID(user.userRecordID) { (info, fetchError) in
            if fetchError != nil {
                completionHandler(success: false, user: nil)
            } else {
                userFull?.firstName = info!.displayContact!.givenName
                userFull?.lastName = info!.displayContact!.familyName

                let mixPanel = Mixpanel.sharedInstanceWithToken("11b47df52a50300426d230d38fa9d30c")
                mixPanel.identify(mixPanel.distinctId)
                mixPanel.people.set(["first_name" : userFull!.firstName!, "last_name" : userFull!.lastName!])
                mixPanel.flush()
                
                completionHandler(success: true, user: user)
            }
        }
    }

}
