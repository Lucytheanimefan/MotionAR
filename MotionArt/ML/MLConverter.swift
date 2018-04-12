//
//  MLConverter.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/30/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

//import UIKit
import CoreML


class MLConverter: NSObject {
    //declare an array of curve/label pairs
    var training_samples: [knn_curve_label_pair] = [knn_curve_label_pair]()
    
    //intantiate the library
    let knn_dtw: KNNDTW = KNNDTW()
    
    override init() {
        
    }
    
    func appendSample(curve:[Float], label:String){
        //add a couple curve/label pair to the training data
        training_samples.append(knn_curve_label_pair(curve: curve, label: label))
    }
    
    func appendToExistingSample(curve:[Float], label:String){
        let i = training_samples.index { (label_pair) -> Bool in
            return (label_pair.label == label)
        }
//        let sample = training_samples.first { (label_pair) -> Bool in
//            return (label_pair.label == label)
//        }
        
        if (i == nil){
            training_samples.append(knn_curve_label_pair(curve: curve, label: label))
        }
        else {
            training_samples[i!].curve.append(contentsOf: curve)
        }
        
    }
    
    func train(){
        //train the model with known samples
        knn_dtw.train(data_sets: training_samples)
    }
    
    func export(){
        print("TRAINING SAMPLES:")
        print(self.training_samples)
    }
    
    func predict(data:[Float])->knn_certainty_label_pair{
    //get a prediction
        let prediction: knn_certainty_label_pair = knn_dtw.predict(curve_to_test: data)
        print("predicted " + prediction.label, "with ", prediction.probability*100,"% certainty")
        return prediction
    }
}
