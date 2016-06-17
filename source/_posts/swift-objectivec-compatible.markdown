---
layout: post
title: "Swift项目兼容Objective-c问题汇总"
date: 2015-06-02 17:01:06 +0800
comments: true
keywords: Swift与Objective-c兼容,Swift调用Objective-c,Swift调用OC,Swift找不到符号
categories: experience
---

## 一、解决问题

Swift项目需要使用封装好的Objective-c组件、第三方类库，苹果提供的解决方案能够处理日常大部分需求，但还不能称之为完美，混编过程中会遇到很多问题。本文将Swift兼容Objective-c的问题汇总，以帮助大家更好的使用Swift，内容列表如下：

	1. Swift调用Objective-c代码
	2. Objective-c调用Swift代码
	3. Swift兼容Xib/Storyboard
	4. Objective-c巧妙调用不兼容的Swift方法
	5. 多Target编译错误解决
	6. 第三方类库支持
	
<!-- more -->


## 二、基础混合编程

Swift与Objective-c的代码相互调用，并不像Objective-c与C/C++那样方便，需要做一些额外的配置工作。无论是Swift调用Objective-c还是Objective-c调用Swift，Xcode在处理上都需要两个步骤:

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_step.png %}



### 2.1 Swift调用Objective-c代码

Xcode对于Swift调用Objective-c代码，除宏定义外，其它支持相对完善。
#### 2.1.1 使用Objetvie-c的第一步，

告诉Xcode、哪些Objective-c类要使用，新建.h头文件，文件名可以任意取，建议采用**"项目名-Bridging-Header.h"**命令格式。

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_0.png %}


#### Tips
Swift之IOS项目，在Xcode6创建类文件，默认会自动选择OS X标签下的文件，这时*一定要选择iOS标签*下的文件，否则会出现语法智能提示不起作用，严重时会导致打包出错。

#### 2.1.2 第二步，Target配置，使创建的头文件生效

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_1.png %}

设置**Objective-C Bridging Header**时，路径要配置正确，例如：创建的名为**"ILSwift-Bridging-Header.h"**文件，存于ILSwift项目文件夹的根目录下，写法如下：

	ILSwift/ILSwift-Bridging-Header.h
	
当然，在新项目中，直接创建一个Objective-c类，Xcode会提示：

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_2.png %}

直接选择**Yes**即可，如果不小心点了其它按钮，可以按照上面的步骤一步一步添加。


### 2.2 Objective-c调用Swift代码

#### 2.2.1 Objective-c调用Swift代码两个步骤
第一步告诉Xcode哪些类需要使用(继承自NSObject的类自动处理，不需要此步骤)，通过关键字**@objc(className)**来标记

``` swift 
import UIKit

@objc(ILWriteBySwift)
class ILWriteBySwift {
    var name: String!
    
    class func newInstance() -> ILWriteBySwift {
        return ILWriteBySwift()
    }
}
```

第二步引入头文件，Xcode头文件的命名规则为

	$(SWIFT_MODULE_NAME)-Swift.h
	
示例如下：

    #import "ILSwift-Swift.h"


##### Tips
不清楚**SWIFT_MODULE_NAME**可通过以下步骤查看

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_3.png %}

#### 2.2.2找不到$(SWIFT_MODULE_NAME)-Swift.h

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_4.png %}

1.遇到此问题可按以下步骤做常规性检查

	1.确定导入SWIFT_MODULE_NAME)-Swift.h头文件的文件名正确
	2.SWIFT_MODULE_NAME)-Swift.h在clean后没有重新构建，执行Xcode->Product->Build

2.头文件循环

在混合编程的项目中，由于两种语言的同时使用，经常会出现以下需求：在Swift项目中需要使用Objectvie-c写的A类，而A类又会用到Swift的一些功能，头文件的循环，导致编译器不能正确构建**$(SWIFT_MODULE_NAME)-Swift.h**，遇到此问题时，在.h文件做如下处理

``` swift
//删除以下头文件
//#import "ILSwift-Swift.h"
//通过代码导入类
@class ILSwiftBean;
```
在Objevtive-c的.m文件最上面，添加

    #import "ILSwift-Swift.h"


出现**Use of undecalared identifier**错误或者找不到方法，如下：

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_5.png %}

引起的原因有以下几种可能：

	1.使用的Swift类不是继承自NSObject，加入关键字即可
	2.SWIFT_MODULE_NAME)-Swift.h没有实时更新，Xcode->Product->Build
	3.此Swift文件中使用了Objective-c不支持的类型或者语法，如private

出现**部分方法找不到**的问题，Xcode无智能提示：

	此方法使用了Objective-c不支持的类型或者语法

苹果官方给出的不支持转换的类型

>Generics<br>
>Tuples<br>
>Enumerations defined in Swift<br>
>Structures defined in Swift<br>
>Top-level functions defined in Swift<br>
>Global variables defined in Swift<br>
>Typealiases defined in Swift<br>
>Swift-style variadics<br>
>Nested types<br>
>Curried functions<br>


## 三、Xib/StoryBoard支持
Swift项目在使用Xib/StoryBoard时，会遇到两种不同的问题

	1.Xib：不加载视图内容
	2.Storyboard：找不到类文件

### 3.1 Xib不加载视图内容
在创建UIViewController时，默认选中Xib文件，在Xib与类文件名一致时，可通过以下代码实例化：

``` swift
let controller = ILViewController()
```
运行，界面上空无一物，Xib没有被加载。解决办法，在类的前面加上**@objc(类名)**，例如：
 
``` swift
import UIKit

@objc(ILViewController)
class ILViewController: UIViewController {
    
}
```
#### Tips:
StoryBoard中创建的UIViewController，不需要**@objc(类名)**也能够保持兼容 

### 3.2 Storyboard找不到类文件
Swift语言引入了Module概念，在通过关键字**@objc(类名)**做转换的时候，由于Storboard没有及时更新Module属性，会导致如下两种类型错误：

#### 3.2.1 用**@objc(类名)**标记的Swift类或者Objective-c类可能出现错误：

	2015-06-02 11:27:42.626 ILSwift[2431:379047] Unknown class _TtC7ILSwift33ILNotFindSwiftTagByObjcController in Interface Builder file.
	
解决办法，按下图，选中Module中的空白，直接回车

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_6.png %}

#### 3.2.2 无**@objc(类名)**标记的Swift类

	2015-06-02 11:36:29.788 ILSwift[2719:417490] Unknown class ILNotFindSwiftController in Interface Builder file.

解决办法，按下图，选择正确的Module

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_7.png %}

3.产生上面错误的原因：
在设置好Storyboard后，直接在类文件中，添加或者删除**@objc(类名)**关键字，导致Storyboard中 Module属性没有自动更新，所以一个更通用的解决办法是，让Storyboard自动更新Module,如下：

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_8.png %}


### 3.3 错误模拟Demo下载

为了能够让大家更清楚的了解解决流程，将上面的错误进行了模拟，想动手尝试解决以上问题的同学可以直接下载[demo](/download/Swift项目兼容Objective-c问题汇总/demo.zip)

## 四、Objective-c巧妙调用不兼容的Swift方法
在Objective-c中调用Swift类中的方法时，由于部分Swift语法不支持转换，会遇到无法找到对应方法的情况，如下：

``` swift
import UIKit

enum HTTPState {
    case Succed, Failed, NetworkError, ServerError, Others
}

class ILHTTPRequest: NSObject {
   
    class func requestLogin(userName: String, password: String, callback: (state: HTTPState) -> (Void)) {
        dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
            NSThread.sleepForTimeInterval(3)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(state: HTTPState.Succed)
            })
        })
    }
    
}
```

对应的**$(SWIFT_MODULE_NAME)-Swift.h**文件为：

``` swift
SWIFT_CLASS("_TtC12ILSwiftTests13ILHTTPRequest")
@interface ILHTTPRequest : NSObject
- (SWIFT_NULLABILITY(nonnull) instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end
```
从上面的头文件中可以看出，方法**requestLogin**使用了不支持的Swift枚举，转换时方法被自动忽略掉，有以下两种办法，可以巧妙解决类似问题：

### 4.1 用支持的Swift语法包装

在Swift文件中，添加一个可兼容包装方法**wrapRequestLogin**,注意此方法中不能使用不兼容的类型或者语法

``` swift
import UIKit

enum HTTPState: Int {
    case Succed = 0, Failed = 1, NetworkError = 2, ServerError = 3, Others = 4
}

class ILHTTPRequest: NSObject {
   
    class func requestLogin(userName: String, password: String, callback: (state: HTTPState) -> (Void)) {
        dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
            NSThread.sleepForTimeInterval(3)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                callback(state: HTTPState.Succed)
            })
        })
    }
    
    class func wrapRequestLogin(userName: String, password: String, callback: (state: Int) -> (Void)) {
        self.requestLogin(userName, password: password) { (state) -> (Void) in
            callback(state: state.rawValue)
        }
    }
    
}
```

对应的**$(SWIFT_MODULE_NAME)-Swift.h**文件为：

``` swift
SWIFT_CLASS("_TtC12ILSwiftTests13ILHTTPRequest")
@interface ILHTTPRequest : NSObject
+ (void)wrapRequestLogin:(NSString * __nonnull)userName password:(NSString * __nonnull)password callback:(void (^ __nonnull)(NSInteger))callback;
- (SWIFT_NULLABILITY(nonnull) instancetype)init OBJC_DESIGNATED_INITIALIZER;
@end
```
此时，我们可以在Objective-c中直接使用包装后的方法**wrapRequestLogin**

### 4.2 巧妙使用继承

使用继承可以支持所有的Swift类型，主要的功能在Objective-c中实现，不支持的语法在Swift文件中调用，例如，**ILLoginSuperController**做为父类

``` swift
@interface ILLoginSuperController : UIViewController
@property (weak, nonatomic) IBOutlet UITextField *userNameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

- (IBAction)loginButtonPressed:(id)sender;
@end


////////////////////////////////////////////////////////////////

@implementation ILLoginSuperController


- (IBAction)loginButtonPressed:(id)sender
{
}
@end
```

创建Swift文件，继承自**ILLoginSuperController**，在此Swift文件中调用那些不支持的语法

``` swift
import UIKit

class ILLoginController: ILLoginSuperController {

    override func loginButtonPressed(sender: AnyObject!) {
        ILHTTPRequest.requestLogin(self.userNameField.text, password: self.passwordField.text) { (state) -> (Void) in
            //具体业务逻辑
        }
    }
    
}
```


## 五、多Target编译错误解决

在使用多Target时，会出现一些编译错误

### 5.1 Use of undeclared type

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_9.png %}

此类错误，是因为当前运行的Target找不到必须编译文件。将文件添加到Target即可，如下支持**ILSwiftTests** Target，选中**ILSwiftTests**前的复选框即可

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_10.png %}


### 5.2 does not have a member named

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_11.png %}

此类错误可能由于如下两种原因引起，解决办法同上：

	1.此方法来自父类，父类文件没有加入到当前Target
	2.此方法来自扩展，扩展没有加入到当前Target

#### Tips

如果检查发现，所有的类文件都已经准确添加到Target中，但编译还是不通过，此时着重检查桥接文件是否正确设置，是否将相应的头文件加入到了桥接文件中。如无特别要求，建议将所有Target的桥接文件全都指向同一文件。关于桥接文件的设置，请参考**2.1**


## 六、第三方类库支持

Swift项目取消了预编译文件，一些第三方Objective-c库没有导入必要框架(如UIKit)引起编译错误

### 6.1 Cocoapods找不到.o文件
在使用了Cocoapods项目中，会出现部分类库的.o文件找不到，导致此种错误主要是以下两种问题：
	
	1.类库本身存在编译错误
	2.Swift没有预编译，UIKit等没有导入

将此库文件中的代码文件直接加到项目中，编译，解决错误

### 6.2 JSONModel支持

在Swift中可以使用JSONModel部分简单功能，一些复杂的数据模型建议使用Objevtive-c

``` swift
import UIKit


@objc(ILLoginBean)
public class ILLoginBean: JSONModel {
    var userAvatarURL: NSString?
    var userPhone: NSString!
    var uid: NSString!
    
}
```

#### Tips
在Swift使用JSONModel框架时，字段只能是NSFoundation中的支持类型，Swift下新添加的String、Int、Array等都不能使用

### 6.3 友盟统计

Swift项目中引入友盟统计SDK会出现**referenced from**错误：

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_12.png %}

解决办法，找到**Other Linker Flags**，添加**-lz**

{% img /images/article/Swift项目兼容Objective-c问题汇总/image_13.png %}


## 七、综述

现在大部分成熟的第三方框架都是使用Objective-c写的，开发时不可避免的涉及到两种语言的混合编程，期间会遇到很多奇怪的问题。因为未知才有探索的价值，Swift的简洁快速，能够极大的推进开发进度。所以从今天开始，大胆的开始尝试


#### 版权声明：本文章在微信公众平台的发表权，已「独家代理」给指定公众帐号[iOS开发](http://blog.devtang.com/images/weixin-qr.jpg)(iOSDevTips)