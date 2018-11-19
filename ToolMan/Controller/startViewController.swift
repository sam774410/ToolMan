//
//  startViewController.swift
//  ToolMan
//
//  Created by 呂明聲 on 2018/11/19.
//  Copyright © 2018 MingShengLyu. All rights reserved.
//

import UIKit

class startViewController: UIViewController {

    let carLogo = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        carLogo.image = UIImage(named: "car")
        carLogo.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        carLogo.center = view.center
        view.addSubview(carLogo)
    }
    

    override func viewDidAppear(_ animated: Bool) {
        
        UIView.animate(withDuration: 0.5, animations: {
            
            self.carLogo.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
            self.carLogo.center = self.view.center
        }) { (finished) in
            
            UIView.animate(withDuration: 0.4, animations: {
                
                self.carLogo.frame = CGRect(x: 0, y: 0, width: 20000, height: 20000)
                self.carLogo.center = self.view.center
            })
            
            let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginVC")
            
            self.present(loginVC, animated: true, completion: nil)
        }
    }

}
