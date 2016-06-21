//
//  ButtonUtil.swift
//  uicomponetTest3
//
//  Created by linhan on 15/7/6.
//  Copyright (c) 2015年 linhan. All rights reserved.
//

import Foundation
import UIKit

class ButtonUtil
{
    class func createTextImageVerticalButton(title:String, imageSize:CGSize, fontSize:CGFloat, gap:CGFloat = 10)->UIButton
    {
        let button:UIButton = UIButton(type:.Custom)
        //button.backgroundColor = UIColor.darkGrayColor()
        let font:UIFont = UIFont.systemFontOfSize(fontSize)
        let ImageWidth:CGFloat = imageSize.width
        let ImageHeight:CGFloat = imageSize.height
        let TextWidth:CGFloat = StringUtil.getStringWidth(title, font: font)
        let height = imageSize.height + gap + font.lineHeight
        let width = max(ImageWidth, TextWidth)
        button.frame = CGRectMake(0, 0, width, height)
        button.imageEdgeInsets = UIEdgeInsets(top: -((height - imageSize.height) * 1), left: (width - ImageWidth) * 0.5, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: ImageHeight + gap, left: -TextWidth - (ImageWidth - TextWidth), bottom: 0, right: 0)
        button.titleLabel?.font = font
        button.setTitle(title, forState: .Normal)
        return button
    }
}

extension UIButton
{
    
    
    public func setImageURL(url:String, forState state:UIControlState)
    {
        /**
        var loader:Downloader = Downloader()
        loader.completeCallback = {[weak self] data in
        
            dispatch_async(dispatch_get_main_queue(),
                {
                    var image:UIImage? = UIImage(data:data)
                    if let strongSelf = self
                    {
                        strongSelf.setImage(image, forState: state)
                    }
            })
        
        }
        loader.load(url, data: nil)
**/
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
            {
                let nsurl:NSURL? = NSURL(string:url)
                let nsData:NSData? = nsurl != nil ? NSData(contentsOfURL:nsurl!) : nil
                if nsData != nil
                {
                    let image:UIImage? = UIImage(data:nsData!, scale:2)
                    dispatch_async(dispatch_get_main_queue(),
                        {
                            self.setImage(image, forState: state)
                    });
                }
        });
    }
    
    
}

