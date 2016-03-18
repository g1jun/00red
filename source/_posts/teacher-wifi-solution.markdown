---
layout: post
title: "IOS客户端公共WIFI解决方案"
date: 2015-01-14 13:43:38 +0800
comments: true
keywords: IOS WIFI,公共WIFI
categories: experience 
---
## 一、公共WIFI综述

现在很多公司都在做免费WIFI，车站、公交、地铁、餐厅，只要是人员密集流动的地方就有WIFI，免费WIFI从最初的网页认证方式也逐渐向客户端认证方式偏移。本文主要讨论IOS认证上网的解决方案。
IOS端WIFI应用的相关开发，主要存在以下问题

	1.IOS系统WIFI相关的接口很少，大部分接口都是私有接口
	2.在设备连接上WIFI，没有通过路由器认证前，如果关闭IOS自动弹出的Portal页面，Iphone的WIFI会自动断开
	3.如何禁止IOS系统自动弹Portal页面
	4.公共WIFI的名称确定及不确定时的处理办法

本文主要讨论在使用公开的API，即可以提交到App Store的应用。
<!-- more -->


## 二、基础信息获取

### 1.获取网卡IP

``` javascript
+ (NSString *)localIPAddress
{
    NSString *localIP = nil;
    struct ifaddrs *addrs;
    if (getifaddrs(&addrs)==0) {
        const struct ifaddrs *cursor = addrs;
        while (cursor != NULL) {
            if (cursor->ifa_addr->sa_family == AF_INET && (cursor->ifa_flags & IFF_LOOPBACK) == 0)
            {
                NSString *name = [NSString stringWithUTF8String:cursor->ifa_name];
                if ([name isEqualToString:@"en0"]) // Wi-Fi adapter
                {
                    localIP = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)cursor->ifa_addr)->sin_addr)];
                    break;
                }
            }
            cursor = cursor->ifa_next;
        }
        freeifaddrs(addrs);
    }
    return localIP;
}

```

### 2.获取网卡信息

``` javascript
- (NSDictionary *)getWIFIDic
{
    CFArrayRef myArray = CNCopySupportedInterfaces();
    if (myArray != nil) {
        CFDictionaryRef myDict = CNCopyCurrentNetworkInfo(CFArrayGetValueAtIndex(myArray, 0));
        if (myDict != nil) {
            NSDictionary *dic = (NSDictionary*)CFBridgingRelease(myDict);
            return dic;
        }
    }
    return nil;
}

- (NSString *)getBSSID
{
    NSDictionary *dic = [self getWIFIDic];
    if (dic == nil) {
        return nil;
    }
    return dic[@"BSSID"];
}

- (NSString *)getSSID
{
    NSDictionary *dic = [self getWIFIDic];
    if (dic == nil) {
        return nil;
    }
    return dic[@"SSID"];
}

```

**注意事项**

在实际测试时，获取网卡信息**getWIFIDic**方法，在部分路由器上耗时很长(10秒以上)，如果直接放在主线程中，会导致界面卡死。在认证相关的应用中，会根据网卡上的BSSID（例如：以特定3d:e6:c3开头的即为本公司架设网络）来判断是否属于本公司的路由。SSID、BSSID若为应用启动时必须获取的信息（我们公司的应用，就是这种），这个时候怎样处理呢？	

放在异步线程，获取到网卡信息再初使化界面，这种方法依然会导致在某些路由器下初次打开界面超长时间的等待，我们的处理方法是，如果3秒内能够获取到相应的配置信息，直接根据配置信息初使化界面，在超过3秒时，给予默认的假WIFI信息，初使化界面。异步线程获取到真实的配置信息后，再重新更新界面。
	

## 三、认证过程中的棘手问题

### 1、Portal禁止弹出与WIFI自动关闭的问题

正常情况，用户使用Iphone手机连接带有Portal认证的路由器，在连接成功后，IOS系统会在已有列表中随机选择连接指定的网址（例如：www.itools.info）以测试当前路由器是否需要Portal认证。在需要Portal认证的网络，系统会弹出Portal页面，这个时候，如果用关掉portal页面，或者直接切换到其它应用，WIFI网络会直接自动断开（根本不给客户端认证机会^_^）。

我们的解决办法是路由器白名单，让路由器放行所有Portal测试的IP,以下为测试的域名：

	www.appleiphonecell.com
	captive.apple.com
	www.itools.info
	www.ibook.info
	www.airport.us
	www.thinkdifferent.us
	
对应的IP地址：

	23.207.103.91
	23.33.54.18
	23.44.167.91
	23.67.183.91
	96.7.103.91
	23.42.71.91
	23.34.105.211
	23.59.167.91
	23.42.184.50
	23.47.232.190
	23.77.23.91
	23.194.87.91
	23.61.91.190
	23.218.12.50
	23.2.38.95
	23.46.135.91
	172.225.213.179
	218.205.66.94
	23.64.251.249
	23.58.250.189
	
将以上所有IP加到路由器的白名单中，即可解决Iphone断开WIFI的问题，但是同时也不自动弹出Portal页面了，用户打开浏览器才会重定向到Portal页面。

### 2、WIFI名确定解决方法

如果公司部署的公共WIFI名确定的情况，就比较简单了，不需要配置上述白名单也可以保证WIFI不断开，具体办法是，在程序启动时，向IOS系统注册SSID，方法如下：

``` javascript
//注册一个SSID，注意此方法多次调用时，最后一次有效
- (void)registerNetworkOnlyOneSSIDValidate:(NSString *)ssid
{
    [self registerNetwork:@[ssid]];
}

//注册多个SSID，多次调用，最后一次有效
- (void)registerNetwork:(NSArray *)ssidStringArray
{
    
    CFArrayRef ssidCFArray = (__bridge CFArrayRef)ssidStringArray;
    if(!CNSetSupportedSSIDs(ssidCFArray)) {
        return;
    }
    CFArrayRef interfaces = CNCopySupportedInterfaces();
        
    for (int i = 0; i < CFArrayGetCount(interfaces); i++) {
        CFStringRef interface = CFArrayGetValueAtIndex(interfaces, i);
        CNMarkPortalOnline(interface);
    }
    
}

```

## 四、总结

苹果对于WIFI这块公开的API非常少，在开发公共WIFI应用时会遇到各种问题，上面是在使用非私有API的一些解决方案，如果大家有更优的办法，欢迎留言分享。如果公司有企业账号可以通过调用私有API的办法来处理大部分需求。
	
	
