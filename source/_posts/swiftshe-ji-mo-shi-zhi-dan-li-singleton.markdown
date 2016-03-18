---
layout: post
title: "Swift设计模式之单例(Singleton)"
date: 2014-07-30 21:12:42 +0800
comments: true
keywords: Swift,一叶博客,Swift单例,Swift单态,Swift设计模式,一叶
categories: experience
---
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
Swift变化很快，目前已经更新到最新的2.0的语法，也将语言中的关键字统一，以下列出区另，请根据具体的Xcode版本，选择实现方式

### Swift1.0实现方式
在Swift1.0中，类只支持静态方法，不支持静态全局变量，结构体静态方法及属性都支持，而且：

	1.类：静态方法只能使用class关键字
	2.结构体：静态方法及全局变量只能使用static关键字

类及结构体有很大的区别，类的**"="**关键字为传引用，结构体的**"="**关键字为传值，在Swift1.0中单独使用类或者结构体都不能实现单利，单例本身通过类来实现，唯一实例的保存通过结构体来保存，代码如下：

``` ruby  单例GCD实现方式
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

运行如下代码进行简单的测试：

``` ruby 单例GCD实现方式测试代码
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
 
在Swift中，static类型变量会自动实现成延迟加载，也可以更简单的实现成如下：

``` ruby 延迟加载实现安全单例模式
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

单例模式分为懒汉模式（延迟加载），饿汉模式，一般为了避免资源浪费，大家普遍实现成懒汉模式，即第一次使用时生成实例。在Swift语言中，针对static关键字做了优化，自动实现了延迟加载，所以上面的代码实现的是懒汉模式而并非饿汉模式

### Swift1.2及2.0实现方式
在Swift1.2及2.0中，对关键字static做了统一支持，即类、结构的方法和属性都可以直接使用static关键字，static关键字的功能进行了扩展，所以Swift1.0的实现方式，依然可以在1.2/2.0中使用。新的实现方式如下：

``` ruby 延迟加载实现安全单例模式
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

#### Tips

注意，在Swift1.0-2.0中关键字**class**只能用于类中的静态方法


## 四、错误的实现方式
在Swift中类与结构体的一个非常明显的区别

	类：传引用
	结构体：传值

结构体来实现单例模式，会造成内存中有多个拷贝，测试代码如下：

``` ruby 不正确的单例实现方式
struct SwiftSingleton {
    var name: String = "1"
    static let shared = SwiftSingleton()
}


var single1 = SwiftSingleton.shared
var single2 = SwiftSingleton.shared

single2.name = "2"

println("------->\(single1.name)")
println("------->\(single2.name)")

```

打印结果如下：
```
------->1
------->2
Program ended with exit code: 0
```

从上面的结果也可以看出来，通过结构体的方法实现的单例模式，我们不能保证仅有一个实例。