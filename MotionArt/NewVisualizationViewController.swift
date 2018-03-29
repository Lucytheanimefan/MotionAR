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
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
 
    
    @IBAction func displayMediaPicker(_ sender: UIButton) {
        self.displayMediaPicker()
    }
    
    func displayMediaPicker(){
        mediaPicker = MPMediaPickerController(mediaTypes: .anyAudio)
        
        if let picker = mediaPicker{
            picker.delegate = self
            view.addSubview(picker.view)
            self.present(picker, animated: true, completion: nil)
        }
        else
        {
            print("Error: Couldn't instantiate media picker")
        }
    }

}

extension NewVisualizationViewController: MPMediaPickerControllerDelegate{
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // Get the file
        let musicItem = mediaItemCollection.items[0]
        self.selectedMusicLabel.text = musicItem.title
        if let assetURL = musicItem.value(forKey: MPMediaItemPropertyAssetURL) as? URL
        {
            visualization.musicAssetURL = assetURL
            //self.musicAssetURL = assetURL
        }
        
        
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}

extension NewVisualizationViewController: UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // allow backspace
        // allow digit 0 to 9
        return (string.count > 0) && (Int(string) != nil)

    }
}