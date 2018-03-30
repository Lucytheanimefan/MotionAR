//
//  NewVisualizationViewController.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/29/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import UIKit
import MediaPlayer

class NewVisualizationViewController: UIViewController {

    var visualization = ARVisualization()
    
    var mediaPicker: MPMediaPickerController?
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var boxDimensionsField: UITextField!
    @IBOutlet weak var ringSeparationField: UITextField!
    @IBOutlet weak var numRingsField: UITextField!
    @IBOutlet weak var selectedMusicLabel: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        boxDimensionsField.delegate = self
        ringSeparationField.delegate = self
        numRingsField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(sender:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(sender:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func keyboardWillShow(sender: NSNotification) {
        print("Move view 150 points upward")
        self.view.frame.origin.y = -150 // Move view 150 points upward
    }
    
    @objc func keyboardWillHide(sender: NSNotification) {
        print("Move view to original position")
        self.view.frame.origin.y = 0 // Move view to original position
    }
    
    @IBAction func save(_ sender: UIBarButtonItem) {
        visualization.name = self.nameField.text
        if let rings = self.numRingsField.text{
            visualization.num_rings = Int(rings)!
        }
        if let sep = self.ringSeparationField.text{
            visualization.ring_separation = Float(sep)!
        }
        if let box = self.boxDimensionsField.text{
            visualization.box_dimensions = Float(box)!
        }
        ARVisualizationManager.shared.addSetting(setting: visualization)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }

 

}


extension NewVisualizationViewController: UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // allow backspace
        // allow digit 0 to 9
        return (string.count > 0) || (Int(string) != nil)

    }
}
