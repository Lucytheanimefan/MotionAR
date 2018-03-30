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

    var mediaPicker: MPMediaPickerController?
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var selectedMusicLabel: UILabel!
    var musicAssetURL:URL!

    var selectedARViz:ARVisualization!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ARVisualizationManager.shared.delegate = self
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if ARVisualizationManager.shared.needsRefresh{
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            ARVisualizationManager.shared.needsRefresh = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addARVisualization(_ sender: UIButton) {
        self.performSegue(withIdentifier: "addVizSegue", sender: self)
    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? ARViewController{
            vc.option = self.option
            //vc.musicAssetURL = self.musicAssetURL
            vc.ARVizSettings = self.selectedARViz
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
        self.selectedMusicLabel.text = musicItem.title
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

extension ViewController: UITableViewDelegate{
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "visualizationCell") as! ARSettingVizTableViewCell
        cell.title.text = ARVisualizationManager.shared.visualizations[indexPath.row].name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row < ARVisualizationManager.shared.visualizations.count else{
            return
        }
        self.selectedARViz = ARVisualizationManager.shared.visualizations[indexPath.row]
        self.selectedARViz.musicAssetURL = self.musicAssetURL
        // Update the object that's stored
        ARVisualizationManager.shared.visualizations[indexPath.row] = self.selectedARViz
        self.performSegue(withIdentifier: "toARView", sender: self)
    }
}

extension ViewController: UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ARVisualizationManager.shared.visualizations.count
    }
}

extension ViewController: ARVisualizationManagerDelegate{
    func onSettingChange() {
        self.tableView.reloadData()
    }
}
