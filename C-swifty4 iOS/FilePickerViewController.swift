//
//  FilePickerViewController.swift
//  C-swifty4 iOS
//
//  Created by Fabio Ritrovato on 12/02/2015.
//  Copyright (c) 2015 orange in a day. All rights reserved.
//

import UIKit

class FilePickerViewController: UITableViewController {
    
    var completionBlock: ((_ url: URL) -> Void)?

    fileprivate let dataSource: [URL] = {
        var files =  [URL]()
        if let txtFiles = Bundle.main.urls(forResourcesWithExtension: "txt", subdirectory: "Programs") {
            files.append(contentsOf: txtFiles)
        }
        if let prgFiles = Bundle.main.urls(forResourcesWithExtension: "prg", subdirectory: "Programs") {
            files.append(contentsOf: prgFiles)
        }
        return files
    }()
    
    //MARK: Actions
    
    @IBAction func onCancelButton() {
        dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FileCell")!
        cell.textLabel?.text = dataSource[(indexPath as NSIndexPath).row].lastPathComponent
        return cell
    }
   
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true, completion: { () -> Void in
            self.completionBlock?(self.dataSource[(indexPath as NSIndexPath).row])
        })
    }
    
}
