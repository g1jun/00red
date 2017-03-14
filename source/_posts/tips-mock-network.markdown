---
layout: post
title: "Swift简化网络层开发流程"
date: 2017-03-08 09:45:26 +0800
comments: true
keywords: 模拟网络,网络层,AFNetworking
categories: experience
---

## 一、解决问题

####本文已经更新到Swift3.0语法

在开发过程中，iOS网络层开发一直受制于Server端的进度，iOS网络层的进度又影响到整个应用的功能集成

{% img /images/article/Swift简化网络层开发流程/image_0.png %}

<br>

为了提升整体开发效率，我们引入**模拟网络请求**，使得整体开发进度不再受制于Server的进度

{% img /images/article/Swift简化网络层开发流程/image_1.png %}

<!-- more -->

## 二、功能实现

### 2.1模拟网络代码


``` swift
//是否模拟开关
let ILMOCK_OPEN: Bool = true

class ILMock: NSObject {


class func delayRun<T : NSObject>(_ obj: T, callback: @escaping (_ instance: T) -> ()) {
let obj = self.inflateObject(obj)
self.delayRun { 
callback(obj)
}
}


class func delayRunAndCopy<T : NSObject>(_ obj: T, callback: @escaping (_ array: [T]) -> ()) {
let ret = self.inflateAndCopy(obj)
self.delayRun { 
callback(ret)
}
}

class func delayRun(_ callback: @escaping () -> ()) {

let time = DispatchTime.now() + Double(Int64(UInt64(2) * NSEC_PER_SEC)) / Double(NSEC_PER_SEC)
DispatchQueue.main.asyncAfter(deadline: time) { () -> Void in
callback()
}

}


fileprivate class func inflateAndCopy<T : NSObject>(_ obj: T) -> [T] {
var ret = [T]()
for _ in 0 ... 10 {
let obj = obj.classForCoder.alloc()
let item = self.inflateObject(obj as! T)
ret.append(item)
}
return ret
}


fileprivate class func inflateObject<T : NSObject>(_ obj: T) -> T {
let children = Mirror(reflecting: obj).children

for (_, element) in children.enumerated() {
let key = element.label!
obj.setValue(key, forKey: key)
}
return  obj
}





}


```

### 2.2具体使用
例如：模拟登陆请求

``` swift
    class func requestLogin(userName: String!, password: String!,
                            successCallBack:@escaping ((_ userModel: ILUserModel?)->(Void)),
                            failedCallBack:(_ state: HTTPResultState)->(Void)){
        
        if ILMOCK_OPEN {
            ILMock.delayRun(ILUserModel()) { (userModel) in
                successCallBack(userModel)
            }
            return
        }
        
        //具体实现逻辑...
    }
```

模拟获取用户列表

``` swift
    class func requestUserList(userId: String,
                               successCallBack:@escaping ((_ userModels:[ILUserModel]?)->(Void)),
                               failedCallBack:(_ state: HTTPResultState)->(Void)) {
        
        if ILMOCK_OPEN {
            ILMock.delayRunAndCopy(ILUserModel(), callback: { (userModels) in
                successCallBack(userModels)
            })
            return
        }
        
        //实现获取用户列表的逻辑...
    }
    
```

### 2.3使用说明

**模拟网络请求**的逻辑非常简单，根据要返回的数据类型，先填充数据，填充逻辑为**字段值=[字段名]**，并在延时2秒后将数据返回。

#### Tips
网络接口定义各式各样，这里只模拟成功的情况，可根据需求，实现随机出现错误。我们的iOS网络层接口为避免出现类型转换引起的Crash问题，将所有的Model字段全定义为NSString/String类型，如果您使用了非String类型，需要对**inflateObject**方法进行扩展
