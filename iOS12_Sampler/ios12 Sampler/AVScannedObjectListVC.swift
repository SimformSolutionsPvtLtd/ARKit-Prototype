//
//  AVScannedObjectListVC.swift
//  ios12 Sampler
//
//  Created by Testing on 13/06/18.
//  Copyright © 2018 Testing. All rights reserved.
//

import UIKit

class AVScannedObjectListVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    static let kArObject = "arobject"
    static let kPng = "png"
    var arrObjectName:[String] = []
    var arrObejectURL :[[String:URL]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getAllStoredObjectModelFromDirectory()
        // Do any additional setup after loading the view.
    }
    func getAllStoredObjectModelFromDirectory() {
        let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        do {
            let directoryContents = try FileManager.default.contentsOfDirectory(at: documentsUrl, includingPropertiesForKeys: nil, options: [])
            let arobjectFiles = directoryContents.filter{ $0.pathExtension == AVScannedObjectListVC.kArObject || $0.pathExtension == AVScannedObjectListVC.kPng }
            print("arobject urls:",arobjectFiles)
            let fileName = arobjectFiles.map{ $0.deletingPathExtension().lastPathComponent }
            print("object Name list:", fileName)
            for itm in arobjectFiles {
                if "\(itm)".contains(AVScannedObjectListVC.kArObject){
                    print("contain ARobejct")
                    arrObejectURL.append([AVScannedObjectListVC.kArObject:itm])
                } else {
                    print("contain image")
                    arrObejectURL.append([AVScannedObjectListVC.kPng:itm])
                }
            }
            arrObjectName = fileName
            if arrObjectName.count == 0 {
                self.tableView.setBackgroundText(stringValue: "There is no Scanned/Saved objects available. \n Please Scan and Save Object from Scan New Object Section.")
                self.tableView.reloadData()
            } else {
                self.tableView.removeBackgroundText()
                self.tableView.delegate = self
                self.tableView.dataSource = self
                self.tableView.reloadData()
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}
extension AVScannedObjectListVC:UITableViewDelegate,UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrObjectName.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        let label = cell?.viewWithTag(10) as? UILabel
        label?.text = arrObjectName[indexPath.row]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AVReadARObjectVC") as! AVReadARObjectVC
        if arrObejectURL[indexPath.row].keys.first == AVScannedObjectListVC.kArObject {
            vc.objectURL = arrObejectURL[indexPath.row][AVScannedObjectListVC.kArObject]
        } else {
            vc.imageURL = arrObejectURL[indexPath.row][AVScannedObjectListVC.kPng]
        }
        
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let Delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            print("more button tapped")
            let fileManager = FileManager.default
            let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
            let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
            let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
            guard let dirPath = paths.first else {
                return
            }
            var filename = ""
            if (self.arrObejectURL[indexPath.row].keys.first)! == AVScannedObjectListVC.kArObject {
                filename = "\(self.arrObjectName[indexPath.row]).\(AVScannedObjectListVC.kArObject)"
            } else {
                filename = "\(self.arrObjectName[indexPath.row]).\(AVScannedObjectListVC.kPng)"
            }
            let filePath = "\(dirPath)/\(filename)"
            do {
                try fileManager.removeItem(atPath: filePath)
                self.arrObjectName.remove(at: indexPath.row)
                self.arrObejectURL.remove(at: indexPath.row)
                self.tableView.reloadData()
            } catch let error as NSError {
                print(error.debugDescription)
            }
        }
        Delete.backgroundColor = .lightGray
        return [Delete]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
}
extension UITableView {
    
    func setBackgroundText(stringValue:String) {
        let backgroundLabel = UILabel()
        backgroundLabel.font = UIFont.systemFont(ofSize: 14)
        backgroundLabel.textColor = .black
        backgroundLabel.numberOfLines = 0
        
        backgroundLabel.textAlignment = .center
        backgroundLabel.text = stringValue
        
        backgroundLabel.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundLabel.translatesAutoresizingMaskIntoConstraints = true
        
        self.backgroundView = backgroundLabel
    }
    
    func removeBackgroundText() {
        self.backgroundView = nil
    }
}
