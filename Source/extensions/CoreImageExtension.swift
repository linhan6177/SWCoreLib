//
//  CoreImageExtension.swift
//  ImageTest
//
//  Created by linhan on 16/11/2.
//  Copyright © 2016年 me. All rights reserved.
//

import Foundation
import CoreMedia
import UIKit

extension CIImage {
    convenience init?(buffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(buffer) else{
            return nil
        }
        self.init(CVPixelBuffer: pixelBuffer)
    }
}

extension CIFilter
{
    //黑白
    class func grayscale(source:UIImage) -> UIImage?
    {
        let filter:CIFilter? = CIFilter(name:"CIColorControls")
        filter?.setValue(0.0, forKey: kCIInputBrightnessKey)
        filter?.setValue(0.0, forKey: kCIInputSaturationKey)
        filter?.setValue(1, forKey: kCIInputContrastKey)
        return performImageProcess(source, filter: filter)
    }
    
    //像素化(默认8，最大100，最小0)
    class func pixellate(source:UIImage, scale:Float = 8) -> UIImage?
    {
        let inputScale = min(max(scale, 1), 100)
        let filter:CIFilter? = CIFilter(name:"CIPixellate")
        filter?.setValue(inputScale, forKey: kCIInputScaleKey)
        return performImageProcess(source, filter: filter)
    }
    
    private class func performImageProcess(source:UIImage, filter:CIFilter?) -> UIImage?
    {
        guard let cgImage = source.CGImage,let filter = filter else{
            return nil
        }
        filter.setValue(CIImage(CGImage: cgImage), forKey: kCIInputImageKey)
        if let ciImage = filter.outputImage
        {
            let context:CIContext = CIContext(options: nil)
            let rect = ciImage.extent
            let cgImage = context.createCGImage(ciImage, fromRect: rect)
            return UIImage(CGImage: cgImage, scale: source.scale, orientation: source.imageOrientation)
        }
        return nil
    }
    
    
}