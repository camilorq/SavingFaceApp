//
//  ViewController.swift
//  SavingFaceToF
//
//  MIT License
//
//  Copyright (c) 2020 Camilo Rojas, Niels Poulsen, James Pruegsanusak, Zhi Wei Gan
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import AudioKit
import AudioKitUI
import AVFoundation

class ViewController: UIViewController, UITableViewDelegate,  UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource {
    
    // Speed of Sound
    let speedOfSound: Double = 343.0
    
    // Sampling Rate
    let sample_rate: Double = 44_100.0
    
    // The length of samples to use to measure phase
    let sample_length_t: Double = 0.01
    var sample_length: Int = 0 // sample_rate * sample_length_t
    
    // The frequency at which samples are taken
    let sample_freq_t: Double = 0.1
    var sample_freq: Int = 0 // sample_rate * sample_freq_t
    
    // If stereo sound with an offset of pi should be used
    let stereo_sound: Bool = true
    
    // Elements for amplitude measurement
    // Ultrasound Oscillators
    var hf_frequencies: [Double] = [18_000.0]
    var hf_oscillators: [AKOscillator]!
    var hf_mixedOscillator: AKMixer!
    // Bandpass filters
    var hf_bandwidth: Double = 500
    var hf_bandPassFilters: [AKBandPassButterworthFilter]!
    var hf_mixedBandPassFilter: AKMixer!
    // Constants
    var amplitude_threshold = 0.01
    
    
    // Elements for phase shift measurement
    // Low-frequency Oscillators
    var lf_frequencies: [Double] = [1400.0]
    var lf_oscillators: [AKOscillator]!
    var lf_mixedOscillator: AKMixer!
    // Bandpass filters
    var lf_bandwidth: Double = 150
    var lf_bandPassFilters: [AKBandPassButterworthFilter]!
    var lf_mixedBandPassFilter: AKMixer!
    // Constants
    let n: Int = 1024
    let distance_threshold = 10.0
    var ks: [Int] = [0, 0, 0]
    var amplitudeCurrent: Double = 1.0
    var amplitudePlaying: Double = 1.0
    var amplitudeQuiet: Double = 0.01
    
    
    // Microphone
    var mic: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    
    // Recorders
    var lf_recorder: AKClipRecorder!
    var hf_recorder: AKClipRecorder!
    
    var outRecorder: AKNodeRecorder!
    
    // Output
    var output: AKNode!
    
    // Phase/Index variables
    var peakIndex: Int?
    var calibratedPeakIndex: Int?
    var calibratedPhase: [Double]?
    var phase: [Double]?
    var est_distance: Double?
    var touching: Bool = false
    var numTouches: Int = 0
    var lastTouchTime: DispatchTime = DispatchTime.now()
    
    // UI elements
    @IBOutlet weak var touchLabel: UILabel!
    @IBOutlet weak var calibrateButton: UIButton!
    @IBOutlet weak var hideparameter: UIImageView!
    @IBOutlet weak var appearparameter: UIImageView!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var indexLabel: UILabel!
    @IBOutlet weak var calibratedIndexLabel: UILabel!
    @IBOutlet weak var amplitudeLabel: UILabel!
    @IBOutlet weak var amplitudeThresholdLabel: UILabel!
    
    // plots
    @IBOutlet weak var plotTableView: UITableView!
    var plotInfos = [PlotInfo]()
    var addZoomInPlots = false
    var plotSignalData: [[Float]] = [[0.0], [0.0]]

    @IBOutlet weak var inputDevicePicker: UIPickerView!
    
    /**
    Sets ```self.distanceString``` to be equal to the the time of flight between the mic and the earbud.

    - Parameters:
       - micData: A float array of length sampleLength, contains recorded data from AKClipRecorder
    */
    func getDistance(micData: [Float]) {
        let signal: [Float] = micData
        
        updatePlot(index: 0, data: signal)
        self.phase = phase_values(signal: signal, n: self.n, frequencies: self.lf_frequencies)
        if let calibratedPhase = self.calibratedPhase, let phase = self.phase {
            let phase_change = zip(calibratedPhase, phase).map {($0 - $1).mod2pi}
            self.est_distance = phase_shift_distance(frequencies: self.lf_frequencies, phases: phase_change, ks: self.ks)
        }
        
    }
    
    func updateUltrasound(micData: [Float]) {
        updatePlot(index: 1, data: micData)
    }
    
    /**
     Prints the index first peak in the signal to the console, for each frequency in the signal
    */
    func firstPeak(micData: [Float]) {
        let signal: [Float] = micData
        
        updatePlot(index: 0, data: signal)
        var index = 1
        while (index < signal.count - 1) && !((signal[index - 1] < signal[index]) && (signal[index] > signal[index + 1])) {
            index += 1
        }
        self.peakIndex = index
    }
    
    
    func distanceFromIndices(index: Int, calibratedIndex: Int) -> Double {
        var diff = Double(index - calibratedIndex)
        if diff < 0.0 {
            diff += round(self.sample_rate/self.lf_frequencies[0])
        }
        let delta_t = diff/self.sample_rate
        return speedOfSound * delta_t
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sample_length = Int(round(sample_rate * sample_length_t))
        sample_freq = Int(round(sample_rate * sample_freq_t))
        
        plotSignalData = [[Float](repeating: 0, count: sample_length), [Float](repeating: 0, count: sample_length)]
        
        calibrateButton.layer.cornerRadius = 4
        touchLabel.text = String(self.numTouches) + " touches"
        plotTableView.layer.cornerRadius = 4
        
        // Setup for microphone
        mic = AKMicrophone()
        
        // Sine wave to use
        let sine = AKTable(.sine, count: 256)
        
        
        func initializeOscillatorsFilters(frequencies: [Double], bandwidth: Double) -> ([AKOscillator], [AKBandPassButterworthFilter]) {
            var oscillators: [AKOscillator] = []
            var bpFilters: [AKBandPassButterworthFilter] = []
            for f in frequencies {
                let osc = AKOscillator(waveform: sine)
                osc.frequency = f
                osc.amplitude = self.amplitudeCurrent
                oscillators.append(osc)
                
                let bp = AKBandPassButterworthFilter(mic, centerFrequency: f, bandwidth: bandwidth)
                bpFilters.append(bp)
            }
            return (oscillators, bpFilters)
        }
        
        // Create oscillators and bandpass filters
        (lf_oscillators, lf_bandPassFilters) = initializeOscillatorsFilters(frequencies: lf_frequencies, bandwidth: lf_bandwidth)
        (hf_oscillators, hf_bandPassFilters) = initializeOscillatorsFilters(frequencies: hf_frequencies, bandwidth: hf_bandwidth)

        if self.stereo_sound{
            let left_lf_oscillators: [AKPanner] = lf_oscillators.map {AKPanner($0, pan: -1)}
            let right_lf_oscillators: [AKPanner] = lf_oscillators.map {AKPanner(AKBooster($0, gain: -1), pan: 1)}
            
            let left_hf_oscillators: [AKPanner] = hf_oscillators.map {AKPanner($0, pan: -1)}
            let right_hf_oscillators: [AKPanner] = hf_oscillators.map {AKPanner(AKBooster($0, gain: -1), pan: 1)}
            
            lf_mixedOscillator = AKMixer(left_lf_oscillators + right_lf_oscillators)
            hf_mixedOscillator = AKMixer(left_hf_oscillators + right_hf_oscillators)
        }else{
            lf_mixedOscillator = AKMixer(lf_oscillators)
            hf_mixedOscillator = AKMixer(hf_oscillators)
        }

        lf_mixedBandPassFilter = AKMixer(lf_bandPassFilters)
        hf_mixedBandPassFilter = AKMixer(hf_bandPassFilters)
        
        // Track the amplitude of the bandpass filter for the ultrasounds
        tracker = AKFrequencyTracker(hf_mixedBandPassFilter)
        // Output the results
        silence = AKBooster(AKMixer(lf_mixedBandPassFilter, tracker), gain: 0)
        
        // Total oscillator
        let oscillator = AKMixer(lf_mixedOscillator, hf_mixedOscillator)
    
        output = AKMixer(silence, oscillator)
        
        // Initialize recorders
        lf_recorder = AKClipRecorder(node: lf_mixedBandPassFilter)
        hf_recorder = AKClipRecorder(node: hf_mixedBandPassFilter)
        
        
        var sample_data: [Float] = []
        var isStoring = false
        var buffer_offset = 0
        
        // tap closure to parse recorder data before it is saved to disk
        let tap = { (process_recording: @escaping ([Float]) -> ()) in
            return { (buffer: AVAudioPCMBuffer, time: AVAudioTime) in

                buffer_offset += Int(buffer.frameLength)
                            
                if(isStoring){
                    let to_record = self.sample_length - sample_data.count
                    for i in 0..<to_record {
                        sample_data.append((buffer.floatChannelData?[0][i])!)
                    }
                    isStoring = false
                    buffer_offset %= self.sample_freq
                    sample_data = []
                }
                
                else if (buffer_offset >= self.sample_freq){
                    isStoring = true
                    let start = (buffer_offset % self.sample_freq)
                    let end = (buffer_offset % self.sample_freq) + self.sample_length - 1
                    
                    if(end < buffer.frameLength){
                        
                        for i in start...end {
                            sample_data.append((buffer.floatChannelData?[0][i])!)
                        }
                        isStoring = false
                        process_recording(sample_data)
                        sample_data = []
                    }
                    
                }
            }
        }
        
        do {
            try self.lf_recorder?.recordClip(time: (self.lf_recorder?.currentTime)!, duration: Double.greatestFiniteMagnitude,
                                             tap: tap(self.firstPeak(micData:)), completion: {_ in
                print("\nRecorders Set Up\n")
            })
            try self.hf_recorder?.recordClip(time: (self.hf_recorder?.currentTime)!, duration: Double.greatestFiniteMagnitude,
                                             tap: tap(self.updateUltrasound(micData:)), completion: {_ in
                print("\nRecorders Set Up\n")
            })
        } catch {
            AKLog("Recording did not start")
        }

        setupPlot()
        setupTableView()
        setupPickerView()
    }
    
    // Updates labels on the view
    @objc func updateUI() {
        amplitudeLabel.text = String(format: "%.5f", tracker.amplitude)
        amplitudeThresholdLabel.text = String(format: "%.5f", amplitude_threshold)
        
        if let peakIndex = self.peakIndex {
            self.indexLabel.text = "\(peakIndex)"
            
            if let calibratedPeakIndex = self.calibratedPeakIndex {
                if tracker.amplitude > amplitude_threshold {
                    if self.amplitudeCurrent != self.amplitudePlaying {
                        self.amplitudeCurrent = self.amplitudePlaying
                        self.lf_oscillators.forEach {$0.amplitude = self.amplitudeCurrent}
                    }
                    
                    let distance = distanceFromIndices(index: peakIndex, calibratedIndex: calibratedPeakIndex)
                    if distance > 0.15 {
                        distanceLabel.text = ">15.00 cm"
                    }else{
                        distanceLabel.text = String(format: "%.2f cm", 100 * distance)
                    }
                    if (distance < 0.10){
                        if !self.touching {
                            self.touching = true
                            if timeSinceLastTouch(lastTouchTime: self.lastTouchTime) > 2.0 {
                                self.numTouches += 1
                            }
                        }
                        self.lastTouchTime = DispatchTime.now()
                    }else{
                        self.touching = false
                    }
                }else{
                    if self.amplitudeCurrent != self.amplitudeQuiet {
                        self.amplitudeCurrent = self.amplitudeQuiet
                        self.lf_oscillators.forEach {$0.amplitude = self.amplitudeCurrent}
                    }
                    
                    self.touching = false
                    distanceLabel.text = ">15.00 cm"
                }
            }else{
                distanceLabel.text = "Please Calibrate"
            }
            
        }
        
        touchLabel.text = String(self.numTouches) + " touches"
    }
    
    // Starts recording when view appears.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        AudioKit.output = output
        do {
            try AudioKit.start()
            self.lf_recorder.start()
            self.hf_recorder.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
        
        lf_oscillators.forEach { $0.start() }
        hf_oscillators.forEach { $0.start() }
        calibrateButton.isEnabled = true
        hideparameter.isHidden = true
        appearparameter.isHidden = true

        //updates UI every 0.1 seconds
        Timer.scheduledTimer(timeInterval: 0.1,
                             target: self,
                             selector: #selector(ViewController.updateUI),
                             userInfo: nil,
                             repeats: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        calibrateButton.isEnabled = false
    }

    //MARK: - Calibrate Button
    @IBAction func calibrate(_ sender: Any) {
        if let phase = self.phase {
            print("calibrated at \(phase)")
            self.calibratedPhase = phase
        }
        if let peakIndex = self.peakIndex {
            print("calibrated at \(peakIndex)")
            self.calibratedPeakIndex = peakIndex
            self.calibratedIndexLabel.text = "\(peakIndex)"
        }
        // if addZoomInPlots { ... }
    }
    
    // MARK: Increase Amplitude Threshold (+) Button
    @IBAction func increaseAmplitude(_ sender: Any) {
        self.amplitude_threshold += 0.0025
    }
    
    // MARK: Decreasae Amplitude Threshold (-) Button
    @IBAction func decreaseAmplitude(_ sender: Any) {
        if self.amplitude_threshold > 0.0025 {
            self.amplitude_threshold -= 0.0025
        }
    }

    //MARK: - Visualizations/Plots
    func setupTableView() {
        plotTableView.delegate = self
        plotTableView.dataSource = self
    }

    func setupPlot() {
        plotInfos = [
            PlotInfo(name: "Mic low frequencies", bufferLength: sample_length, color: .red),
            PlotInfo(name: "Mic high frequencies", bufferLength: sample_length, color: .blue),
        ]
        // if addZoomInPlots { ... }
    }
    
    func updatePlot(index: Int, data: [Float]) {
        self.plotSignalData[index] = data
        var newBuffers = self.plotSignalData
        if addZoomInPlots {
            newBuffers += self.plotSignalData
        }
        for (plotInfo, newBuffer) in zip(plotInfos, newBuffers) {
            plotInfo.plot.update(newBuffer)
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return plotInfos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Table view cells are reused and should be dequeued using a cell identifier.
        let cellIdentifier = "PlotTableViewCell"

        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? PlotTableViewCell  else {
            fatalError("The dequeued cell is not an instance of PlotTableViewCell.")
        }
        cell.plotInfo = plotInfos[indexPath.row]
        return cell
    }

    // MARK: - UIPickerView
    func setupPickerView() {
        inputDevicePicker.delegate = self
        inputDevicePicker.dataSource = self
        
        var initialRow = 0
        if let devices = AudioKit.inputDevices, let currentDevice = AudioKit.inputDevice {
            initialRow = devices.lastIndex(of: currentDevice) ?? (devices.count - 1)
        }
        inputDevicePicker.selectRow(initialRow, inComponent: 0, animated: false)
    }
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return AudioKit.inputDevices?.count ?? 0
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        do {
            try mic.setDevice(AudioKit.inputDevices![row])
        } catch {
            AKLog("could not set device for mic")
        }
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let pickerLabel = UILabel()
        pickerLabel.font = UIFont.systemFont(ofSize: 14)
        pickerLabel.textAlignment = .center
        var desc = ""
        if let devices = AudioKit.inputDevices {
            desc = devices[row].description
            if let startIndex = desc.firstIndex(of: "("), let endIndex = desc.firstIndex(of: ")") {
                desc = String(desc[desc.index(after: startIndex) ..< endIndex])
            }
        }
        pickerLabel.text = desc
        return pickerLabel
    }
}


func timeSinceLastTouch(lastTouchTime: DispatchTime) -> Double {
    let currentTime = DispatchTime.now()
    let nanoTime = currentTime.uptimeNanoseconds - lastTouchTime.uptimeNanoseconds
    return Double(nanoTime) / 1_000_000_000.0
}

