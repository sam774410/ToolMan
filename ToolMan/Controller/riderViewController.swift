//
//  riderViewController.swift
//  EasyUber
//
//  Created by 呂明聲 on 2018/11/17.
//  Copyright © 2018 MingShengLyu. All rights reserved.
//

import UIKit
import FacebookLogin
import FBSDKLoginKit
import FacebookCore
import GoogleMaps
import FirebaseDatabase
import CoreLocation


class riderViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    //firebase DB
    let reference = Database.database().reference()
    let locationManager = CLLocationManager()
    var userLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var driverName:String?
    let userMarker = GMSMarker()
    
    let user = UserDataModel()
    
    var toolManHasBeenCalled = false
    var toolManOnTheWay = false
    
    @IBOutlet weak var mMapView: GMSMapView!
    
    
    @IBOutlet weak var startCallBtn_Outlet: UIButton!
    
    @IBAction func startCallBtn(_ sender: UIButton) {
        
        if !toolManOnTheWay {
            
            if toolManHasBeenCalled {
                //取消訂單
                reference.child("RiderRequest").queryOrdered(byChild: "email").queryEqual(toValue: user.user_email).observe(DataEventType.childAdded) { (dataSnapShot) in
                    dataSnapShot.ref.removeValue()
                    
                    self.reference.child("RiderRequest").removeAllObservers()
                }
                
                //變可以呼叫
                cancelToolManMode()
            } else {
                //新增訂單
                let riderRequestDic:[String:Any] = ["email": user.user_email, "name": user.user_name, "imgUrl": user.user_imgUrl, "latitude": userLocation.latitude,  "longitude": userLocation.longitude]
                reference.child("RiderRequest").childByAutoId().setValue(riderRequestDic)
                
                //變可以取消
                callToolManMode()
            }
        }
       
    }
    
    
    @IBAction func logoutBtn(_ sender: UIBarButtonItem) {
        
        let loginVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginVC")
       dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setDelegate()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        //permimission setting
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        } else if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted{
            locationManager.requestWhenInUseAuthorization()
        }
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            //locationManager.startUpdatingHeading()
        }
        
        //init map
        let camera = GMSCameraPosition.camera(withLatitude: 24.970963, longitude: 121.193523, zoom: 7)
        mMapView.camera = camera

        
        //get user profile
        if FBSDKAccessToken.currentAccessTokenIsActive() {
            
            getUserDetail()
        }
        
        //init mode
        cancelToolManMode()
        
        //檢查是否已被接單
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (timer) in
            self.updateLocation()
            //print("check")
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if CLLocationManager.authorizationStatus() == .denied || CLLocationManager.authorizationStatus() == .restricted{
            locationManager.requestWhenInUseAuthorization()
        }
        
    }
    
    func callToolManMode(){
        startCallBtn_Outlet.setTitle("取消呼叫", for: .normal)
        startCallBtn_Outlet.backgroundColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        startCallBtn_Outlet.setTitleColor(#colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1), for: .normal)
        
        toolManHasBeenCalled = true
    }
    
    func cancelToolManMode(){
        startCallBtn_Outlet.setTitle("呼叫工具人", for: .normal)
        startCallBtn_Outlet.backgroundColor = #colorLiteral(red: 0.4500938654, green: 0.9813225865, blue: 0.4743030667, alpha: 1)
        startCallBtn_Outlet.setTitleColor(#colorLiteral(red: 0.5704585314, green: 0.5704723597, blue: 0.5704649091, alpha: 1), for: .normal)
        
        toolManHasBeenCalled = false
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
                            
                            self.user.user_email = email
                            self.user.user_name = name
                            self.user.user_imgUrl = picURL
//                            let imgData = NSData(contentsOf: URL(string: picURL)!)
//                            self.nameLabel.text = name
//                            self.genderLabel.text = gender
//                            let userImage = UIImage(data: imgData! as Data)
//                            self.imagePhoto.image = userImage
                        }
                    }
                }
            case .failed(let error):
                print(error)
            }
        }
    }
    
    func setDelegate() {
        
        mMapView.delegate = self
        locationManager.delegate = self
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let coordinate:CLLocationCoordinate2D = manager.location?.coordinate {
            userLocation = coordinate
            print("rider現在位置：\(userLocation.longitude)+\(userLocation.latitude)")
            
            //已被接單
            if toolManOnTheWay {
                
                displayDriverAndRider()
            } else {
                
                UIView.animate(withDuration: 5, animations: {
                    
                    if let userLocation:CLLocationCoordinate2D = self.userLocation{
                        
                        let camera = GMSCameraPosition.camera(withLatitude: userLocation.latitude, longitude: userLocation.longitude, zoom: 17)
                        self.mMapView.mapType = .normal
                        self.mMapView.camera = camera
                        
                        //set user marker
                        self.userMarker.map = self.mMapView //nil消失
                        self.userMarker.position = CLLocationCoordinate2D(latitude: userLocation.latitude, longitude: userLocation.longitude)
                        self.userMarker.title = "I'm here"
                        
                        self.userMarker.icon = GMSMarker.markerImage(with: .green)
                        
                    }
                })
            }
        }
    }
    
    //檢查是否已接單
    func updateLocation() {
        
        reference.child("RiderRequest").queryOrdered(byChild: "email").queryEqual(toValue: user.user_email).observe(DataEventType.childAdded) { (dataSnapShot) in
            
            self.callToolManMode()
            
            if let driverRequestDic = dataSnapShot.value as? [String : Any]{
                
                if let driverLat = driverRequestDic["driverLat"] as? Double, let driverLon = driverRequestDic["driverLon"] as? Double, let driverName = driverRequestDic["driverName"] as? String{
                    
                        self.driverLocation.latitude = driverLat
                        self.driverLocation.longitude = driverLon
                        self.driverName = driverName
                    
                        self.toolManOnTheWay = true
                    self.reference.child("RiderRequest").removeAllObservers()
                }
            }
        }
    }
    
    func displayDriverAndRider() {
        
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let riderCLLocation = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)
        
        let distance = driverCLLocation.distance(from: riderCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        
        startCallBtn_Outlet.setTitle("您的工具人約 \(roundedDistance)km away", for: .normal)
        
        let driverMarker = GMSMarker()
        driverMarker.position = CLLocationCoordinate2D(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        driverMarker.title = "工具人\(driverName!)"
        driverMarker.icon = GMSMarker.markerImage(with: .yellow)
        driverMarker.map = mMapView
        
        let camera = GMSCameraPosition.camera(withLatitude: driverLocation.latitude, longitude: driverLocation.longitude, zoom: 15)
        self.mMapView.mapType = .normal
        self.mMapView.camera = camera
    }
    

}
