//
//  Watchface.swift
//  
//
//  Created by Daniel Sawin on 10/19/17.
//

import Foundation
import "CDVPhotos.h"
import <Photos/Photos.h>

@objc(Watchface) class Watchface : CDVPlugin {
    var mainAssetCollection: PHAssetCollection!
    var oldAssetCollection: PHAssetCollection!
    var created: bool
    
    func createAlbum(albumName: String) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)   // create an asset collection with the album name
        }) { success, error in
            if success {
              return self.fetchAssetCollectionForAlbum()
            } else {
                print("error \(error)")
            }
        }
    }
    
    func save(image: UIImage) {
        if assetCollection == nil {
            return                          // if there was an error upstream, skip the save
        }
        
        PHPhotoLibrary.shared().performChanges({
            let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
            let albumChangeRequest = PHAssetCollectionChangeRequest(for: mainAssetCollection)
            let enumeration: NSArray = [assetPlaceHolder!]
            albumChangeRequest!.addAssets(enumeration)
            
        }, completionHandler: nil)
    }
    func update(command: CDVInvokedUrlCommand) {
        var pluginResult = CDVPluginResult(
            status: CDVCommandStatus_ERROR
        )
        
        let dataURL = command.arguments[0] as? String ?? ""
        //Create image with DataURL
        let imageData = NSData(base64EncodedStringL dataURL options: .allZeros)
        
        let newFace = UIImage(data: imageData)
        
        let mainAlbumName = "oneWatch"
        let oldAlbumName = "oneWatch Archive"
        
        //Check if folders exist
        //Fetch Main Album
        let fetchOptions = PHFetchOptions();
        fetchOptions.predicate = NSPredicate(format: "title = %@", mainAlbumName)
        
        let mainAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions);
        
        //Fetch Old Album
        fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", oldAlbumName)
        
        let oldAlbum = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions);
        
        //Check if Main Album Exists
        if(mainAlbum == nil){
            created = false
            //Create Album
            mainAssetCollection = createAlbum(mainAlbumName);
            //Put Image in Album
            save(newFace)
        }else{
            created = true
            //Main Album Exists
            mainAssetCollection = mainAlbum.firstObject as PHAssetCollection
            
            //Move assets from Main Album to Old AlbumAlbum
            var oldFac: PHFetchResult
            oldFace = fetchKeyAssets(in mainAlbumName, nil)
            
            PHAssetCollectionChangeRequest(forAssetCollection: mainAssetCollection).removeAssets(oldFace)
            PHAssetCollectionChangeRequest(forAssetCollection: oldAssetCollection).addAssets(oldFace)
        }
        
        //Check if Old Album Exists
        if(oldAlbum == nil){
            //Create Album
            oldAssetCollection = createAlbum(oldAlbumName)
        }else{
            //Old Album Exists
            oldAssetCollection = oldAlbum.firstObject as PHAssetCollection
            //Put New Face in Main Album
            save(newFace)
        }
    }
    
}
