//
//  HomePageViewController.swift
//  TravelAssistant
//
//  Created by ning li on 13/10/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth
import UserNotifications

class HomePageViewController: UIViewController,UNUserNotificationCenterDelegate {

    var ref: DatabaseReference?
    let uid = (Auth.auth().currentUser?.uid)!
    var itemString = ""
    
    @IBOutlet weak var indoorTextField: UITextField!
    
    @IBOutlet weak var outdoorTextField: UITextField!
    
    @IBOutlet weak var northTextView: UITextView!
    @IBOutlet weak var westTextView: UITextView!
    @IBOutlet weak var eastTextView: UITextView!
    @IBOutlet weak var southTextView: UITextView!
    @IBOutlet weak var compassImageView: UIImageView!
    
    

    
    @IBAction func forecastButton(_ sender: Any) {
        self.performSegue(withIdentifier: "forecastSegue", sender: self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference()
        recommend(completion: nil)
        //Display indoor and outdoor temperature
        indoorAndOutdoorTemperature()
        // Send notification
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge], completionHandler: {didAllow, error in
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("got some notifications")
        //displaying the ios local notification when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    //Get data from firebase and display
    func indoorAndOutdoorTemperature(){
        ref?.child(uid).observe(.value, with: { (snapshot) in
            let data = snapshot.value as! Dictionary<String,Any>
            let sensorIndoor = data["sensorIndoor"] as! Dictionary<String,Any>
            let moreDirections = data["moreDirections"] as! Dictionary<String, Any>
            let temp = moreDirections["temp"] as! Dictionary<String, Any>
            let indoorTemp = sensorIndoor["temp"] as! Double
            if indoorTemp != -100{
                self.indoorTextField.text = "\(indoorTemp)°C"
            }else{
                self.indoorTextField.text = "0°C"
            }
            if let outdoorTemp = temp["h"]{
                self.outdoorTextField.text = "\(outdoorTemp)°C"
            }
        })
    }
    
    // Fill the recommendation field
    func recommend(completion:((String)->())?){
        var directions:Dictionary<String,UITextView>?
        directions = ["n":northTextView,"s":southTextView,"e":eastTextView,"w":westTextView]
        for direction in directions!{
            recommender(direction: direction.key, vc: direction.value)
        }
        if let completion = completion{
            completion(self.itemString)
        }
    }
 
    //Make recommendations based on various conditions
    func recommender(direction: String, vc: UITextView){
        var recommedItemString = ""
        ref?.child(uid).observe(.value, with: { (snapshot) in
            let data = snapshot.value as! Dictionary<String,Any>
            
            let sensorIndoor = data["sensorIndoor"] as! Dictionary<String, Any>
            let indoorTemp = sensorIndoor["temp"] as! Double

            let moreDirections = data["moreDirections"] as! Dictionary<String, Any>
            let weatherCon = moreDirections["weatherCondition"] as! Dictionary<String,Any>
            let UVindex = moreDirections["UVindex"] as! Dictionary<String, Double>
            let uv = UVindex[direction]
            let weather = weatherCon[direction] as! String

            let temperature = moreDirections["temp"] as! Dictionary<String, Double>
            let outdoorTemp = temperature[direction]

            let personalInfo = data["personalInfo"] as! Dictionary<String, Any>
            let transport = personalInfo["transport"] as? String
            let outdoorHour = personalInfo["outdoorHour"] as? Double

            // Conditions for recommending sun screen
            if (indoorTemp != -100){
                if uv! > 2.0 || outdoorHour! > 2{
                    recommedItemString.append("Sun Screen \n")
                }
            }
            
            // Conditions for recommending myki
            if transport == "public transport"{
                recommedItemString.append("MyKi\n")
            }

            //Conditions for redommending sun glasses
            if (transport == "private vehicle" && uv! > 4.0) ||
                (transport == "walk" && uv! > 4.0) {
                recommedItemString.append("Sun Glasses\n")
            }

            //Conditions for recommending water bottle
            if abs(indoorTemp - outdoorTemp!) > 5 && outdoorTemp! > 30 && indoorTemp != -100{
                recommedItemString.append("Water\n")
            }
            
            //Conditions for recommending coat
            if(indoorTemp != -100){
                if (abs(indoorTemp - outdoorTemp!) > 5) || weather == "rainy" || weather == "cloudy" {
                    recommedItemString.append("coat\n")
                }
            }
            
            //Conditions for recommending umbrella
            if weather == "rainy" || weather == "cloudy"{
                recommedItemString.append("umbrella\n")
            }
         
            //Set the recommendation list
            vc.text = recommedItemString
            self.itemString = recommedItemString
            print("recommed item string \(recommedItemString)")
        })
        
    }
    
    // send notifications
    func sendAlert(){
        ref?.child(uid).child("sensorIndoor").child("motion").observe(.value, with: { (snapshot) in
            // detect the motion of a user
            // send alert accordingly
            let content = UNMutableNotificationContent()
            
            //adding title, subtitle, body and badge
            content.title = "Recommended items"
            content.body = self.itemString
            content.badge = 1
            
            //getting the notification trigger
            //it will be called after 3 seconds
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            
            //getting the notification request
            let request = UNNotificationRequest(identifier: "SimplifiedIOSNotification", content: content, trigger: trigger)
            
            //adding the notification to notification center
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        })
    }
}
