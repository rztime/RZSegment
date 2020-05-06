//
//  IndexDemoViewController.swift
//  RZSegment
//
//  Created by ruozui on 2020/4/30.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit

class IndexDemoViewController: UIViewController {
    var segmentPagesView : RZSegmentPagesView!
    var topView = UIView().then {
        $0.backgroundColor = .red
    }
    
    var vcs = [ChildViewController(), ChildViewController(), ChildViewController()]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        
        topView.frame = .init(x: 0, y: 0, width: self.view.frame.size.width, height: 100)
        
        segmentPagesView = .init(frame: self.view.bounds, delegate: self)
        
        if #available(iOS 11.0, *) {
            
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        self.view.addSubview(segmentPagesView)
        segmentPagesView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(UIEdgeInsets.init(top: 64, left: 0, bottom: 0, right: 0))
        }
        self.segmentPagesView.segmentView.rzDefaultItemStyle = .init(font: .systemFont(ofSize: 15), textColor: .gray)
        self.segmentPagesView.segmentView.rzHightLightItemStyle = .init(font: .systemFont(ofSize: 17), textColor: .red)
        self.segmentPagesView.segmentView.rzItems = [
            .init(text: "最新"),
            .init(text: "热门"),
            .init(text: "关注"),
        ]
 
        self.segmentPagesView.tableView.mj_header = MJRefreshNormalHeader.init(refreshingBlock: { [weak self] in
            // 模拟请求总的数据， 比如拉取所有的配置，
            self?.requestData(complete: {
                // 设置打开的页数
//                self?.segmentPagesView.setCurrentIndex(1)
                // 配置好之后，请求当前显示的界面的数据
                guard let vc = self?.segmentPagesView.childControllers[self?.segmentPagesView.currentIndex ?? 0] else {
                    return
                }
                // 刷新当前显示的子视图
                vc.beginRefresh {
                    // 子VC刷新数据完毕，回调，关闭header
                    self?.segmentPagesView.tableView.mj_header?.endRefreshing()
                    self?.segmentPagesView.reloadData()
                }
            })
        })
        self.segmentPagesView.tableView.mj_header?.beginRefreshing()
    }
    
    func updateData() {
        
        self.segmentPagesView.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("111111111111")
    }
    
    func requestData(complete:(()->Void)?) {
        // 模拟请求数据
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // 数据回来，
            // 设置topView上的数据
            self.topView.backgroundColor = .green
            // 设置segmentView的数据
            self.segmentPagesView.segmentView.rzItems = [
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
            
            self.vcs = [vc1, vc2, vc3]
            // 设置子controllers
            self.segmentPagesView.childControllers = self.vcs
            
            complete?()
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
extension IndexDemoViewController: RZSegmentPagesViewDelegate {
    func rzSegmentPagesChildViewHeight(segmentPagesView: RZSegmentPagesView, index: Int) -> CGFloat {
        return self.view.frame.size.height - 64 - 44 // 减去 导航栏高度，减去 segmentView高度
    }
    
    func rzSegmentViewHeight(segmentPagesView: RZSegmentPagesView, index: Int) -> CGFloat {
        return 44
    }
    
    func rzSegmentPagesHasTopView(segmentPagesView: RZSegmentPagesView, index: Int) -> Bool {
        return true
    }
    
    func rzSegmentPagesTopView(_ view: RZSegmentPagesView, index: Int) -> UIView {
        return self.topView
    }
    
    func rzSegmentPagesTopViewHeight(segmentPagesView: RZSegmentPagesView, index: Int) -> CGFloat {
        return self.topView.frame.size.height
    } 
}
