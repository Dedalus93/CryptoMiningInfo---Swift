//
//  ProgressHUD.swift
//  CryptoInfoMining
//
//  Created by Samith Aturaliyage on 10/12/24.
//

import Foundation
import SVProgressHUD

class ProgressHUD {
    
    static func initStyle(){
        SVProgressHUD.setMinimumSize(CGSize.zero)
        SVProgressHUD.setRingRadius(18)
        SVProgressHUD.setRingThickness(2)
    }
    
    static func show(status : String? = nil) {
        initStyle()
        SVProgressHUD.show(withStatus: status)
    }
    
    static func showProgress(progress : Float, status : String) {
        initStyle()
        SVProgressHUD.showProgress(progress, status: status)
    }
    
    static func showProgressForFlyer(progress : Float, name: String = "") {
        let width = UIScreen.main.bounds.width
        SVProgressHUD.setRingRadius(36)
        SVProgressHUD.setRingThickness(4)
        SVProgressHUD.setMinimumSize(CGSize(width: width - 20, height: 200))
        SVProgressHUD.showProgress(progress, status: "Download \(name)")
    }
    
    static func dismiss(){
        SVProgressHUD.dismiss()
    }
    
    static func showSuccess(withStatus : String?){
        initStyle()
        SVProgressHUD.showSuccess(withStatus:withStatus ?? nil)
    }
    
}

