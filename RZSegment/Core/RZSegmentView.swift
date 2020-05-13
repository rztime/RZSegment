//
//  RZSegmentView.swift
//  RZSegment
//
//  Created by ruozui on 2020/4/30.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit

//MARK:在使用过程中的配置的方法
open class RZSegmentView: UIView {
    /// 滚动方向 (水平、垂直)  默认水平
    var rzScrollDirection = RZSegmentView.RZScrollDirection.horizontal {
        didSet {
            initCollectionView()
        }
    }
    // 样式(如果内容不能铺满，则自动居上，左，下，右，或中)  其中，水平支持左中右，垂直支持上中下
    var rzStyle = RZSegmentView.RZSegmentViewStyle.auto
    // 文本对齐方式，默认居中
    var rzTextAlign : RZSegmentView.RZSegmentItemTextAlignStyle = .center
//    var
    // 默认item配置（未选中）
    var rzDefaultItemStyle = RZSegmentView.RZSegmentItemStyle.init(font: UIFont.systemFont(ofSize: 14), textColor: UIColor.init(white: 0.1, alpha: 0.7))
    // 高亮的时候的item配置（已选中）
    var rzHightLightItemStyle = RZSegmentView.RZSegmentItemStyle.init(font: UIFont.systemFont(ofSize: 15), textColor: UIColor.init(white: 0.1, alpha: 1))
    
    /// 标题
    var rzItems :[RZSegmentView.RZSegmentItemContent] = []
    
    /// 当前选中的索引
    var currentIndex : Int {
        return index
    }

    // item的大小的配置
    var rzItemSize = RZSegmentView.RZSegmentItemSize.auto(leadingMargin: 15, height: 44)
    
    // 底部线条的配置
    var rzBottomLineStyle = RZSegmentView.RZSegmentBottomScrollLineStyle.none

    // 选中时，添加一个背景图层
    var rzItemBackgroundViewStyle = RZSegmentView.RZSegmentScrollBackgroundStyle.none
    // 每个cell右侧的分界线
    var rzSeparateLineStyle: RZSegmentSeparateLineStyle = .none
    
    // 所有的动画的执行时间
    var rzAnimationTimer : TimeInterval = 0.3
    
    /// 索引将要改变 return false时，不改变
    var rzWillChangedIndex:((_ view:RZSegmentView, _ index:Int) -> Bool)?
    /// 索引已经改变 return false时，不改变
    var rzDidChangedIndex:((_ view:RZSegmentView, _ index:Int) -> ())?
    
    // segment的collectionView (初始化的时候隐藏，reloaddata之后显示，避免刚刚出现的时候跳动)
    var collectionView: UICollectionView!
    // 自定义cell
    var rzCustomCell:((_ collectionView: UICollectionView, _ indexPath:IndexPath) -> RZSegmentItemViewCell)?
    // 选中时，添加一个背景图层
    private var itemBackgroundView = UIView().then {
        $0.isHidden = true
        $0.layer.masksToBounds = true
    }
    // 底部线条
    private var bottomLine = UIView().then {
        $0.isHidden = true
        $0.layer.masksToBounds = true
    }
   
    override init(frame:CGRect) {
        super.init(frame:frame)
        createUI()
        makeConstraints()
    }
    // 索引
    private var index = 0
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
//MARK:segmentView的内部方法
extension RZSegmentView {
    func createUI() {
        self.initCollectionView()
        collectionView.isHidden = true
        self.addSubview(collectionView)
        collectionView.addSubview(itemBackgroundView)
        collectionView.addSubview(bottomLine)
        self.backgroundColor = .clear
    }
    func makeConstraints() {
   
    }

    func initCollectionView() {
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = rzScrollDirection == .horizontal ? .horizontal : .vertical
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.sectionInset = UIEdgeInsets.zero
        if collectionView == nil {
            collectionView = UICollectionView.init(frame: self.bounds, collectionViewLayout: layout)
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(RZSegmentItemViewCell.self, forCellWithReuseIdentifier: "cell")
            collectionView.backgroundColor = .clear
            collectionView.showsVerticalScrollIndicator = false
            collectionView.showsHorizontalScrollIndicator = false
        } else {
            collectionView.setCollectionViewLayout(layout, animated: true)
        }
    }
    
    // 刷新额外的UI
    func updateExView(_ animation:Bool) {
        updateBottomLine(animation)
        updateSelectedItemBackgroundView(animation)
    }
    // 刷新底部线条
    func updateBottomLine(_ animation:Bool) {
        let indexPath = IndexPath.init(row: self.index ,section: 0)
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? RZSegmentItemViewCell else {
            return
        }
        cell.layoutIfNeeded()
        var bgColor : UIColor?
        var width: CGFloat = 0
        var height: CGFloat = 0
        var bottomMargin : CGFloat = 0
        switch rzBottomLineStyle {
        case .none:
            self.bottomLine.isHidden = true
        case .auto(let leading, let h, let bottom, let color):
            bgColor = color
            width = cell.textLabel.frame.size.width + 2 * leading
            height = h
            bottomMargin = bottom
            break
        case .lock(let w, let h, let bottom, let color):
            bgColor = color
            width = w
            height = h
            bottomMargin = bottom
            break
        case .custom(let value):
            value(self, cell, bottomLine)
            return
        }
        bottomLine.backgroundColor = bgColor
        let cellFrame = cell.frame
        var lineFrame = cellFrame
        lineFrame.size.width = min(width, cell.frame.size.width)
        lineFrame.size.height = height
        lineFrame.origin.x = cellFrame.origin.x + cell.textLabel.frame.origin.x - (lineFrame.size.width - cell.textLabel.frame.size.width) / 2.0   //     max(0, (cellFrame.size.width - lineFrame.size.width)/2.0)
        lineFrame.origin.y = cellFrame.maxY - bottomMargin - height
                
        let timer = animation ? rzAnimationTimer : 0
        UIView.animate(withDuration: timer, delay: 0, options: .curveEaseInOut, animations: {
            self.bottomLine.frame = lineFrame
            self.bottomLine.layer.cornerRadius = height / 2.0
        }) { (_) in
            self.bottomLine.isHidden = false
        }
    }
    // 刷新选中的item的背景
    func updateSelectedItemBackgroundView(_ animation:Bool) {
        let indexPath = IndexPath.init(row: self.index ,section: 0)
        guard let cell = self.collectionView.cellForItem(at: indexPath) as? RZSegmentItemViewCell  else {
            return
        }
        cell.contentView.layoutIfNeeded()
        collectionView.sendSubviewToBack(self.itemBackgroundView)
        var bgFrame = cell.frame
        var radius : CGFloat = 0
        var bgColor : UIColor = .clear
        switch rzItemBackgroundViewStyle {
        case .none:
            self.itemBackgroundView.isHidden = true
            return
        case .full(let r, let c):
            radius = r
            bgColor = c
        case .fullEdge(let edge, let r, let c):
            bgFrame.origin.x += edge.left
            bgFrame.origin.y += edge.top
            bgFrame.size.width = cell.frame.size.width - edge.left - edge.right
            bgFrame.size.height = cell.frame.size.height - edge.top - edge.bottom
            radius = r
            bgColor = c
        case .textEdge(let edge, let r, let c):
            bgFrame.origin.x = cell.frame.origin.x + cell.textLabel.frame.origin.x - edge.left
            bgFrame.origin.y = cell.frame.origin.y + cell.textLabel.frame.origin.y - edge.top
            bgFrame.size.width = cell.textLabel.frame.size.width + edge.left + edge.right
            bgFrame.size.height = cell.textLabel.frame.size.height + edge.top + edge.bottom
            radius = r
            bgColor = c
        case .custom(let value):
            value(self, cell, itemBackgroundView)
            return
        }
        let timer = animation ? rzAnimationTimer : 0
        UIView.animate(withDuration: timer, delay: 0, options: .curveEaseInOut, animations: {
            self.itemBackgroundView.frame = bgFrame
            self.itemBackgroundView.backgroundColor = bgColor
            self.itemBackgroundView.layer.cornerRadius = radius
        }) { (_) in
            self.itemBackgroundView.isHidden = false
        }
    }
    
    func collectionViewContentSize() -> CGSize {
        var contentSize = CGSize.zero
        let layout = UICollectionViewLayout.init()
        for (index, _) in rzItems.enumerated() {
            let size = self.collectionView(self.collectionView, layout: layout, sizeForItemAt: IndexPath.init(row: index, section: 0))
            if self.rzScrollDirection == .horizontal {
                contentSize.width += size.width
                contentSize.height = size.height
            } else {
                contentSize.width = size.width
                contentSize.height += size.height
            }
        }
        return contentSize
    }
    
    func updateCollectionViewFrame() {
        let collectionViewContentSize = self.collectionViewContentSize()
        if self.rzScrollDirection == .horizontal {
            var size : CGSize = .zero
            if collectionViewContentSize.width > self.bounds.size.width {
                size = self.bounds.size
            } else {
                size = collectionViewContentSize
            }
            switch self.rzStyle {
            case .auto:
                self.collectionView.frame = .init(x: (self.bounds.size.width - size.width) / 2.0, y: (self.bounds.size.height - size.height) / 2.0, width: size.width, height: size.height)
            case .left:
                self.collectionView.frame = .init(x: 0, y: 0, width: size.width, height: size.height)
            case .right:
                self.collectionView.frame = .init(x: self.bounds.size.width - size.width, y: 0, width: size.width, height: size.height)
            default:
                break
            }
        } else {
            var size : CGSize = .zero
            if collectionViewContentSize.height > self.bounds.size.height {
                size = self.bounds.size
            } else {
                size = collectionViewContentSize
            }
            switch self.rzStyle {
            case .auto:
                self.collectionView.frame = .init(x: (self.bounds.size.width - size.width) / 2.0, y: max(0, (self.bounds.size.height - size.height) / 2.0), width: size.width, height: size.height)
            case .top:
                self.collectionView.frame = .init(x: (self.bounds.size.width - size.width)/2.0, y: 0, width: size.width, height: size.height)
            case .bottom:
                self.collectionView.frame = .init(x: (self.bounds.size.width - size.width)/2.0, y: self.bounds.size.height - size.height, width: size.width, height: size.height)
            default:
                break
            }
        }
        self.collectionView.isHidden = false
    }
    
}
//MARK:segmentView的代理方法
extension RZSegmentView : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.rzItems.count
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch rzItemSize {
        case .auto(let leadingMargin, let height):
            let attrText = self.rzItems[indexPath.row].attributedText
            var width : CGFloat = 0
            if self.rzScrollDirection == .vertical {
                width = self.bounds.size.width
            } else if attrText != nil {
                width = (attrText!.sizeWithConditionHeight(height: Float(height))).width + 2 * leadingMargin
            } else {
                let text = self.rzItems[indexPath.row].text
                if text != nil {
                    width = self.rzDefaultItemStyle.font.pointSize * CGFloat(text!.count) + 2 * leadingMargin
                }
            }
            return CGSize.init(width: width, height: height)
        case .lock(let w, let h):
            return CGSize.init(width: w, height: h)
        case .custom(let value):
            return value(self)
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let custom = self.rzCustomCell?(collectionView, indexPath)
        if custom != nil {
            return custom!
        }
        let cell : RZSegmentItemViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as! RZSegmentItemViewCell
        let selected = self.index == indexPath.row
        let configure :RZSegmentItemStyle = selected ? self.rzHightLightItemStyle : self.rzDefaultItemStyle
        cell.rzTextAlign(self.rzTextAlign)
        let item = self.rzItems[indexPath.row]
        cell.setData(configure: configure, content: item, selected: selected)
        cell.setSeparateLineConfigure(type: self.rzSeparateLineStyle)
        cell.separateLine.isHidden = (indexPath.row >= self.rzItems.count - 1)
        return cell
    }
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.setCurrentIndex(index: indexPath.row, animation: true)
    }
}
//MARK:segmentView对外的公用方法
extension RZSegmentView {
    /// 改变当前选择的索引
    /// - Parameters:
    ///   - notice: 是否去通知回调，以方便在回调中进行处理索引改变事件
    open func setCurrentIndex(index:Int, animation:Bool, notice:Bool = true) {
        if index >= self.rzItems.count {
            self.collectionView.reloadData()
            return
        }
        // 如果不允许修改，则不作处理
        if notice {
            let allow = self.rzWillChangedIndex?(self, index) ?? true
            if !allow {
                return
            }
        }
        self.index = index
        self.reloadData()
        if notice {
            self.rzDidChangedIndex?(self, index)
        }
    }
    open func reloadData(animation:Bool = true) {
        if self.index >= self.rzItems.count {
            self.setCurrentIndex(index: 0, animation: true)
            return
        }
        self.isUserInteractionEnabled = false
        self.updateCollectionViewFrame()
        self.collectionView.reloadData()
        if self.rzItems.count > 0 {
            self.collectionView.scrollToItem(at: IndexPath.init(row: index, section: 0), at: (self.rzScrollDirection == .horizontal ? .centeredHorizontally : .centeredVertically), animated: animation)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.updateExView(animation)
            self.isUserInteractionEnabled = true
        }
    }
}

//MARK: segment view的单独一个item的视图
open class RZSegmentItemViewCell : UICollectionViewCell {
    open var textLabel:UILabel = UILabel().then {
        $0.numberOfLines = 0
        $0.textColor = UIColor.init(white: 0.1, alpha: 0.7)
        $0.font = UIFont.systemFont(ofSize: 14)
    }
    open var badgeLabel:UILabel = UILabel().then {
        $0.numberOfLines = 1
        $0.textColor = UIColor.red
        $0.font = UIFont.systemFont(ofSize: 7)
        $0.layer.masksToBounds = true
        $0.textAlignment = .center
        $0.baselineAdjustment = .alignCenters
    }
    open var separateLine = UIView().then {
        $0.layer.masksToBounds = true
    }
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.contentView.addSubview(textLabel)
        self.contentView.addSubview(badgeLabel)
        self.contentView.addSubview(separateLine)
        textLabel.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
        }
        badgeLabel.snp.makeConstraints { (make) in
            make.centerX.equalTo(textLabel.snp.right)
            make.centerY.equalTo(textLabel.snp.top)
            make.height.equalTo(10)
        }
        separateLine.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize.zero)
            make.centerY.equalToSuperview()
            make.centerX.equalTo(self.contentView.snp.right)
        }
    }
    open func setSeparateLineConfigure(type:RZSegmentView.RZSegmentSeparateLineStyle) {
        switch type {
        case .none:
            return
        case .lock(let size, let radius, let color):
            separateLine.snp.updateConstraints { (make) in
                make.size.equalTo(size)
            }
            separateLine.layer.cornerRadius = radius
            separateLine.backgroundColor = color
        }
    }
    
    open func setData(configure:RZSegmentView.RZSegmentItemStyle, content:RZSegmentView.RZSegmentItemContent, selected:Bool) {
        // 背景
        self.contentView.backgroundColor = configure.bgColor
        // 标题
        if selected && content.hightLightAttributedText != nil {
            self.textLabel.attributedText = content.hightLightAttributedText
        } else if content.attributedText != nil {
            self.textLabel.attributedText = content.attributedText
        } else if content.text != nil {
            self.textLabel.rz_colorfulConfer { (confer) in
                confer.text(content.text)?.textColor(configure.textColor).font(configure.font)
            }
        } else {
            self.textLabel.text = nil
        }
        // 小红点
        if selected && content.hightLightAttributedBadge != nil {
            self.badgeLabel.attributedText = content.hightLightAttributedBadge
        } else if content.attributedBadge != nil {
            self.badgeLabel.attributedText = content.attributedBadge
        } else if content.badge != nil {
            self.badgeLabel.rz_colorfulConfer { (confer) in
                confer.text("1")?.textColor(.clear).font(UIFont.systemFont(ofSize: configure.badgeFont.pointSize)) // 占位用的
                confer.text(content.badge)?.textColor(configure.badgeTextColor).font(configure.badgeFont)
                confer.text("1")?.textColor(.clear).font(UIFont.systemFont(ofSize: configure.badgeFont.pointSize)) // 占位用的
            }
        } else {
            self.badgeLabel.text = nil
        }
        self.badgeLabel.backgroundColor = configure.badgeBgColor
        self.badgeLabel.layer.cornerRadius = configure.badgeFont.pointSize / 2.0 - 1
    }
    open func rzTextAlign(_ a:RZSegmentView.RZSegmentItemTextAlignStyle) {
        switch a {
        case .center:
            textLabel.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
            }
        case .left(let leftMargin):
            textLabel.snp.remakeConstraints { (make) in
                make.left.equalToSuperview().offset(leftMargin)
                make.centerY.equalToSuperview()
            }
        case .right(let rightMargin):
            textLabel.snp.remakeConstraints { (make) in
                make.right.equalToSuperview().offset(-rightMargin)
                make.centerY.equalToSuperview()
            }
        }
    }
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
//MARK:segment View 的初始化的一些配置方法
public extension RZSegmentView {
    // segmentView里的布局样式 如果内容不能铺满，则按照设置，居中、居左、居上、居下
    enum RZSegmentViewStyle {
        // 自动 （当内容较少时，collectionView居中） 默认
        case auto
        // 强制居左 （当内容较少时，collectionView居左）水平滚动有效
        case left
        // 强制居右（当内容较少时，collectionView居右）水平滚动有效
        case right
        // 顶部 垂直滚动有效
        case top
        // 底部 垂直滚动有效
        case bottom
    }
    // 控件是水平还是垂直的
    enum RZScrollDirection {
        /// 水平
        case horizontal
        /// 垂直
        case vertical
    }
    // segment 的item的size配置
    enum RZSegmentItemSize {
        // 自动 （文字宽度+ 头尾间距）
        case auto(leadingMargin:CGFloat, height:CGFloat)
        // 固定
        case lock(width:CGFloat, height:CGFloat)
        // 自定义，自己根据内容进行配置
        case custom(value:((RZSegmentView) -> CGSize))
    }
    /// 底部线条
    enum RZSegmentBottomScrollLineStyle {
        // 不显示
        case none
        // 自动（根据内容，自动大小） = 内容显示的长度 bottomMargin：距离底部距离
        case auto(leadingMargin:CGFloat, height:CGFloat, bottomMargin:CGFloat, color:UIColor)
        // 固定大小
        case lock(width:CGFloat, height:CGFloat, bottomMargin:CGFloat, color:UIColor)
        // 可以自定义，reference 为当前选择的cell的view，当做参照物，需要修改line的各种属性（位置）
        case custom(value:((_ target:RZSegmentView, _ reference:RZSegmentItemViewCell, _ line:UIView) -> ()))
        
    }
    /// 选择的cell 的背景样式
    enum RZSegmentScrollBackgroundStyle {
        // 不显示
        case none
        // 整个cell铺满 圆角
        case full(radius:CGFloat, color:UIColor)
        // 距整个cell有一个边距
        case fullEdge(edge:UIEdgeInsets, radius:CGFloat, color:UIColor)
        // 距整个文本框有一个边距
        case textEdge(edge:UIEdgeInsets, radius:CGFloat, color:UIColor)
        // 可以自定义，reference 为当前选择的cell的view，当做参照物，需要修改bg的各种属性（位置） 初始化的时候 itemBackgroundView是隐藏的，所以在动画完成之后，需要显示设置bg.isHidden = false
        case custom(value:((_ target:RZSegmentView, _ reference:RZSegmentItemViewCell, _ bg:UIView) -> ()))
    }
    // 分割线的样式
    enum RZSegmentSeparateLineStyle {
        case none // 不显示
        // 固定大小
        case lock(size:CGSize, radius:CGFloat, color:UIColor)
    }
    // 文字的对齐方式
    enum RZSegmentItemTextAlignStyle {
        // 居中 默认
        case center
        // 居左 (label距离左侧距离)
        case left(leftMargin:Float)
        // 居右，(label距离右侧距离)
        case right(righMargin:Float)
    }
    //MARK: 外观配置
    struct RZSegmentItemStyle {
        // 常规文字
        var font = UIFont.systemFont(ofSize: 14)
        var textColor = UIColor.init(white: 0.1, alpha: 0.7)
        
        /// 右上角小红点
        var badgeFont = UIFont.systemFont(ofSize: 11)
        var badgeTextColor = UIColor.white
        var badgeBgColor = UIColor.red
        
        /// 背景颜色
        var bgColor = UIColor.clear
    }
    //MARK:segment Item的内容
    struct RZSegmentItemContent {
        var text : String?
        var badge : String?
        // 如果设置这个，则badge无效 富文本的优先级高于文本
        var attributedBadge : NSAttributedString?
          // 高亮的富文本
        var hightLightAttributedBadge : NSAttributedString?
        
        // 如果设置这个，则text无效
        var attributedText : NSAttributedString?
        // 高亮的富文本
        var hightLightAttributedText: NSAttributedString?
        // 设置tag，可以做其他一些区分的事
        var tag = 0
    }
}
