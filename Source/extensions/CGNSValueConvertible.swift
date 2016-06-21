//
//  CGNSValueConvertible.swift
//  Basic
//
//  Created by linhan on 16/6/4.
//  Copyright © 2016年 linhan. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
#endif


protocol CGNSValueConvertible
{
    var toNSValue:NSValue {get}
    
}

extension CGPoint:CGNSValueConvertible
{
    public var toNSValue:NSValue{
        return NSValue(CGPoint: self)
    }
}

extension CGSize:CGNSValueConvertible
{
    
    public var toNSValue:NSValue{
        return NSValue(CGSize: self)
    }
    
}

extension CGRect:CGNSValueConvertible
{
    public var toNSValue:NSValue {
        return NSValue(CGRect: self)
    }
}

extension CGVector:CGNSValueConvertible
{
    public var toNSValue:NSValue{
        return NSValue(CGVector: self)
    }
}

extension CGAffineTransform:CGNSValueConvertible
{
    public var toNSValue:NSValue{
        return NSValue(CGAffineTransform: self)
    }
}

extension UIEdgeInsets:CGNSValueConvertible
{
    public var toNSValue:NSValue{
        return NSValue(UIEdgeInsets: self)
    }
}

extension UIOffset:CGNSValueConvertible
{
    public var toNSValue:NSValue{
        return NSValue(UIOffset: self)
    }
}


