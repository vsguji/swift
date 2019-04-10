//
//  AwareButton.swift
//  OSLogDemo
//
//  Created by lipeng on 2019/4/9.
//  Copyright © 2019 lipeng. All rights reserved.
//

// 防止重复点击UIButton

import Foundation
import UIKit

// 定义protocol
public protocol SelfAware:class {
  static func awake()
}

// 创建代理执行单例
class NothingToSeeHere {
    static func harmlessFunction(){
        var autoreleasingTypes:AutoreleasingUnsafeMutablePointer<AnyClass>? = nil
        let typeCount = Int(objc_getClassList(nil, 0))
        let types = UnsafeMutablePointer<AnyClass?>.allocate(capacity: typeCount)
        autoreleasingTypes = AutoreleasingUnsafeMutablePointer<AnyClass>(types)
        objc_getClassList(autoreleasingTypes, Int32(typeCount))
        for index in 0 ..< typeCount {
            (types[index] as? SelfAware.Type)?.awake()
        }
        types.deallocate()
    }
}


// 执行单例

extension UIApplication {
    private static let runOnce:Void = {
        NothingToSeeHere.harmlessFunction()
    }()
    
    override open var next:UIResponder? {
        UIApplication.runOnce
        return super.next
    }
}

// 将类设置为代理并在代理中实现运行时代码

extension UIButton:SelfAware {
    public static func awake() {
        let changeBefore:Method = class_getInstanceMethod(self, #selector(UIButton.sendAction(_:to:for:)))!
        let changeAfter:Method = class_getInstanceMethod(self, #selector(UIButton.cs_sendAction(action:to:for:)))!
        method_exchangeImplementations(changeBefore, changeAfter)
    }
    private struct cs_associatedKeys {
        static var accpetEventInterval = "cs_acceptEventInterval"
        static var accpetEventTime = "cs_acceptEventTime"
    }
    
    var cs_accpetEventInterval:TimeInterval {
        get {
            if let accpetEventInterval = objc_getAssociatedObject(self, &cs_associatedKeys.accpetEventInterval) as? TimeInterval {
                return accpetEventInterval
            }
            return 5
        }
        set {
            objc_setAssociatedObject(self, &cs_associatedKeys.accpetEventInterval, newValue as TimeInterval, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var cs_acceptEventTime:TimeInterval {
        get {
            if let accpetEventTime = objc_getAssociatedObject(self, &cs_associatedKeys.accpetEventTime) as? TimeInterval {
                return accpetEventTime
            }
            return 5
        }
        set {
            objc_setAssociatedObject(self, &cs_associatedKeys.accpetEventTime, newValue as TimeInterval, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    @objc func cs_sendAction(action:Selector,to target:AnyObject?,for event:UIEvent?) {
        if Date().timeIntervalSince1970 - self.cs_acceptEventTime < self.cs_accpetEventInterval {
            return
        }
        if self.cs_accpetEventInterval > 0 {
            self.cs_acceptEventTime = Date().timeIntervalSince1970
        }
        self.cs_sendAction(action: action, to: target, for: event)
    }
}
