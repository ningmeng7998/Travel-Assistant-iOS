//
//  ForecastViewController.swift
//  TravelAssistant
//
//  Created by ning li on 14/10/18.
//  Copyright © 2018 ning li. All rights reserved.
//

import UIKit
import FirebaseAuth
import SwiftChart
import FirebaseDatabase


class ForecastViewController: UIViewController {
    
    var ref: DatabaseReference?

    var tempArray:[(Int,Double)] = []
    var windSpeedArray:[(Int,Double)] = []
    var uvindexArray:[(Int,Double)] = []
    
    @IBOutlet weak var temperatureChart: Chart!
    @IBOutlet weak var windSpeedChart: Chart!
    @IBOutlet weak var UVIndexChart: Chart!
    
    //Display the data according to the slider
    @IBAction func slideValueChanged(_ sender: UISlider) {
        
        print("new value \(sender.value)")
        let intValue = Int(sender.value)
        print("conver to int \(intValue)")
        sender.setValue(Float(intValue), animated: true)
        
        let newTempArray = tempArray.filter { (arg0) -> Bool in
            return arg0.0 <= (intValue * 3)
        }
        drawChart(data: newTempArray, color: UIColor.green, chart: temperatureChart)
        
        let newWindSpeedArray = windSpeedArray.filter { (arg0) -> Bool in
            return arg0.0 <= (intValue * 3)
        }
        drawChart(data: newWindSpeedArray, color: UIColor.blue, chart: windSpeedChart)
        
        let newuvindexArray = uvindexArray.filter { (arg0) -> Bool in
            return arg0.0 <= (intValue * 3)
        }
        drawChart(data: newuvindexArray, color: UIColor.black, chart: UVIndexChart)
    }
    
    //Log the user out
    @IBAction func logoutButton(_ sender: UIBarButtonItem) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        ref = Database.database().reference()
        createChart()
    }
    
    // Create the chart
    func createChart(){
        let uid = (Auth.auth().currentUser?.uid)!
        
        ref?.child(uid).observe(.value, with: { (snapshot) in

            let data = snapshot.value as! Dictionary<String,Dictionary<String,Any>>
            let forecast = data["forecast"]
            let temperature = forecast?["temp"]
            print("data is \(String(describing: data))")
            print("forecast is \(String(describing: forecast))")
            print("temp is \(String(describing: temperature))")
            
            let tempValue = self.extractDoublesFromDictionary(key: "temp", source: forecast!)
            self.tempArray = tempValue
            //self.drawChart(data: tempValue, color: UIColor.green, chart: self.temperatureChart)
            
            let windSpeedValue = self.extractDoublesFromDictionary(key: "windSpeed", source: forecast!)
            self.windSpeedArray = windSpeedValue
            //self.drawChart(data: windSpeedValue, color: UIColor.blue, chart: self.windSpeedChart)
            
            let uvindexValue = self.extractDoublesFromDictionary(key: "UVindex", source: forecast!)
            self.uvindexArray = uvindexValue
            //self.drawChart(data: uvindexValue, color: UIColor.black, chart: self.UVIndexChart)
        })
    }
    
    //change the x label and y label format and draw the chart
    func drawChart(data:[(Int,Double)],color:UIColor, chart: Chart){
        let series = ChartSeries(data: data)
        series.color = color
        series.area = true
        
        // Use `xLabels` to add more labels, even if empty
        chart.xLabels = [0,3,6,9,12,15,18,21]
        print("chart.xlabels is \(String(describing: chart.xLabels))")
        
        // Format the labels with a unit
        chart.xLabelsFormatter = { String(Int(round($1))) + "h" }
        
        switch chart {
        case temperatureChart:
            chart.yLabelsFormatter = {String(Int(round($1))) + "°C"}
        case windSpeedChart:
            chart.yLabelsFormatter = {String(Int(round($1))) + "km/h"}
        default:
            print("This is the default value")
        }
        chart.removeAllSeries()
        chart.add([series])
    }
    
    //Extract the double value from the data stored in a dictionary
    func extractDoublesFromDictionary(key:String,source:Dictionary<String,Any>)->[(Int,Double)]{
        let dictionary = source[key] as! Dictionary<String,Double>
        let formatter = DateFormatter()
        
        var keys = Array(dictionary.keys)
        //sort keys first
        keys.sort(by: { (a, b) -> Bool in
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let date1 = formatter.date(from: a)
            let date2 = formatter.date(from: b)
            
            return date1!<date2!
        })
        let pairArray = keys.map { (akey) -> (x:Int, y:Double) in
            // get value
            let yValue = dictionary[akey]
            // convert key to hour
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let keyDate = formatter.date(from: akey)
            
            formatter.dateFormat = "HH"
            let hourString = formatter.string(from: keyDate!)
            
            print("aKey == \(akey), hours = \(hourString)")
            return (Int(hourString)!,yValue!)
        }
        print("the pairArray looks like this:\(pairArray)")
        return pairArray
    }
}
