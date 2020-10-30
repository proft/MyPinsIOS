//
//  SettingsViewController.swift
//  MyPins
//
//  Created by Ivan Morgun on /3010/20.
//

import UIKit
import RealmSwift
import JGProgressHUD

class SettingsViewController: UIViewController {
    var markers = [Pin]()
    let realm = try! Realm()
    
    let radiusLabel = UILabel(text: "Radius", font: .boldSystemFont(ofSize: 18))
    let radiusTF: UITextField = {
        let v = UITextField()
        v.placeholder = "Radius in meters"
        v.backgroundColor = UIColor(white: 0, alpha: 0.03)
        v.borderStyle = .roundedRect
        v.font = UIFont.systemFont(ofSize: 14)
        v.keyboardType = .numberPad
        v.addTarget(self, action: #selector(handleTextInputChange), for: .editingChanged)
        return v
    }()
    
    let colorLabel = UILabel(text: "Color of pin", font: .boldSystemFont(ofSize: 18))
    let colorPickerView = ColorPickerView()
    
    let clearButton: UIButton = {
        let v = UIButton(type: .system)
        v.setTitle("Clear all pins", for: .normal)
        v.backgroundColor = UIColor(red: 149/255, green: 204/255, blue: 244/255, alpha: 1)
        v.layer.cornerRadius = 5
        v.titleLabel?.font = UIFont.boldSystemFont(ofSize: 14)
        v.setTitleColor(.white, for: .normal)
        v.addTarget(self, action: #selector(handleClear), for: .touchUpInside)
        return v
    }()
    
    lazy var overallStackView = UIStackView(arrangedSubviews: [
        radiusLabel, radiusTF, colorLabel, colorPickerView, clearButton
    ])
    
    @objc func handleClear() {
        let all = realm.objects(Pin.self)
        let total = all.count
        try! realm.write {
            realm.delete(all)
        }
        
        let hud = JGProgressHUD(style: .dark)
        hud.textLabel.text = "Deleting \(total) pins"
        hud.show(in: self.view)
        hud.dismiss(afterDelay: 2)
    }
    
    @objc func handleTextInputChange() {
        UserData.searchRadius = Int(radiusTF.text ?? "") ?? 1000
    }
    
    fileprivate func setupUI() {
        navigationItem.title = "Settings"
        view.backgroundColor = .white
        
        radiusTF.text = String(UserData.searchRadius)
        colorLabel.textColor = UIColor(hex: UserData.pinColor)
        
        colorPickerView.constrainWidth(250)
        colorPickerView.constrainHeight(100)
        clearButton.constrainHeight(44)
        
        overallStackView.distribution = .fillProportionally
        overallStackView.axis = .vertical
        overallStackView.spacing = 16
        view.addSubview(overallStackView)
        
        overallStackView.anchor(top: view.safeAreaLayoutGuide.topAnchor, leading: view.leadingAnchor, bottom: nil, trailing: view.trailingAnchor, padding: .init(top: 16, left: 8, bottom: 0, right: 8))
        
        colorPickerView.onColorDidChange = { [weak self] color in
            DispatchQueue.main.async {
                self?.colorLabel.textColor = color
                UserData.pinColor = color.toHex()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTapGesture()
        setupUI()
    }
    
    func setupTapGesture() {
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapDismiss)))
    }
    
    @objc func handleTapDismiss() {
        self.view.endEditing(true)
    }
}
