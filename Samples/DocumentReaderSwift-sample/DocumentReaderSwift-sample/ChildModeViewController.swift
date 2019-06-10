//
//  ChildModeViewController.swift
//  DocumentReaderFullSwift-sample
//
//  Created by Dmitry Smolyakov on 9/21/18.
//  Copyright © 2018 Dmitry Smolyakov. All rights reserved.
//

import UIKit
import DocumentReader

class ChildModeViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var initializationLabel: UILabel!
    @IBOutlet weak var presentButton: UIButton!
    
    @IBOutlet weak var presentationView: UIView!
    
    var cameraViewController: UIViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializationReader()
    }
    
    func initializationReader() {
        //initialize license
        guard let dataPath = Bundle.main.path(forResource: "regula.license", ofType: nil) else { return }
        guard let licenseData = try? Data(contentsOf: URL(fileURLWithPath: dataPath)) else { return }
        
        presentButton.isHidden = true
        
        RGLDocReader.shared().prepareDatabase(withID: "Full", progressHandler: { (progress) in
            guard let progress = progress else { return }
            let progressValue = String(format: "%.1f", progress.fractionCompleted * 100)
            self.initializationLabel.text = "Downloading database: \(progressValue)%"
        }, completion: { (successfull, error) in
            self.initializationLabel.text = "Initialization..."
            RGLDocReader.shared().initializeReader(withLicense: licenseData) { (successfull, error) in
                if successfull {
                    self.activityIndicator.stopAnimating()
                    self.initializationLabel.isHidden = true
                    self.presentButton.isHidden = false
                    
                    //Get available scenarios
                    for scenario in RGLDocReader.shared().availableScenarios {
                        print(scenario)
                        print("--------")
                    }
                  
                    //set scenario
                    if let firstScenario = RGLDocReader.shared().availableScenarios.first {
                      RGLDocReader.shared().processParams.scenario = firstScenario.identifier
                    }

                } else {
                    self.activityIndicator.stopAnimating()
                    let licenseError = error ?? "Unknown error"
                    self.initializationLabel.text = "Initialization error: \(licenseError)"
                    print(licenseError)
                }
            }
          
            //scan window will not be closed automatically, you should close it manually
            RGLDocReader.shared().functionality.singleResult = false
        })
    }
    
    @IBAction func presentTapped(_ sender: UIButton) {
        
        let vc = RGLDocReader.shared().prepare(nil) { (action, result, error) in
            switch action {
            case .complete:
                print("COMPLETED")
                print("RESULTS:")
                // handle results and stop scan
                // go though all text results
                // more info: https://github.com/regulaforensics/DocumentReader-iOS/wiki/Handle-scan-results
                guard let result = result else { return }
                for textField in result.textResult.fields {
                    guard let value = result.getTextFieldValue(by: textField.fieldType, lcid: textField.lcid) else { continue }
                    print("Field type name: \(textField.fieldName), value: \(value)")
                }
                // stop scan
                self.stopScan()
            case .morePagesAvailable:
                print("MORE PAGES AVAILABLE")
            case .cancel:
                self.stopScan()
                print("CANCEL")
            case .error:
                print("ERROR")
            case .process:
                print("PROCESS") // you can handle intermediate result here
            }
        }
        
        cameraViewController = vc
        
        self.addChild(cameraViewController!)
        cameraViewController?.view.frame = self.presentationView.frame
        self.view.addSubview(cameraViewController!.view)
        cameraViewController!.didMove(toParent: self)        
    }
    
    func stopScan() {
        self.cameraViewController?.willMove(toParent: nil)
        self.cameraViewController?.view.removeFromSuperview()
        self.cameraViewController?.removeFromParent()
        self.cameraViewController = nil
    }
}
