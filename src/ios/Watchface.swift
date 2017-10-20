//
//  Watchface.swift
//
//
//  Created by Daniel Sawin on 10/19/17.
//

import Foundation
import Photos


class CustomPhotoAlbum {
    var albumName = "Album Name"
    
    var assetCollection: PHAssetCollection!
    
    func load() {
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
        
        if PHPhotoLibrary.authorizationStatus() != PHAuthorizationStatus.authorized {
            PHPhotoLibrary.requestAuthorization({ (status: PHAuthorizationStatus) -> Void in
                ()
            })
        }
        
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            self.createAlbum()
        } else {
            PHPhotoLibrary.requestAuthorization(requestAuthorizationHandler)
        }
    }
    
    func requestAuthorizationHandler(status: PHAuthorizationStatus) {
        if PHPhotoLibrary.authorizationStatus() == PHAuthorizationStatus.authorized {
            // ideally this ensures the creation of the photo album even if authorization wasn't prompted till after init was done
            print("trying again to create the album")
            self.createAlbum()
        } else {
            print("should really prompt the user to let them know it's failed")
        }
    }
    
    func createAlbum() {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)   // create an asset collection with the album name
        }) { success, error in
            if success {
                self.assetCollection = self.fetchAssetCollectionForAlbum()
            } else {
                print("error \(String(describing: error))")
            }
        }
    }
    
    func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", self.albumName)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }
    
    func save(image: UIImage) {
        if assetCollection == nil {
            return                          // if there was an error upstream, skip the save
        }
        
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
            let enumeration: NSArray = [assetPlaceHolder!]
            albumChangeRequest!.addAssets(enumeration)
            
        }, completionHandler: nil)
    }
    
    func removeImages() {
        let oldFace = PHAsset.fetchKeyAssets(in: self.assetCollection, options: nil)
        let request = PHAssetCollectionChangeRequest(for: self.assetCollection)
        request!.removeAssets(oldFace!)
    }
}

@objc(Watchface) class Watchface : CDVPlugin {
    func update(command: CDVInvokedUrlCommand) {
        //Fetch and Create Albums
        let mainAlbum = CustomPhotoAlbum()
        mainAlbum.albumName = "oneWatch"
        mainAlbum.load()
        let oldAlbum = CustomPhotoAlbum()
        oldAlbum.albumName = "oneWatch Archive"
        oldAlbum.load()
        
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        let dataURL = command.arguments[0]
        //Create image with DataURL
        let imageData = NSData(base64Encoded: dataURL as! String, options: [])
        
        let newFace = UIImage(data: imageData! as Data)
        
        
        //Check if folders exist
        if(mainAlbum.fetchAssetCollectionForAlbum() == nil){
            mainAlbum.createAlbum()
            oldAlbum.createAlbum()
        }else{
            oldAlbum.removeImages()
        }
        
        if(oldAlbum.fetchAssetCollectionForAlbum() == nil){
            oldAlbum.createAlbum()
        }else{
            mainAlbum.save(image: newFace!)
        }
        
        
        //Get Plugin Result
        pluginResult = CDVPluginResult(
            status: CDVCommandStatus_OK,
            messageAs: msg
        )
        
        //Send pluginResult
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
        
    }
}

