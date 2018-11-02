//
//  BBDiskStorage.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2018/10/29.
//  Copyright © 2018年 Kaibo Lu. All rights reserved.
//

import UIKit
import SQLite3

public enum BBDiskStorageType {
    case file
    case sqlite
}

public class BBDiskStorage {
    private let ioLock: DispatchSemaphore
    private let baseDataPath: String
    private var database: OpaquePointer?
    
    public init?(path: String) {
        ioLock = DispatchSemaphore(value: 1)
        baseDataPath = path + "/Data"
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)
        } catch _ {
            print("Fail to create BBCache base path")
            return nil
        }
        do {
            try FileManager.default.createDirectory(atPath: baseDataPath, withIntermediateDirectories: true)
        } catch _ {
            print("Fail to create BBCache base data path")
            return nil
        }
        let databasePath = path + "/BBCache.sqlite"
        if sqlite3_open(databasePath, &database) != SQLITE_OK {
            print("Fail to open sqlite at \(databasePath)")
            return nil
        }
        let sql = "CREATE TABLE IF NOT EXISTS Storage_item (key text PRIMARY KEY, filename text, data blob, size integer, last_access_time real);"
        if sqlite3_exec(database, sql, nil, nil, nil) != SQLITE_OK {
            print("Fail to create BBCache sqlite Storage_item table")
            return nil
        }
        // TODO: Create index
    }
    
    deinit {
        ioLock.wait()
        if let db = database { sqlite3_close(db) }
        ioLock.signal()
    }
    
    public func data(forKey key: String) -> Data? {
        if key.isEmpty { return nil }
        ioLock.wait()
        var data: Data?
        let sql = "SELECT filename, data, size FROM Storage_item WHERE key = '\(key)';"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                let filenamePointer = sqlite3_column_text(stmt, 0)
                let dataPointer = sqlite3_column_blob(stmt, 1)
                let size = sqlite3_column_int(stmt, 2)
                if let currentDataPointer = dataPointer,
                    size > 0 {
                    // Get data from database
                    data = Data(bytes: currentDataPointer, count: Int(size))
                } else if let currentFilenamePointer = filenamePointer {
                    // Get data from data file
                    let filename = String(cString: currentFilenamePointer)
                    data = try? Data(contentsOf: URL(fileURLWithPath: "\(baseDataPath)/\(filename)"))
                }
                if data != nil {
                    // Update last access time
                    let sql = "UPDATE Storage_item SET last_access_time = \(CACurrentMediaTime()) WHERE key = '\(key)';"
                    sqlite3_exec(database, sql, nil, nil, nil)
                }
            }
            sqlite3_finalize(stmt)
        } else {
            print("Can not select data")
        }
        ioLock.signal()
        return data
    }
    
    public func store(_ data: Data, forKey key: String, type: BBDiskStorageType) {
        if key.isEmpty { return }
        ioLock.wait()
        let sql = "INSERT OR REPLACE INTO Storage_item (key, filename, data, size, last_access_time) VALUES (?1, ?2, ?3, ?4, ?5);"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(database, sql, -1, &stmt, nil) == SQLITE_OK {
            sqlite3_bind_text(stmt, 1, (key as NSString).utf8String, -1, nil)
            let nsdata = data as NSData
            if type == .file {
                let filename = key.md5
                sqlite3_bind_text(stmt, 2, (filename as NSString).utf8String, -1, nil)
                sqlite3_bind_blob(stmt, 3, nil, 0, nil)
                try? data.write(to: URL(fileURLWithPath: "\(baseDataPath)/\(filename)"))
            } else {
                sqlite3_bind_text(stmt, 2, nil, -1, nil)
                sqlite3_bind_blob(stmt, 3, nsdata.bytes, Int32(nsdata.length), nil)
            }
            sqlite3_bind_int(stmt, 4, Int32(nsdata.length))
            sqlite3_bind_double(stmt, 5, CACurrentMediaTime())
            if sqlite3_step(stmt) != SQLITE_DONE {
                print("Fail to insert data for key \(key)")
            }
            sqlite3_finalize(stmt)
        }
        ioLock.signal()
    }
    
    public func removeData(forKey key: String) {
        if key.isEmpty { return }
        ioLock.wait()
        // Get filename and delete file data
        let selectSql = "SELECT filename FROM Storage_item WHERE key = '\(key)';"
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(database, selectSql, -1, &stmt, nil) == SQLITE_OK {
            if sqlite3_step(stmt) == SQLITE_ROW {
                if let filenamePointer = sqlite3_column_text(stmt, 0) {
                    let filename = String(cString: filenamePointer)
                    try? FileManager.default.removeItem(atPath: "\(baseDataPath)/\(filename)")
                }
            }
            sqlite3_finalize(stmt)
        }
        // Delete from database
        let sql = "DELETE FROM Storage_item WHERE key = '\(key)';"
        if sqlite3_exec(database, sql, nil, nil, nil) != SQLITE_OK {
            print("Fail to remove data for key \(key)")
        }
        ioLock.signal()
    }
    
    public func clear() {
        ioLock.wait()
        let sql = "DELETE FROM Storage_item;"
        if sqlite3_exec(database, sql, nil, nil, nil) != SQLITE_OK {
            print("Fail to delete data")
        }
        if let enumerator = FileManager.default.enumerator(atPath: baseDataPath) {
            for next in enumerator {
                if let path = next as? String {
                    try? FileManager.default.removeItem(atPath: "\(baseDataPath)/\(path)")
                    print("Clear item at path: \(baseDataPath)/\(path)")
                }
            }
        }
        ioLock.signal()
    }
}
