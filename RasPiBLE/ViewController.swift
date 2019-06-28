//
//  ViewController.swift
//  bletest
//
//  Created by Keiji Suzuki on 2019/06/28.
//  Copyright © 2019 Keiji Suzuki. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral!
    private var characteristic: CBCharacteristic!

    var value: CUnsignedChar = 0

    enum ConnState {
        case off
        case scan
        case connect
        case disconnect
    }
    var cstate: ConnState = .off

    private let targetService: CBUUID = CBUUID(string: "FF10")
    private let targetCharacteristic: CBUUID = CBUUID(string: "FF11")

    @IBOutlet weak var button: UIButton!
    @IBOutlet weak var onoff: UISwitch!


    override func viewDidLoad() {
        super.viewDidLoad()

        // 1-1. CentralManagerの起動
        centralManager = CBCentralManager(delegate: self, queue: nil)
        button.isEnabled = false
        onoff.isEnabled  = false
    }

    // 1-2. CentralManager状態の受信
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            button.isEnabled = true
        }
    }

    // 2-2. Peripheral探索結果の受信(複数あれば複数回)
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        print("discovered peripheral")
        print("name: \(String(describing: peripheral.name))")
        print("UUID: \(peripheral.identifier.uuidString)")

        self.peripheral = peripheral

        // 省電力のためスキャンを停止
        print("stop scan")
        centralManager.stopScan()

        // 3-1. 指定したPeripheralへ接続開始
        print("connect...")
        button.setTitle("コネクト中...", for: .normal)
        centralManager.connect(peripheral, options: nil)
    }

    // 3-2. Peripheralへの接続結果の受信(成功時)
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connected")
        button.setTitle("コネクト", for: .normal)
        peripheral.delegate = self

        // 4-1. 対象Serviceの探索開始
        peripheral.discoverServices([targetService])
    }

    // 3-2. Peripheralへの接続結果の受信(失敗時)
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("connect failed")
    }

    // 4-2. Service探索結果の受信
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            print("discover service error: \(String(describing: error))")
            return
        }

        for service in peripheral.services! {
            // 5-1. 利用可能Characteristicの探索開始
            print("discover characteristic FF11")
            button.setTitle("キャラクタ検索中...", for: .normal)
            peripheral.discoverCharacteristics([targetCharacteristic], for: service)
        }
    }

    // 5-2. Characterristic探索結果の受信
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print("discover chara error: \(String(describing: error))")
            return
        }
        print("discovered characteristic FF11")
        for charact in service.characteristics! {
            button.setTitle("切断する", for: .normal)
            cstate = .connect
            onoff.isEnabled = true
            self.characteristic = charact
        }
    }

    // 6.2. Peripheral切断の確認
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("discconected")
        cstate = .off
        onoff.isEnabled = false
        button.setTitle("接続する", for: .normal)
    }

    @IBAction func operate(_ sender: UIButton) {
        if cstate == .off {
            // 2-1. Peripheral探索開始
            button.setTitle("スキャン中...", for: .normal)
            cstate = .scan
            centralManager.scanForPeripherals(withServices: [targetService], options: nil)
        } else if cstate == .connect {
            // 6.1. Peripheralを切断
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    @IBAction func switchOnOff(_ sender: UISwitch) {
        if sender.isOn {
            print("write on")
            value = 1
            peripheral.writeValue(Data(bytes: &value, count: 1), for: characteristic, type: .withResponse)
        } else {
            print("write off")
            value = 0
            peripheral.writeValue(Data(bytes: &value, count: 1), for: characteristic, type: .withResponse)
        }
    }
}

