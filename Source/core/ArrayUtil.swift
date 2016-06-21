//
//  ArrayUtil.swift
//  uicomponetTest3
//
//  Created by linhan on 15-5-12.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation

extension Array
{
    subscript(input: [Int]) -> ArraySlice<Element>
    {
        get
        {
            var result = ArraySlice<Element>()
            for i in input
            {
                if let value = valueAt(i)
                {
                    result.append(value)
                }
            }
            return result
        }
        set
        {
            //for (index,i) in enumerate(input)
            for i in 0..<input.count
            {
                self[i] = newValue[i]
            }
        }
    }
        
        
    
}


extension Array where Element:Equatable
{
    //移除元素
    mutating func removeObject(object: Element) {
        if let index = self.indexOf(object) {
            self.removeAtIndex(index)
        }
    }
}

