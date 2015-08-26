//
//  ImageCache.swift
//  SmashTag
//
//  Created by Todd Laney on 8/24/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import Foundation
import UIKit

private extension UIImage {
    func resize(size : CGSize) -> UIImage {
        
        let hasAlpha = false
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, 0.0)
        CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh)
        self.drawInRect(CGRect(origin: CGPointZero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}

class ImageCache {
    
    // MARK: Public
    class func sharedInstance() -> ImageCache {
        assert(NSThread.isMainThread())
        return sharedCache
    }
    
    typealias ImageCallback = (UIImage?) -> Void
    
    class func loadImageUrl(url:NSURL, size:CGSize, asyncHandler:ImageCallback!) -> UIImage? {
        return sharedInstance().loadImageUrl(url, size: size, asyncHandler: asyncHandler)
    }

    // MARK: Private
    private static let sharedCache = ImageCache()
    //private var imageCache = [String:UIImage]()
    private var imageCache = NSCache()
    private var imageCallbacks = [String:[ImageCallback]]()
    private let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate:nil, delegateQueue:NSOperationQueue())

    func loadImageUrl(url:NSURL, size:CGSize, asyncHandler:ImageCallback!) -> UIImage? {
        
        // this function is only safe to call on main thread
        assert(NSThread.isMainThread())
        
        // build a key that includes url+size
        let key = "\(url)[\(size)]"
        
        // see if we got's the image
        if let image = imageCache.objectForKey(key) as? UIImage {
            println("CACHE HIT: \(key)")
            return image
        }
        
        println("CACHE MISS: \(key)")

        // if the caller does not want async callback, we are done
        if asyncHandler == nil {
            return nil
        }
        
        // add handler to list of waiting callers, if no list yet keep going....
        if imageCallbacks[key]?.append(asyncHandler) != nil {
            println("....pending load")
            return nil
        }

        // create list of waiting callers and add current caller as only one
        imageCallbacks[key] = [asyncHandler]
        
        // fire up network to go get image, if we get called again for same image caller will just get added to list
        println("CACHE LOAD: \(key)")

        let task = session.dataTaskWithURL(url, completionHandler: { (data, response, error) in
            assert(!NSThread.isMainThread())
            let image = UIImage(data: data)?.resize(size)
            usleep(arc4random_uniform(2 * 1000000))
            dispatch_async(dispatch_get_main_queue()) {
                assert(NSThread.isMainThread())
                assert(self.imageCallbacks[key] != nil)
                assert(self.imageCache.objectForKey(key) == nil)
                println("CACHE LOADED: \(key)")
                if let image = image {
                    self.imageCache.setObject(image, forKey: key)
                }
                if let imageCallbacks = self.imageCallbacks[key] {
                    for imageCallback in imageCallbacks {
                        println("CACHE CALLBACK: \(key)")
                        imageCallback(image)
                    }
                    self.imageCallbacks[key] = nil
                }
            }
        })
        task.resume()
        
        return nil
    }
}
