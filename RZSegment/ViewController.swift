//
//  ViewController.swift
//  RZSegment
//
//  Created by ruozui on 2020/4/30.
//  Copyright © 2020 rztime. All rights reserved.
//

import UIKit
@_exported import SnapKit
@_exported import RZColorfulSwift
@_exported import Then

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        let seg =  RZSegmentView()
//
//        self.view.addSubview(seg)
//        seg.snp.makeConstraints { (make) in
//            make.center.width.equalToSuperview()
//            make.height.equalTo(44)
//        }
//        seg.backgroundColor = UIColor.black
//        seg.rzDefaultItemStyle = .init(font: .systemFont(ofSize: 14), textColor: .gray)
//        seg.rzHightLightItemStyle = .init(font: .systemFont(ofSize: 16), textColor: .white)
//        seg.rzDidChangedIndex = { (v , index) in
//            self.navigationController?.pushViewController(IndexDemoViewController(), animated: true)
//        }
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            seg.rzItems = [
//                 .init(text:"标题1"),
//                 .init(text:"标题2"),
//                 .init(text:"标题3"),
//             ]
//            seg.reloadData(animation: true)
        segmentOne()
        segmentTwo()
        segmentThree()
        segmentFour()
//        }
    }
    
    // 常用，只有常态文字和高亮（选中）状态文字
    func segmentOne() {
        let segment = RZSegmentView.init(frame: .init(x: 0, y: 100, width: self.view.frame.size.width, height: 44))
        self.view.addSubview(segment)
        
        segment.rzDefaultItemStyle = .init(font: .systemFont(ofSize: 14), textColor: .gray)
        segment.rzHightLightItemStyle = .init(font: .systemFont(ofSize: 16), textColor: .red)
    
        segment.rzDidChangedIndex = { (seg, index) in
            print("点击：\(index)")
            self.navigationController?.pushViewController(IndexDemoViewController(), animated: true)
        }
        segment.rzItems = [
            .init(text: "标题1"),
            .init(text: "标题2"),
            .init(text: "标题3"),
            .init(text: "标题4"),
            .init(text: "标题5"),
            .init(text: "标题6"),
            .init(text: "标题7"),
            .init(text: "标题8"),
            .init(text: "标题9"),
        ]
        segment.reloadData()
    }
    // 加底部选中的文本的底部线
    func segmentTwo() {
        let segment = RZSegmentView.init(frame: .init(x: 0, y: 160, width: self.view.frame.size.width, height: 44))
        self.view.addSubview(segment)
        
        segment.rzDefaultItemStyle = .init(font: .systemFont(ofSize: 14), textColor: .gray)
        segment.rzHightLightItemStyle = .init(font: .systemFont(ofSize: 16), textColor: .red)

        segment.rzDidChangedIndex = { (seg, index) in
            print("点击：\(index)")
        }
        
        segment.rzBottomLineStyle = .auto(leadingMargin: 10, height: 3, bottomMargin: 3, color: .red)
        
        // 默认样式为auto，当标题显示的文本宽度不能超过view本身的宽度，则居中显示
//        segment.rzStyle = .auto
        segment.rzItems = [
            .init(text: "标题", badge: "3"),
            .init(text: "标题"),
            .init(text: "标题"),
        ]
        segment.reloadData()
    }
    
    func segmentThree() {
        let segment = RZSegmentView.init(frame: .init(x: 0, y: 220, width: self.view.frame.size.width, height: 44))
        self.view.addSubview(segment)
        
        segment.rzDefaultItemStyle = .init(font: .systemFont(ofSize: 14), textColor: .gray)
        segment.rzHightLightItemStyle = .init(font: .systemFont(ofSize: 16), textColor: .red)
  
        segment.rzDidChangedIndex = { (seg, index) in
            print("点击：\(index)")
        }
        
        segment.rzBottomLineStyle = .auto(leadingMargin: 10, height: 3, bottomMargin: 3, color: .red)
        segment.rzItemBackgroundViewStyle = .textEdge(edge: .init(top: 2, left: 10, bottom: 2, right: 10), radius: 3, color:.blue)
        
        segment.rzStyle = .left
        segment.rzItems = [
            .init(text: "标题", badge: "3"),
            .init(text: "标题"),
            .init(text: "标题"),
        ]
        segment.reloadData()
    }
    func segmentFour() {
        let segment = RZSegmentView.init(frame: .init(x: 0, y: 280, width: self.view.frame.size.width, height: 44))
        self.view.addSubview(segment)
        
        segment.rzDefaultItemStyle = .init(font: .systemFont(ofSize: 14), textColor: .gray)
        segment.rzHightLightItemStyle = .init(font: .systemFont(ofSize: 16), textColor: .red)
 
        segment.rzDidChangedIndex = { (seg, index) in
            print("点击：\(index)")
        }
        
        segment.rzBottomLineStyle = .auto(leadingMargin: 10, height: 3, bottomMargin: 3, color: .red) 
        
        // 支持标题用富文本，显示图片文字
        let attr1 = NSAttributedString.rz_colorfulConfer { (confer) in
            confer.text("标题")?.font(.systemFont(ofSize: 14)).textColor(.gray)
            confer.image(UIImage.init(named: "image"))?.size(CGSize.init(width: 16, height: 16), align: .center, font: .systemFont(ofSize: 14))
            confer.text("图片")?.font(.systemFont(ofSize: 14)).textColor(.gray)
        }
        let attr2 = NSAttributedString.rz_colorfulConfer { (confer) in
            confer.text("标题")?.font(.systemFont(ofSize: 16)).textColor(.red)
            confer.image(UIImage.init(named: "image"))?.size(CGSize.init(width: 18, height: 18), align: .center, font: .systemFont(ofSize: 16))
            confer.text("图片")?.font(.systemFont(ofSize: 16)).textColor(.red)
        }
        
        segment.rzItems = [
            .init(text: "标题", badge: "3"),
            .init(text: "标题"),
            .init(text: "标题"),
            .init(attributedText: attr1, hightLightAttributedText: attr2)
        ]
        segment.reloadData()
    }
    

}

