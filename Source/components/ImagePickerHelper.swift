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
    
    var cropSize:CGSize = CGSize.zero
    
    deinit
    {
        //trace("DEINIT ImagePickerHelper")
    }
    
    
    //打开相册
    func presentPhotoLibraryPickerController(allowsEditing:Bool = true)
    {
        let photoLibraryAvailable:Bool = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.photoLibrary)
        if photoLibraryAvailable
        {
            let pickerController:UIImagePickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
            pickerController.allowsEditing = allowsEditing
            //containerViewController?.present(pickerController, animated:true, completion:nil)
            UIApplication.shared.keyWindow?.rootViewController?.present(pickerController, animated:true, completion:nil)
        }
    }
    
    //打开摄像头
    func presentCameraPickerController(allowsEditing:Bool = true)
    {
        let cameraAvailable:Bool = UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera)
        if cameraAvailable
        {
            let pickerController:UIImagePickerController = UIImagePickerController()
            pickerController.delegate = self
            pickerController.sourceType = UIImagePickerControllerSourceType.camera
            pickerController.allowsEditing = allowsEditing
            //containerViewController?.present(pickerController, animated:true, completion:nil)
            UIApplication.shared.keyWindow?.rootViewController?.present(pickerController, animated:true, completion:nil)
        }
    }
    
    //选完相片
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        if let image:UIImage = info[UIImagePickerControllerEditedImage] as? UIImage ?? info[UIImagePickerControllerOriginalImage] as? UIImage
        {
            DispatchQueue.global(priority: .default).async(execute:
                {
                    let resizedImge:UIImage = self.cropSize.isEmpty ? image : Toucan.Resize.resizeImage(image, size: self.cropSize, fitMode:.crop)
                    DispatchQueue.main.async{
                        
                        picker.dismiss(animated:true, completion: {finish in
                            
                            self.delegate?.imagePickerDidFinishPickingImage(image: resizedImge)
                        })
                        
                    }
                    
            })
        }
        else
        {
            picker.dismiss(animated:true, completion: {finish in
                self.delegate?.imagePickerDidFinishPickingImage(image: nil)
            })
        }
        
    }
    
}

