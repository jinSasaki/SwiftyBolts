# SwiftyBolts

[![Build Status](https://travis-ci.org/jinSasaki/SwiftyBolts.svg?branch=master)](https://travis-ci.org/jinSasaki/SwiftyBolts)
[![codecov](https://codecov.io/gh/jinSasaki/SwiftyBolts/branch/master/graph/badge.svg)](https://codecov.io/gh/jinSasaki/SwiftyBolts)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

A type-safe wrapper for [Bolts](https://github.com/BoltsFramework/Bolts-ObjC)

## Installation

### Carthage
```
github "jinSasaki/SwiftyBolts"
```

## Usage
#### Handling error in `continueWith` Method
``` swift
let task: Task<Bool>
task.continueWith { (task) -> Object? in
    if let error = task.error  {
        // Handling error
        throw error
    }
    let result = task.result
    // Convert to other object
    let object = Object(with: result)
    return object
}
```

#### Chaining Tasks
```swift
let task: Task<Bool>
task.continueOnSuccessWith { (result) -> Bool? in
    let success = result ?? false
    return success ? "Success!" : "Failure..."
}.continueOnSuccessWith { (result) -> Void in
    let message = result ?? ""
    print(message)
    return
}
```

### Creating Async Methods

```swift
func asyncTask() -> Task<String> {
    let tcs = TaskCompletionSource<String>()
    DispatchQueue.global().asyncAfter(deadline: .now() + .seconds(1)) {
        tcs.trySet(result: "ended")
    }
    return tcs.task
}
``` 

### Tasks in Parallel
```swift
Task<String>
    .forCompletionOfAllTasksWithResults([task1, task2])
    .continueWith { (task) -> Void in
        let strings: [String] = task.result ?? []
        print(strings)
        return
}
```
