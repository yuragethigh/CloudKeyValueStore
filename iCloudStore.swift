//
//  CloudKeyValueStoreService.swift
//  Assistants
//
//  Created by Yuriy on 07.02.2025.
//

import Foundation

protocol CloudKeyValueStoring {
    func save<Value>(value: Value, for key: CloudStorageKey)
    func fetch<Value>(for key: CloudStorageKey) -> Value?
    func delete(for key: CloudStorageKey)
    func clearAll()
}

enum CloudStorageKey: String {
    case freeUserRemainingRequests
}

final class CloudKeyValueStoreService: CloudKeyValueStoring {
    
    private let synchronizationQueue = DispatchQueue(label: "com.assistants.cloudKeyValueStoreQueue", attributes: .concurrent)
    
    private let store: NSUbiquitousKeyValueStore
    private let logger: LoggerProtocol
    
    init(store: NSUbiquitousKeyValueStore = .default, logger: LoggerProtocol = MockLogger()) {
        self.store = store
        self.logger = logger
    }
    
    func save<Value>(value: Value, for key: CloudStorageKey) {
        synchronizationQueue.sync(flags: .barrier) {
            store.set(value, forKey: key.rawValue)
            store.synchronize()
            logger.log(object: self, "✅ Save success - Key: \(key.rawValue), Value: \(value)")
        }
    }
    
    func fetch<Value>(for key: CloudStorageKey) -> Value? {
        var result: Value?
        synchronizationQueue.sync {
            result = store.object(forKey: key.rawValue) as? Value
            if let value = result {
                logger.log(object: self, "✅ Fetch success - Key: \(key.rawValue), Value: \(value)")
            }
        }
        return result
    }
    
    func delete(for key: CloudStorageKey) {
        synchronizationQueue.sync(flags: .barrier) {
            store.removeObject(forKey: key.rawValue)
            store.synchronize()
            logger.log(object: self, "✅ Delete success - Key: \(key.rawValue)")
        }
    }
    
    func clearAll() {
        synchronizationQueue.sync(flags: .barrier) {
            for key in store.dictionaryRepresentation.keys {
                store.removeObject(forKey: key)
                logger.log(object: self, "Deleted key - \(key)")
            }
            store.synchronize()
        }
    }
}

//MARK: - Mock logger

protocol LoggerProtocol {
   func log(object: Any, _ message: String)
}

struct MockLogger: LoggerProtocol {
    func log(object: Any, _ message: String) {
        print("Object: -", message, "")
    }
}

