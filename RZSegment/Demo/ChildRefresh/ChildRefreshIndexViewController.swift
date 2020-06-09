//
//  ChildRefreshIndexViewController.swift
//  RZSegment
//
//  Created by ruozui on 2020/5/11.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit

class ChildRefreshIndexViewController: UIViewController {
    var pageView : RZPageContainerView?
    
    var topView: UIView = .init()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.title = "刷新在子View里"
        
        pageView = .init(frame:.init(x: 0, y: kNavBarHeight(), width: self.view.frame.size.width, height: self.view.frame.size.height - kNavBarHeight()), delegate: self)
        self.view.addSubview(pageView!)
 
        pageView?.segmentView.rzBottomLineStyle = .auto(leadingMargin: 5, height: 3, bottomMargin: 3, color: .red)
        pageView?.segmentView.rzDefaultItemStyle = .init(font: .systemFont(ofSize: 15), textColor: .gray)
        pageView?.segmentView.rzHightLightItemStyle = .init(font: .systemFont(ofSize: 17), textColor: .red)
        pageView?.segmentView.rzItems = [
            .init(text: "最新"),
            .init(text: "热门"),
            .init(text: "关注"),
        ]
        let vc1 = ChildViewController()
        vc1.needRefresh = true
        vc1.title = "第一个文本"
        let vc2 = ChildViewController()
        vc2.needRefresh = true
        vc2.title = "第二个文本"
        let vc3 = ChildViewController()
        vc3.needRefresh = true
        vc3.title = "第三个文本"
        
        self.addChild(vc1)
        self.addChild(vc2)
        self.addChild(vc3)
        
        pageView?.childVCs = [vc1, vc2, vc3]
        topView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))

        topView.backgroundColor = .red
        pageView?.setCurrentIndex(index: 1, animation: true)
        pageView?.reloadData() 
    } 
}

extension ChildRefreshIndexViewController : RZPageContainerViewDelegate {
    func rzMaxContentOffsetY() -> CGFloat {
        return 0
    }
}
