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

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if let remakerParameter = HJResourceRemakerResizeImage.parameter(fromWidth: 100, height:100, contentMode:.aspectFit ) {
            let query:[String:Any] = [HJResourceQueryKeyRequestValue:"http://www.p9soft.com/images/sample.jpg",
                         HJResourceQueryKeyDataType:Int(HJResourceDataType.image.rawValue),
                         HJResourceQueryKeyRemakerName:"resize",
                         HJResourceQueryKeyRemakerParameter:remakerParameter
            ]
            HJResourceManager.default().resource(forQuery: query, completion: { (result:[AnyHashable : Any]?) in
                print("done")
            })
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

