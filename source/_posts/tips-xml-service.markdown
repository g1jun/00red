---
layout: post
title: "XML国际电话代码国内地区服务"
date: 2015-04-21 09:45:26 +0800
comments: true
keywords: IOS国际代码,地区XML,swift xml
categories: tips
---

## 一、解决的问题
在很多应用的注册界面中，会有国家电话代码供选择，以方便验证码的发送;以及有些需要填写简单的城市信息，这里提供封装好的API供大家直接使用，API主要功能(Swift语言实现):

	1.世界所有的国家的电话代码
	2.国内所有省份数据
	3.提供根据省份直接查询该省所有市
	4.提供根据市直接查询该市所有县区
<!-- more -->	

## 二、使用的框架
整体逻辑，先将XML数据文件解析成NSDictionary,然后再将NSDictionary解析成具体的实体对象：	
1.[XMLDictionary](https://github.com/nicklockwood/XMLDictionary)提供将XML数据解析成NSDictionary<br>
2.[JSONModel](https://github.com/icanzilb/JSONModel)提供将NSDictionary解析到具体实体对象<br>
3.XML数据文件下载：[国家电话代码](/download/xml_service/Country.xml) [省份](/download/xml_service/Provinces.xml) [城市](/download/xml_service/Cities.xml) [县区](/download/xml_service/Districts.xml) [ILXMLParse源代码](/download/xml_service/ILXMLParse.swift)


## 三、API说明及使用示例

1、API说明
获取所有国家电话代码
``` javascript
public class func asyncGetAllCountries(callback: (countries: [ILCountry]) -> (Void))
```

获取国内所省份
``` javascript
public class func asyncGetAllProvinces(callback:(provinces: [ILProvince]) -> (Void))
```

根据省份ID获取所有城市
``` javascript
public class func asyncGetAllCities(provinceId: String, callback: (cities: [ILCity]) -> (Void))
```

根据城市ID获取所有县区
``` javascript
public class func asyncGetAllDistrict(cityId: String, callback: (districts: [ILDistrict]) -> (Void))
```


2、使用国家电话代码示例
``` javascript
ILXMLParse.asyncGetAllCountries { (countries) -> (Void) in
            self.allCountries = countries
            self.tableView.reloadData()
        }
```


## 四、具体代码

1、实体类代码

``` javascript

public class ILCountry: JSONModel {
    var Country_name: NSString!
    var Country_name_CN: NSString!
    var DialingCode: NSString!
    var Code: NSString!
    var NumberCode: NSString!
    
}

public class ILProvince: JSONModel {
    var _ID: NSString!
    var _ProvinceName: NSString!
}

public class ILCity: JSONModel {
    var _ID: NSString!
    var _CityName: NSString!
    var _PID: NSString!
    var _ZipCode: NSString!
}

public class ILDistrict: JSONModel {
    var _ID: NSString!
    var _PID: NSString!
}

```

2、*ILXMLParse*功能实现类代码

``` javascript
public class ILXMLParse: NSObject {
    
    //获取所有国家电话代码
    public class func asyncGetAllCountries(callback: (countries: [ILCountry]) -> (Void)) {
        var ret: [ILCountry]?
        self.async({
            ret = self.allCountries()
            },  mainThreadCode: {
                callback(countries: ret!)
        })
    }
    
    //获取国内所有省份
    public class func asyncGetAllProvinces(callback:(provinces: [ILProvince]) -> (Void)) {
        var ret: [ILProvince]?
        self.async({
            ret = self.allProvinces()
            },  mainThreadCode: {
                callback(provinces: ret!)
        })
    }
    
    //根据省份ID查询城市
    public class func asyncGetAllCities(provinceId: String, callback: (cities: [ILCity]) -> (Void)) {
        var ret: [ILCity]?
        self.async({
            ret = self.allCities(provinceId)
            },  mainThreadCode: {
                callback(cities: ret!)
        })
    }
    
    //根据城市ID查询县区
    public class func asyncGetAllDistrict(cityId: String, callback: (districts: [ILDistrict]) -> (Void)) {
        var ret: [ILDistrict]?
        self.async({
            ret = self.allDistrict(cityId)
            },  mainThreadCode: {
                callback(districts: ret!)
            })
        
    }
    
    private class func async(asyncCode: (Void -> Void), mainThreadCode: (Void -> Void )) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            asyncCode()
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                mainThreadCode()
            })
        })
    }
    
    private class func allCountries() -> Array<ILCountry> {
        return self.readXMLToMap("Country", rootLabel: "Country")
    }
    
    private class func allProvinces() -> Array<ILProvince> {
        
        return self.readXMLToMap("Provinces", rootLabel: "Province")
    }
    

    
    private class func allCities(provinceId: String) -> Array<ILCity> {
        var cities = self.readXMLToMap("Cities", rootLabel: "City") as [ILCity]
        var retArray: [ILCity] = []
        for city in cities {
            if city._PID == provinceId {
                retArray.append(city)
            }
        }
        return retArray
    }
    
    private class func allDistrict(cityId: String) -> Array<ILDistrict> {
        let districts = self.readXMLToMap("Districts", rootLabel: "District") as [ILDistrict]
        var retArray: [ILDistrict] = []
        for district in districts {
            if district._PID == cityId {
                retArray.append(district)
            }
        }
        return retArray
    }
    
    
    //注意，以下为Swift2.0语法
    private class func readXMLToMap<T: JSONModel>(fileName: String, rootLabel: String) -> [T]  {
        let dic = self.loadXMLDcionaryData(fileName)
        let array = dic[rootLabel] as! NSArray
        var ret: [T] = []
        for tempDic in array {
            let dic = tempDic as! NSDictionary
            //注意，Swift1.2使用以下两行代码
            //let bean = T(dictionary: dic as! [NSString : NSString], error: nil)
            //ret.append(bean)
            do {
                let bean = try T(dictionary: dic as! [NSString : NSString])
                ret.append(bean)
            } catch {
                print(error)
            }
        }
        return ret
    }

    
    private class func loadXMLDcionaryData(fileName: String) -> NSDictionary {
        let filePath = NSBundle.mainBundle().pathForResource(fileName, ofType: "xml")
        let dic = NSDictionary(XMLFile: filePath)
        return dic
    }
   
}

```