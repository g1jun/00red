---
layout: post
title: Swift高频网络请求利用签名丢弃过时结果
date: 2016-06-16 11:05:17
comments: true
keywords: Swift,高频请求,网络请求,网络请求技巧
categories: experience
---
## 一、解决问题

项目会有分类筛选、搜索关键词推荐等功能，用户操作时可能短时触发多次网络请求，由于是异步，请求结果顺序随机，如下图：

{% img /images/article/Swift高频网络请求利用签名丢弃过时结果/image_0.png %}

<!-- more -->

短时间内连续触发三次请求1、2、3，请求结果返回顺序不确定（上图2、3、1为一种可能情况），本文将给出一种简单准只处理最后一次请求的方法


## 二、处理办法

以搜索关键词功能为例，其网络层接口如下：

``` swift
class ILHTTPRequest {
    
    class func requestRecommendWords(
        inputKeyword: String!,
        successCallBack: (recommendWords: [String]?)->(Void),
        failedCallBack: (failedMessage: String?)->(Void)){
        //具体实现代码省略
    }
    
}
```

处理结果时，需要丢弃前n-1次请求，只处理第n次返回。利用闭包的内存管理特殊性，对每一次请求签名，丢掉过时请求，处理最后一次正确的请求

``` swift
class ILSearchController: UIViewController {
    
    private var signUUID = ""
    
    //省略很多很多处理逻辑...
    
    
    //此方法在搜索文本改变时被调用
    private func textFiledDidChanged(text: String!) {
        if text == nil || text == "" {
            return
        }
        self.startHTTPRequest(text)
    }
    
    private func startHTTPRequest(inputKeyword: String) {
        let uuid = NSUUID().UUIDString
        self.signUUID = uuid
        ILHTTPRequest.requestRecommendWords(inputKeyword, successCallBack: { (recommendWords) -> (Void) in
            //丢掉过时请求,注意下面的uuid，每一次都会不一样
            if self.signUUID != uuid {
                return
            }
            
            //处理逻辑
            
            }) { (failedMessage) -> (Void) in
                //处理逻辑省略
        }
    }
    
    
}

```

在方法**startHTTPRequest**中，使用一个全局属性保存最后一次正确的UUID,并用一个临时变量uuid来标记每一次请求，最后通过两者的比较得出是否丢掉结果。这里使用了一个闭包内存管理小技巧

	1.对于全局属性self.signUUID，闭包使用引用，所以一直是最新的uuid
	2.对于临时局部变量uuid，闭包直接进行copy，每个请求都有不同uuid
	
大家可以参考Objective-c中的block内存管理，原理是相同的。
