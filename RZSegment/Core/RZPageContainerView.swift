//
//  RZPageContainerView.swift
//  RZSegment
//
//  Created by ruozui on 2020/5/11.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit
// 需要翻页的界面的delegate
protocol RZPageContainerChildViewDelegate {
    func rzScrollView() -> UIScrollView?
}
// 主界面的delegate
@objc protocol RZPageContainerViewDelegate {
    // 最大移动的位移（悬停时，scrollview的contentOffset.y） 如果没有额外的topView，则为0
    func rzMaxContentOffsetY() -> CGFloat
}
class RZPageContainerView: UIView, UIScrollViewDelegate {
    // 容器
    open var contentView : RZCustomScrollView!
    // 分页控件
    open var segmentView : RZSegmentView!
    // 分页控件顶部视图
    open var topView : UIView?
    
    // 滑动切换界面的scrollview
    open var childVCContainerView : RZCustomScrollView!
    
    // 可以添加view或者ViewController 二选一
    open var childVCs : [UIViewController & RZPageContainerChildViewDelegate] = []
    open var childViews : [UIView & RZPageContainerChildViewDelegate] = []
    
    open weak var delegate : RZPageContainerViewDelegate?
    
    open var currentIndex : Int {
        return self.segmentView.currentIndex
    }
    // 每次切换时，将会调用
    open var didShowedViewWithIndex:((_ index:Int) -> Void)?
    
    // 正在改变索引
    private var changeIndexIng : Bool = false
    // 自动修正视图偏移...
    // 当设置了contentView的刷新（mj_header）之后，请设置为false，主要作用在于手势完成之后，修正contentView的contentOffset
    open var autoFixContentViewOffsetY = true
    
    private var willShowedIndex : Int?
    private let childViewTag = 1001
    
    private var isPanSuperView = false
    init(frame: CGRect, delegate:RZPageContainerViewDelegate) {
        super.init(frame: frame)
        self.delegate = delegate
        childVCContainerView = .init(frame: .init(x: 0, y: 44, width: self.bounds.size.width, height: self.bounds.size.height - 44))
        childVCContainerView.isPagingEnabled = true
        childVCContainerView.showsVerticalScrollIndicator = false
        childVCContainerView.showsHorizontalScrollIndicator = false
        childVCContainerView.delegate = childVCContainerView
        childVCContainerView.bounces = false
        
        contentView = .init(frame: self.bounds)
        contentView.delegate = contentView
        contentView.showsVerticalScrollIndicator = false
        contentView.showsHorizontalScrollIndicator = false
        
        segmentView = .init(frame: .init(x: 0, y: 0, width: self.bounds.size.width, height: 44))
        self.addSubview(contentView)
        contentView.addSubview(childVCContainerView)
        contentView.addSubview(segmentView)
        
        eventBind()
    }
    private func pages() -> Int {
        return max(childVCs.count, childViews.count)
    }
    private func currentChildScrollView() -> UIScrollView? {
        if self.childVCs.count > 0 {
            let vc = self.childVCs[self.currentIndex]
            return vc.rzScrollView()
        }
        if self.childViews.count > 0 {
            let view = self.childViews[self.currentIndex]
            return view.rzScrollView()
        }
        return nil
    }
    //MARK:- 对外方法
    open func setCurrentIndex(index:Int, animation:Bool = true) {
        self.segmentView.setCurrentIndex(index: index, animation: animation, notice: false)
        self.didShowIndex(index)
    }
    //MARK:- 对外方法
    open func reloadData(animation:Bool = true) {
        if topView != nil {
            contentView.addSubview(topView!)
            contentView.contentSize = .init(width: 0, height: self.contentView.bounds.size.height + topView!.frame.size.height)
        } else {
            contentView.contentSize = .init(width: 0, height: 0)
        } 
        var frame = segmentView.frame
        frame.origin.y = topView?.frame.maxY ?? 0
        segmentView.frame = frame
        
        segmentView.reloadData()
        
        var containerFrame = self.childVCContainerView.frame
        containerFrame.origin.y = segmentView.frame.maxY
        containerFrame.size.height = self.bounds.size.height - segmentView.frame.size.height
        self.childVCContainerView.frame = containerFrame
        
        let pageCount = pages()
        childVCContainerView.contentSize = .init(width: CGFloat(pageCount) * childVCContainerView.frame.size.width, height: 0)
        
        childVCContainerView.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        for i in 0...(pageCount-1) {
            let view = UIView.init(frame: .init(x: CGFloat(i) * self.bounds.size.width, y: 0, width: self.bounds.size.width, height: containerFrame.size.height))
            childVCContainerView.addSubview(view)
            view.tag = i + childViewTag
        }
        let index = self.currentIndex
        
        didShowIndex(index, animation: animation)
    }
    private func eventBind() {
        segmentView.rzDidChangedIndex = { [weak self] (_ ,index) in
            self?.didShowIndex(index)
        }
        childVCContainerView.didScroll = { [weak self] (scrollView, _) in
            if self?.changeIndexIng == true {
                return
            }
            var willShowIndex : Int? = nil
            switch scrollView.rzScrollDirection() {
            case .toLeft:
                if CGFloat(self?.currentIndex ?? 0) * scrollView.frame.size.width - scrollView.contentOffset.x >= 0 {
                    return
                }
                willShowIndex = (self?.currentIndex ?? 0) + 1
                break
            case .toRight:
                if CGFloat(self?.currentIndex ?? 0) * scrollView.frame.size.width - scrollView.contentOffset.x <= 0 {
                    return
                }
                willShowIndex = (self?.currentIndex ?? 0) - 1
                break
            default:
                return
            }
            guard (willShowIndex != nil) else {
                return
            }
            // 当滑动的下一个界面超过1/2被显示时，就当做正在显示的界面，改变分页segmentView
            let showPage : Int = Int((scrollView.contentOffset.x + (scrollView.frame.size.width/2)) / scrollView.frame.size.width)
            if showPage != self?.currentIndex {
                self?.changeIndexIng = true
                self?.segmentView.setCurrentIndex(index: showPage, animation: true, notice: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + (self?.segmentView.rzAnimationTimer ?? 0)) {
                    self?.changeIndexIng = false
                }
            }
            if willShowIndex! > (self?.pages() ?? 0)  || willShowIndex! < 0 {
                return
            }
            if willShowIndex == self?.willShowedIndex {
                return
            }
            self?.willShowedIndex = willShowIndex
            // 加载将要显示的
            self?.willShowIndex(willShowIndex!)
        }
        childVCContainerView.willScroll = {(view) in
            // 作为分页scrollview的手势判断，水平移动时，contentView不可垂直移动，（水平、垂直、互斥）
            view.panDirection = nil
        }
        childVCContainerView.panLocationChanged = { [weak self] (view) in
            guard let self = self else {
                return
            }
            let point = view.panGestureRecognizer.translation(in: self)
            if view.panDirection == nil { // 只记录初次滑动时，是水平还是垂直
                if abs(point.x) > abs(point.y) {
                    view.panDirection = .toLeft
                } else if abs(point.x) < abs(point.y) {
                    view.panDirection = .toDown
                }
                if view.panDirection == .toLeft {
                    self.contentView.isScrollEnabled = false
                } else if view.panDirection == .toDown {
                    view.isScrollEnabled = false
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.contentView.isScrollEnabled = true
                    view.isScrollEnabled = true
                }
            }
        }
        contentView.willScroll = { [weak self] scrollView in
            guard let childScrollView = self?.currentChildScrollView() else {
                return
            }
            childScrollView.rzLastContentOffset = childScrollView.contentOffset
        }
        contentView.didScroll = { [weak self] (scrollView, finish) in
            if finish {
                self?.isPanSuperView = false
            }
            guard let childScrollView = self?.currentChildScrollView() else {
                return
            }
          
            // 最大偏移量
            let maxOffsetY = self?.delegate?.rzMaxContentOffsetY() ?? 0
            if scrollView.contentOffset.y >= maxOffsetY {
                // 超过最大偏移量、则顶部segment悬浮
                scrollView.setContentOffset(.init(x: 0, y: maxOffsetY), animated: false)
                scrollView.rzLastContentOffset = scrollView.contentOffset
            }
            let point = scrollView.panGestureRecognizer.location(in: self)
            let frame = childScrollView.convert(childScrollView.bounds, to: self)
            if !frame.contains(point) || self?.isPanSuperView == true {
                // 当触摸的点不在子视图上时，外层可以随意
                self?.isPanSuperView = true
                return
            } 
            // 在上下运动过程中
            let dir = scrollView.rzScrollDirection()
            switch dir {
            case .toUp:
                // 如果contentView未能到顶，则子视图先不动，contentView先走到悬停位置
                let slider : Bool = scrollView.contentOffset.y <= maxOffsetY
                childScrollView.rzCanSlide = !slider
                scrollView.rzCanSlide = slider
            case .toDown:
                // 如果子视图未到顶，则contentView先不动，
                let slide : Bool = childScrollView.contentOffset.y >= CGFloat(0.5)
                scrollView.rzCanSlide = !slide
                childScrollView.rzCanSlide = slide
            default:
                return
            }
            // 修正位置
            if childScrollView.rzCanSlide == false {
                if self?.autoFixContentViewOffsetY == false && childScrollView.isDecelerating != false {
                    childScrollView.setContentOffset(CGPoint.zero, animated: false)
                } else {
                    childScrollView.setContentOffset(childScrollView.rzLastContentOffset, animated: false)
                }
            }
            if scrollView.rzCanSlide == false {
                if self?.autoFixContentViewOffsetY == true && scrollView.isDecelerating != false {
                    scrollView.setContentOffset(CGPoint.zero, animated: true)
                } else {
                    scrollView.setContentOffset(scrollView.rzLastContentOffset, animated: false)
                }
            }
            // 保留当前位移
            childScrollView.rzLastContentOffset = childScrollView.contentOffset
            scrollView.rzLastContentOffset = scrollView.contentOffset
        }
    }
    
    private func didShowIndex(_ index:Int, animation:Bool = true) {
        changeIndexIng = true
        childVCContainerView.setContentOffset(CGPoint.init(x: Int(self.bounds.size.width) * index, y: 0), animated: animation)
        showIndex(index)
        DispatchQueue.main.asyncAfter(deadline: .now() + segmentView.rzAnimationTimer) {
            self.changeIndexIng = false
        }
    }
    private func willShowIndex(_ index:Int) {
        showIndex(index)
    }
    
    private func showIndex(_ index:Int) {
        guard let view = childVCContainerView.viewWithTag(index + childViewTag) else {
            return
        }
        var childView:UIView!
        if self.childVCs.count > index {
            childView = self.childVCs[index].view
        } else if self.childViews.count > index {
            childView = self.childViews[index]
        } else {
            return
        }
        self.didShowedViewWithIndex?(index)
        if view.subviews.first == childView {
            return
        } else {
            view.subviews.forEach { (v) in
                v.removeFromSuperview()
            }
            view.addSubview(childView)
            childView.bounds = view.bounds
            childView.snp.makeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIScrollView {
    fileprivate struct RZScrollViewPerpotyName {
        static var canSlide = "canSlide"
        static var lastContentOffset = "lastContentOffset"
        static var direction = "direction"
    }
    // 是否可以滑动
    fileprivate var rzCanSlide : Bool {
        set {
            objc_setAssociatedObject(self, &RZScrollViewPerpotyName.canSlide, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            if let can = objc_getAssociatedObject(self, &RZScrollViewPerpotyName.canSlide) {
                return can as! Bool
            }
            return true
        }
    }
    // 上一次的位置偏移量
    fileprivate var rzLastContentOffset : CGPoint {
        set {
            objc_setAssociatedObject(self, &RZScrollViewPerpotyName.lastContentOffset, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        get {
            if let contentOffset = objc_getAssociatedObject(self, &RZScrollViewPerpotyName.lastContentOffset) {
                return contentOffset as! CGPoint
            }
            return .init(x: 0, y: 0)
        }
    }
    // 滑动方向
    enum RZScrollDiret {
        case none
        case toLeft
        case toRight
        case toUp
        case toDown
    }
    
    fileprivate func rzScrollDirection() -> RZScrollDiret {
        var dir : RZScrollDiret = .none
        if self.contentSize.width > self.frame.size.width {
            let offsetX = self.contentOffset.x - self.rzLastContentOffset.x
            if  offsetX > 0 {
                dir = .toLeft
            } else if offsetX < 0 {
                dir = .toRight
            }
        } else {
            let offsetY = self.contentOffset.y - self.rzLastContentOffset.y
            if offsetY > 0 {
                dir = .toUp
            } else if offsetY < 0 {
                dir = .toDown
            }
        }
        return dir
    }
}


class RZCustomScrollView : UIScrollView, UIGestureRecognizerDelegate, UIScrollViewDelegate{
    // 滑动之后的回调，  h:水平滑动的方向，v：垂直滑动的方向
    open var didScroll:((_ view: RZCustomScrollView, _ finish:Bool) -> Void)?
    // 将要滑动
    open var willScroll:((_ view:RZCustomScrollView) -> Void)?
    
    open var panLocationChanged:((_ view: RZCustomScrollView) -> Void)?
    
    open var panDirection: RZScrollDiret?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.delaysContentTouches = false
        self.panGestureRecognizer.addTarget(self, action: #selector(panGest(_:)))
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    @objc func panGest(_ pan: UIPanGestureRecognizer) {
        self.panLocationChanged?(self)
    }
    // 支持多手势响应
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.willScroll?(self)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.didScroll?(self, false)
        self.rzLastContentOffset = scrollView.contentOffset
    }
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate == false {
            self.scrollViewDidEndDecelerating(scrollView)
        }
    }
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.didScroll?(self, true)
        self.rzLastContentOffset = scrollView.contentOffset
        self.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.isUserInteractionEnabled = true
        }
    }
}
