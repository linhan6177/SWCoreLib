//
//  NullDataStatusProtocol.swift
//  BaseDemo
//
//  Created by linhan on 2016/12/23.
//  Copyright © 2016年 me. All rights reserved.
//

import Foundation

//空数据状态
protocol NullDataStatusProtocol:NSObjectProtocol
{
    var nullDataView:UIView? {get set}
    func setNullDataViewHidden(_ hidden: Bool)
}

extension NullDataStatusProtocol
{
    func setupNullDataView(withImage image:UIImage, container:UIView, contentInset inset:UIEdgeInsets = UIEdgeInsets.zero)
    {
        let imageView = UIImageView(image:image)
        addNullDataView(container, view:imageView, contentInset:inset)
    }
    
    func setupNullDataView(withText text:String, container:UIView, contentInset inset:UIEdgeInsets = UIEdgeInsets.zero)
    {
        let font = UIFont.systemFont(ofSize: 14)
        let contentWidth:CGFloat = container.width - inset.left - inset.right
        let label:UILabel = UILabel.labelWithLimitWidth(contentWidth, text: text, font: font)
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        addNullDataView(container, view:label, contentInset:inset)
    }
    
    private func addNullDataView(_ container:UIView, view:UIView, contentInset inset:UIEdgeInsets)
    {
        nullDataView?.removeFromSuperview()
        nullDataView = view
        view.frame = CGRectMake(inset.left + (container.width - inset.left - inset.right - view.width) * 0.5, inset.top + (container.height - inset.top - inset.bottom - view.height) * 0.5, view.width, view.height)
        view.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin, .flexibleRightMargin, .flexibleLeftMargin]
        view.isHidden = true
        container.addSubview(view)
    }
    
    func setNullDataViewHidden(_ hidden: Bool)
    {
        nullDataView?.isHidden = hidden
    }
    
}
