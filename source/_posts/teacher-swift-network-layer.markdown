---
title: Swift网络层开发解决方案
date: 2016-08-01 13:49:04
comments: true
keywords: swift网络层,ios网络层,swift接口设计,swift网络服务
categories: experience
---
## 一、解决的问题
iOS应用网络层开发，基于Swift,将结合工作经验，给出最佳实践，包括以下部分:

	1.框架分层设计
	2.Log管理
	3.状态结果封装
	4.业务逻辑接口设计
	5.协议制定

<!-- more -->	

## 二、框架分层设计

开发过程中，为了让网络层易维护、使用简单，细分为三层，如下：


{% img /images/article/Swift网络层开发解决方案/image_0.png %}
<br>
<font color="#E0CD2F">三方库层</font>：一般由第三方库组成，提供最基本的功能，如：HTTP功能、AES加密功能等

<font color="#3B95B2">公共封装层</font>：主要使用是将第三方库与应用业务逻辑隔离开，并提供公用的基础服务。例如：处理加密、Log管理等（部分公司在API中使用SessionId，一般管理及激活也会放在此层）

<font color="#6AA13E">业务层</font>：

