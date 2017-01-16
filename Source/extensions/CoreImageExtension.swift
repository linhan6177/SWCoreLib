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
        self.init(cvPixelBuffer: pixelBuffer)
    }
}

extension CIFilter
{
    //黑白
    class func grayscale(_ source:UIImage) -> UIImage?
    {
        let filter:CIFilter? = CIFilter(name:"CIColorControls")
        filter?.setValue(0.0, forKey: kCIInputBrightnessKey)
        filter?.setValue(0.0, forKey: kCIInputSaturationKey)
        filter?.setValue(1, forKey: kCIInputContrastKey)
        return performImageProcess(source, filter: filter)
    }
    
    //像素化(默认8，最大100，最小0)
    class func pixellate(_ source:UIImage, scale:Float = 8) -> UIImage?
    {
        let inputScale = min(max(scale, 1), 100)
        let filter:CIFilter? = CIFilter(name:"CIPixellate")
        filter?.setValue(inputScale, forKey: kCIInputScaleKey)
        return performImageProcess(source, filter: filter)
    }
    
    private class func performImageProcess(_ source:UIImage, filter:CIFilter?) -> UIImage?
    {
        guard let cgImage = source.cgImage,let filter = filter else{
            return nil
        }
        filter.setValue(CIImage(cgImage: cgImage), forKey: kCIInputImageKey)
        if let ciImage = filter.outputImage
        {
            let context = OCPatch.ciContextMake()
            //let context:CIContext = CIContext(options: nil)
            let rect = ciImage.extent
            if let cgImage = context.createCGImage(ciImage, from: rect)
            {
                return UIImage(cgImage: cgImage, scale: source.scale, orientation: source.imageOrientation)
            }
            return nil
        }
        return nil
    }
    
    
}
