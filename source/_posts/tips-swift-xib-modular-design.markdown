---
title: Swift之xib模块化设计
date: 2016-07-27 13:55:15
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

### 2.1 View的Class属性

 View的Class属性用于指定选中的视图的实例化类。Xib实际上是一个XML文件，在加载时，解析逻辑会根据XML内容，创建并设置View实例。而此处的**Class**就是告诉解析逻辑，想要创建什么类的实例。如果此处设置为UIButton，则解析逻辑会生成一个UIButton的实例。
 
 
### 2.2 File's Owner的Class属性
 
Feile's Owner的Class属性，大部分情况下，都为**UIViewController**及其子类。


``` swift

public func loadNibNamed(name: String!, owner: AnyObject!, options: [NSObject : AnyObject]!) -> [AnyObject]!


```

从上面xib的加载接口可以看出，加载Xib需要指定一个owner类的**实例**，解析逻辑并没有像**2.1**创建新实例，而是使用参数名为owner的已创建好的实例。

	如果没有创建，为什么还要指定File's Owner的Class属性？

此处设置的Class属性值，主要作用是通过关键字**@IBOutlet**，声明有哪些属性及方法可以建立关联关系。解析逻辑会将关联视图的引用赋值给**owner**的对应属性，触发事件则执行**owner.method()**方法。目的为了在**owner**中，就可以方便的处理界面相关的业务逻辑。可以这样理解，File's Owner的Class，是关联接口声明，loadNibNamed传入的**owner**是实现。

#### Tips
File's Owner的Class属性，起一个声明作用，告知哪些属性及方法可以使用。

``` swift
class ILViewController: UIViewController {

     @IBOutlet weak var label: UILabel!

}


class ILFlagController: UIViewController {
    
    @IBOutlet weak var label: UILabel!
    
}
```


既然如此(如上面代码)，使用**loadNibNamed**方法加载Xib时，owner参数传入**ILViewController**实例，而Xib中File's Owner的Class却设置为**ILFlagController**，是否可行？答案：可行。

### 2.4 Xib模块化原理
在Storybarod/Xib中，与组件化有关的只有视图的Class属性。视图是由xib解析逻辑创建，所以要实现组件化，就要在此Class实例化时，自动执行加载子xib模块的功能。

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

### 4.1 封装Xib组件

新建**ILDemoView.xib**、**ILDemoView.swift**两个文件(文件名要相同)，并将**ILDemoView**文件的File's Owner的Class设置为**ILDemoView**

``` swift
class ILDemoView: ILXibView {

    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
    	//一定要调用super
        super.awakeFromNib()
        self.label.text = "你好，中国"
    }

}
```

在xib文件中添加UILabel，并关联到ILDemoView中

{% img /images/article/Swift之xib模块化设计/image_2.png %}

### 4.2 使用Xib组件

新建Xib/Storyboard文件，添加一个UIView控件，并将此控件的Class属性设置为**ILDemoView**

{% img /images/article/Swift之xib模块化设计/image_3.png %}


#### Tips
使用的时候，先设置目标UIView的Class属性为**ILDemoView**，再将此UIView控件拖拽建立关联关系，会发现此时代码中属性类型已自动设置为**ILDemoView**。**ILXibView**简单却非常实用，我们项目中已经大量的使用它，对于Xib的模块化封装，绝对是一利器。


### [直接下载demo](/download/Swift之xib模块化设计/ILXibDemo.zip)