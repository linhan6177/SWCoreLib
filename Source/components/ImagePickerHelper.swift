//
//  ImagePickerHelper.swift
//  KanHigh
//
//  Created by linhan on 15/7/16.
//  Copyright (c) 2015年 KanHigh. All rights reserved.
//

import Foundation
import UIKit

protocol ImagePickerHelperDelegate:NSObjectProtocol
{
    func imagePickerDidFinishPickingImage(image:UIImage?)
}

class ImagePickerHelper:NSObject,UIImagePickerControllerDelegate,UINavigationControllerDelegate
{
    
    weak var delegate:ImagePickerHelperDelegate?
    
    weak var containerViewController:UIViewController?
    
    var cropSize:CGSize = CGSizeMake(160, 160)
    
    deinit
    {
        //trace("DEINIT ImagePickerHelper")
    }
    
    
    //打开相册
    func presentPhotoLibraryPickerController(allowsEditing:Bool = true)
    {
        let photoLibraryAvailable:Bool = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.PhotoLibrary)
        if photoLibraryAvailable
        {
            let pickerController:UIImagePickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = UIImagePickerControllerSourceType.PhotoLibrary
            pickerController.allowsEditing = allowsEditing
            containerViewController?.presentViewController(pickerController, animated:true, completion:nil)
        }
    }
    
    //打开摄像头
    func presentCameraPickerController(allowsEditing:Bool = true)
    {
        let cameraAvailable:Bool = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera)
        if cameraAvailable
        {
            let pickerController:UIImagePickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = UIImagePickerControllerSourceType.Camera
            pickerController.allowsEditing = allowsEditing
            containerViewController?.presentViewController(pickerController, animated:true, completion:nil)
        }
    }
    
    //选完相片
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
    {
        if let image:UIImage = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                {
                    let resizedImge:UIImage = self.cropSize.isEmpty ? image : Toucan.Resize.resizeImage(image, size: self.cropSize, fitMode:.Crop)
                    dispatch_async(dispatch_get_main_queue()){
                        
                        picker.dismissViewControllerAnimated(true, completion: {finish in
                            self.delegate?.imagePickerDidFinishPickingImage(resizedImge)
                        })
                        
                    }
                    
            })
        }
        else
        {
            picker.dismissViewControllerAnimated(true, completion: {finish in
                self.delegate?.imagePickerDidFinishPickingImage(nil)
            })
        }
        
    }
    
}

