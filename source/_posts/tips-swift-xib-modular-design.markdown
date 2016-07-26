---
title: Swift之xib模块化设计
date: 2016-06-27 13:55:15
comments: true
keywords: xib模块化,storybaord模块化
categories: experience
---
## 一、解决问题
Xib/Storybarod可以方便、可视化的设置约束，在开发中也越来越重要。由于Xib不能组件化，使得封装、重用都变得不可行。本文将介绍一种解决方案，来实现Xib组件化。

{% img /images/article/Swift之xib模块化设计/image_0.png %}

<!-- more -->

## 二、模型块原理

在介绍原理之前，我们先弄清楚两个概念:

{% img /images/article/Swift之xib模块化设计/image_1.png %}

从上图可以看出，分别选中**File's Owner**及根视图**View**，都有*Custom Class*属性面板。其中**Class**属性，有什么作用，区别又是什么呢？

### 2.1View的Class属性

 View的Class属性用于指定选中的视图的实例化类。Xib实际上是一个XML文件，在加载时，解析逻辑会根据XML内容，创建并设置View实例。而此处的**Class**就是告诉解析逻辑，想要创建什么类的实例。如果此处设置为UIButton，则解析逻辑会生成一个UIButton的实例。
 
 
### 2.2File's Owner的Class属性
 
Feile's Owner的Class属性，大部分情况下，都为**UIViewController**及其子类。


``` swift

public func loadNibNamed(name: String!, owner: AnyObject!, options: [NSObject : AnyObject]!) -> [AnyObject]!


```

从上面xib的加载接口可以看出，加载Xib需要指定一个owner类的**实例**。处理File's Owner时有别于**2.1**，解析逻辑没有创建实例，使用的是传入的owner实例。

	如果没有创建，为什么还要指定File's Owner的Class属性？

此处设置的Class属性值，主要作用是通过关键字**@IBOutlet**，告诉Xcode哪些属性或者方法可以建立关联关系。实际上就是声明此处设置的File's Owner类，有哪些属性及方法可以设值。

#### Tips
File's Owner的Class属性，起一个标识声明作用，告知哪些属性及方法可以使用。

``` swift
class ILViewController: UIViewController {

     @IBOutlet weak var label: UILabel!

}


class ILFlagController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
}
```


既然如此(如上面代码)，使用**loadNibNamed**方法加载Xib时，owner参数传入**ILViewController**实例，而Xib中File's Owner的Class却设置为**ILFlagController**，是否可行？答案：可行。

### 2.4原理
在Storybarod/Xib中，与组件化有关，是视图的Class属性。视图是由xib解析逻辑创建，所以要实现组件化，就要在此Class中实现自动加载子Xib的功能。

## 三、工具类源码
为了实现xib的模块化，需要有一个小的功能类：


``` swift
import UIKit

@objc class ILXibView: UIView {
    
    @IBOutlet var contentView: UIView!
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.loadView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.loadView()
        
    }
    
    private func getXibName() -> String {
        let clzzName = NSStringFromClass(self.classForCoder)
        let nameArray = clzzName.componentsSeparatedByString(".")
        var xibName = nameArray[0]
        if nameArray.count == 2 {
            xibName = nameArray[1]
        }
        return xibName
    }
    
    
    func loadView() {
        if self.contentView != nil {
            return
        }
        self.contentView = self.loadViewWithNibName(self.getXibName(), owner: self)
        self.contentView.frame = self.bounds
        self.contentView.backgroundColor = UIColor.clearColor()
        self.addSubview(self.contentView)
    }
    
    private func loadViewWithNibName(fileName: String, owner: AnyObject) -> UIView {
        let nibs = NSBundle.mainBundle().loadNibNamed(fileName, owner: owner, options: nil)
        return nibs[0] as! UIView
    }
    
    
    
}
```

## 四、实战示例

