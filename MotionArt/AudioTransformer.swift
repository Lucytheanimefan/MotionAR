//
//  AudioTransformer.swift
//  MotionArt
//
//  Created by Lucy Zhang on 3/28/18.
//  Copyright © 2018 Lucy Zhang. All rights reserved.
//
import AVFoundation
import Accelerate
import aubio
import os.log

protocol AudioTransformerDelegate{
    func onPlay()
    
    func dealWithFFTMagnitudes(magnitudes:[Float])
}

class AudioTransformer: NSObject {
    
    var audioEngine = AVAudioEngine()
    var audioNode = AVAudioPlayerNode()
    
    var magnitudes:[Float]!
    
    var delegate: AudioTransformerDelegate!
    
    static let shared = AudioTransformer()
    
    var addedNode:Bool = false
    
    var aubiomfcc = new_aubio_mfcc(uint_t(Constants.NUM_NODES), 20, 13, 16000)
    
    func begin(file:URL){
        os_log("%@: Begin", self.description)
        audioEngine.attach(audioNode)
        addedNode = true
        guard let audioFile = try? AVAudioFile(forReading: file) else {
            os_log("%@: Invalid file: %@", self.description, (file.absoluteString))
            return
        }
        if let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat,
                                         frameCapacity: AVAudioFrameCount(audioFile.length)){
            try? audioFile.read(into: buffer)
            audioEngine.connect(audioNode, to: audioEngine.mainMixerNode, format: buffer.format)
            audioNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
            retrieveAudioBuffer()
        }
    }
    
    func cancel(){
        if (addedNode){
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.detach(audioNode)
            addedNode = false
        }
    }
    
    private func retrieveAudioBuffer(){
        let size: UInt32 = 1024
        let mixerNode = audioEngine.mainMixerNode
        
        
        // observe the output of the player node
        mixerNode.installTap(onBus: 0,
                             bufferSize: size,
                             format: mixerNode.outputFormat(forBus: 0)) { (buffer, time) in self.fftTransform(buffer: buffer)
        }

        audioEngine.prepare()
        do
        {
            try audioEngine.start()
            
            audioNode.play()
            
            os_log("%@: PLAY", self.description)
        }
        catch
        {
            os_log("%@: Error starting audio engine %@", type: .error, self.description, error.localizedDescription)
        }
    }
    
    private func fftTransform(buffer: AVAudioPCMBuffer)/* -> [Float]*/ {
        //print("FFT transform")
        let frameCount = Constants.FRAME_COUNT//buffer.frameLength
        //print("Frame count: \(frameCount)")
        let log2n = UInt(round(log2(Double(frameCount))))
        let bufferSizePOT = Int(1 << log2n)
        let inputCount = bufferSizePOT / 2
        let fftSetup = vDSP_create_fftsetup(log2n, Int32(kFFTRadix2))
        
        var realp = [Float](repeating: 0, count: inputCount)
        var imagp = [Float](repeating: 0, count: inputCount)
        var output = DSPSplitComplex(realp: &realp, imagp: &imagp)
        
        // This is the value the web app uses
        let windowSize = bufferSizePOT
  
        var transferBuffer = [Float](repeating: 0, count: windowSize)
        var window = [Float](repeating: 0, count: windowSize)
        
        vDSP_hann_window(&window, vDSP_Length(windowSize), Int32(vDSP_HANN_NORM))
        vDSP_vmul((buffer.floatChannelData?.pointee)!, 1, window,
                  1, &transferBuffer, 1, vDSP_Length(windowSize))
        
        let temp = UnsafePointer<Float>(transferBuffer)
        
        temp.withMemoryRebound(to: DSPComplex.self, capacity: transferBuffer.count) { (typeConvertedTransferBuffer) -> Void in
            vDSP_ctoz(typeConvertedTransferBuffer, 2, &output, 1, vDSP_Length(inputCount))
        }
        
        vDSP_fft_zrip(fftSetup!, &output, 1, log2n, FFTDirection(FFT_FORWARD))
        
        var magnitudes = [Float](repeating: 0.0, count: inputCount)
        
        
        vDSP_zvmags(&output, 1, &magnitudes, 1, vDSP_Length(inputCount))
        
        var normalizedMagnitudes = [Float](repeating: 0.0, count: inputCount)
        vDSP_vsmul(sqrtq(magnitudes), 1, [2.0 / Float(inputCount)],
                   &normalizedMagnitudes, 1, vDSP_Length(inputCount))
        
        
        delegate.dealWithFFTMagnitudes(magnitudes: normalizedMagnitudes)
        
        #if DEBUG
            //os_log("%@: FFT magnitudes: %@", self.description,  normalizedMagnitudes)
        #endif
        
        //let buffer = Buffer(elements: normalizedMagnitudes)
        
        vDSP_destroy_fftsetup(fftSetup)
        
        //return buffer.elements
    }
    
    
    func computeMFCC(audioFilePath:URL?) -> [Float]{
        print(audioFilePath!.absoluteString)
        
        var dataStore:[Float] = [Float]()
//        let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.allDomainsMask, true).first
//        let path = NSURL(fileURLWithPath: dir!).appendingPathComponent(audioFilePath.relativeString)
        
        guard let audioPath = audioFilePath else {
            return dataStore
        }
        
        print("File path: \(audioPath)")
        
        
        let hop_size : uint_t = uint_t(Constants.NUM_NODES)
        let a = new_fvec(hop_size)
        let b = new_aubio_source(audioPath.path, 0, hop_size)
        
        let win_s:uint_t = uint_t(Constants.NUM_NODES)
        let n_filters:uint_t = 20
        let n_coefs:uint_t = 13
        let samplerate:uint_t = 16000
        let iin = new_cvec(win_s)
        let oout = new_fvec(n_coefs)
        
        let c = new_aubio_mfcc(win_s, n_filters, n_coefs, samplerate);
        
        var read: uint_t = 0
        var total_frames : uint_t = 0
        
        while (true) {
            aubio_source_do(b, a, &read)
            aubio_mfcc_do(c, iin, oout)
            
            print(oout as Any)
            
            total_frames += read
            
            if (read < hop_size) { break }
        }
        print("read", total_frames, "frames at", aubio_source_get_samplerate(b), "Hz")
        
        del_aubio_source(b)
        del_fvec(a)
        
        del_aubio_mfcc(c)
        
        if let data = fvec_get_data(oout) {
            for j in 0..<Int(n_coefs) {
                dataStore.append(data[j])
            }
        }
    
        print(dataStore)
        return dataStore
    }
    
    
    func sqrtq(_ x: [Float]) -> [Float] {
        var results = [Float](repeating: 0.0, count: x.count)
        vvsqrtf(&results, x, [Int32(x.count)])
        
        return results
    }
    
    
}

extension String {
    
    func fileName() -> String {
        if let fileNameWithoutExtension = NSURL(fileURLWithPath: self).deletingPathExtension?.lastPathComponent {
            return fileNameWithoutExtension
        }
        return ""
    }
    
    func fileExtension() -> String {
        
        if let fileExtension = NSURL(fileURLWithPath: self).pathExtension {
            return fileExtension
        }
        return ""
        
    }
}

struct Buffer {
    var elements: [Float]
    var realElements: [Float]?
    var imagElements: [Float]?
    
    var count: Int {
        return elements.count
    }
    
    // MARK: - Initialization
    init(elements: [Float], realElements: [Float]? = nil, imagElements: [Float]? = nil) {
        self.elements = elements
        self.realElements = realElements
        self.imagElements = imagElements
    }
}

