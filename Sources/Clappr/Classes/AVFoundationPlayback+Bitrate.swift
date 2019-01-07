import AVFoundation

extension AVFoundationPlayback {
    public func getBitrate() -> Double? {
        guard let logEvent = lastLogEvent() else { return nil }
        if (logEvent.segmentsDownloadedDuration ) > 0 {
            return logEvent.indicatedBitrate
        }
        return logEvent.observedBitrate
    }

    public func getAvgBitrate() -> Double? {
        guard let logEvent = lastLogEvent() else { return nil }
        if #available(iOS 10.0, *) {
            return logEvent.averageVideoBitrate
        }
        return nil
    }
    
    public func speed(_ speed: Float) {
        player?.rate = speed
    }
    
    public func speed() -> Float? {
        return player?.rate
    }

    private func lastLogEvent() -> AVPlayerItemAccessLogEvent? {
        return player?.currentItem?.accessLog()?.events.last
    }
}
