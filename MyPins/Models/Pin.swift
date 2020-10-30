//
//  Pin.swift
//  MyPins
//
//  Created by Ivan Morgun on /3010/20.
//

import Realm
import RealmSwift

class Pin: Object {
    @objc dynamic var title = ""
    @objc dynamic var lat: Double = 0.0
    @objc dynamic var lng: Double = 0.0
    @objc dynamic var color = ""
}
