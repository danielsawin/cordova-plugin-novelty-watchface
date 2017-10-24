//
//  Watchface.swift
//
//
//  Created by Daniel Sawin on 10/19/17.
//
import Photos

@objc(Watchface) class Watchface : CDVPlugin {
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
            if self.assetCollection == nil {
                print("error")
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
        
        func reMoveImages(oldAlbum:PHAssetCollection) {
            let oldFace = PHAsset.fetchKeyAssets(in: self.assetCollection, options: nil)!
            if(oldFace.firstObject != nil){
                PHPhotoLibrary.shared().performChanges({
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
                    albumChangeRequest!.removeAssets(oldFace)
                }, completionHandler: nil)
                
                PHPhotoLibrary.shared().performChanges({
                    let albumChangeRequest = PHAssetCollectionChangeRequest(for: oldAlbum)
                    albumChangeRequest!.addAssets(oldFace)
                }, completionHandler: nil)
                
                
            }else{
                NSLog("no images to remove...")
            }
        }
    }
    func getAssetThumbnail(asset: PHAsset) -> UIImage {
        let manager = PHImageManager.default()
        let option = PHImageRequestOptions()
        var thumbnail = UIImage()
        option.isSynchronous = true
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFit, options: option, resultHandler: {(result, info)->Void in
            thumbnail = result!
        })
        return thumbnail
    }
    @objc(update:)
    func update(command: CDVInvokedUrlCommand) {
        //Fetch and Create Albums
        let mainAlbum = CustomPhotoAlbum()
        mainAlbum.albumName = "oneWatch"
        mainAlbum.load()
        let oldAlbum = CustomPhotoAlbum()
        oldAlbum.albumName = "oneWatch Archive"
        oldAlbum.load()
        
        let pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        var dataURL: String
        dataURL = command.arguments[0] as! String
        //Create image with DataURL
        var newFace: UIImage
        
        if let decodedData = Data(base64Encoded: dataURL, options: .ignoreUnknownCharacters) {
            let image = UIImage(data: decodedData)
            newFace = image!
            //Check if folders exist
            if(mainAlbum.fetchAssetCollectionForAlbum() == nil){
                NSLog("creating albums...")
                mainAlbum.createAlbum()
                oldAlbum.createAlbum()
                mainAlbum.save(image: newFace)
            }else{
                NSLog("removing images...")
                mainAlbum.reMoveImages(oldAlbum: oldAlbum.assetCollection)
            }
            
            if(oldAlbum.fetchAssetCollectionForAlbum() == nil){
                oldAlbum.createAlbum()
            }else{
                NSLog("saving new face...")
                mainAlbum.save(image: newFace)
            }
        }
        //Send pluginResult
        self.commandDelegate!.send(
            pluginResult,
            callbackId: command.callbackId
        )
        
    }
    /*@objc(getCurrentFace:)
     func getCurrentFace(command: CDVInvokedUrlCommand) {
     let mainAlbum = CustomPhotoAlbum()
     mainAlbum.albumName = "oneWatch"
     mainAlbum.load()
     
     let currentFace = PHAsset.fetchKeyAssets(in: mainAlbum.assetCollection, options: nil)!
     
     let img = getAssetThumbnail(asset: currentFace.firstObject!)
     
     let imageData = UIImageJPEGRepresentation(img, 0.5)
     
     let strBase64 = imageData?.base64EncodedString(options: .lineLength64Characters)
     print(strBase64 ?? "encoding failed...")
     
     let pluginResult = CDVPluginResult(
     status: CDVCommandStatus_ERROR,
     messageAs: strBase64
     )
     
     self.commandDelegate!.send(
     pluginResult,
     callbackId: command.callbackId
     )
     }*/
    
}

