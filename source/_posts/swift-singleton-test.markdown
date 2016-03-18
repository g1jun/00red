---
layout: post
title: "Swift百万线程攻破单例（Singleton)模式"
date: 2014-08-07 11:21:38 +0800
comments: true
keywords: Swift,一叶博客,Swift教程,Swift 单例,swift单态,swift线程同步
categories: experience
---

## 一、单例实现
上一篇文章[《Swift设计模式之单例(Singleton)》](http://00red.com/blog/2014/07/30/swiftshe-ji-mo-shi-zhi-dan-li-singleton/)我们给出了单例的设计模式，直接给出了线程安全的实现方法。单例的实现有多种方法，如下面:

``` ruby 单例实现
public class SwiftSingleton {   
    public class var shared: SwiftSingleton {   
    if !Inner.instance {   
        Inner.instance = SwiftSingleton()   
        }   
        return Inner.instance!   
    }
    
    private init() {
    }   
       
    private struct Inner {   
        private static var instance: SwiftSingleton?   
    }   
}

```
<!-- more -->

这段代码的实现，在shared中进行条件判断，如果*Inner.instance*.为空就生成一个实例，这段代码很简单看出当线程同时访问*SwiftSingleton.shared*方法时，会有如下问题出现，线程A判断*Inner.instance*为空，进入if语句后立即切换到线程B执行，线程B也进行判断，由于线程A只是进入了if语句，这行代码
``` ruby
Inner.instance = SwiftSingleton()
```

并没有执行，这时Inner.instance还是为空，纯种B也进行了if语句，这种情况下就会创建多个实例，没有保证实例的唯一性。上面的理论分析基本上任何一篇文章都会讲的，也不能理解，关键问题，如何测试上面的理论是否正确呢？

## 二、线程抢占原理

其实要实现上面的例子不是很难，创建N个线程，让他同时访问SwiftSingleton.shared的方法，然后将所返回值保存最后比较引用。原理很正确，但是创建线程的过程也是极为耗时的，现在的电脑执行速度又非常快，模拟具有不稳定性。如何才能最大程度测试上面的安全性呢？这里我们可以考虑一个现实的问题，假设找1000人通过一段100米的赛道，我们想要更多的人同时去冲刺终点，越多越好。如果你找一个人，告诉他去跑100米，然后再找下一个，这种方法队员同时到达终点的几率很底。怎么办才能让更多的人在同一时刻到达终点呢？问题很简单，让这1000人有一个同一起跑点，让他们都准备好，随着一声令下，一起奔跑。回到技术问题，我们想要更多的线程访问SwiftSingleton.shared方法，只要先准备好所有的线程，然后发一个信号，让他们同时去访问这个方法就可以了。 

{% img /images/article/Swift百万线程攻破单例（Singleton)模式/image0.png %}

实现代码如下：

``` ruby
class SwiftSingletonTest: XCTestCase {   
    let condition = NSCondition()   
    let mainCondition = NSCondition()   
    let singleton: NSMutableArray = NSMutableArray()   
    let threadNumbers = 1000   
    var count = 0   
       
       
    func testSingletonThreadSafe() {   
           
        for index in 0...threadNumbers {   
            NSThread.detachNewThreadSelector("startNewThread", 
            toTarget: self, withObject: nil)   
        }   
        condition.broadcast()   
        mainCondition.lock()   
        mainCondition.wait()   
        mainCondition.unlock()   
        checkOnlyOne()   
    }   
       
    func startNewThread() {   
        condition.lock()   
        condition.wait()   
        condition.unlock()   
        let temp = SwiftSingleton.shared   
        count++   
        singleton.addObject(temp)   
        if count >= threadNumbers {   
            mainCondition.signal()   
        }   
    }   
       
    func checkOnlyOne () {   
        let one = singleton[0] as SwiftSingleton   
        for temp : AnyObject  in singleton {   
            let newTemp = temp as SwiftSingleton   
            if(newTemp !== one) {   
                XCTFail("singleton error!");   
                break;   
            }   
        }   
    }   
   
}
```
这段代码主要使用了NSCondition进行同步，其中NSCondition分为两组，condition主要负责除主线程外的线程，在for语句中会创建并启动N（threadNumbers）个线程，每个线程启动后都会去执行startNewThread方法，执行到语句
``` ruby
	condition.wait()
```
会挂起当前线程，当所有线程都创建并启动完时，主线程会执行
``` ruby
	condition.broadcast()
```
来通知挂起的N个线程继承执行，此时主线程调了
``` ruby
	mainCondition.wait()
```
主线和进入持起状态，此处将主线程挂起是为了在所有线程执行完，依次检查取得引用的唯一性。
``` ruby
	if count >= threadNumbers {   
            mainCondition.signal()   
	} 
```
当所有线程执行完时，通知主线程开始检查引用 ，执行结果如下：
{% img /images/article/Swift百万线程攻破单例（Singleton)模式/image1.png %}
从上面执行结果可以看出，这种单例并不能保证唯一性。上面用到了NSMutableArray类，网上说是线程不安全的，这里用的Swift语言，这么多线程一起操作暂没有发现异常......

## 三、其它测试结果
1、最简单的实现
``` ruby
public class Singleton {
    //提供静态访问方法
    public class var shared: Singleton {
        return Inner.instance
    }
    
    //私有化构造方法
    private init() {
    }
    
    //通过结构体来保存实例引用
    private struct Inner {
        private static let instance = Singleton()
    }
}
```
解释：上述代表也实现了延迟加载技术
``` ruby
private static let instance = Singleton()
```
首次访问Inner.instance时才会创建SwiftSingleton,此处的延迟加载由Swift语言原生提供。
	测试结果：通过
2、使用GCD技术实现的单例模式
``` ruby
public class Singleton {
    
    //提供静态访问方法
    public class var shared: Singleton {
    dispatch_once(&Inner.token) {
        Inner.instance = Singleton()
        }
        return Inner.instance!
    }

    
    //私有化构造方法
    private init() {
        
    }
    
    //通过结构体保存实例的引用
    private struct Inner {
        private static var instance: Singleton?
        private static var token: dispatch_once_t = 0
    }
    
}
```

	测试结果：通过

## 四、测试说明

1、Mac OS线程总量有限制，你可以创建线程，但是最大线程启动数为2048（暂不清楚是否跟硬件有关）。

2、如果遇到测试无响应时，可以尝试重启电脑

