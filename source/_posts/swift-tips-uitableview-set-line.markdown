---
title: Swift之UITableView线条的设置
date: 2016-06-22 10:53:00
comments: true
keywords: Swift UITableView线条,UITableView line,UITableView 通栏, UITableView 线条设置
categories: experience
---

## 一、内容概要
UITableView在开发过程，使用非常多，设计对线条有不同的要求，本文主要介绍线条相关的设置方法:

{% img /images/article/Swift之UITableView线条的设置/image_0.png %}


<!-- more -->

## 二、代码设置

### 2.1通栏设置
通栏即UITableView的线条左右端间距都为0的情况，通栏的设置需要分别设置UITableView及UITableViewCell的layoutMargins属性

第一步设置UITableView
``` swift
tableView.layoutMargins = UIEdgeInsetsZero
```
第二步设置UITableViewCell
``` swift
tableViewCell.layoutMargins = UIEdgeInsetsZero
```

### 2.2线条左右等间距
左右等间距，分两种情况，一种间距大于系统默认左端间距，一种为小于系统默认左端艰巨

大于系统默认左端间距时，直接设置UITableview属性

``` swift
tableView.separatorInset = UIEdgeInsetsMake(0, 20, 0, 20)
```

小于系统默认左端间距时，则多增加一个步骤：
	
	* 按2.1先设置成通栏
	* 再按上面步骤设置UITableView的separatorInset属性


### 2.3Group风格扁平化
UITableView的plain style默认为扁平化风格，这里介绍group style如何进行扁平化设置。添加扩展：

``` swift
extension UITableView {
    
    private var FLAG_TABLE_VIEW_CELL_LINE: Int {
        get { return 977322 }
    }
    
    //自动添加线条
    func autoAddLineToCell(cell: UITableViewCell, indexPath: NSIndexPath, lineColor: UIColor) {
        
        let lineView = cell.viewWithTag(FLAG_TABLE_VIEW_CELL_LINE)
        if self.isNeedShow(indexPath) {
            if lineView == nil {
                self.addLineToCell(cell, lineColor: lineColor)
            }
        } else {
            lineView?.removeFromSuperview()
        }
        
    }
    
    private func addLineToCell(cell: UITableViewCell, lineColor: UIColor) {
        let view = UIView(frame: CGRectMake(0, 0, self.bounds.width, 0.5))
        view.tag = FLAG_TABLE_VIEW_CELL_LINE
        view.backgroundColor = lineColor
        cell.contentView.addSubview(view)
    }
    
    private func isNeedShow(indexPath: NSIndexPath) -> Bool {
        let countCell = self.countCell(indexPath.section)
        if countCell == 0 || countCell == 1 {
            return false
        }
        if indexPath.row == 0 {
            return false
        }
        return true
    }
    
    
    
    private func countCell(atSection: Int) -> Int {
        return self.numberOfRowsInSection(atSection)
    }
    
}

```

#### 2.3.1代码设置
第一步，设置UITableView的separatorStyle属性
``` swift
tableView.separatorStyle = .None
```
第二步，设置Cell

``` swift
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(ILTableView_Cell)
        //省略逻辑...
        
        //设置
        tableView.autoAddLineToCell(cell!, indexPath: indexPath, lineColor: UIColor.lightGrayColor())
        
        return cell!
    }
```

#### 2.3.2 Storyboard设置
新建自定义类，ILTableViewController

``` swift
class ILTableViewController: UITableViewController {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAtIndexPath: indexPath)
        
        //设置
        tableView.autoAddLineToCell(cell, indexPath: indexPath, lineColor: UIColor.lightGrayColor())
        
        return cell
    }
}
```


在storybarod中找到Controller中的class属性，设置为ILTableViewController，并修改UITableView的**separatorStyle**为**None**