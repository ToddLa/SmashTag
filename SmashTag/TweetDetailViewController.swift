//
//  TweetDetailViewController.swift
//  SmashTag
//
//  Created by Todd Laney on 8/31/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

class TweetDetailViewController: UITableViewController {
    
    // MARK: Public
    
    var tweet : Tweet? {
        didSet {
            update()
        }
    }
    
    // MARK; Storyboard constants
    
    private struct Storyboard {
        static let cellIdent = "TweetDetailCell"
    }
    
    // MARK - Private
    private var data = [(String, [String])]()
    
    private func update() {
        
        data.removeAll()
        
        if let tweet = tweet {
            data.append(("Text", [tweet.text]))
            data.append(("User", [tweet.user.name, "@" + tweet.user.screenName]))
            data.append(("Hashtags", tweet.hashtags.map({$0.keyword})))
            data.append(("Mentions", tweet.userMentions.map({$0.keyword})))
            data.append(("URLs", tweet.urls.map({$0.keyword})))
            data.append(("Media", tweet.media.map({$0.description})))
        }
    }

    
    // MARK: - view life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        println("rowHeight = \(tableView.rowHeight), estimatedRowHeight=\(tableView.estimatedRowHeight)")
        
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return data.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data[section].1.count
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return data[section].1.count == 0 ? nil : data[section].0
    }
    
    // MARK: - Table view delegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.cellIdent, forIndexPath: indexPath) as! UITableViewCell
        
        let item = data[indexPath.section].1[indexPath.row]
        
        cell.textLabel?.text = item
        cell.textLabel?.numberOfLines = 0
        
        return cell
    }
}
