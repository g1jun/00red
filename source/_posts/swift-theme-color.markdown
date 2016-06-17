---
layout: post
title: "Swift主题色顶级解决方案一"
date: 2014-11-27 13:57:57 +0800
comments: true
keywords: Swift,一叶博客,Swift main, 主题色, NavigationBar颜色,一叶
categories: experience
---
## 一、常规主题色使用点
应用在发布前都会对其主题色进行设置，以统一应用的风格（可能有多套主题）。在主题色设置上有几个方面，如下：

	1.TabBar部分，设置图片高亮、文本高度颜色
	2.NavigationBar部分，设置导航栏颜色及字体颜色
	3.应用标签等，设置字体的颜色
	4.应用图片主题色

主题色的设置点，大体从上面四个方面着手，图片的主题色我们可通过图片更换的方式进行处理。而通过代码来处理的`1-3`条，有着不同的处理方法。大家常规处理方法如下：
<!-- more -->

步骤一：变化分离
	1.利用Swift扩展语法扩展UIColor，将应用主题色在扩展中统一处理（适合单一主题色）
	2.将主题色的配置写入文件中，由相应逻辑进行解析。此方法将主题色逻辑封装成主题色管理类（适合多套主题）
	
步骤二：离散使用上步封装的类

	1.在任何使用主题色的地方，使用扩展中的UIColor方法来设置，一般包括背景色，文字颜色等
	
这里给出UIColor的扩展

``` swift

extension UIColor {
    
    //主题色
    class func applicationMainColor() -> UIColor {
        return UIColor(red: 238/255, green: 64/255, blue: 86/255, alpha:1)
    }
    
    //第二主题色
    class func applicationSecondColor() -> UIColor {
        return UIColor.lightGrayColor()
    }
    
    //警告颜色
    class func applicationWarningColor() -> UIColor {
        return UIColor(red: 0.1, green: 1, blue: 0, alpha: 1)
    }
    
    //链接颜色
    class func applicationLinkColor() -> UIColor {
        return UIColor(red: 59/255, green: 89/255, blue: 152/255, alpha:1)
    }
    
}

```

## 二、TabBar主题色设置
很多应用中，默认情况下都使用了TabBar控件，但是TabBar主题色等设置根据使用情况的不同，设置起来也不一样。代码创建比较灵活，更改主题色比较容易。而使用了Xib/Storyboard也是有办法做统一处理的，如下，迭代更改TabBar默认字体颜色
``` swift

 func configTabBar() {
        let items = self.tabBar.items
        for item in items as [UITabBarItem] {
            let dic = NSDictionary(object: UIColor.applicationMainColor(),
             forKey: 	NSForegroundColorAttributeName)
            item.setTitleTextAttributes(dic, 
             forState: UIControlState.Selected)
        }
    }
```

设置TabBar图片及文字默认选中颜色
``` swift
        self.tabBar.selectedImageTintColor = UIColor.applicationMainColor()
```

#### Tips注意事项
>  Changing this property’s value provides visual feedback in the user interface, including the running of any associated animations. The selected item displays the tab bar item’s selectedImage image, using the tab bar’s selectedImageTintColor value. To prevent system coloring of an item, provide images using the UIImageRenderingModeAlwaysOriginal rendering mode.

在一些情况，正常状态为白色图片时，真机测试时，白色图片会出现偏色（显示结果为灰色），这是因为系统默认着色导致的，在创建UITabBarItem时，可通过使用UIImageRenderingModeAlwaysOriginal避免。示例代码如下：
``` swift
let imageNormal = UIImage(contentsOfFile: "imageNormal")?.
imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
let imageSelected = UIImage(contentsOfFile: "imageSelected")
let tabBarItem = UITabBarItem(title: "title",
         image: imageNormal,
         selectedImage: imageSelected)
```

## 三、一劳永逸，利用Hook原理通设NavigationBar颜色

IOS应用中，NavigationBar十分常用，它的使用主要包括以下两个场景
	1.代码直接构建
	2.Xib/Storyboard构建
如果是纯代码构建的时候，比较简单，直接使用UIColor的扩展来设置颜色。实际项目中，有些界面是通过Xib/Storyboard来创建的，有些是代码写的，但这也难不到大家，使用继承。创建一个继承自UINavigationController的子类，通过这个子类来统一设置主题色。然后告诉项目中的所有人，强制使用UINavigationController子类，包括Xib/Storyboard等。问题是旧项目怎么办，这种强制要求可以工作，有没有一个更好的办法，让所有人正常使用UINavigationController，而在神不知鬼不觉的情况下，通设所有NavigationBar呢？
**先上代码，再解释**
#### 1.创建一个UIViewController的扩展
	
``` swift 
extension UIViewController {
    func viewDidLoadForChangeTitleColor() {
        self.viewDidLoadForChangeTitleColor()
        if self.isKindOfClass(UINavigationController.classForCoder()) {
           self.changeNavigationBarTextColor(self as UINavigationController)
        }
    }
    
    func changeNavigationBarTextColor(navController: UINavigationController) {
        let nav = navController as UINavigationController
        let dic = NSDictionary(object: UIColor.applicationMainColor(),
         forKey:NSForegroundColorAttributeName)
        nav.navigationBar.titleTextAttributes = dic
        nav.navigationBar.barTintColor = UIColor.applicationSecondColor()
        nav.navigationBar.tintColor = UIColor.applicationMainColor()
        
    }
  
}
```

#### 2.编写用于Hook的工具类

``` swift
func swizzlingMethod(clzz: AnyClass, #oldSelector: Selector, #newSelector: Selector) {
    let oldMethod = class_getInstanceMethod(clzz, oldSelector)
    let newMethod = class_getInstanceMethod(clzz, newSelector)
    method_exchangeImplementations(oldMethod, newMethod)
}
```

#### 3.在AppDelegate中调用

``` swift
  func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: NSDictionary?) -> Bool {
        swizzlingMethod(UIViewController.self, 
        oldSelector: "viewDidLoad", 
        newSelector: "viewDidLoadForChangeTitleColor")
	//do others
        return true
    }
```

#### 4.原理说明
在程序入口处，通过运行时机制，动态的替换UIViewController的周期方法**viewDidLoad**为我们指定的方法**viewDidLoadForChangeTitleColor**。在**viewDidLoadChangeTitleColor**中，需要做两件事：

* 调用原来的**viewDidLoad**方法
* 执行修改主题色相关代码

**1.如何调用原来的viewDidLoad方法**

在AppDelegate中，通过调用方法`swizzlingMethod`我们将**viewDidLoad**与**viewDidLoadForChangeTitleColor**方法体进行了替换，原理如下图：

{% img /images/article/Swift主题色顶级解决方案/color_theme_1.png %}

{% img /images/article/Swift主题色顶级解决方案/color_theme_2.png %}

从上面的图可以看出，当在**viewDidLoadForChangeTitleColor**中执行：
``` swift
self.viewDidLoadForChangeTitleColor()
```
是不会造成循环调用，反而是调用了我们期望执行的**viewDidLoad**方法体。

## 三、Xib/Storyboard的处理
一些在Xib/Storyboard中设置的主题色，比如文本颜色，按钮的高亮颜色等，该如何处理呢，以UILabel为例，建立扩展

``` swift
extension UILabel {
    var colorString: String {
        set(newValue) {
            switch newValue {
            case "main":
                self.textColor = UIColor.applicationMainColor()
            case "second":
                self.textColor = UIColor.applicationSecondColor()
            case "warning":
                self.textColor = UIColor.applicationWarningColor()
            default:
                self.textColor = UIColor.applicationSecondColor()
            }
        }
        get {
            return self.colorString
        }
    }
}
```
在Xib/Storyboard的查检器中进行编辑，如下图：
{% img /images/article/Swift主题色顶级解决方案/color_theme_3.png %}

## 4.总结

1.只有一套主题时，上面的方法可以直接复制使用，在更换主题时，只需要更换相应图片及修改UIColor的扩展类

2.在有多套主题，用户可以自由切换主题时，可以按文章中的Hook机制，对**viewWillAppear**进行劫持，也可以轻松实现主题的改变
