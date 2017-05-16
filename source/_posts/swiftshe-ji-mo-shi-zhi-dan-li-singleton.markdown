---
layout: post
title: "Swift设计模式之单例(Singleton)"
date: 2014-07-30 21:12:42 +0800
comments: true
keywords: Swift,一叶博客,Swift单例,Swift单态,Swift设计模式,一叶
categories: experience
---

## 本文已经将语法更新到Swift 3.0

## 一、意图
保证一个类有且仅有一个实例，并提供一个访问它的全局访问点

## 二、使用场景
1.使用场景
	-	当类只能有一个实例而且客户可以从一个众所周知的访问点访问它时
	-	当这个唯一实例应该是通过子类化可扩展的，并且客户应该无需更改代码就能使用一个扩展的实例时。
	

2.实现单例的三个重要步骤
	-	私有化构造方法
	-	使用一个静态变量保存实例的引用
	-	提供一个静态访问方法

<!-- more -->

## 三、Swift下的实现办法

``` swift 延迟加载实现安全单例模式
public class Singleton {
    
    //通过关键字static来保存实例引用
    private static let instance = Singleton()
    
    //私有化构造方法
    private init() {
    }
    
    //提供静态访问方法
    public static var shared: Singleton {
        return self.instance
    }
    
}
```

Swift语言已经支持线程安全的全局属性、静态属性的lazy初使化，即上面的实现为懒汉单例模式

运行如下代码进行简单的测试：

``` swift 测试代码
import XCTest

class SwiftSingletonTest: XCTestCase {
    
    func testSingleton() {
        let singleton1 = Singleton.shared
        let singleton2 = Singleton.shared
        assert(singleton1 === singleton2, "pass")
    }
}
```

运行结果，左侧绿色对号，代表测试通过
{% img /images/article/Swift设计模式之单例(Singleton)/singleton_test.png %}

其中`===`在Swift中代表“等价于”，比较的是两个变量或者常量的引用地址，只能用于class的比较
 




## 四、错误的实现方式
在Swift中类与结构体的一个非常明显的区别

	类：传引用
	结构体：传值

结构体来实现单例模式，会造成内存中有多个拷贝，测试代码如下：

``` swift 不正确的单例实现方式
struct SwiftSingleton {
    var name: String = "1"
    static let shared = SwiftSingleton()
}


var single1 = SwiftSingleton.shared
var single2 = SwiftSingleton.shared

single2.name = "2"

print("------->\(single1.name)")
print("------->\(single2.name)")

```

打印结果如下：
```
------->1
------->2
Program ended with exit code: 0
```

从上面的结果也可以看出来，通过结构体的方法实现的单例模式，我们不能保证仅有一个实例。
