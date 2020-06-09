//
//  MultipleScrollviewControllerViewController.swift
//  RZSegment
//
//  Created by ruozui on 2020/6/9.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit

class MultipleScrollviewControllerViewController: UIViewController {
    var scrollview : UIScrollView?
//    var collectionView : UICollectionView!
    
    var viewSController : [TopRefreshIndexViewController] = [
    .init(),
    .init(),
    .init(),
    .init(),
    .init()
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "多个scrollview嵌套"
        scrollview = UIScrollView.init(frame: self.view.bounds)
        scrollview?.contentSize = CGSize.init(width: viewSController.count * Int(self.view.bounds.size.width), height: 0)
        self.view.addSubview(scrollview!)
        scrollview?.backgroundColor = UIColor.white
        scrollview?.isPagingEnabled = true
        scrollview?.tag = 100
        for (i, v) in viewSController.enumerated() {
            scrollview?.addSubview(v.view)
            v.view.frame = CGRect.init(x: CGFloat(i) * self.view.bounds.size.width, y: 0, width: self.view.bounds.size.width, height: self.view.bounds.size.height)
        }
         
    }
     
}
