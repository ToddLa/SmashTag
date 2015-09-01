//
//  TweetTableViewController.swift
//  SmashTag
//
//  Created by Todd Laney on 8/23/15.
//  Copyright (c) 2015 Todd Laney. All rights reserved.
//

import UIKit

class TweetTableViewController: UITableViewController, UITextFieldDelegate, UISearchBarDelegate {

    // MARK: - MODEL
    var tweets = [[Tweet]]()

    // MARK: - Properties

    var searchText : String? = "#Wombat" {
        didSet {
            lastReq = nil
            searchTextField?.text = searchText
            searchBar?.text = searchText
            tweets.removeAll()
            tableView.reloadData()
            doSearch()
        }
    }

    // MARK: - Outlets
    @IBOutlet weak var searchBar: UISearchBar! {
        didSet {
            searchBar.delegate = self
            searchBar.text = searchText
            searchBar.placeholder = "#Search"
        }
        
    }
    
    @IBOutlet weak var searchTextField: UITextField! {
        didSet {
            searchTextField.delegate = self
            searchTextField.text = searchText
        }
    }

    // MARK; Storyboard constants
    
    private struct Storyboard {
        static let cellIdent = "TweetCell"
        static let detailSegueIdent = "TweetDetailSegue"
    }

    // MARK: Search

    private var lastReq : TwitterRequest?
    private var nextReq : TwitterRequest? {
        if lastReq == nil {
            if let searchText = searchText {
                return TwitterRequest(search: searchText, count: 500)
            }
        } else {
            return lastReq!.requestForNewer
        }
        return nil
    }

    private func doSearch() {
        refreshControl?.beginRefreshing()
        println(tableView.contentOffset)
        if tableView.contentOffset.y <= 0.0 {
            tableView.scrollRectToVisible(CGRectMake(0, 0, 1, 1), animated: true)
        }

        if let req = nextReq {
            req.fetchTweets { newTweets in
                dispatch_async(dispatch_get_main_queue()) {
                    if newTweets.count > 0 {
                        self.lastReq = req
                        self.tweets.insert(newTweets, atIndex: 0)
                        self.tableView.reloadData()
                        self.title = self.searchText
                    }
                    self.refreshControl?.endRefreshing()
                    if self.tweets.count > 0 {self.tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), atScrollPosition:.Top, animated:true)}
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

    // MARK - Segue
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        println("prepareForSegue: \(segue) \(segue.identifier) \(sender)")
        
        if let dest = (segue.destinationViewController as? UIViewController) ?? (segue.destinationViewController as? UINavigationController)?.topViewController {
            println("destination: \(dest)")
            if let cell = sender as? TweetCell {
                println("cell: \(cell)")
                let indexPath = tableView.indexPathForCell(cell)
                println("indexPath: \(indexPath)")
                
                if segue.identifier == Storyboard.detailSegueIdent {
                    if let dest = dest as? TweetDetailViewController {
                        dest.tweet = cell.tweet
                    }
                }
            }
        }
        
        let vc = (segue.destinationViewController as? UIViewController) ?? (segue.destinationViewController as? UINavigationController)?.topViewController
        
        if let detail = (vc as? TweetDetailViewController) where segue.identifier == "" {
            
        }
    }
    
    // MARK - UITextFieldDelegate

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == searchTextField {
            textField.resignFirstResponder()
            searchText = textField.text
        }
        return true
    }
    
    // MARK - UISearchBarDelegate

    func searchBarTextDidBeginEditing(searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    func searchBarTextDidEndEditing(searchBar: UISearchBar){
        searchBar.setShowsCancelButton(false, animated: true)
    }
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        println("searchBartextDidChange: \(searchText)")
    }
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        println("searchBarSearchButtonClicked: \(searchBar.text)")
        searchBar.resignFirstResponder()
        searchText = searchBar.text
    }
    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        println("searchBarBookmarkButtonClicked")
    }
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        println("searchBarCancelButtonClicked")
        searchBar.resignFirstResponder()
        searchBar.text = searchText
    }
    func searchBarResultsListButtonClicked(searchBar: UISearchBar) {
        println("searchBarResultsListButtonClicked")
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
