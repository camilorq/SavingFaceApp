// Adapted from https://github.com/AudioKit/AudioKit/blob/master/AudioKit/Common/User%20Interface/AKNodeOutputPlot.swift

//
//  ArrayOutputPlot.swift
//  AudioKitUI
//
//  Created by Aurelius Prochazka, revision history on Github.
//  Copyright © 2018 AudioKit. All rights reserved.
//
import AudioKit
import AudioKitUI

extension Notification.Name {
    static let IAAConnected = Notification.Name(rawValue: "IAAConnected")
    static let IAADisconnected = Notification.Name(rawValue: "IAADisconnected")
}

/// Plot the output of an array
///
/// Similar to AKNodeOutputPlot, but requires manual updating
@IBDesignable
open class ArrayOutputPlot: EZAudioPlot {

    public var isConnected = false
    public var isNotConnected: Bool { return !isConnected }

    // Useful to reconnect after connecting to Audiobus or IAA
    @objc func reconnect() {
        pause()
        resume()
    }

    @objc open func pause() {
    }

    @objc open func resume() {
    }
    
    public func update(_ buffer: [Float]) {
        if buffer.count == 0 { return }

        let endIndex = min(self.startIndex + Int(self.bufferSize), buffer.count)
        self.bufferSize = UInt32(endIndex - self.startIndex)
        var data = Array(buffer[self.startIndex ..< endIndex])

        if self.normalize { data = data.normalized() }

        // https://stackoverflow.com/a/54702528
//        let pointer = UnsafeMutablePointer<Float>.init(mutating: data)
        let pointer = UnsafeMutablePointer<Float>.allocate(capacity: data.count)
        pointer.assign(from: data, count: data.count)
        self.updateBuffer(pointer, withBufferSize: self.bufferSize)
    }

    private func setupReconnection() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reconnect),
                                               name: .IAAConnected,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reconnect),
                                               name: .IAADisconnected,
                                               object: nil)
    }

    internal var bufferSize: UInt32 = 1_024
    internal var normalize: Bool = true
    internal var startIndex: Int = 0 // for zoom-in

    /// Required coder-based initialization (for use with Interface Builder)
    ///
    /// - parameter coder: NSCoder
    ///
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupReconnection()
    }

    /// Initialize the plot with the output from a given node and optional plot size
    ///
    /// - Parameters:
    ///   - input: AKNode from which to get the plot data
    ///   - width: Width of the view
    ///   - height: Height of the view
    ///
    @objc public init(frame: CGRect = CGRect.zero, bufferSize: Int = 1_024, normalize: Bool = true, startIndex: Int = 0) {
        super.init(frame: frame)
        self.plotType = .buffer
        self.backgroundColor = AKColor.white
        self.shouldCenterYAxis = true
        self.bufferSize = UInt32(bufferSize)
        self.normalize = normalize
        self.startIndex = startIndex

        setupReconnection()
    }
}
