//
//  ILXMLParse.swift
//  AddressBook
//
//  Created by Mac on 15/4/2.
//  Copyright (c) 2015年 Mac. All rights reserved.
//

import UIKit

@objc(ILCountry)
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

public class ILXMLParse: NSObject {
    
    
    public class func asyncGetAllCountries(callback: (countries: [ILCountry]) -> (Void)) {
        var ret: [ILCountry]?
        self.async({
            ret = self.allCountries()
            },  mainThreadCode: {
                callback(countries: ret!)
        })
    }
    
    public class func asyncGetAllProvinces(callback:(provinces: [ILProvince]) -> (Void)) {
        var ret: [ILProvince]?
        self.async({
            ret = self.allProvinces()
            },  mainThreadCode: {
                callback(provinces: ret!)
        })
    }
    
    public class func asyncGetAllCities(provinceId: String, callback: (cities: [ILCity]) -> (Void)) {
        var ret: [ILCity]?
        self.async({
            ret = self.allCities(provinceId)
            },  mainThreadCode: {
                callback(cities: ret!)
        })
    }
    
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
