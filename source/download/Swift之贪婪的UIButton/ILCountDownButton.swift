//
//  ILCountDownButton.swift
//  ILButton
//
//  Created by Mac on 15/7/20.
//  Copyright © 2015年 Mac. All rights reserved.
//

import UIKit

class ILCountDownButton: UIButton {
    
    
    private var timer: Timer!
    private var countDown = 0
    var timeWait = 60
    //回调接口
    var restartCallback: (() -> (Bool))?
    //动态计数时，加在数字前面的字符串
    var countFrontString: String = ""
    //动态计数时，加在数字后面的字符串
    var countRearString: String = ""


    convenience init(count: Int) {
        self.init(frame: CGRect.zero)
        self.timeWait = count
        self.doInit()
    }
    
    private func doInit() {
        self.setTitleColor(UIColor.white, for: .normal)
        self.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        super.addTarget(self, action: #selector(ILCountDownButton.restart), for: .touchUpInside)
    }
    
    
    override func awakeFromNib() {
        self.doInit()
    }
    
    //开始倒计时
    func restart() {
        let validate = self.restartCallback == nil ? false : self.restartCallback!()
        if !validate {
            return
        }
        self.countDown = self.timeWait
        self.heartbeat()
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ILCountDownButton.heartbeat), userInfo: nil, repeats: true)
        self.isEnabled = false
        
    }
    
    //设置可点击时标题
    func setTitleForRestart(title: String) {
        super.setTitle(title, for: .normal)
    }
    
    //设置可点击时背景图片
    func setBackgroundImageForRestart(image: UIImage) {
        super.setBackgroundImage(image, for: .normal)
        self.setBackgroundImageForHighlighted(image: image)
    }
    
    //设置计数背景图片
    func setBackgroundImageForCount(image: UIImage) {
        super.setBackgroundImage(image, for: .disabled)
    }
    
    
//////////////////////////////////////////////////////////////////////////
    
    override func setTitle(_ title: String?, for state: UIControlState) {
//        assertionFailure("please use setTitleForRestart")
    }
    
    override func addTarget(_ target: Any?, action: Selector, for controlEvents: UIControlEvents) {
//        assertionFailure("please use buttonClickedCallback")

    }
    
    
    private func setBackgroundImageForHighlighted(image: UIImage) {
        super.setBackgroundImage(image, for: .highlighted)
        
    }
    
    
    @objc private func heartbeat() {
        self.countDown -= 1
        if self.countDown == 0 {
            self.normalState()
            return
        }
        let countDwonStr = self.countFrontString + String(self.countDown) + self.countRearString
        super.setTitle(countDwonStr, for: .disabled)
    }
    
    func normalState() {
        if self.timer == nil {
            return
        }
        self.timer.invalidate()
        self.timer = nil
        self.isEnabled = true
    }
    

}
