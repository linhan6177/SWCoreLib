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



