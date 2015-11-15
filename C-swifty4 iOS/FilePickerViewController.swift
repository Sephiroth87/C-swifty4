//
//  FilePickerViewController.swift
//  C-swifty4 iOS
//
//  Created by Fabio Ritrovato on 12/02/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import UIKit

class FilePickerViewController: UITableViewController {
    
    var completionBlock: ((url: NSURL) -> Void)?

    private let dataSource: [NSURL] = {
        var files =  [NSURL]()
        if let txtFiles = NSBundle.mainBundle().URLsForResourcesWithExtension("txt", subdirectory: "Programs") {
            files.appendContentsOf(txtFiles)
        }
        if let prgFiles = NSBundle.mainBundle().URLsForResourcesWithExtension("prg", subdirectory: "Programs") {
            files.appendContentsOf(prgFiles)
        }
        return files
    }()
    
    //MARK: Actions
    
    @IBAction func onCancelButton() {
        dismissViewControllerAnimated(true, completion: nil)
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("FileCell")!
        cell.textLabel?.text = dataSource[indexPath.row].lastPathComponent
        return cell
    }
   
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            self.completionBlock?(url: self.dataSource[indexPath.row])
        })
    }
    
}
