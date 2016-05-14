//
//  User.swift
//  iCloudLogin
//
//  Created by Catarina Simões on 16/11/14.
//  Copyright (c) 2014 velouria.org. All rights reserved.
//

import CloudKit

class User: NSObject {
   
    var userRecordID: CKRecordID
    var firstName: String?
    var lastName: String?
    var phoneNumber: String?
    
    init(userRecordID: CKRecordID, phoneNumber:String) {
        print ("making subscription...")
        self.userRecordID = userRecordID
        self.phoneNumber = phoneNumber
        if (phoneNumber.characters.count > 0){
            
        
       /* let searchTerm = String(phoneNumber.characters.suffix(10))
         print (searchTerm)
        let predicate = NSPredicate(format: "toUser = '\(searchTerm)'")
        let defaultContainer = CKContainer.defaultContainer()
       let publicDatabase = defaultContainer.publicCloudDatabase
        let subs = CKSubscription(recordType: "Message", predicate: predicate,options: .FiresOnRecordCreation)
        subs.notificationInfo = CKNotificationInfo()
        subs.notificationInfo!.alertBody = "New item added"*/
       /* publicDatabase.saveSubscription(subs, completionHandler: {
            subscription, error in
        
       //  print (subscription)
            //print (error)
        })*/
    
        }
        
        
       
        
    }
    

}

