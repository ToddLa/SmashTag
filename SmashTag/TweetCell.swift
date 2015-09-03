//
//  TweetCell.swift
//  SmashTag
//
//  Created by Todd Laney on 8/23/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

class TweetCell: UITableViewCell {

    // MARK: Properties

    var tweet : Tweet? {
        didSet {
            updateUI()
        }
    }

    // MARK: Private

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var bodyText: UILabel!
    @IBOutlet weak var timeText: UILabel!
    @IBOutlet weak var userNameText: UILabel!
    @IBOutlet weak var screenNameText: UILabel!
    
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
        if let tweet = tweet {
            println("UpdateUI: \(tweet)")
            
            // HACK - Fonts - NEED TO SET THESE HERE (INSTEAD OF STORYBOARD) TO GET DynamicText size to work (kind of...)
            //userNameText.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
            //screenNameText.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
            //bodyText.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            //timeText.font = UIFont.preferredFontForTextStyle(UIFontTextStyleSubheadline)
            //self.setNeedsLayout()
            // HACK

            // Name
            userNameText.text = tweet.user.name
            screenNameText.text = "@\(tweet.user.screenName)"

            // Body
            bodyText.text = tweet.text
            
            // convert to attributed text and color items...
            var text = NSMutableAttributedString(attributedString: bodyText.attributedText)
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

            // Image
            if let url = tweet.user.profileImageURL {
                
                let size = profileImage.bounds.size
                
                let image = ImageCache.loadImageUrl(url, size:size) { image in
                    assert(NSThread.isMainThread())
                    // only set the image if the tweet id matches, in case the cell gets reused!
                    if self.tweet?.id == tweet.id {
                        self.profileImage.image = image
                    }
                }
                
                profileImage.image = image
                profileImage.layer.cornerRadius = size.width / 8.0
                profileImage.layer.borderColor = Colors.ImageBorder.CGColor
                profileImage.layer.borderWidth = 2.0
                profileImage.clipsToBounds = true
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
            timeText.text = df.stringFromDate(tweet.created)
        } else {
            profileImage?.image = nil
            timeText?.text = nil
            userNameText?.text = nil
            screenNameText?.text = nil
            bodyText?.text = nil
        }
    }
}

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


