//
//  Weaker.swift
//  Basic
//
//  Created by linhan on 16/6/8.
//  Copyright © 2016年 linhan. All rights reserved.
//

import Foundation


//弱引用包装器
class SWWeakWrapper : Equatable
{
    var valueAny : Any?
    weak var weakValue : AnyObject?
    
    init(value: Any) {
        if let valueObj = value as? AnyObject {
            self.weakValue = valueObj
        } else {
            self.valueAny = value
        }
    }
    
    var value:Any?
    {
        if let value = weakValue {
            return value
        } else if let value = valueAny {
            return value
        }
        return nil
    }
}

func ==(lhs: SWWeakWrapper, rhs: SWWeakWrapper) -> Bool
{
    return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
}

extension Array where Element : SWWeakWrapper
{
    
    mutating func compress() {
        for obj in self {
            if obj.value == nil {
                self.removeObject(obj)
            }
        }
    }
}



class WeakObject<T: AnyObject>: Equatable, Hashable {
    weak var object: T?
    init(object: T) {
        self.object = object
    }
    
    var hashValue: Int {
        if let object = self.object { return unsafeAddressOf(object).hashValue }
        else { return 0 }
    }
}

func == <T> (lhs: WeakObject<T>, rhs: WeakObject<T>) -> Bool {
    return lhs.object === rhs.object
}


class WeakObjectSet<T: AnyObject> {
    var objects: Set<WeakObject<T>>
    
    init() {
        self.objects = Set<WeakObject<T>>([])
    }
    
    init(objects: [T]) {
        self.objects = Set<WeakObject<T>>(objects.map { WeakObject(object: $0) })
    }
    
    var allObjects: [T] {
        return objects.flatMap { $0.object }
    }
    
    func contains(object: T) -> Bool {
        return self.objects.contains(WeakObject(object: object))
    }
    
    func addObject(object: T) {
        self.objects.unionInPlace([WeakObject(object: object)])
        
    }
    
    func addObjects(objects: [T]) {
        self.objects.unionInPlace(objects.map { WeakObject(object: $0) })
    }
    
    func removeObject(object: T) {
        if let index = objects.indexOf(WeakObject(object: object)){
            objects.removeAtIndex(index)
        }
    }
    
    
    
    
}

