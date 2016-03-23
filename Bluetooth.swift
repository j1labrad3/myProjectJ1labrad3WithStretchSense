/*
//
//  Bluetooth.swift
//  bluetooth01
//
//  Created by Jeremy Labrado on 10/03/16.
//  Copyright © 2016 Jeremy Labrado. All rights reserved.
//

import UIKit
import CoreBluetooth



/////////////let deviceName = "StretchSense"



// Service UUIDs
let IRStretchsenseServiceUUID = CBUUID(string: "00001501-7374-7265-7563-6873656e7365")
// Characteristic UUIDs
let IRStretchSenseDataUUID = CBUUID(string: "00001502-7374-7265-7563-6873656e7365")
let IRStretchSenseResetUUID = CBUUID(string: "00001503-7374-7265-7563-6873656e7365")
let IRStretchSenseFreqUUID = CBUUID(string: "00001504-7374-7265-7563-6873656e7365")
let IRStretchSenseShutDownUUID = CBUUID(string: "00001505-7374-7265-7563-6873656e7365")
//let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

//stretchsenseCentralManager = CBCentralManager(delegate: self, queue: nil)

let launchBluetooth = Bluetooth()


class Bluetooth: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    // BLE
    var stretchsenseCentralManager : CBCentralManager! //CBCentralManager object is used to manage the discovered sensors
    var stretchsensePeripheral : CBPeripheral! //The CBPeripheral object represent the discovered peripheral
    
    var titleLabel : String!
    var statusLabel : String! = "stat"
    
    
    //stretchsenseCentralManager = CBCentralManager(delegate: self, queue: nil)
    
   
    func startBluetooth(){
        print("launch1")
        print("\(stretchsenseCentralManager)")
        stretchsenseCentralManager = CBCentralManager(delegate: self, queue: nil)
        print("\(stretchsenseCentralManager)")
        print("\(stretchsenseCentralManager.state)")

        print("launch2")
    }
    
    
    func centralManagerDidUpdateState(central: CBCentralManager) {
        
        //stretchsenseCentralManager = CBCentralManager(delegate: self, queue: nil)
    
        print("centralManagerDidUpdatesStates")
        print("\(stretchsenseCentralManager)")
        print("\(central.state)")
        var consoleMsg = ""
        switch (central.state){
        case .PoweredOff:
            consoleMsg = "BLE is powered off"
        case .PoweredOn:
            consoleMsg = "BLE is powered on"
            print("BLE ON")
            stretchsenseCentralManager.scanForPeripheralsWithServices(nil, options: nil)
            print("BLE ON2")
            //self.statusLabel.text = "Searching for BLE Devices"
            
        case .Resetting:
            consoleMsg = "BLE is resetting"
        case .Unauthorized:
            consoleMsg = "BLE is unauthorized"
        case .Unknown:
            consoleMsg = "BLE is unknown"
        case .Unsupported:
            consoleMsg = "BLE is nos supported"

        }
        print("\(consoleMsg)")
        ////////statusLabel = consoleMsg
        //consoleLabel.text = consoleMsg
    }
    
    
    // Check out the discovered peripherals to find Sensor Tag
    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        let nameOfDeviceFound = (advertisementData as NSDictionary).objectForKey(CBAdvertisementDataLocalNameKey) as? NSString
        
        
        if nameOfDeviceFound != nil {
            //print("nameOfDeviceFound != nil")
            print("nameOfDeviceFound : \(nameOfDeviceFound!)")
            if (nameOfDeviceFound! == deviceName) {
                
                // Update Status Label
                print("StretchSense Founded")
                statusLabel = "StretchSense Found"
                // Stop scanning, set as the peripheral to use and establish connection
                self.stretchsenseCentralManager.stopScan()
                //print("stopScan")
                self.stretchsensePeripheral = peripheral
                self.stretchsensePeripheral.delegate = self
                //print("peripheral before : \(peripheral)")
                self.stretchsenseCentralManager.connectPeripheral(peripheral, options: nil)
                //print("try to connect")
                //print("peripheral after connection: \(peripheral)")
                
                
            }
            else {
                statusLabel = "StretchSense NOT Found"
                //showAlertWithText(/*header:*/ "Warning", message: "SensorTag Not Found")
            }
        }
        else{
            print("nameOfDeviceFound = nil")
        }
    }
    
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral/*, advertisementData: [String : AnyObject], RSSI: NSNumber*/) {
        print("didConnectPeripheral")
        print ("Peripheral: \(peripheral)")
        statusLabel = "Discovering peripheral services"
        peripheral.discoverServices(nil)
    }
    
    // If disconnected, start searching again
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("didDisconnectPeripheral")
        if (error != nil) {
            print("Error :  \(error?.localizedDescription)");
        }
        //statusLabel = "Disconnected"
        central.scanForPeripheralsWithServices(nil, options: nil)
        print("5. \(statusLabel)")
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("didDiscoverServices")
        statusLabel = "Looking at peripheral services"
        for service in peripheral.services! {
            if (error != nil) {
                print("Error:  \(error?.localizedDescription)");
            }
            let thisService = service as CBService
            if service.UUID == IRStretchsenseServiceUUID {
                // Discover characteristics of all valid services
                peripheral.discoverCharacteristics(nil, forService: thisService) //call the disDiscoverCharacteristicForService()
            }
            print(thisService.UUID)
        }
    }
    
    
    // Enable notification and sensor for each characteristic of valid service
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("didDiscoverCharacteristicsForService")
        // update status label
        statusLabel = "Enabling sensors"
        // check the uuid of each characteristic to find config and data characteristics
        
        for charateristic in service.characteristics! {
            let thisCharacteristic = charateristic as CBCharacteristic
            // check for data characteristic
            if thisCharacteristic.UUID == IRStretchSenseDataUUID {
                // Enable Sensor Notification
                self.stretchsensePeripheral.setNotifyValue(true, forCharacteristic: thisCharacteristic)
            }
        }
        
        
    }
    
    // Get data values when they are updated
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        //print("didUploadValueForCharacteristic")
        statusLabel = "Connected"
        if (error != nil) {
            print("Error Upload :  \(error?.localizedDescription)");
        }
        
        if characteristic.UUID == IRStretchSenseDataUUID {
            // Convert NSData to array of signed 16 bit values
            let ValueSensor = characteristic.value!
            //print("1. \(ValueSensor)")
            let valueInt = ValueSensor.hexadecimalString()
            //print("2. \(valueInt!)")
            let valueInt2 = String(Int!(Int(valueInt!, radix: 16)))
            //print("3. \(valueInt2)")
            statusLabel = valueInt2
            print("4. \(statusLabel)")
            
            // Display on the temp label
            //self.tempLabel.text = valueInt2
           // ViewController.displayStatusLabel(statusLabel!)
            
        }
        //updateViewConstraints()
    }
    
    /******* Helper *******/
     
     // Show alert
    func showAlertWithText (header : String = "Warning", message : String) {
        print("showAlertWithText")
        let alert = UIAlertController(title: header, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
        alert.view.tintColor = UIColor.redColor()
        //self.presentViewController(alert, animated: true, completion: nil)
    }
    

    
    
}*/
