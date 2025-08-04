//
//  DIContainer.swift
//  ThamanyaTask
//
//  Created by Ahmed Rabie on 01/08/2025.
//

import Foundation

// MARK: - Dependency Registration
public protocol DependencyRegistration {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, instance: T)
    func register<T>(_ type: T.Type, scope: DependencyScope, factory: @escaping () -> T)
}

// MARK: - Dependency Resolution
public protocol DependencyResolution {
    func resolve<T>(_ type: T.Type) -> T
    func resolve<T>(_ type: T.Type) -> T?
    func resolveOptional<T>(_ type: T.Type) -> T?
}

// MARK: - Dependency Scope
public enum DependencyScope {
    case singleton
    case transient
    case scoped
}

// MARK: - Dependency Info
private struct DependencyInfo {
    let factory: () -> Any
    let scope: DependencyScope
    var instance: Any?
    
    init(factory: @escaping () -> Any, scope: DependencyScope) {
        self.factory = factory
        self.scope = scope
        self.instance = nil
    }
}

// MARK: - DI Container
public final class DIContainer: DependencyRegistration, DependencyResolution {
    
    // MARK: - Properties
    private var dependencies: [String: DependencyInfo] = [:]
    private let lock = NSLock()
    
    // MARK: - Singleton
    public static let shared = DIContainer()
    
    private init() {}
    
    // MARK: - Registration Methods
    public func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        register(type, scope: .transient, factory: factory)
    }
    
    public func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        var info = DependencyInfo(factory: { instance }, scope: .singleton)
        info.instance = instance
        dependencies[key] = info
    }
    
    public func register<T>(_ type: T.Type, scope: DependencyScope, factory: @escaping () -> T) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        
        let info = DependencyInfo(factory: factory, scope: scope)
        dependencies[key] = info
    }
    
    // MARK: - Resolution Methods
    public func resolve<T>(_ type: T.Type) -> T {
        guard let resolved: T = resolveOptional(type) else {
            print("⚠️ Warning: Unable to resolve dependency: \(type)")
            print("🔍 Available dependencies: \(dependencies.keys.joined(separator: ", "))")
            fatalError("Unable to resolve dependency: \(type). Make sure it's registered in AppDependencies.configure()")
        }
        return resolved
    }
    
    public func resolve<T>(_ type: T.Type) -> T? {
        return resolveOptional(type)
    }
    
    public func resolveOptional<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        
        lock.lock()
        defer { lock.unlock() }
        
        guard var info = dependencies[key] else {
            return nil
        }
        
        switch info.scope {
        case .singleton:
            if let instance = info.instance as? T {
                return instance
            } else {
                let instance = info.factory() as! T
                info.instance = instance
                dependencies[key] = info
                return instance
            }
        case .transient:
            return info.factory() as? T
        case .scoped:
            if let instance = info.instance as? T {
                return instance
            } else {
                let instance = info.factory() as! T
                info.instance = instance
                dependencies[key] = info
                return instance
            }
        }
    }
    
    // MARK: - Utility Methods
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        dependencies.removeAll()
    }
    
    public func remove<T>(_ type: T.Type) {
        let key = String(describing: type)
        lock.lock()
        defer { lock.unlock() }
        dependencies.removeValue(forKey: key)
    }
    
    // MARK: - Debug Methods
    public func debugRegisteredDependencies() {
        lock.lock()
        defer { lock.unlock() }
        
        print("🔍 Registered Dependencies:")
        for (key, info) in dependencies {
            print("  - \(key): \(info.scope)")
        }
    }
}

// MARK: - Property Wrapper for Dependency Injection
@propertyWrapper
public struct Injected<T> {
    private var _value: T?
    
    public var wrappedValue: T {
        mutating get {
            if _value == nil {
                _value = DIContainer.shared.resolveOptional(T.self) ?? {
                    print("⚠️ Warning: Failed to resolve \(T.self) from DI container")
                    fatalError("Unable to resolve dependency: \(T.self). Make sure it's registered in AppDependencies.configure()")
                }()
            }
            return _value!
        }
    }
    
    public init() {}
}

// MARK: - Property Wrapper for Optional Dependency Injection
@propertyWrapper
public struct OptionalInjected<T> {
    private var _value: T??
    
    public var wrappedValue: T? {
        mutating get {
            if _value == nil {
                _value = DIContainer.shared.resolveOptional(T.self)
            }
            return _value!
        }
    }
    
    public init() {}
}