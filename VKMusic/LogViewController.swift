//
//  LogViewController.swift
//  VKMusic
//
//  Created by Yuriy Shilov on 17.02.16.
//  Copyright © 2016 Yuriy Shilov. All rights reserved.
//

import UIKit

class LogViewController: UIViewController {
    @IBOutlet weak var logTextField: UITextView!
    
    override func viewDidLoad() {
        logTextField.text = ""
        for s in logsArray {
            logTextField.text.appendContentsOf(s)
            logTextField.text.appendContentsOf("\n")
        }
        
    }

}
