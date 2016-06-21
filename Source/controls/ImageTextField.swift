//
//  ImageTextField.swift
//  ThemeTest
//
//  Created by linhan on 15/7/10.
//  Copyright (c) 2015年 KanHigh. All rights reserved.
//

import Foundation
import UIKit
class ImageTextField: UITextField
{
    
    var leftViewInset:UIEdgeInsets = UIEdgeInsetsZero
    var textInset:UIEdgeInsets = UIEdgeInsetsZero
    
    override func leftViewRectForBounds(bounds: CGRect) -> CGRect
    {
        var iconRect:CGRect = super.leftViewRectForBounds(bounds)
        iconRect.origin.x += (leftView == nil ? 0 : leftViewInset.left)
        return iconRect
    }
    
    override func textRectForBounds(bounds: CGRect) -> CGRect
    {
        var textRect:CGRect = super.textRectForBounds(bounds)
        textRect.origin.x += (leftView == nil ? 0 : leftViewInset.right) + textInset.left
        return textRect
    }
    
    override func editingRectForBounds(bounds: CGRect) -> CGRect
    {
        var textRect:CGRect = super.editingRectForBounds(bounds)
        textRect.origin.x += (leftView == nil ? 0 : leftViewInset.right) + textInset.left
        return textRect
    }
    
}