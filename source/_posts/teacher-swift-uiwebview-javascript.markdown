---
title: Swift中UIWebView与Javascript交互解决方案
date: 2016-03-22 14:16:44
comments: true
keywords: UIViewView调用js,js调用UIWebView
categories: experience
---

## 内容概要
现阶段App与H5混合编程的需求越来越多，本文(基于iOS7.0及以上)主要给出在Swift项目中，UIWebView与JavaScript的双向交互。包括以下几点：

    1、简单交互,UIWebView的API
    2、频繁复杂交互,JavaScriptCore
    3、中国移动插入JavaScript代码等问题
    
所有示例及代码请在Swift2.2以上环境运行
<!-- more -->

## 一、简单交互,UIWebView的API

对交互要求少且逻辑简单时，可以直接使用UIWebView提供的API。UIWebView可以直接调用JavaScript，并提供重定向拦截功能。

### 1.1Swift调用JavaScript

``` swift
self.webView.stringByEvaluatingJavaScriptFromString("alert()")
```

### 1.2利用重定向让HTML与Swift交互
UIWebView没有提供直接与Swift交互方法，只能通过重定向的拦截来间接的交互，这种间接交互不能将数据返回给HTML中，有些弊端。一般用于简单的交互要求中。示例：打开举报界面(设置UIWebView的代理，并实现代理中的重定向方法)。

``` swift
func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.URL!.absoluteString.hasPrefix("app://") {        
            //解析app://report?userId=0001逻辑
            return false
        }
        return true
    }
```

## 二、频繁复杂交互,JavaScriptCore

随着H5日益增长的业务需求，交互越来越复杂，在第1大节提供的方法不再适用。苹果在iOS7中引入了javaScriptCore框架，用于Swift/OC与JavaScript直接交互。本节主要有以下三个内容：

	2.1 调试工具的使用
	2.2 UIWebView中实现JavaScript与Swift交互
	2.3 优化体验
	
### 2.1调试工具的使用
##### 第一步，打开Safari开发者模式
打开Safari, [偏好设置]->[高级]->选中[在菜单栏中显示“开发”菜单]，如下图：

{% img /images/article/Swift中UIWebView与Javascript的交互/image_0.png %}

设置成功后，就会在Safari的菜单栏中出现**开发**菜单

{% img /images/article/Swift中UIWebView与Javascript的交互/image_1.png %}

##### 第二步，打开iPhone/模拟器【Web 检查器】
打开iOS【设置】->【Safari】->[高级]->打开【Web 检查器】,如下图：

{% img /images/article/Swift中UIWebView与Javascript的交互/image_2.png %}

**注意**
此种方法真机调试的时候，一定要用线缆连接到电脑

#### 第三步，打开调试应用
在真机或者模拟器打开APP，找到应用中的UIWebView所在界面(如果是Safari直接打开网页即可)。按下图，点击需要调试网址对应的[Web 检查器]，例如下图：点击[m.baidu.com]会直打开对应[m.baidu.com]的[Web 检查器]

{% img /images/article/Swift中UIWebView与Javascript的交互/image_3.png %}


#### 第四步，查看控制台日志输出
打[Web 检查器]中的[控制台]选项卡，查看相应日志输出。在调度JavaScriptCore过程中，此控制台的输出信息非常有价值

{% img /images/article/Swift中UIWebView与Javascript的交互/image_4.png %}

### 2.2UIWebView中实现JavaScript与Swift交互

#### JavaScript调用Swift代码
Swift中使用JavaScriptCore,实现细节点比较多，非常容易出错，使用时主要有四个步骤：

	1.准备好测试用HTML
	2.告诉程序JavaScript可以使用的方法
	3.方法的具体实现逻辑
	4.建立关联关系，实现交互

##### 2.2.1准备好测试用HTML
以下为用于测试的HTML代码
``` html
<html>

<body>
<button onclick='callSwift.postContent("value", 2)'>Call Swift1</button>
<button onclick='callSwift.postContentNumber("value", 2)'>Call Swift2</button>
</body>

</html>
```
将以上代码保存为**index.html**并加到项目中，并使UIWebView正确加载HTML

``` swift
let path = NSBundle.mainBundle().pathForResource("index", ofType: "html")
let html = try! String(contentsOfFile: path!)
self.webView.loadHTMLString(html, baseURL: nil)
```

##### 2.2.2告诉程序JavaScript可以使用的方法
我们先看一下官方说明：

 >By default, no methods or properties of the Objective-C class are exposed to JavaScript; instead, you must choose methods and properties to export. For each protocol that a class conforms to, if the protocol incorporates the JSExport protocol, then JavaScriptCore interprets that protocol as a list of methods and properties to be exported to JavaScript.

以上内容主要说明，需要有一个继承自JSExport的协议用来告诉程序哪些方法可以在JavaScript中使用。示例代码如下：

``` swift
import UIKit
import JavaScriptCore

@objc protocol JavaScriptMethodProtocol: JSExport {
    var value: String {get set}
    //对应JavaScript中callSwift.postContent方法
    func postContent(value: String, _ number: String)
    //对应JavaScript中callSwift.postContentNumber方法
    func postContent(value: String, number: String)
}
```

**注意**

	1.一定要加[@objc]前缀，否则方法不被调用
	2.此协议用于告诉程序哪些方法将用于JavaScript,此协议不能省略
	3.postContent方法第二个参数，前面有无[-]对应方法签名不同
	
##### 2.2.3方法的具体实现逻辑
建立一个新的类，实现**JavaScriptMethodProtocol**协议。交互方法也可以使用计算属性，每个方法也可根据需要加上返回值(下面计算属性只作示例，没有使用)。

``` swift
class JavaScriptMethod : NSObject, JavaScriptMethodProtocol {
    
    var value: String {
        get { return ""}
        set {          }
    }
    
    func postContent(value: String, _ number: String) {
        //方法名postContent
    }
    
    func postContent(value: String, number: String) {
        //方法名postContentNumber
    }
}
```

**注意**

	1.需要继承NSObject(或者自己实现NSObjectProtocol)
	2.实现JavaScriptMethodProtocol协议
	
#### 2.2.4建立关联关系，实现交互
建立关联关系时，要保证所有代码都已成功加载，示例使用本地资源，可以直接在**loadHTMLString**方法后，执行相关逻辑

``` swift
 let jsContext = webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext
 jsContext?.setObject(JavaScriptMethod(), forKeyedSubscript: "callSwift")
```
#### [直接下载demo](/download/Swift中UIWebView与Javascript的交互/Demo.zip)
以上4个步骤，实现了JavaScript调用Swift，整体流程相对复杂，比较容易出错。下面讨论Swift如何调用JavaScript代码。

#### Swift调用JavaScript代码
有两种方法可以实现Swift对JavaScript的调用

``` swift
self.webView.stringByEvaluatingJavaScriptFromString("alert()")
```
第二种方法

``` swift
let jsContext = self.webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext
jsContext?.evaluateScript("alert()")
```


### 2.3优化体验
实现运用中，我们发现了以下问题：
	
	1.点击网页上按钮，调用Swift代码时，响应迟钝(有300毫秒的延时)
	2.等资源加载完，再调用[2.2.4建立关联]逻辑，前期出现点击无效(网页是边加载边解析，资源没有都加载完时，也可以显示，但是此时还没有建立关联)
	3.将[2.2.4建立关联]代码提前至开始加载HTML，在刷新或重定向后，点击无效
	点击无效：指点击网页中控件或者逻辑执行JavaScript，Swift代码不被调用

提示：如果遇到点击无效的情况时，可以采用2.1中的调试方法，查看控制台日志

#### 2.3.1响应迟钝优化
关于300毫秒延时，网上给出更多的是为了区分双击放大手势与打开链接而导致的，解决办法，主要是在HTML中加入[fastclick](https://github.com/ftlabs/fastclick)

#### 2.3.2交互过程及优化

##### 1.加载完成建立关系
通过设置UIWebView的delegate,在资源加载完成时，建立关联关系,会出现资源加载中，点击失效的问题

``` swift
    func webViewDidStartLoad(webView: UIWebView) {
    	//需要判断是否正在加载，部分网页在完成加载前，会多次调用此方法
        if !webView.loading {
            //建立关联关系
            let jsContext = self.webView.valueForKeyPath("documentView.webView.mainFrame.javaScriptContext") as? JSContext
            jsContext?.setObject(JavaScriptMethod(), forKeyedSubscript: "callSwift")
        }
    }
 ```

##### 2.优化方法
加载开始建立关联关系，会在刷新、重定向后失效。我们尝试重新建立关联，也不起作用(在资源加载完成或者等待一段时间，再次尝试重新建立关联才成功)。

目前采用的办法是牺牲性能，每次刷新或者重定向时，都将现有的webView释放掉，重新创建一个新的webView。如果您有更好的方法，欢迎联系。


## 三、中国移动插入JavaScript代码等问题

### 3.1移动插入JavaScript
中国移动用户通过2G/3G/4G上网时，UIWebView打开HTTP链接时，会被移动随机加入流量统计的JavaScript代码。移动的JavaScript代码会导致加载缓慢，或者长时间处于加载状态。对于此，可以转向更安全的HTTPS协议。

### 3.2界面错位问题
UIWebView的根视图是UIScrollView,使用NavigationController时，多次打开并返回UIWebView所在页面时，会出现界面64点错位问题，可以按以下方法解决：

##### 1.关闭当前UIViewController的UIScrollView自动调整
``` swift
//self指当前controller
self.automaticallyAdjustsScrollViewInsets = false
```
##### 2.调整UIWebView的Frame
``` swift
let webView = UIWebView(frame: CGRectMake(0, 64, self.view.frame.width, self.view.frame.height - 64))
```
### 3.3底部灰色条
``` swift
webView.opaque = false
```

### 3.4禁止选择
``` swift
self.webView.stringByEvaluatingJavaScriptFromString("document.documentElement.style.webkitUserSelect='none';")
self.webView.stringByEvaluatingJavaScriptFromString("document.documentElement.style.webkitTouchCallout='none';")        
```

## 2016.7.14更新
### 最佳交互协议
开发过程中，频繁变更或者增加方法，使得H5与Native都要付出很大的维护成本。我们推荐制定交互协议,减少交互方法的变更，转而维护协议。示例如下：

{% img /images/article/Swift中UIWebView与Javascript的交互/image_5.png %}

