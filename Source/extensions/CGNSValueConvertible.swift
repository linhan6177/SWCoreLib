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
        return NSValue(cgPoint: self)
    }
}

extension CGSize:CGNSValueConvertible
{
    
    public var toNSValue:NSValue{
        return NSValue(cgSize: self)
    }
    
}

extension CGRect:CGNSValueConvertible
{
    public var toNSValue:NSValue {
        return NSValue(cgRect: self)
    }
}

extension CGVector:CGNSValueConvertible
{
    public var toNSValue:NSValue{
        return NSValue(cgVector: self)
    }
}

extension CGAffineTransform:CGNSValueConvertible
{
    public var toNSValue:NSValue{
        return NSValue(cgAffineTransform: self)
    }
}

extension UIEdgeInsets:CGNSValueConvertible
{
    public var toNSValue:NSValue{
        return NSValue(uiEdgeInsets: self)
    }
}

extension UIOffset:CGNSValueConvertible
{
    public var toNSValue:NSValue{
        return NSValue(uiOffset: self)
    }
}


