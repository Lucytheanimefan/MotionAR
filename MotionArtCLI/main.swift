//
//  main.swift
//  MotionArtCLI
//
//  Created by Lucy Zhang on 4/5/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//

import Foundation

print("Hello, World!")

let audioFiles = ["Shelter", "Sakura", "shigatsu_short"]
let extensions = ["mp3", "mp3", "wav"]

for (i, file) in audioFiles.enumerated(){
    let url = Bundle.main.url(forResource: file, withExtension: extensions[i])
    let data = AudioTransformer.shared.computeMFCC(audioFilePath: url)
}

