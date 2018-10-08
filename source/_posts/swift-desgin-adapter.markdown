---
layout: post
title: Swift之适配器模式
date: 2018-09-25 16:50:05
keywords: swift,适配器,设计模式,adapter,adaptee
categories: experience
---

## 一、前言
适配器模式，使用非常简单，现在iOS开发面试过程中也经常会被提及，部分人对其理解有偏差，接下来简单讲理一下其用法：

{% img /images/article/Swift之适配器模式/image_0.png %}

<!-- more -->

## 二、意图
通览设计模式，会看到很多模式**长相**差不多，都是根据设计模式六大原则演变而来，区分他们一个重要工具是**意图**，即此模式要解决什么样问题；下面来看一下适配器模式意图：

	将一个类的接口转换成客户希望的另外一个接口。适配器模式使得原本由于接口不兼容而不能一起工作的那些类可以一起工作
	
### 2.1 使用场景
其使用场景为：已有功能A能满足大部分要求，但是使用者只能使用B接口，这个时候可以用适配器转换，将A转换为B；类比生活中的手机，手机冲电电压为3.7V，现有家用电是220V，电压不匹配，采用电源**适配器**来进行电压适配

{% img /images/article/Swift之适配器模式/image_1.png %}

### 2.2 UML类图
先来看一下，适配器模式的标准写法：
{% img /images/article/Swift之适配器模式/image_3.png %}

回到iPhone充电问题：
{% img /images/article/Swift之适配器模式/image_4.png %}

### 2.3 代码实现
``` swift
//iphone只能充电，必须实现此协议
protocol IPhoneUSBPower {
    //充电方法
    func usbProvidePower()
}

//已经存在的220V电压
class Household220VProvide {
    func provide220VPower() {
        print("输出220V电压")
    }
}

//适配器类，此类主要功能将220V电压转换为iPhone可以使用的电压
class USBPowerAdapter: IPhoneUSBPower {
    private let household220VProvide = Household220VProvide()
    func usbProvidePower() {
        household220VProvide.provide220VPower()
        print("转换220V电压为3.7V")
    }
}

//充电使用方
class Phone {
    //给手机充电
    func charge() {
        let usb = USBPowerAdapter()
        usb.usbProvidePower()
    }
}
```


### Tips 
适配器有很多变种，如双向适配器，判断其是否为适配器模式的重要功能，即适配器模式的意图；简单一句话，解决接口不兼容问题；最近面试了几个开发者，聊开发亮点时，经常会遇到用适配器设计某新功能的自述，大部分情况下为误用，形似神不似；

{% img /images/article/Swift之适配器模式/image_2.png %}

