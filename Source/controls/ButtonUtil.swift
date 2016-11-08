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
    class func createTextImageVerticalButton(_ title:String, imageSize:CGSize, fontSize:CGFloat, gap:CGFloat = 10)->UIButton
    {
        let button:UIButton = UIButton(type:.custom)
        //button.backgroundColor = UIColor.darkGrayColor()
        let font:UIFont = UIFont.systemFont(ofSize: fontSize)
        let ImageWidth:CGFloat = imageSize.width
        let ImageHeight:CGFloat = imageSize.height
        let TextWidth:CGFloat = StringUtil.getStringWidth(title, font: font)
        let height = imageSize.height + gap + font.lineHeight
        let width = max(ImageWidth, TextWidth)
        button.frame = CGRect(x: 0, y: 0, width: width, height: height)
        button.imageEdgeInsets = UIEdgeInsets(top: -((height - imageSize.height) * 1), left: (width - ImageWidth) * 0.5, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: ImageHeight + gap, left: -TextWidth - (ImageWidth - TextWidth), bottom: 0, right: 0)
        button.titleLabel?.font = font
        button.setTitle(title, for: UIControlState())
        return button
    }
}

extension UIButton
{
    public func setImageURL(_ url:String, forState state:UIControlState)
    {
        DispatchQueue.global(priority: .default).async(execute: {
                let nsurl:URL? = URL(string:url)
                let nsData:Data? = nsurl != nil ? (try? Data(contentsOf: nsurl!)) : nil
                if nsData != nil
                {
                    let image:UIImage? = UIImage(data:nsData!, scale:UIScreen.main.scale)
                    DispatchQueue.main.async(execute: {
                            self.setImage(image, for: state)
                    });
                }
        });
    }
}

