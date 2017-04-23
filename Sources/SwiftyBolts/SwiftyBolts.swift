//
//  SwiftyBolts.swift
//  SwiftyBolts
//
//  Created by Jin Sasaki on 2017/04/19.
//  Copyright © 2017年 sasakky. All rights reserved.
//

import Foundation
import Bolts

public typealias Executor = BFExecutor
public typealias CancellationToken = BFCancellationToken
public typealias CancellationTokenRegistration = BFCancellationTokenRegistration
public typealias CancellationTokenSource = BFCancellationTokenSource

public struct Task<T> {
    public struct MultipleError: Error {
        let errors: [Error]
    }
    fileprivate let bfTask: BFTask<AnyObject>
    fileprivate init(bfTask: BFTask<AnyObject>) {
        self.bfTask = bfTask
    }

    public init(result: T) {
        self.bfTask = BFTask<AnyObject>(result: result as AnyObject)
    }

    public init(error: Error) {
        self.bfTask = BFTask<AnyObject>(error: error)
    }

    public static var cancelled: Task<T> {
        let bfTask = BFTask<AnyObject>.cancelled()
        return Task<T>(bfTask: bfTask)
    }

    public var result: T? {
        return self.bfTask.result as? T
    }

    public var error: Error? {
        if let error = self.bfTask.error as NSError?,
            error.domain == BFTaskErrorDomain,
            error.code == kBFMultipleErrorsError {

            let errors = error.userInfo[BFTaskMultipleErrorsUserInfoKey] as? [Error]
            return MultipleError(errors: errors ?? [])
        }
        return self.bfTask.error
    }

    public var isFaulted: Bool {
        return self.bfTask.isFaulted
    }

    public var isCancelled: Bool {
        return self.bfTask.isCancelled
    }

    public var isCompleted: Bool {
        return self.bfTask.isCompleted
    }

    public static func forCompletionOfAllTasks(_ tasks: [Task<T>]) -> Task<Void> {
        return Task<Void>(bfTask: BFTask<AnyObject>(forCompletionOfAllTasksWithResults: tasks.map({ $0.bfTask })))
    }

    public static func forCompletionOfAllTasksWithResults(_ tasks: [Task<T>]) -> Task<[T]> {
        return Task<[T]>(bfTask: BFTask<AnyObject>(forCompletionOfAllTasksWithResults: tasks.map({ $0.bfTask })))
    }

    public static func forCompletionOfAnyTask(_ tasks: [Task<T>]) -> Task<T> {
        return Task<T>(bfTask: BFTask<AnyObject>(forCompletionOfAnyTask: tasks.map({ $0.bfTask })))
    }

    public init(from executor: Executor, with block: @escaping (() -> T)) {
        self.bfTask = BFTask(from: executor, with: {
            return block()
        })
    }
}

public extension Task {

    @discardableResult
    public func continueWith<S>(executor: Executor = Executor.default(), cancellationToken: CancellationToken? = nil, block: @escaping (_ task: Task<T>) throws -> S?) -> Task<S> {
        let bfTask = self.bfTask.continueWith(executor: executor, block: { (_bfTask) -> Any? in
            do {
                return try block(Task<T>(bfTask: _bfTask))
            } catch let error {
                return BFTask<AnyObject>(error: error)
            }
        }, cancellationToken: cancellationToken)
        return Task<S>(bfTask: bfTask)
    }

    @discardableResult
    public func continueOnSuccessWith<S>(executor: Executor = Executor.default(), cancellationToken: CancellationToken? = nil, block: @escaping (_ result: T?) throws -> S?) -> Task<S> {
        let bfTask = self.bfTask.continueOnSuccessWith(executor: executor, block: { (_bfTask) -> Any? in
            do {
                return try block(_bfTask.result as? T)
            } catch let error {
                return BFTask<AnyObject>(error: error)
            }
        }, cancellationToken: cancellationToken)
        return Task<S>(bfTask: bfTask)
    }

    public func waitUntilFinished() {
        self.bfTask.waitUntilFinished()
    }
}

public struct TaskCompletionSource<T> {
    fileprivate let bfTaskCompletionSource: BFTaskCompletionSource<AnyObject>
    public init() {
        self.bfTaskCompletionSource = BFTaskCompletionSource<AnyObject>()
    }

    public var task: Task<T> {
        return Task<T>(bfTask: self.bfTaskCompletionSource.task)
    }

    public func set(result: T?) {
        self.bfTaskCompletionSource.set(result: result as AnyObject)
    }

    public func set(error: Error) {
        self.bfTaskCompletionSource.set(error: error)
    }

    public func cancel() {
        self.bfTaskCompletionSource.cancel()
    }

    @discardableResult
    public func trySet(result: T?) -> Bool {
        return self.bfTaskCompletionSource.trySet(result: result as AnyObject)
    }

    @discardableResult
    public func trySet(error: Error) -> Bool {
        return self.bfTaskCompletionSource.trySet(error: error)
    }

    @discardableResult
    public func trySetCancelled() -> Bool {
        return self.bfTaskCompletionSource.trySetCancelled()
    }
}
