//
//  TopRefreshIndexViewController.swift
//  RZSegment
//
//  Created by ruozui on 2020/5/13.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit
// 3步
// 1.segment
// 2.topview
// 3.子vc（view）

class TopRefreshIndexViewController: UIViewController {
    var pageView : RZPageContainerView?
    
    var topView: UIView = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        self.title = "刷新在子当前顶部"
        // 1。用frame布局，设置好位置
        pageView = .init(frame:.init(x: 0, y: kNavBarHeight(), width: self.view.frame.size.width, height: self.view.frame.size.height - kNavBarHeight()), delegate: self, autoFixContentViewOffsetY: false)
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
        
        pageView?.topView = topView
        
        pageView?.autoFixContentViewOffsetY = false
        pageView?.contentView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: {[weak self] in
            guard let self = self else {return }
            // 刷新操作
            // 按照自己的需求，如果是在子视图里刷新数据，调子视图的刷新方法，并在完成之后通知关闭顶部视图
            [vc1, vc2, vc3][self.pageView?.currentIndex ?? 0].requestDataByRefresh(refresh: true)
        })
        pageView?.contentView.mj_header?.beginRefreshing()
        pageView?.didShowedViewWithIndex = { [weak self] (index) in
            print("index:\(index)") 
            self?.refreshEndOrChangedIndex()
        }
        // 刷新完成之后的回调通知（关闭mj_header）
        [vc1, vc2, vc3].forEach({ [weak self] (vc) in
            vc.refreshComplete = { [weak self] in
                self?.refreshEndOrChangedIndex()
            }
        })
        pageView?.reloadData()
    }
    
    func refreshEndOrChangedIndex() {
        pageView?.contentView.mj_header?.endRefreshing()
    }
}

extension TopRefreshIndexViewController : RZPageContainerViewDelegate {
    func rzMaxContentOffsetY() -> CGFloat {
        return self.topView.frame.size.height
    }
}
