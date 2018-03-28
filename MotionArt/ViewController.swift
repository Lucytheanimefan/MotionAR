//
//  ViewController.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/16/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import UIKit
import MediaPlayer
class ViewController: UIViewController {
    
    // "anime" or "motion"
    var option:String! = "motion"
    
    // Choosing existing music from itunes
    var mediaPicker: MPMediaPickerController?
    var musicAssetURL:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func toARView(_ sender: UIButton) {
        self.option = sender.restorationIdentifier
        self.performSegue(withIdentifier: "toARView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ARViewController{
            vc.option = self.option
            vc.musicAssetURL = self.musicAssetURL
        }
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


extension ViewController: MPMediaPickerControllerDelegate{
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        // Get the file
        let musicItem = mediaItemCollection.items[0]
        if let assetURL = musicItem.value(forKey: MPMediaItemPropertyAssetURL) as? URL
        {
            self.musicAssetURL = assetURL
        }
        
        
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        self.dismiss(animated: true, completion: nil)
    }
}
