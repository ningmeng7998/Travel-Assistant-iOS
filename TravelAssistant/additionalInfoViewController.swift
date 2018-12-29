//
//  additionalInfoViewController.swift
//  TravelAssistant
//
//  Created by ning li on 14/10/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseAuth
import CoreLocation

class additionalInfoViewController: UIViewController{
    
    
    var ref: DatabaseReference?
    var transport: String?
    var distance: Double?
    var outdoorHour: Double?
    let uid = (Auth.auth().currentUser?.uid)!
    
    @IBOutlet weak var addressTextField: UITextField!
    
    @IBOutlet weak var sensorIDTextField: UITextField!
    
    @IBAction func transportSegement(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0{
            transport = "walk"
        }else if sender.selectedSegmentIndex == 1{
            transport = "public transport"
        }else{
            transport = "private vehicle"
        }
    }
    
    @IBAction func distanceSegement(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0{
            distance = 1
        }else if sender.selectedSegmentIndex == 1{
            distance = 3
        }else if sender.selectedSegmentIndex == 2{
            distance = 5
        }else if sender.selectedSegmentIndex == 3{
            distance = 10
        }else{
            distance = 50
        }
    }
    
    @IBAction func outdoorHour(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0{
            outdoorHour = 1
        }else if sender.selectedSegmentIndex == 1{
            outdoorHour = 3
        }else if sender.selectedSegmentIndex == 2{
            outdoorHour = 5
        }else if sender.selectedSegmentIndex == 3{
            outdoorHour = 10
        }else{
            outdoorHour = 50
        }
    }

    @IBAction func doneButton(_ sender: UIButton) {

        var alert: UIAlertController?
        let action = UIAlertAction(title: "OK", style: .default)
        
        //validating the address
        let inputLocationIsValid = checkAlphNumerics(input: (addressTextField.text!))
        
        //Send alert if the address is empty
        if (addressTextField.text?.isEmpty)!{
            alert = UIAlertController(title:"Invalid Address", message: "Address cannot be null! ", preferredStyle: .alert)
            alert?.addAction(action)
            self.present(alert!, animated: true, completion: nil)
            return
        }
        
        //Send alert if the address contains invalid signs
        if inputLocationIsValid == false{
            alert = UIAlertController(title:"Invalid Address", message: "Only letters and numbers are accepted! ", preferredStyle: .alert)
            alert?.addAction(action)
            self.present(alert!, animated: true, completion: nil)
            return
        }
        
        //Validate the sensor id
        let inputSensorIDIsValid = checkAlphNumerics(input: sensorIDTextField.text!)
        
        //Send alert if the sensor id is empty
        if (sensorIDTextField.text?.isEmpty)!{
            alert = UIAlertController(title:"Invalid Sensor ID", message: "SensorID cannot be null! ", preferredStyle: .alert)
            alert?.addAction(action)
            self.present(alert!, animated: true, completion: nil)
            return
        }
        
        //Send alert if sensor id is invalid
        if inputSensorIDIsValid == false{
            alert = UIAlertController(title:"Invalid Sensor ID", message: "Only letters and numbers are accepted! ", preferredStyle: .alert)
            alert?.addAction(action)
            self.present(alert!, animated: true, completion: nil)
            return
        }
        getCoordinate(address: addressTextField.text!)
    }
    
   
    //Convert coordination from the address
    func getCoordinate(address:String)->(Double,Double){
        let geocoder = CLGeocoder()
        var coordinates:CLLocationCoordinate2D?
        var latitude: Double = 0
        var longitude: Double = 0
        
        //If the address are not null, get the first address and convert to
        geocoder.geocodeAddressString(address, completionHandler: {(placemarks, error) -> Void in
            if((error) != nil){
                print("Error", error ?? "")
            }
            if let placemark = placemarks?.first {
                coordinates = placemark.location!.coordinate
            }
            //If the coordinates are not null, get the first address and convert to coordinates
            if coordinates != nil {
                print("Contains a value!")
                print("location text field \(address)")
                print("Lat: \(String(describing: coordinates?.latitude)) -- Long: \(String(describing: coordinates?.longitude))")
                latitude  = (coordinates?.latitude)!
                longitude = (coordinates?.longitude)!
                self.setupDataAndMoveToNextViewController(coordinate: (latitude,longitude))
            } else {
                print("Doesn’t contain a value.")
            }
        })
        print("Lat****: \(String(describing: coordinates?.latitude)) -- Long*****: \(String(describing: coordinates?.longitude))")
        return(latitude,longitude)
    }
    
    //Set coresponding data
    func setupDataAndMoveToNextViewController(coordinate:(Double,Double)){
        print("latitude = \(coordinate.0),longitude = \(coordinate.1)")
        var dict = [String: Any]()
        dict["latitude"] = coordinate.0
        dict["longitude"] = coordinate.1
        print("lat\(String(describing: dict["latitude"])) long\(String(describing: dict["longitude"]))")
        
        dict["sensorID"] = sensorIDTextField.text!
        dict["transport"] = transport
        dict["distance"] = distance
        dict["outdoorHour"] = outdoorHour
        dict["address"] = addressTextField.text!
        let ref = Database.database().reference()
        ref.child(self.uid).child("personalInfo").updateChildValues(dict)
        print("values in segments\(dict.keys)")
        
        self.performSegue(withIdentifier: "homeSegue", sender: nil)
    }
    
    //Check if the input only contains letters and numbers
    func checkAlphNumerics(input: String) -> Bool{
        let allowedChars = NSCharacterSet.alphanumerics.union(NSCharacterSet.whitespaces)
        let inputChars = NSCharacterSet.init(charactersIn: input)
        return allowedChars.isSuperset(of: inputChars as CharacterSet)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
