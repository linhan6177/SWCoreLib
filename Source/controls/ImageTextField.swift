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
    
    var leftViewInset:UIEdgeInsets = UIEdgeInsets.zero
    var textInset:UIEdgeInsets = UIEdgeInsets.zero
    
    override func leftViewRect(forBounds bounds: CGRect) -> CGRect
    {
        var iconRect:CGRect = super.leftViewRect(forBounds: bounds)
        iconRect.origin.x += (leftView == nil ? 0 : leftViewInset.left)
        return iconRect
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect
    {
        var textRect:CGRect = super.textRect(forBounds: bounds)
        textRect.origin.x += (leftView == nil ? 0 : leftViewInset.right) + textInset.left
        return textRect
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect
    {
        var textRect:CGRect = super.editingRect(forBounds: bounds)
        textRect.origin.x += (leftView == nil ? 0 : leftViewInset.right) + textInset.left
        return textRect
    }
    
}
