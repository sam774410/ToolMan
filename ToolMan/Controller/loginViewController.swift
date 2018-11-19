//
//  loginViewController.swift
//  EasyUber
//
//  Created by 呂明聲 on 2018/11/17.
//  Copyright © 2018 MingShengLyu. All rights reserved.
//

import UIKit
import Pastel
import TransitionButton
import FacebookLogin
import FBSDKLoginKit
import FacebookCore
import UIView_Shake
import NotificationBannerSwift

class loginViewController: UIViewController {

    @IBOutlet weak var loginBtn: TransitionButton!
    @IBOutlet weak var driverOrRider: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setloginBtn()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        setBG()
        
    }
    
    func fbLogIn() {
        
        let loginManager = LoginManager()
        
        
        loginManager.logIn(readPermissions: [.email, .publicProfile], viewController: self) { (loginResult) in
            
            switch loginResult{
                
            case .success(let grantedPermissions, let declinedPermissions, let token):
                
                print("user log in")
                let banner = StatusBarNotificationBanner(title: "登入成功", style: .success)
                banner.show()
                //self.getUserDetail()
                self.loginBtn.stopAnimation(animationStyle: StopAnimationStyle.expand, revertAfterDelay: 0.5, completion: {
                    
                    if self.driverOrRider.isOn {
                        //rider
                        self.performSegue(withIdentifier: "riderSegue", sender: self)
                    } else {
                        //driver
                        self.performSegue(withIdentifier: "driverSegue", sender: self)
                    }
                })
                
            case .cancelled:
                
                print("the user cancels login")
                let banner = StatusBarNotificationBanner(title: "登入失敗", style: .danger)
                banner.show()
                self.loginBtn.stopAnimation()
                self.loginBtn.shake()
            case .failed(let error):
                
                print(error)
                let banner = StatusBarNotificationBanner(title: error as! String, style: .danger)
                banner.show()
                self.loginBtn.stopAnimation()
                self.loginBtn.shake()
            }
        }
        
    }
    
    func setloginBtn(){
        
        loginBtn.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        loginBtn.spinnerColor = .white
        loginBtn.cornerRadius = 10
        loginBtn.clipsToBounds = true
    }
    
    @objc func buttonAction(){
        
        loginBtn.startAnimation()
        fbLogIn()
    }

    



    
    func setBG(){
        
        let pastelView = PastelView(frame: view.bounds)
        // Custom Direction
        pastelView.startPastelPoint = .bottomLeft
        pastelView.endPastelPoint = .topRight
        // Custom Duration
        pastelView.animationDuration = 2.0
        pastelView.setColors([UIColor(red:0.99, green:0.89, blue:0.54, alpha:1.0), UIColor(red:0.95, green:0.51, blue:0.51, alpha:1.0)])
        
        pastelView.startAnimation()
        view.insertSubview(pastelView, at: 0)
    }

}
