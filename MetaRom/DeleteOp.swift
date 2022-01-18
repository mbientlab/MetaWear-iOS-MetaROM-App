//
//  DeleteOp.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 1/17/19.
//  Copyright © 2019 MBIENTLAB, INC. All rights reserved.
//

//import Parse
import RealmSwift
import BoltsSwift
//import Bolts

class DeleteOp: Object {
    @objc dynamic var parseObjectId = ""
    @objc dynamic var isPatient = false
    
    func delete() -> Task<Void> {
        // TO DO
        let source = TaskCompletionSource<Void>()
        /*let object = isPatient ?
            ParsePatient(withoutDataWithObjectId: parseObjectId) :
            ParseSession(withoutDataWithObjectId: parseObjectId)
        let selfRef = ThreadSafeReference(to: self)
        object.deleteInBackground().continueWith(executor: .background) { t in
            autoreleasepool {
                let realm = try! Realm()
                guard let me = realm.resolve(selfRef) else {
                    source.trySet(result: ())
                    return nil
                }
                if let error = t.error, let code = PFErrorCode(rawValue: error._code) {
                    switch code {
                    case .errorObjectNotFound:
                        // Object already deleted
                        try! realm.write {
                            realm.delete(me)
                        }
                        source.trySet(result: ())
                    default:
                        source.trySet(error: error)
                    }
                } else {
                    try! realm.write {
                        realm.delete(me)
                    }
                    source.trySet(result: ())
                }
                return nil
            }
        }*/
        return source.task
    }
    
    static func deleteAll() -> Task<Void> {
        let realm = try! Realm()
        let allOps = realm.objects(DeleteOp.self)
        return Task<Void>.whenAll(allOps.map { $0.delete() }).continueWithTask { t in
            if let aggregateError = t.error as? AggregateError {
                return Task<Void>(error: aggregateError.errors.first!)
            }
            return t
        }
    }
    
    //static func deleteAllBolts() -> BFTask<AnyObject> {
        //let source = BFTaskCompletionSource<AnyObject>()
        //deleteAll().continueWith { t in
        //    if let error = t.error {
        //        source.trySet(error: error)
        //    } else {
        //        source.trySet(result: nil)
        //    }
        //}
        //return source.task
    //}
}
