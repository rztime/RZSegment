//
//  RZSegmentPagesView.swift
//  RZSegment
//
//  Created by ruozui on 2020/4/30.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit

// 要实现滑动，需要添加的子childViewController实现以下协议
public protocol RZSegmentPagesChildViewControllerDelegate {
    /// 获取当前界面的scrollView到顶的时候的offset，
    /// 如果tableView这种没有下拉刷新，则返回0，有下拉刷新的时候，会有一个偏移量，比如MJRefresh的mj_header 为 -44
    func getScrollViewTopOffsetY() -> CGFloat
    /// 获取当前界面的scrollView，如果没有返回0.。。在控制悬停以及多手势时，需要其做处理
    func getScrollView() -> UIScrollView?
    /// 通知子controller需要刷新了，需要自行实现
    /// 如设置了RZSegmentPagesView的tableview的mj_header, 在触发了刷新之后，通过segmentPages的childControllers以及currentIndex，去刷新当前index的vc的数据，并请在子vc刷新数据回来之后，给complete回调，以关闭segmentPagesView的刷新状态
    /// - Parameter complete: 刷新数据完成之后的回调
    func beginRefresh(complete:(() -> Void)?)
}
// segmentPagesViewControllerDelegate 需要实现的协议
public protocol RZSegmentPagesViewDelegate {
    /// 子childViewController的view的高度，如果返回nil，则默认为 RZSegmentPagesView 的高度-segmentView的高度
    func rzSegmentPagesChildViewHeight(segmentPagesView:RZSegmentPagesView, index:Int) -> CGFloat
    /// segmentView的高度 默认44
    func rzSegmentViewHeight(segmentPagesView:RZSegmentPagesView, index:Int) -> CGFloat
    /// 在segmentView上是否有其他视图
    func rzSegmentPagesHasTopView(segmentPagesView:RZSegmentPagesView, index:Int) -> Bool
    // 在segmentView上如果有额外的视图时，请返回此视图
    func rzSegmentPagesTopView(_ view:RZSegmentPagesView, index:Int) -> UIView
    /// 顶部视图的高度
    func rzSegmentPagesTopViewHeight(segmentPagesView:RZSegmentPagesView, index:Int) -> CGFloat
}
public protocol RZPageViewsMultipleGesture : UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool
}

// 让tableview支持多视图手势响应，这样才能让子视图跟着一起滑动
public class RZTableView: UITableView, RZPageViewsMultipleGesture {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
/// RZSegmentPagesViewController的层级结构如下
///         Controller
///           >  view    // 不做任何处理
///               >  tableView           是grounp的类型，只有一个section，且只有1行row
///     顶部视图加在这                                                              > tableHeaderView       在segmentView分页控件上如果有额外的视图，直接设置好，赋在tableHeaderView上
///     segment分页按钮控件                                                    > sectionHeaderView    segmentView 分页控件绑定在第一行的sectionView上
///                                            > cellForRow         只有一行 ，里边绑定了一个左右切换滑动的collectionView ，在collectionView上会把childViewControllers的view加到collectionViewCell上
///     子Controller的view加在row的collectionView上                              > collectionView   >  collectionViewCell 会将childViewController.view加上去
open class RZSegmentPagesView: UIView ,UIGestureRecognizerDelegate {
    public var tableView:(UITableView & RZPageViewsMultipleGesture) = RZTableView.init(frame: UIScreen.main.bounds, style: .plain)
    
    public var segmentView : RZSegmentView = RZSegmentView.init(frame: .init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: 44))
    
    // 子视图的scrollView的上一次滑动的初始位置
    var childScrollViewLastContentOffSet : CGPoint = .zero
    // 当前视图的scrollView的上一次滑动的初始位置
    var superScrollViewLastContentOffset : CGPoint = .zero
    
    public let layout = UICollectionViewFlowLayout().then {
        $0.minimumLineSpacing = 0
        $0.minimumInteritemSpacing = 0
        $0.sectionInset = .zero
        $0.scrollDirection = .horizontal
    }
    public var pagesView : UICollectionView = UICollectionView.init(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()).then {
        $0.isPagingEnabled = true
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.backgroundColor = .clear
        $0.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        $0.bounces = false
    }
    // 控制器列表
    public var childControllers : [UIViewController & RZSegmentPagesChildViewControllerDelegate] = []
    
    public var currentIndex : Int {
        return self.segmentView.currentIndex
    }
    // 是否在左右滑动切换page
    private var isPaningRefresh : Bool = false
    // 点击顶部的时候，默认没有切换效果，如果有切换动画，那么没点击的界面也将加载，大大增加内存
    public var segmentTapSwitchAnimation : Bool = false
    /// 当前持有segmentPagesView的UIViewcontroller，因为要涉及到push，pop，所以需要此
    weak open var delegate : (RZSegmentPagesViewDelegate & UIViewController)?
    
    /// 是否是拖拽的当前最外层的tableview
    open var isDragSuperTableView = false
    public init (frame:CGRect, delegate:(RZSegmentPagesViewDelegate & UIViewController)?) {
        super.init(frame: frame)
        self.segmentView.frame = .init(x: 0, y: 0, width: UIScreen.main.bounds.size.width, height: (delegate?.rzSegmentViewHeight(segmentPagesView: self, index: 0)) ?? 44)
        self.delegate = delegate
        createUI()
        bindEventHandle()
        
        let pan = UIPanGestureRecognizer.init(target: self, action: #selector(panGuesture(_ :)))
        self.addGestureRecognizer(pan)
    }
    // 在当前view上添加的pan手势，因为子childView里有scrollview会拦截事件，所以只有触摸在当前的tableview上时，才会触发此方法
    @objc func panGuesture(_ pan:UIPanGestureRecognizer) {
        switch pan.state {
        case .began:
            isDragSuperTableView = true
        case .changed:
            break
        default:
            isDragSuperTableView = false
        }
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func reloadData() {
        
        self.tableView.reloadData()
        DispatchQueue.main.async {
            self.segmentView.reloadData()
            self.pagesView.scrollToItem(at: IndexPath.init(row: self.currentIndex, section: 0), at: .centeredHorizontally, animated: false)
            self.pagesView.reloadData()
        } 
    }
    open func resetTableView() {
        self.addSubview(tableView)
        tableView.tableFooterView = UIView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        tableView.isScrollEnabled = false
    }
    
    open func createUI() {
        resetTableView()
        pagesView.setCollectionViewLayout(layout, animated: false)
        pagesView.delegate = self
        pagesView.dataSource = self
    }
    open func bindEventHandle() {
        segmentView.rzDidChangedIndex = { [weak self] (v, index) in
            if self?.isPaningRefresh == false {
                if self?.childControllers.count == 0 {return}
                if index >= (self?.childControllers.count ?? 0) {
                    return
                }
                let indexpath = IndexPath.init(row: index, section: 0)
                let dir:UICollectionView.ScrollPosition = .centeredHorizontally
                self?.pagesView.scrollToItem(at: indexpath, at:dir , animated: self?.segmentTapSwitchAnimation ?? false)
                self?.pagesView.reloadItems(at: [indexpath])
            }
        }
    }
    open func setCurrentIndex(_ index:Int) {
        segmentView.setCurrentIndex(index: index, animation: true)
    }
}

//MARK: tableview 总的布局，可以继承重写
extension RZSegmentPagesView : UITableViewDelegate, UITableViewDataSource  {
    
    open func numberOfSections(in tableView: UITableView) -> Int {
        if self.segmentView.rzItems.count == 0 || self.childControllers.count == 0 {
            return 0
        }
        if self.delegate?.rzSegmentPagesHasTopView(segmentPagesView: self, index: self.currentIndex) == true {
            self.tableView.isScrollEnabled = true
            return 2
        }
        self.tableView.isScrollEnabled = false
        return 1
    }
    public func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return CGFloat.leastNonzeroMagnitude
    }
    open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0  && self.delegate?.rzSegmentPagesHasTopView(segmentPagesView: self, index: self.currentIndex) == true {
           return 0
        }
        return 1
    }
    open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && self.delegate?.rzSegmentPagesHasTopView(segmentPagesView: self, index: self.currentIndex) == true {
            return self.delegate?.rzSegmentPagesTopViewHeight(segmentPagesView: self, index: self.currentIndex) ?? CGFloat.leastNonzeroMagnitude
        }
        return self.delegate?.rzSegmentViewHeight(segmentPagesView: self, index: self.currentIndex) ?? 44
    }
    open func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return self.delegate?.rzSegmentPagesChildViewHeight(segmentPagesView: self, index: self.currentIndex) ?? (self.tableView.frame.size.height - (self.delegate?.rzSegmentViewHeight(segmentPagesView: self, index: self.currentIndex) ?? 44))
    }
    open func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 && self.delegate?.rzSegmentPagesHasTopView(segmentPagesView: self, index: self.currentIndex) == true {
            var topHeader = tableView.dequeueReusableHeaderFooterView(withIdentifier: "topHeader")
            if topHeader == nil {
                topHeader = UITableViewHeaderFooterView.init(reuseIdentifier: "topHeader")
            }
            let topView = self.delegate?.rzSegmentPagesTopView(self, index: self.currentIndex) ?? UIView()
            if topHeader?.contentView.subviews.contains(topView) == false {
                topHeader?.contentView.addSubview(topView)
                topView.snp.makeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            }
            return topHeader
        }
        var segment = tableView.dequeueReusableHeaderFooterView(withIdentifier: "segment")
        if segment == nil {
            segment = UITableViewHeaderFooterView.init(reuseIdentifier: "segment")
        }
        if segment?.contentView.subviews.contains(self.segmentView) == false {
            segment?.contentView.addSubview(self.segmentView)
            self.segmentView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        segmentView.reloadData(animation: false)
        return segment
    }
    open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .default, reuseIdentifier: "cell")
            
        }
        if cell?.contentView.subviews.contains(self.pagesView) == false {
            cell?.contentView.addSubview(self.pagesView)
            self.pagesView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
        return cell!
    }
    
}
//MARK:pagesView
extension RZSegmentPagesView : UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.childControllers.count
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        let vc = self.childControllers[indexPath.row]
        cell.contentView.subviews.forEach { (v) in
            v.removeFromSuperview()
        }
        vc.view.bounds = cell.contentView.bounds
        cell.contentView.addSubview(vc.view)
        vc.view?.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.delegate?.addChild(vc)
        vc.didMove(toParent: self.delegate)
        return cell
    }
    // 滑动停止时，去更新segment
    open func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            if scrollView.isEqual(self.pagesView) {
                self.stopScroll()
            }
        }
    }
    open func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView.isEqual(self.pagesView) {
            self.stopScroll()
        }
    }
    // 停止滚动
    open func stopScroll() {
        DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
            let indexpath = self.pagesView.indexPathForItem(at: CGPoint.init(x: self.pagesView.contentOffset.x + self.pagesView.frame.size.width / 2.0, y: self.pagesView.frame.size.height / 2.0))
            if indexpath != nil {
                self.isPaningRefresh = true
                self.segmentView.setCurrentIndex(index: indexpath!.row, animation: true)
                DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
                    self.isPaningRefresh = false
                    self.pagesView.reloadItems(at: [indexpath!])
                }
            }
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if isDragSuperTableView {
            return
        }
        if self.childControllers.count == 0 {return }
        guard let childScrollView = self.childControllers[self.currentIndex].getScrollView() else {
            return
        }
        childScrollViewLastContentOffSet = childScrollView.contentOffset
        superScrollViewLastContentOffset = scrollView.contentOffset
    }
    // segmentView悬停的位置
    func superTableViewMaxOffsetY() -> CGFloat {
        var maxOffsetY : CGFloat = 0 // segmentView悬停的位置
        if self.delegate?.rzSegmentPagesHasTopView(segmentPagesView: self, index: self.currentIndex) == true {
            maxOffsetY = self.delegate?.rzSegmentPagesTopViewHeight(segmentPagesView: self, index: self.currentIndex) ?? 0
        }
        return maxOffsetY
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let maxOffsetY = superTableViewMaxOffsetY()
        if isDragSuperTableView {
            if tableView.contentOffset.y > maxOffsetY {
                tableView.contentOffset = .init(x: 0, y: maxOffsetY)
            }
            superScrollViewLastContentOffset = tableView.contentOffset
            return
        }
        if self.childControllers.count == 0 || self.segmentView.rzItems.count == 0 {return }
        guard let childScrollView = self.childControllers[self.currentIndex].getScrollView() else {
            return
        }
        if self.tableView.numberOfSections == 0 {return }
        let y = tableView.contentOffset.y - superScrollViewLastContentOffset.y // 如果大于0 ，是向上
        if y > 0 { // 向上拉，
            // 如果superScrollView没有拉到最大的位置，则superScrollView可以移动，childScrollView不可移动
            if tableView.contentOffset.y < maxOffsetY {
                childScrollView.contentOffset = childScrollViewLastContentOffSet
                superScrollViewLastContentOffset = tableView.contentOffset
                childScrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0)
            } else { // 如果拉到顶了，则childScrollView才可以滑动
                tableView.contentOffset = .init(x: 0, y: maxOffsetY)
                superScrollViewLastContentOffset = tableView.contentOffset
                childScrollViewLastContentOffSet = childScrollView.contentOffset
                childScrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 1)
            }
        } else if y < 0 { // 向下拉
            // 如果是拉的最外层的tableView，则childScrollView不动
            if isDragSuperTableView {
                superScrollViewLastContentOffset = tableView.contentOffset
            } else {
              // 如果是拉的ChildScrollView，没有拉到顶的话，则外层的scrollView不可移动
                let top = self.childControllers[self.currentIndex].getScrollViewTopOffsetY()
                if childScrollView.contentOffset.y > top { //
                    tableView.contentOffset = superScrollViewLastContentOffset
                    childScrollViewLastContentOffSet = childScrollView.contentOffset
                    childScrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 1)
                } else {
                    childScrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0)
                    childScrollView.contentOffset = childScrollViewLastContentOffSet
                    superScrollViewLastContentOffset = tableView.contentOffset
                }
            }
        }
    }
}
