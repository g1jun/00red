---
title: Swift中UIWebView与Javascript的交互
date: 2016-03-22 14:16:44
comments: true
keywords: UIViewView调用js,js调用UIWebView
categories: experience
---

## 一、内容概要
现阶段App与H5混合编程的需求越来越多，本文(基于iOS7.0及以上)主要给出在Swift项目中，UIWebView与Javascript的双向交互。包括以下几点：

    1、简单请求拦截及UIWebView运行Javascript
    2、通过JavaScriptCore实现UIWebView与Javascript交互
    3、使用过程中常见问题及解决方法
    
本文使用的Swift版本为2.0，所有示例及代码请在2.0环境运行

## 二、简单请求拦截及UIWebView运行Javascript