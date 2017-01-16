//
//  SWRadioButtonGroup.swift
//  UIcomnentTest2
//
//  Created by linhan on 2016/12/20.
//  Copyright © 2016年 test. All rights reserved.
//

import Foundation
import UIKit

protocol SWIRadioButton:NSObjectProtocol
{
    var beSelected:Bool {get set}
    
}

class SWRadioButtonGroup: NSObject
{
    private var items:[SWIRadioButton] = []
    private var _selectedIndex:Int = -1
    
    init(items:[SWIRadioButton]) {
        self.items = items
    }
    
    override init() { }
    
    var selectedIndex:Int
    {
        get{
            return _selectedIndex
        }
        set
        {
            items.valueAt(_selectedIndex)?.beSelected = false
            if items.count > 0 && newValue >= 0 && newValue < items.count && newValue != _selectedIndex
            {
                _selectedIndex = newValue
                items.valueAt(newValue)?.beSelected = true
            }
        }
    }
    
    var selectedItem:SWIRadioButton?{
        return items.valueAt(_selectedIndex)
    }
    
    func addItems(_ aItems:[SWIRadioButton])
    {
        for item in aItems
        {
            if !items.contains(where: {item.hash == $0.hash})
            {
                items.append(item)
            }
        }
    }
    
    func selectItem(_ item:SWIRadioButton)
    {
        if let index = items.index(where: {item.hash == $0.hash})
        {
            selectedIndex = index
        }
    }
    
    func removeAll()
    {
        selectedIndex = -1
        items.removeAll()
    }
    
}
