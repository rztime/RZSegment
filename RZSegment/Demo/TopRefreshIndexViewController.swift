//
//  TopRefreshIndexViewController.swift
//  RZSegment
//
//  Created by ruozui on 2020/5/13.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit

class TopRefreshIndexViewController: UIViewController {
    var pageView : RZPageContainerView?
    
    var topView: UIView = .init()
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.title = "刷新在子当前顶部"
        // 1。用frame布局，设置好位置
        pageView = .init(frame:.init(x: 0, y: kNavBarHeight(), width: self.view.frame.size.width, height: self.view.frame.size.height - kNavBarHeight()), delegate: self)
        self.view.addSubview(pageView!)
        // 2.配置segment
        pageView?.segmentView.rzBottomLineStyle = .auto(leadingMargin: 5, height: 3, bottomMargin: 3, color: .red)
        pageView?.segmentView.rzDefaultItemStyle = .init(font: .systemFont(ofSize: 15), textColor: .gray)
        pageView?.segmentView.rzHightLightItemStyle = .init(font: .systemFont(ofSize: 17), textColor: .red)
        pageView?.segmentView.rzItems = [
            .init(text: "最新"),
            .init(text: "热门"),
            .init(text: "关注"),
        ]
        let vc1 = ChildViewController()
            vc1.title = "第一个文本"
            let vc2 = ChildViewController()
            vc2.title = "第二个文本"
            let vc3 = ChildViewController()
            vc3.title = "第三个文本"
        
        self.addChild(vc1)
        self.addChild(vc2)
        self.addChild(vc3)
        // 3.配置子切换view
        pageView?.childVCs = [vc1, vc2, vc3]
        topView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 100))

        topView.backgroundColor = .red
        // 4.如果有顶部图，加上
//        pageView?.topView = topView
        // 5. 配置完成之后，刷新，但凡有改变数据源、改变view的布局等等，都需要调用reloaddata，
//        pageView?.reloadData()
        
        // 改变索引 这个不需要reloadData
//        pageView?.setCurrentIndex(index: 1, animation: true)
        
        pageView?.autoFixContentViewOffsetY = false
        pageView?.contentView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: {[weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self?.pageView?.contentView.mj_header?.endRefreshing()
                let x = arc4random() % 255
                self?.topView.backgroundColor = UIColor.init(red: CGFloat(x) / 255.0, green: CGFloat(x) / 255.0, blue: CGFloat(x) / 255.0, alpha: 1)
                self?.pageView?.topView = self?.topView
                self?.pageView?.reloadData()
            }
        })
        pageView?.contentView.mj_header?.beginRefreshing()
    }
}

extension TopRefreshIndexViewController : RZPageContainerViewDelegate {
    func rzMaxContentOffsetY() -> CGFloat {
        return self.topView.frame.size.height
    }
}
