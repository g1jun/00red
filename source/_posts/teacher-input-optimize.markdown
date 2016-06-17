---
layout: post
title: "Swift社交应用文本输入优化汇总"
date: 2015-03-02 16:09:00 +0800
comments: true
keywords: 一叶博客,UITextField,输入优化
categories: experience
---

## 一、输入相关的优化问题

在大部分应用中，都有输入的需求，面对众多用户，他们的想法各异，输入的文本内容也是千奇百怪，面对不同的输入，我们该如何优化输入体验？这里集中汇总输入相关问题，主要如下：

	1、输入控件UITextField跟随键盘移动
	2、过滤输入内容
	3、响应编程的处理，去除体验不好的对话框、HUD提示
	4、中文输入
<!-- more -->

## 二、输入框随键盘移动

界面构建有两种方法，代码或者storyboard/xib，这两种方法在处理键盘移动上方法相同，这里推荐使用已经封装好的第三方框架：[TPKeyboardAvoiding](https://github.com/michaeltyson/TPKeyboardAvoiding)

### 1、代码处理方法
rootView使用**TPKeyboardAvoiding**框架中的TPKeyboardAvoidingScrollView来初使化。例如，登录界面，LoginViewController(继承自UIViewController),处理方法如下：

``` swift
let rootView = TPKeyboardAvoidingScrollView(frame: self.view.bounds);
//...
//add all subviews to rootView
//...
self.view.addSubview(rootView)

```

代码构建界面，实现输入框随键盘移动，需要将类**TPKeyboardAvoidingScrollView**做为根视图来处理。

### 2、storyboard/xib处理办法 
storyboard/xib处理起来更简单，将视图控制器的rootView设置为TPKeyboardAvoidingScrollView即可

(1)选择控制器的根视图

{% img /images/article/IOS社交应用文本输入优化汇总/input_0.png %}

(2)设置默认实例化类

{% img /images/article/IOS社交应用文本输入优化汇总/input_1.png %}


## 三、常用基本设置
### 1、常用基本设置
包括打开键盘、关闭键盘、指定键盘的输入类型、指定return按钮的类型，如以下代码

``` swift
//打开键盘
self.inputText.becomeFirstResponder()
//关闭键盘
self.inputText.resignFirstResponder()
//指定键盘的输入类型
self.inputText.keyboardType = UIKeyboardType.NumberPad
//指定return按键的类型
self.inputText.returnKeyType = UIReturnKeyType.Go
```

### 2、通过代理过滤输入
通过UITextField/UITextView的代理，可以更精确的控制输入，例如：过滤指定字符、超过字符数禁止输入等

(1)UITextField代码如下：
``` swift
//设置代理，可根据实际情况来设置代理，这里使用self来指定
self.textField.delegate = self

//代理方法实现
func textField(textField: UITextField, shouldChangeCharactersInRange
 range: NSRange, replacementString string: String) -> Bool
    {
        //禁止输入空格
        if (string == " ") {
            return false
        }
        
        //按下回车后取消键盘
        if (string == "\n") {
            textField.resignFirstResponder()
            return false
        }
        
        return true
    }
```

(2)UITextView代码如下：

``` swift
/设置代理，可根据实际情况来设置代理，这里使用self来指定
self.textView.delegate = self

//代理方法实现
func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, 
replacementText text: String) -> Bool
    {
        //禁止输入空格
        if (text == " ") {
            return false
        }
        
        //按下回车后取消键盘
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        
        return true
    }
```

UITextField/UITextView可以通过代理方法实时检测用户输入的内容,方便对输入约束，例如，在输入超过10个字符时，禁止用户输入，不过这种体验不好，建议不要使用

## 四、响应编程处理，精确提示信息

### 1、如何优化

输入信息的约束一般是将规则直接提示给用户，例如：社交中用户昵称的输入：

	请输入1-8位的字符作为昵称，不能包括空格、回车、标点
	
用户点击**确定**按钮之后，检查输入的合法性，并通过对话框（或HUD）的形式，提示给用户信息

上面的处理方式，十分常见，能满足基本需求。不过我们已经不再采用上面的设计，原因有以下两点：
	
	1.提示信息过多，大部分用户不会看
	2.对话框及HUD提示比较突兀，容易使用户产生挫败感

在实际开发过程中，精减提示信息为

	请输入1-8个字符
	
用户主动输入空格、回车、标点这些字符或者超出长度时，才主动提示给用户信息，如下图，无输入，确定按钮disable，只提示极少有用信息

{% img /images/article/IOS社交应用文本输入优化汇总/input_2.png %}


输入合法，确定按钮enable

{% img /images/article/IOS社交应用文本输入优化汇总/input_3.png %}

输入不合法，高亮错误显示，确定按钮disable

{% img /images/article/IOS社交应用文本输入优化汇总/input_4.png %}


### 2、代码实现
使用第三方框架[ReactiveCocoa](https://github.com/ReactiveCocoa/ReactiveCocoa),首先实现在用户输入时，下方提示及右侧图片的功能（不使用三方框架，可自己通过代理实现）

``` swift

    @IBOutlet weak var nickTextField: UITextField!//文本输入框
    @IBOutlet weak var checkResultShowImageView: UIImageView!//输入框右侧图片
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var hintLabel: UILabel!//文本框下方提示文字

	override func viewDidLoad() {
        super.viewDidLoad()
        //配置输入
        configInput()    
    }

 func configInput() {
        self.nickTextField.rac_textSignal().subscribeNext { (text) -> Void in
            if (text == nil || text.length == 0) {
                self.checkResultShowImageView.hidden = false
                return
            }
            
            self.checkResultShowImageView.hidden = true
            var imageName = ""
            if (self.checkInputValidate()) {
                imageName = "ok.png"
                self.hintLabel.text = ""
            } else {
                imageName = "warning.png"
                self.hintLabel.text = "超出\(text.length - 8)个字符"
            }
            self.checkResultShowImageView.image = UIImage(named: imageName)
            
        }
    }
    
    func checkInputValidate() -> Bool {
        //输入条件检查，这里示例，只检查字符长度
        let length = (self.nickTextField.text as NSString).length
        return length > 0 && length <= 8
    }


```

下面实现功能：根据输入的合法性，设置按钮的enabled属性，此步骤需要下载文件[RAC语法支持文件](https://github.com/yusefnapora/ReactiveSwift/blob/master/ReactiveSwift/RAC.swift),更详细介绍[Swift支持ReactiveCocoa](http://napora.org/a-swift-reaction/)

``` swift

func configButtonEnable() {
        RAC(self.button, "enabled") <~ RACSignal.combineLatest(
            [self.nickTextField.rac_textSignal()],
            reduce: { () -> AnyObject! in
            
            return self.checkInputValidate()
                
        })
    }

```

## 五、中文处理办法

有中文输入时，上面的字数检查不准确，如通过输入法输入**"我爱中国文化"**6个字符时self.nickTextField.text的字符个数为23个，提示信息不正确

{% img /images/article/IOS社交应用文本输入优化汇总/input_5.png %}

UITextView/UITextFiled有一个markedTextRange属性，用于标识当前是否有选中的文本（有选中文本时即为上图中的未完成输入状态），利用此原理来解决中文等类似问题

``` swift

    @IBOutlet weak var nickTextField: UITextField!
    @IBOutlet weak var checkResultShowImageView: UIImageView!
    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var hintLabel: UILabel!
    
    var chineseText: NSString!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.nickTextField.delegate = self
        filterInput()
        configButtonEnable()
        
        
    }
    
    func filterInput() {
        self.nickTextField.rac_textSignal().subscribeNext { (text) -> Void in
            if(self.nickTextField.markedTextRange != nil) {
                return;
            }
            //这里可以加入去除空格，标点等操作
            self.chineseText = text as NSString
            
            if (text == nil || text.length == 0) {
                self.checkResultShowImageView.hidden = false
                return
            }
            
            self.checkResultShowImageView.hidden = true
            var imageName = ""
            if (self.checkInputValidate()) {
                imageName = "ok.png"
                self.hintLabel.text = ""
            } else {
                imageName = "warning.png"
                self.hintLabel.text = "超出\(text.length - 8)个字符"
            }
            self.checkResultShowImageView.image = UIImage(named: imageName)
            
        }
    }
    
    func checkInputValidate() -> Bool {
        //输入条件检查，这里示例，只检查字符长度
        let length = chineseText.length
        return length > 0 && length <= 8
    }
    
    func configButtonEnable() {
        RAC(self.button, "enabled") <~ RACSignal.combineLatest(
            [self.nickTextField.rac_textSignal()],
            reduce: { () -> AnyObject! in
            
            if(self.nickTextField.markedTextRange == nil) {
                return self.checkInputValidate()
            }
            return self.button.enabled
                
        })
    }
    
    
    @IBAction func buttonPressed(sender: AnyObject) {
        println("------>\(self.chineseText)")
    }
    

```

## 六、总结

输入是手机App中最耗时的操作，处理不当很容易失去用户，这里总结以下几点
	
	1.不要将所有的约束信息直接展示给用户，只展示那些对大部分用户都有用的信息，对于其他约束
	在用户输入错误的时候再提示
	2.尽量少用或者不用对话框及HUD的方式提示错误
	3.提示信息准确，例如超出字符数，一种提示为：超出最大140字符
	另一种为：超出n个字符，显然后者提示对用户更有价值
	4.不要擅自更改用户输入内容或者粗暴禁止用户输入


