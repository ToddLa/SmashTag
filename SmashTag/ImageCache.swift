//
//  ImageCache.swift
//  SmashTag
//
//  Created by Todd Laney on 8/24/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import Foundation
import UIKit

/**

ImageCache

cache of UIImages of a given size, all loading happens in the background.

usage

image = ImageCache.loadImageUrl(url, size, {image in 
    /* this is called back after image is loaded, on main thread */
    if image != nil {
    }
})
if image != nil {
    /* image was in cache, callback will not be called */
}

*/

class ImageCache {
    
    // MARK: Public
    class func sharedInstance() -> ImageCache {
        assert(NSThread.isMainThread())
        return sharedCache
    }
    
    typealias ImageCallback = (UIImage?) -> Void
    
    // class version of loadImageUrl
    class func loadImageUrl(url:NSURL, size:CGSize, asyncHandler:ImageCallback!) -> UIImage? {
        return sharedInstance().loadImageUrl(url, size: size, asyncHandler: asyncHandler)
    }

    // MARK: Private
    private static let sharedCache = ImageCache()   // shared global instance
    private var imageCache = NSCache()
    private var imageCallbacks = [String:[ImageCallback]]()
    
    // create our own session based on defaultSessionConfiguration instead of using sharedSession, this way we get to use a conncurent queue, not serial queue
    private let session = NSURLSession(configuration:NSURLSessionConfiguration.defaultSessionConfiguration(), delegate:nil, delegateQueue:NSOperationQueue())

   /** 
    
    loadImageUrl
    
    retrive image from cache of given size and return it immediatly
    or load and scale it in the background and call handler later
    
    :param: url image url o load
    :param: size  size requested
    :param: asyncHandler handler called back on **main thread** with image scaled to size
    
    :returns: if image is cached image is returned immediatly and handler not called.  
    :returns: if image is not in cache nil is returned and handler called later.
    
    */
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

private extension UIImage {
    func resize(var size : CGSize) -> UIImage {
        
        if size.width == 0 && size.height == 0 { return self }
        if size.width == 0  {size.width = size.height * self.size.width / self.size.height}
        if size.height == 0 {size.height = size.width * self.size.height / self.size.width}
        
        let hasAlpha = false
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, 0.0)
        CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh)
        self.drawInRect(CGRect(origin: CGPointZero, size: size))
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
}


