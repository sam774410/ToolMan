//
//  driverViewController.swift
//  EasyUber
//
//  Created by 呂明聲 on 2018/11/17.
//  Copyright © 2018 MingShengLyu. All rights reserved.
//

import UIKit
import UIKit
import FacebookLogin
import FBSDKLoginKit
import FacebookCore
import GoogleMaps
import FirebaseDatabase
import CoreLocation
import CDAlertView

class driverViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var tableView: UITableView!
    //firebase
    let reference = Database.database().reference()
    var riderRequest : [DataSnapshot] = []
    
    //location
    let locationManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()
    var driverName:String?
    
    //get firebase data
    func retrieveData() {
        
        reference.child("RiderRequest").observe(.childAdded) { (dataSnapShot) in
            
            if let riderRequestDic = dataSnapShot.value as? [String : Any]{
                
                if riderRequestDic["driverLat"] != nil{
                    
                }else{
                    self.riderRequest.append(dataSnapShot)
                    dataSnapShot.ref.removeAllObservers()
                    self.tableView.reloadData()
                }
            }
            //print(dataSnapShot.value)
            //print(riderRequestDic["email"])
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        driverLocation = (manager.location?.coordinate)!
        print("司機位置:\(driverLocation.latitude), \(driverLocation.longitude)")
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return riderRequest.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! riderTableViewCell
        let snapShot = riderRequest[indexPath.row]
        
        if let riderRequestDic = snapShot.value as? [String:Any] {
            
            if let email = riderRequestDic["email"] as? String {
                
                if let latitude = riderRequestDic["latitude"] as? Double {
                    
                    if let longitude = riderRequestDic["longitude"] as? Double {
                        
                        if let name = riderRequestDic["name"] as? String {
                            
                            if let imgUrl = riderRequestDic["imgUrl"] as? String {
                                
                                //let distance = CLLocation
                                
                                let riderCLLocation = CLLocation(latitude: latitude, longitude: longitude)
                                let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                
                                let distance = riderCLLocation.distance(from: driverCLLocation) / 1000
                                let roundedDistance = round(distance * 100) / 100
                                
                                if let image = UIImage(named: "user"){
                                    let riderDetails = "距離約  \(roundedDistance) km"
                                    
                                    cell.congfigureCell(profileImg: imgUrl, name: name, email: email, detail: riderDetails)
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let snapShot = riderRequest[indexPath.row]
        if let riderRequestDic = snapShot.value as? [String:Any] {
            
            if let latitude = riderRequestDic["latitude"] as? Double {
                
                if let longitude = riderRequestDic["longitude"] as? Double {
                    
                    if let name = riderRequestDic["name"] as? String {
                        let email = riderRequestDic["email"] as? String
                        let alert = CDAlertView(title: "即將前往導航", message:"確定接取\(name)嗎?", type: CDAlertViewType.warning)
                        let cancel = CDAlertViewAction(title: "取消 🙅🏻",textColor: .red)
                        alert.add(action: cancel)
                        
                        let confirm = CDAlertViewAction(title: "確定 🤤",  textColor: .green) { (CDAlertViewAction) -> Bool in
                            
                            //update
                            self.pickUp(email: email!, name: self.driverName!)
                        UIApplication.shared.openURL(URL(string:"https://www.google.com/maps/?q=\(latitude),\(longitude)")!)
                             return true
                        }
                        
                        alert.add(action: confirm)
                        
                        alert.show()
                    }
                   
                }
            }
        }
        
    }

    @IBAction func logoutBtn(_ sender: UIBarButtonItem) {
        
        let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginVC")
        dismiss(animated: true, completion: nil)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getUserDetail()
        retrieveData()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (timer) in
            self.riderRequest = []
            self.retrieveData()
            self.tableView.reloadData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //self.riderRequest = []
        //self.retrieveData()
    }
    
    func getUserDetail(){
        
        guard let _ = AccessToken.current else{return}
        let param = ["fields":"name, email , picture.type(large)"]
        let graphRequest = GraphRequest(graphPath: "me", parameters: param)
        graphRequest.start(){ (urlResponse, requestResult) in
            
            switch requestResult{
                
            case .success(response: let graphResponse):
                if let responseDictionary = graphResponse.dictionaryValue{
                    print(responseDictionary)
                    let name = responseDictionary["name"] as! String
                    let email = responseDictionary["email"] as! String
                    if let photo = responseDictionary["picture"] as? NSDictionary{
                        let data = photo["data"] as! NSDictionary
                        let picURL = data["url"] as! String
                        print(name, picURL, email)
                        
                        DispatchQueue.main.async {
                            
                            self.driverName = name
                        }
                    }
                }
            case .failed(let error):
                print(error)
            }
        }
    }
    
    func pickUp(email:String, name:String) {
        
        reference.child("RiderRequest").queryOrdered(byChild: "email").queryEqual(toValue: email).observeSingleEvent(of: DataEventType.childAdded) { (dataSnapShot) in
            
            dataSnapShot.ref.updateChildValues(["driverLat" : self.driverLocation.latitude, "driverLon" : self.driverLocation.longitude,"driverName" : name])
            
        }
    }


}
