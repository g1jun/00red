---
layout: post
title: "Swift程序入口深度分析"
date: 2014-11-20 10:32:36 +0800
comments: true
keywords: Swift,一叶博客,Swift main,top_level_code,C_ARGC,C_ARGV
categories: experience
---

## 1.swift为什么不需要main

在c/c++及其它语言中都有一个main函数，程序从main作为起点，开始执行程序，如下：
``` swift
int main(int argc, const char * argv[]) {
    printf("Hello, World!\n");
    return 0;
}

```
main函数实际上是一个特殊的函数，为了能找到程序入口，大多楼语言都约定**main()**函数作为入口。那么为什么在Swift中没有这样的一个函数呢？先看一下官方的解释
> Code written at global scope is used as the entry point for the program, so you don’t need a main function. 

大体意思是，在main.swift中的代码是在全局作用域下，这些代码直接作为整个项目的入口，所以这里并不需要main函数。
<!-- more -->

## 2.C与Swift的入口对比
在ios/osx系统中，C/Objective-c项目也有**main()**函数的约定，在项目入口**main()**代码块打断点

{% img /images/article/Swift视频教程第1讲开篇介绍/teacher_1_c_debug.png %}

从上图可以看出在执行程序前，先调用了**start()**方法，而后再执行约定的**main()**方法，这种我们能够很好理解，那么在swift下情况如何呢？

{% img /images/article/Swift视频教程第1讲开篇介绍/teacher_2_swfit_debug.png %}

从上图可以看出Swift的执行顺序是**start()->main()->top_level_code()**，相对于C语言项目，多出来**top_level_code()**，在main.swift中的（非声明）代码会直接作为**top_level_code()**代码执行。此处要注意在Swift语言本身并不需要入口函数，程序入口是指定为main.swift中的非声明代码。在具体编译环节，ios/osx的入口均采用约定的**main()**函数，为了兼容以前的入口方法，将Swift语言程序在编译环节处理成**隐式入口函数top_level_code()**,再由**main()**调用。

## 3.代码top_level_code()
在官方解释
> Code written at global scope is used as the entry point for the program, so you don’t need a main function. 

提及到全局作用域，main.swift中的声明（如变量、常量、类、结构体、枚举）类代码，会作为全局作用域，在程序的任何都方都可以使用。而其中的非声明（赋值、for循环、if语句等）代码，会作为**top_level_code()**中代码来执行。这里注意，声明类代码与非声明类代码的作用域并不相同。声明类的作用域是全局作用域,而非声明类代码为**top_level_code()**作用域。

	这里特别注意，只有在main.swift中的代码才可以作为top_level_code来执行。
	而在其它文件中，是不能直接在文件中含有非声明类的语句，只能含有声明类的代码。
	
## 4.偷天换日，替换隐式入口函数top_level_code()
在编译环节，编译器将**main.swift**非声明代码作为**top_level_code()**来执行，为了能够让程序执行我们的入口函数，而不是**main.swift**代码，需要声明并实现这个特殊的**top_level_code()**函数

``` swift
void top_level_code();
```

下一步如何让编译程序指定我们写的**top_level_code()**，这里需要注意

* main.swift文件不能删除，如果删除程序直接不能编译通过
* 为了能让编译程序认可我们写的**top_level_code()**函数，我们需要在main.swift文件中主动使用一次**top_level_code()**
	这里的使用是指两种情况：
	1. 在main.swift直调用我们写的**top_level_code()**函数
	2. 在main.swift的声明类、结构体等的方法中调用**top_level_code()**函数
**注意**这两种方法都会导致**main.swift**中的所有代码不再执行。此处在**main.swift**加入上述代码的作用就是让编译器改调用我们写的**top_level_code**函数

具体可以[直接下载项目](http://pan.baidu.com/s/1kT5NHWV)来研究
为了测试里面用到了

	1. Swift项目调用C及Objective-c代码的办法
	2. Objective-c代码调用Swift代码
	3. 类的声明

这部分的知识会在后面一一讲解到，大家只需要了解入口的原理即可。

## 5.Swift打印入口参数

在C言语中的**main**函数中，有两个参数

* argc:  命令行中字符串数
* argv:  指向字符串的指针数组

 这两个参数在Swift中被声明为全局变量，分别为
 
 * C_ARGC 
 * C_ARGV
 
 我们也可以在Swift中将入口参数打印出来，注意C中类型与Swift的类型转换

``` swift
//将C语言int型转换为Swift中的Int
let cout = Int(C_ARGC)
println("all->\(cout)")

let end = cout - 1
for index in 0...(end) {
    //获取指定C语言字符串，并将C字符串转换为Swift的String类型
    let str = String.fromCString(C_ARGV[index])
    println("\(str)")
}
```

**点击运行完成后**->将项目Products目录入的文件直接拖入终端中->在后面添加空格"aaa"空格"bbb",类似下面的格式
``` swift
/Users/mac/Library/Developer/Xcode/DerivedData/ILHelloWorld-fvywvzypiomcffbiuxdxwwdaeued/Build/Products/Debug/ILHelloWorld "aaa" "bbb"
```

打印运行结果如下：
``` swift
all->3
Optional("/Users/mac/Library/Developer/Xcode/DerivedData/ILHelloWorld-fvywvzypiomcffbiuxdxwwdaeued/Build/Products/Debug/ILHelloWorld")
Optional("aaa")
Optional("bbb")
```

其中第一个参数为默认的程序路径，第二个及第三个参数为我们在上面输入的**aaa**及**bbb**，加起来共3个参数