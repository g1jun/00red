---
title: Swift网络层开发解决方案
date: 2016-08-01 13:49:04
comments: true
keywords: swift网络层,ios网络层,swift接口设计,swift网络服务
categories: experience
---
## 一、解决的问题
iOS应用网络层开发，基于Swift,将结合工作经验，给出最佳实践，包括以下部分:

	1.框架设计原则
	2.Log管理
	3.状态结果封装
	4.业务逻辑接口设计
	5.协议制定

<!-- more -->	

## 二、框架设计原则

开发过程中，为了让网络层易维护、使用简单，细分为三层，如下：


{% img /images/article/Swift网络层开发解决方案/image_0.png %}
<br>
<font color="#E0CD2F">黄色基础层</font>：提供最基本的HTTP、AES加密等基础服务，一般由第三方框架类库组成，如：AFNetworking等
<font color="#3B95B2">蓝色服务层</font>：提供与业务相关最基本的
<font color="#6AA13E">绿色业务层</font>：
a
b
c
d