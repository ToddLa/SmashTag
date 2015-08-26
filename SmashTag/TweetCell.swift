//
//  TweetCell.swift
//  SmashTag
//
//  Created by Todd Laney on 8/23/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

private extension String {
    // convert string (truncate or padd) to be given length  (U+200B is ZERO WIDTH SPACE)
    func paddToLength(length:Int, paddChar:Character = Character("\u{200B}")) -> String {
        let n = length - count(self)
        if n > 0 {
            return self + String(count: n, repeatedValue: paddChar)
        } else if n < 0 {
            return prefix(self, length)
        }
        else {
            return self
        }
    }
}

/*
private extension UILabel {
    func setColor(color:UIColor, range:NSRange) {
        let text = NSMutableAttributedString(attributedString: self.attributedText)
        text.addAttribute(NSForegroundColorAttributeName, value: color, range: range)
        self.attributedText = text
    }
    func setString(var str:String, range:NSRange) {
        // convert string (truncate or padd) to be same length as passed range, so as not to invalidate other ranges.
        let text = NSMutableAttributedString(attributedString: self.attributedText)
        text.replaceCharactersInRange(range, withString: str.paddToLength(range.length))
        self.attributedText = text
    }
}
**/

/**
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
**/

class TweetCell: UITableViewCell {

    var tweet : Tweet? {
        didSet {
            updateUI()
        }
    }
    
    // MARK: Private

    @IBOutlet weak var leftImage: UIImageView!
    @IBOutlet weak var leftText: UILabel!
    @IBOutlet weak var headerText: UILabel!
    @IBOutlet weak var bodyText: UILabel!
    
    private struct Colors {
        static let ScreenName = UIColor.lightTextColor()
        static let UserName = UIColor.darkTextColor()
        static let Mentions = UIColor.redColor()
        static let Urls = UIColor.blueColor()
        static let Hashtags = UIColor.greenColor()
        static let Media = UIColor.yellowColor()
        static let ImageBorder = UIColor.orangeColor()
    }
    
    private struct Strings {
        static let Url = "[URL]"
        static let Media = "[MEDIA]"
    }

    private func updateUI() {
        leftImage?.image = nil
        leftText?.text = nil
        headerText?.text = nil
        bodyText?.text = nil
        
        if let tweet = tweet {
            println("UpdateUI: \(tweet)")

            // Name
            headerText.text = "\(tweet.user.name) @\(tweet.user.screenName)"
            var text = NSMutableAttributedString(attributedString: headerText.attributedText)
            //text.addAttribute(NSForegroundColorAttributeName, value:Colors.ScreenName, range:index.nsrange)
            headerText.attributedText = text
            
            // Body
            bodyText.text = tweet.text
            
            // convert to attributed text and color items...
            text = NSMutableAttributedString(attributedString: bodyText.attributedText)
            text.beginEditing()
            
            for index in tweet.userMentions {
                text.addAttribute(NSForegroundColorAttributeName, value:Colors.Mentions, range:index.nsrange)
            }
            for index in tweet.urls {
                text.addAttribute(NSForegroundColorAttributeName, value:Colors.Urls, range:index.nsrange)
                text.replaceCharactersInRange(index.nsrange, withString: Strings.Url.paddToLength(index.nsrange.length))
            }
            for index in tweet.hashtags {
                text.addAttribute(NSForegroundColorAttributeName, value:Colors.Hashtags, range:index.nsrange)
            }
            for item in tweet.media {
                if let range = item.index?.nsrange {
                    text.addAttribute(NSForegroundColorAttributeName, value:Colors.Media, range:range)
                    text.replaceCharactersInRange(range, withString: Strings.Media.paddToLength(range.length))
                }
            }

            text.endEditing()
            bodyText.attributedText = text

            
//            for index in tweet.userMentions {
//                bodyText.setColor(Colors.Mentions, range: index.nsrange)
//            }
//            for index in tweet.urls {
//                bodyText.setColor(Colors.Urls, range: index.nsrange)
//                bodyText.setString("[URL]", range: index.nsrange)
//            }
//            for index in tweet.hashtags {
//                bodyText.setColor(Colors.Hashtags, range: index.nsrange)
//            }
//            for item in tweet.media {
//                if let range = item.index?.nsrange {
//                    bodyText.setColor(Colors.Media, range:range)
//                    bodyText.setString("[MEDIA]", range:range)
//                    //bodyText.setString("ABCDEFGHIJKLMNOPQRSTUVWXYZ", range:NSRange(location:0, length:3))
//                }
//            }
            
            
/*
            // Image
            if let url = tweet.user.profileImageURL, data = NSData(contentsOfURL: url) {
                //leftImage?.image = UIImage(data: data)
                leftImage?.image = UIImage(data: data)?.resize(leftImage!.bounds.size)
                leftImage.layer.cornerRadius = leftImage.bounds.size.width / 8.0
                leftImage.layer.borderColor = UIColor.blackColor().CGColor
                leftImage.layer.borderWidth = 2.0
                leftImage.clipsToBounds = true
            }
*/
            // Image
            if let url = tweet.user.profileImageURL {
                
                let size = leftImage.bounds.size
                
                let image = ImageCache.loadImageUrl(url, size:size) { image in
                    assert(NSThread.isMainThread())
                    // only set the image if the tweet id matches, in case the cell gets reused!
                    if self.tweet?.id == tweet.id {
                        self.leftImage?.image = image
                    }
                }
                
                leftImage?.image = image
                leftImage.layer.cornerRadius = size.width / 8.0
                leftImage.layer.borderColor = Colors.ImageBorder.CGColor
                leftImage.layer.borderWidth = 2.0
                leftImage.clipsToBounds = true
            }

            // Date
            let df = NSDateFormatter()
            df.doesRelativeDateFormatting = true
            
            if NSCalendar.currentCalendar().isDateInToday(tweet.created) {
                df.dateStyle = .NoStyle
                df.timeStyle = .ShortStyle
            }
            else {
                df.dateStyle = .ShortStyle
                df.timeStyle = .NoStyle
            }
            leftText.text = df.stringFromDate(tweet.created)
        }
    }
}
