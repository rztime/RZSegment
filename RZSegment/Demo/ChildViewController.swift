//
//  ChildViewController.swift
//  RZSegment
//
//  Created by ruozui on 2020/4/30.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit

class ChildViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    let tableView = UITableView.init(frame: .zero, style: .plain)
    
    var datas : [Int] = []
    
    var refreshComplete : (() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        
        tableView.mj_footer = MJRefreshBackNormalFooter.init(refreshingBlock: { [weak self] in
            self?.requestDataByRefresh(refresh: false)
        })
        
        self.requestDataByRefresh(refresh: true)
    }
    
    // 请求网络数据 （模拟）
    func requestDataByRefresh(refresh:Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.tableView.mj_footer?.endRefreshing()
            if refresh {
                self.datas.removeAll()
            }
            self.datas.append(contentsOf: [1,2,3,4,5,6,7,8,9,10])
            self.tableView.reloadData()
            // 刷新完毕，回调让外层的tableview关闭header刷新状态
            if refresh {
                self.refreshComplete?()
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.datas.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = self.title! + "\(indexPath.row)"
        return cell!
    }
    
}

extension ChildViewController : RZSegmentPagesChildViewControllerDelegate {

    func getScrollViewTopOffsetY() -> CGFloat {
        return 0
    }
    func beginRefresh(complete: (() -> Void)?) {
        self.refreshComplete = complete
        // 刷新数据
        self.requestDataByRefresh(refresh: true)
    }
    func getScrollView() -> UIScrollView? {
        return tableView
    }
}
