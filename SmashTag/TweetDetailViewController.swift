//
//  TweetDetailViewController.swift
//  SmashTag
//
//  Created by Todd Laney on 8/31/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

//
// protoll for a simple cell in our detail view
//
private protocol Item {
    var cellIdent: String {get}
    var segueIdent: String? {get}

    func cellHeightForWidth(width:CGFloat) -> CGFloat
    func select()
    func setupCell(cell: UITableViewCell)
    func setupSegue(segue: UIStoryboardSegue)
}

//
// String Item
//
extension String : Item {
    var cellIdent : String {return "BasicCell"}
    var segueIdent : String? {return nil}
    
    func cellHeightForWidth(width:CGFloat) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func setupCell(cell : UITableViewCell) {
        cell.textLabel?.text = self
        cell.textLabel?.numberOfLines = 0
    }
    func select() {
        println("SELECT: \(self)")
    }
    func setupSegue(segue: UIStoryboardSegue) {
    }
}


//
// Text Item
//
class TextItem : Item {
    var str : String
    
    init(_ text:String) {
        self.str = text
    }
    
    var cellIdent  : String  {return "BasicCell"}
    var segueIdent : String? {return nil}
    
    func cellHeightForWidth(width:CGFloat) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func setupCell(cell : UITableViewCell) {
        cell.textLabel?.text = str
        cell.textLabel?.numberOfLines = 0
        if (segueIdent != nil) {cell.accessoryType = .DisclosureIndicator}
    }
    func setupSegue(segue: UIStoryboardSegue) {
    }
    func select() {
        println("TEXT: \(str)")
    }
}


//
// URL Item
//
class UrlItem : TextItem {
    override func select() {
        println("URL: \(str)")
        if let url = NSURL(string: str) {
            UIApplication.sharedApplication().openURL(url)
        }
    }
}

//
// Hashtag Item
//
class SearchItem : TextItem {
    override var segueIdent : String? {return "search"}
    override func setupSegue(segue: UIStoryboardSegue) {
        let dest = (segue.destinationViewController as? UIViewController) ?? (segue.destinationViewController as? UINavigationController)?.topViewController
        if let tweetVC = (dest as? TweetTableViewController) {
            tweetVC.searchText = self.str
        }
    }
}

//
// User Item
//
class UserItem : Item {
    var user: User  // Twitter User
    
    init(_ user:User) {
        self.user = user
    }
    
    var cellIdent  : String  {return "SubtitleCell"}
    var segueIdent : String? {return "search"}
    
    func cellHeightForWidth(width:CGFloat) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    func setupCell(cell : UITableViewCell) {
        cell.textLabel?.text = user.name
        cell.detailTextLabel?.text = "@" + user.screenName
        if let url = user.profileImageURL {
            let size = CGSize(width: cell.bounds.height, height: cell.bounds.height)
            cell.imageView?.layer.cornerRadius = size.width / 8.0
            cell.imageView?.layer.borderColor = UIColor.orangeColor().CGColor
            cell.imageView?.layer.borderWidth = 2.0
            cell.imageView?.clipsToBounds = true
            
            cell.imageView?.image = ImageCache.loadImageUrl(url, size: size, asyncHandler: {image in
                cell.imageView?.image = image
                cell.setNeedsLayout() // ???
            })
        }
    }
    func setupSegue(segue: UIStoryboardSegue) {
        let dest = (segue.destinationViewController as? UIViewController) ?? (segue.destinationViewController as? UINavigationController)?.topViewController
        if let tweetVC = (dest as? TweetTableViewController) {
            tweetVC.searchText = "from:" + self.user.screenName
        }
    }
    func select() {
        println("USER: @\(user.screenName) (\(user.name))")
    }
}

//
// Image Item
//
class ImageItem : Item {
    var media:MediaItem
    
    init(_ media:MediaItem) {
        self.media = media
    }
    
    var cellIdent  : String  {return "ImageCell"}
    var segueIdent : String? {return nil /*"ImageSegue"*/}
    
    func cellHeightForWidth(width:CGFloat) -> CGFloat {
        return CGFloat(ceil(Double(width) / media.aspectRatio))
    }
    func setupCell(cell : UITableViewCell) {
        if let url = media.url {
            if let cell = (cell as? ImageCell) {
                let size = CGSize(width: cell.bounds.width, height: 0)
                cell.theImageView?.image = ImageCache.loadImageUrl(url, size: size, asyncHandler: {image in
                    cell.theImageView?.image = image
                    cell.spinner.stopAnimating()
                })
                if cell.theImageView?.image == nil {
                    cell.spinner.startAnimating()
                }
            }
        }
    }
    func setupSegue(segue: UIStoryboardSegue) {
    }
    func select() {
        println("IMAGE: @\(media.url)")
    }
}

class ImageCell : UITableViewCell {
    @IBOutlet weak var theImageView: UIImageView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
}

class TweetDetailViewController: UITableViewController {
    
    // MARK: Public
    
    var tweet : Tweet? {
        didSet {
            update()
        }
    }
    
    // MARK - Private
    private struct Section {
        var title : String
        var items : [Item]
    }
    private var data = [Section]()
    
    private func itemForIndexPath(indexPath: NSIndexPath) -> Item {
        return data[indexPath.section].items[indexPath.row]
    }
    
    private func update() {
        
        data.removeAll()
        
        if let tweet = tweet {
            //self.title = tweet.id ?? nil
            self.title = "Tweet"
            data.append(Section(title:"User",     items:[UserItem(tweet.user)]))
            data.append(Section(title:"Text",     items:[TextItem(tweet.text)]))
            data.append(Section(title:"Hashtags", items:tweet.hashtags.map({SearchItem($0.keyword)})))
            data.append(Section(title:"Mentions", items:tweet.userMentions.map({SearchItem($0.keyword)})))
            data.append(Section(title:"URLs",     items:tweet.urls.map({UrlItem($0.keyword)})))
            data.append(Section(title:"Media",    items:tweet.media.map({ImageItem($0)})))
        }
    }

    
    // MARK: - view life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return data.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].items.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data[section].items.count == 0 ? nil : data[section].title
    }
    
    // MARK: - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let dest = (segue.destinationViewController as? UIViewController) ?? (segue.destinationViewController as? UINavigationController)?.topViewController
        
        if let item = (sender as? Item) {
            item.setupSegue(segue)
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let item = itemForIndexPath(indexPath)
        return item.cellHeightForWidth(tableView.bounds.size.width)
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let item = itemForIndexPath(indexPath)
        let cell = tableView.dequeueReusableCellWithIdentifier(item.cellIdent, forIndexPath: indexPath) as! UITableViewCell
        //if (item.segueIdent != nil) {cell.accessoryType = .DisclosureIndicator}
        item.setupCell(cell)
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let item = itemForIndexPath(indexPath)
        item.select()
        if let ident = item.segueIdent {
            self.performSegueWithIdentifier(ident, sender:(item as? AnyObject))
        }
    }
}
