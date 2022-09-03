//
//  ViewController.swift
//  ExitekIOSDeveloperTechTask
//
//  Created by Vadim Igdisanov on 03.09.2022.
//

import UIKit

enum MobileCastError: Error {
    case mobileExists
    case mobileDoesNotExist
}

extension MobileCastError: CustomStringConvertible {
    var description: String {
        switch self {
        case .mobileExists:
            return "mobile with this imei exists"
        case .mobileDoesNotExist:
            return "mobile imei does not exist"
        }
    }
}

struct Mobile: Hashable, Codable {
    let imei: String
    let model: String
}

protocol MobileStorage {
    func getAll() -> Set<Mobile>
    func findByImei(_ imei: String) -> Mobile?
    func save(_ mobile: Mobile) throws -> Mobile
    func delete(_ product: Mobile) throws
    func exists(_ product: Mobile) -> Bool
}

class ViewController: UIViewController {
    
    @IBOutlet var saveTextFields: [UITextField]!
    @IBOutlet var deleteTextField: [UITextField]!
    @IBOutlet var existsTextField: [UITextField]!
    @IBOutlet weak var findByImeiTextField: UITextField!
    @IBOutlet weak var productCollectionView: UITableView!
    
    private var textForTableView: [String] = []
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        productCollectionView.delegate = self
        productCollectionView.dataSource = self
    }
    
    @IBAction func saveButtonAction(_ sender: Any) {
        textForTableView.removeAll()
        guard let imei = saveTextFields[0].text, let model = saveTextFields[1].text  else {return}
        let mobile = Mobile(imei: imei, model: model)
        do {
            let resultMobile = try save(mobile)
            textForTableView.append("Mobile imei-\(resultMobile.imei) mpdel-\(resultMobile.model) saved")
        } catch let error as MobileCastError {
            switch error {
                
            case .mobileExists:
                textForTableView.append(error.description)
            default: break
            }
        } catch {
            print("some error")
        }
        productCollectionView.reloadData()
        
        for textField in saveTextFields {
            textField.text = ""
        }
    }
    
    @IBAction func deleteButtonAction(_ sender: Any) {
        textForTableView.removeAll()
        guard let imei = deleteTextField[0].text, let model = deleteTextField[1].text  else {return}
        let mobile = Mobile(imei: imei, model: model)
        do {
            try delete(mobile)
            textForTableView.append("Mobile removed")
        } catch let error as MobileCastError {
            switch error {
            case .mobileDoesNotExist:
                textForTableView.append(error.description)
            default: break
            }
        } catch {
            print("some error")
        }
        productCollectionView.reloadData()
        
        for textField in deleteTextField {
            textField.text = ""
        }
    }
    
    @IBAction func existsButtonAction(_ sender: Any) {
        textForTableView.removeAll()
        guard let imei = existsTextField[0].text, let model = existsTextField[1].text  else {return}
        let mobile = Mobile(imei: imei, model: model)
        if exists(mobile) {
            textForTableView.append("Such a mobile exists")
        } else {
            textForTableView.append("This mobile does not exist")
        }
        productCollectionView.reloadData()
        
        for textField in existsTextField {
            textField.text = ""
        }
    }
    
    @IBAction func findByImeiButtonAction(_ sender: Any) {
        textForTableView.removeAll()
        guard let imei = findByImeiTextField.text, let mobile = findByImei(imei) else {return}
        textForTableView.append("\(mobile.imei)-\(mobile.model)")
        productCollectionView.reloadData()
        findByImeiTextField.text = ""
    }
    
    @IBAction func getAllButtonAction(_ sender: Any) {
        textForTableView.removeAll()
        let mobiles = getAll()
        for mobile in mobiles {
            textForTableView.append("\(mobile.imei)-\(mobile.model)")
        }
        productCollectionView.reloadData()
    }
    
}

// MARK: TableView

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return textForTableView.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = self.productCollectionView.dequeueReusableCell(withIdentifier: "mobileCell", for: indexPath)
        cell.textLabel?.text = textForTableView[indexPath.row]
        return cell
    }
    
    
    
}

// MARK: MobileStorage

extension ViewController: MobileStorage {
    
    func getAll() -> Set<Mobile> {
        let mobiles = StorageManager.shared.fetchMobile()
        return mobiles.reduce(into: Set<Mobile>()) { (mobiles, mobile) in
            mobiles.insert(mobile.value)
            return
        }
    }
    
    func findByImei(_ imei: String) -> Mobile? {
        let mobiles = StorageManager.shared.fetchMobile()
        for (key, value) in mobiles {
            if key == imei {
                return value
            }
        }
        return nil
    }
    
    func save(_ mobile: Mobile) throws -> Mobile {
        guard let savedMobile = StorageManager.shared.save(mobile: mobile) else { throw MobileCastError.mobileExists }
        return savedMobile
    }
    
    func delete(_ product: Mobile) throws {
        guard let _ = StorageManager.shared.delete(at: product) else {throw MobileCastError.mobileDoesNotExist}
    }
    
    func exists(_ product: Mobile) -> Bool {
        let mobiles = StorageManager.shared.fetchMobile()
        for (_, value) in mobiles {
            if value == product {
                return true
            }
        }
        return false
    }
    
    
}


// MARK: StorageManager

class StorageManager {
    static let shared = StorageManager()
    private init() {}
    private let userDefaults = UserDefaults.standard
    private let mobileKey = "mobiles"
    
    func save(mobile: Mobile) -> Mobile? {
        var mobiles = fetchMobile()
        let result = mobiles.updateValue(mobile, forKey: mobile.imei)
        guard result == nil else {return nil}
        guard let data = try? JSONEncoder().encode(mobiles) else {return nil}
        userDefaults.set(data, forKey: mobileKey)
        return mobile
    }
    
    func fetchMobile() -> [String: Mobile] {
        guard let data = userDefaults.object(forKey: mobileKey) as? Data else {return [:]}
        guard let savedMobiles = try? JSONDecoder().decode([String: Mobile].self, from: data) else {return [:]}
        return savedMobiles
    }
    
    func delete(at mobile: Mobile) -> Mobile? {
        var mobiles = fetchMobile()
        if   let removeMobile = mobiles.removeValue(forKey: mobile.imei) {
            guard let data = try? JSONEncoder().encode(mobiles) else {return nil}
            userDefaults.set(data, forKey: mobileKey)
            return removeMobile
        }
        return nil
    }
}
