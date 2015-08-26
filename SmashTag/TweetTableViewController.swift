//
//  TweetTableViewController.swift
//  SmashTag
//
//  Created by Todd Laney on 8/23/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

class TweetTableViewController: UITableViewController, UITextFieldDelegate {

    // MARK: - MODEL
    var tweets = [[Tweet]]()

    // MARK: - Properties

    var searchText : String? = "#Wombat" {
        didSet {
            lastReq = nil
            searchTextField?.text = searchText
            tweets.removeAll()
            tableView.reloadData()
            doSearch()
        }
    }

    // MARK: - Outlets
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
            searchTextField.text = searchText
        }
    }

    // MARK; Storyboard constants
    private struct Storyboard {
        static let cellIdent = "TweetCell"
    }

    // MARK: Search

    private var lastReq : TwitterRequest?
    private var nextReq : TwitterRequest? {
        if lastReq == nil {
            if let searchText = searchText {
                return TwitterRequest(search: searchText, count: 100)
            }
        } else {
            return lastReq!.requestForNewer
        }
        return nil
    }

    private func doSearch() {
        refreshControl?.beginRefreshing()

        if let req = nextReq {
            req.fetchTweets { newTweets in
                dispatch_async(dispatch_get_main_queue()) {
                    if newTweets.count > 0 {
                        self.lastReq = req
                        self.tweets.insert(newTweets, atIndex: 0)
                        self.tableView.reloadData()
                    }
                    self.refreshControl?.endRefreshing()
                }
            }
        } else {
            refreshControl?.endRefreshing()
        }
     }

    @IBAction func refresh(sender: UIRefreshControl) {
        doSearch()
    }

    // MARK: - ViewController Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = tableView.rowHeight
        tableView.rowHeight = UITableViewAutomaticDimension
        doSearch()
    }

    // MARK - UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == searchTextField {
            textField.resignFirstResponder()
            searchText = textField.text
        }
        return true
    }

    // MARK: - Data Source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return tweets.count
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tweets[section].count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Storyboard.cellIdent, forIndexPath: indexPath) as! TweetCell

        let tweet = tweets[indexPath.section][indexPath.row]
        cell.tweet = tweet

        return cell
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

}
