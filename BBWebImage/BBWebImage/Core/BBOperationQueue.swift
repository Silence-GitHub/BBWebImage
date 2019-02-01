//
//  BBOperationQueue.swift
//  BBWebImage
//
//  Created by Kaibo Lu on 2/1/19.
//  Copyright © 2019 Kaibo Lu. All rights reserved.
//

import UIKit

/// Linked list node with any value
private class BBLinkedListNode {
    fileprivate let value: Any
    fileprivate var next: BBLinkedListNode?
    
    fileprivate init(value: Any) { self.value = value }
}

/// First-in, first out linked list queue
private class BBLinkedListQueue {
    fileprivate var head: BBLinkedListNode?
    fileprivate var tail: BBLinkedListNode?
    
    fileprivate func enqueue(_ node: BBLinkedListNode) {
        if head == nil { head = node }
        tail?.next = node
        tail = node
    }
    
    fileprivate func dequeue() -> BBLinkedListNode? {
        let node = head
        head = head?.next
        return node
    }
}

class BBOperationQueue {
    private let waitingQueue: BBLinkedListQueue
    var maxRunningCount: Int
    private(set) var currentRunningCount: Int
    
    init() {
        waitingQueue = BBLinkedListQueue()
        maxRunningCount = 1
        currentRunningCount = 0
    }
    
    func add(_ operation: BBImageDownloadOperation) {
        if currentRunningCount < maxRunningCount {
            currentRunningCount += 1
            BBDispatchQueuePool.background.async { [weak self] in
                guard self != nil else { return }
                operation.start()
            }
        } else {
            let node = BBLinkedListNode(value: operation)
            waitingQueue.enqueue(node)
        }
    }
    
    func operationComplete() {
        if let next = waitingQueue.dequeue()?.value as? BBImageDownloadOperation {
            BBDispatchQueuePool.background.async {
                next.start()
            }
        } else if currentRunningCount > 0 {
            currentRunningCount -= 1
        }
    }
}
