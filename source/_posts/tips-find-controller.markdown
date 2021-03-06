---
layout: post
title: "Swift快速查找Controller"
date: 2015-05-23 14:27:10 +0800
comments: true
keywords: 事件响应,界面跳转,查找UIViewController
categories: experience
---

## 本文已经更新到Swift3.0语法

## 一、解决的问题
在UIView中快速查找对应UIViewController、UINavigationController或者指定控制器的方法，原理根据事件的响应链，向上查找。

## 二、具体实现代码

``` swift

extension UIView {
    
    
    func findController() -> UIViewController! {
        return self.findControllerWithClass(UIViewController.self)
    }
    
    func findNavigator() -> UINavigationController! {
        return self.findControllerWithClass(UINavigationController.self)
    }
    
    func findControllerWithClass<T>(_ clzz: AnyClass) -> T? {
        var responder = self.next
        while(responder != nil) {
            if (responder!.isKind(of: clzz)) {
                return responder as? T
            }
            responder = responder?.next
        }
        
        return nil
    }
    
    
}


```

<!-- more -->





