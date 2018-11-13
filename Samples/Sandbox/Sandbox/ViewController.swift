//
//  ViewController.swift
//  Sandbox
//
//  Created by Tae Hyun Na on 2016. 1. 15.
//  Copyright (c) 2014, P9 SOFT, Inc. All rights reserved.
//
//  Licensed under the MIT license.

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let remakerParameter = HJResourceRemakerResizeImage.parameter(fromWidth: 240, height:240, contentMode:.aspectFit )
        let query = HJResourceCommon.query(forImageUrlString: "http://www.p9soft.com/images/sample.jpg", remakerName: "resize", remakerParameter: remakerParameter)
        HJResourceManager.default().resource(forQuery: query, completion: { (result:[AnyHashable : Any]?) in
            if let image = result?[HJResourceManagerParameterKeyDataObject] as? UIImage {
                self.imageView.image = image
            }
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

