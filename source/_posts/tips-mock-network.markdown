---
layout: post
title: "Swift简化网络层开发流程"
date: 2016-05-23 09:45:26 +0800
comments: true
keywords: 模拟网络,网络层,AFNetworking
categories: experience
---

## 一、解决问题

在开发过程中，iOS网络层开发一直受制于Server端的进度，iOS网络层的进度又影响到整个应用的功能集成

{% img /images/article/Swift简化网络层开发流程/image_0.png %}

<br>

为了提升整体开发效率，我们引入**模拟网络请求**，使得整体开发进度不再受制于Server的进度

{% img /images/article/Swift简化网络层开发流程/image_1.png %}

<!-- more -->

## 二、功能实现

### 2.1模拟网络代码


```ruby
//是否模拟开关
let ILMOCK_OPEN: Bool = true

class ILMock: NSObject {
    
    
    class func delayRun<T : NSObject>(obj: T, callback: (instance: T) -> ()) {
        let obj = self.inflateObject(obj)
        self.delayRun { 
            callback(instance: obj)
        }
    }
    
    
    class func delayRunAndCopy<T : NSObject>(obj: T, callback: (array: [T]) -> ()) {
        let ret = self.inflateAndCopy(obj)
        self.delayRun { 
            callback(array: ret)
        }
    }
    
    class func delayRun(callback: () -> ()) {
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(UInt64(2) * NSEC_PER_SEC))
        dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
            callback()
        }
        
    }
    
    
    private class func inflateAndCopy<T : NSObject>(obj: T) -> [T] {
        var ret = [T]()
        for _ in 0 ... 10 {
            let obj = obj.classForCoder.alloc()
            let item = self.inflateObject(obj as! T)
            ret.append(item)
        }
        return ret
    }
    
    
    private class func inflateObject<T : NSObject>(obj: T) -> T {
        let mirror = Mirror(reflecting: obj)
        for i in mirror.children.startIndex ..< mirror.children.endIndex {
            let key = mirror.children[i].label!
            obj.setValue(key, forKey: key)
        }
        return  obj
    }

}

```

### 2.2具体使用
例如：模拟登陆请求

``` ruby
    class func requestLogin(userName: String!, password: String!,
        	successCallBack:((userModel:ILUserModel!)->(Void)),
        	failedCallBack:(state: HTTPResultState)->(Void)){
        
            if ILMOCK_OPEN {
                ILMock.delayRun(ILUserModel(), callback: { (userModel) in
                    successCallBack(userModel: userModel)
                })
                return
            }
            
            //具体实现逻辑...
    }
```

模拟获取用户列表

``` ruby
    class func requestUserList(userId: String,
            successCallBack:((userModels:[ILUserModel]!)->(Void)),
            failedCallBack:(state: HTTPResultState)->(Void)) {
        
        if ILMOCK_OPEN {
            ILMock.delayRunAndCopy(ILUserModel(), callback: { (userModels) in
                successCallBack(userModels: userModels)
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
