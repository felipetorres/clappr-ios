open class Seekbar: MediaControlPlugin {

    override open var pluginName: String {
        return "Seekbar"
    }

    override open var panel: MediaControlPanel {
        return .bottom
    }

    override open var position: MediaControlPosition {
        return .none
    }

    public var seekbarView: SeekbarView = .fromNib()

    var containerView: UIStackView! {
        didSet {
            view.addSubview(containerView)
            containerView.bindFrameToSuperviewBounds()
        }
    }

    private var isOfflinePlayback: Bool = false

    required public init(context: UIObject) {
        super.init(context: context)
        bindEvents()
    }

    required public init() {
        super.init()
    }

    private func bindEvents() {
        stopListening()

        bindCoreEvents()
        bindContainerEvents()
        bindPlaybackEvents()
        bindOfflinePlaybackEvents()
    }

    private var activeContainer: Container? {
        return core?.activeContainer
    }

    fileprivate var activePlayback: Playback? {
        return core?.activePlayback
    }

    private func bindCoreEvents() {
        guard let core = core else { return }
        listenTo(core, eventName: Event.didChangeActiveContainer.rawValue) { [weak self] _ in self?.bindEvents() }
    }

    private func bindContainerEvents() {
        if let container = activeContainer {
            listenTo(container,
                     eventName: Event.didChangePlayback.rawValue) { [weak self] (_: EventUserInfo) in self?.bindEvents() }
        }
    }

    fileprivate func setSeekbarViewLive() {
        seekbarView.isLive = activePlayback?.playbackType == .live
    }

    private func bindPlaybackEvents() {
        if let playback = activePlayback {
            listenTo(playback, eventName: Event.ready.rawValue) { [weak self] _ in
                self?.setVideoProperties()
                self?.setSeekbarViewLive()
            }
            listenTo(playback, eventName: Event.didUpdatePosition.rawValue) { [weak self] _ in
                if let isSeeking = self?.seekbarView.isSeeking, !isSeeking {
                    self?.updateElapsedTime()
                }
            }
            listenTo(playback, eventName: Event.seekableUpdate.rawValue) { [weak self] _ in self?.updateElapsedTime() }
            listenTo(playback, eventName: Event.didUpdateBuffer.rawValue) { [weak self] (info: EventUserInfo) in self?.updateBuffer(info) }
        }
    }

    private func bindOfflinePlaybackEvents() {
        if let playback = activePlayback {
            listenToOnce(playback, eventName: Event.playing.rawValue) { [weak self] _ in self?.setVideoProperties() }
        }
    }

    private func setVideoProperties() {
        seekbarView.videoDuration = CGFloat(activePlayback?.duration ?? 0.0)
    }

    private func updateElapsedTime() {
        if let playback = activePlayback {
            seekbarView.updateScrubber(time: CGFloat(playback.position))
        }
    }

    private func updateBuffer(_ info: EventUserInfo) {
        guard let endPosition = info!["end_position"] as? TimeInterval, !endPosition.isNaN else {
            return
        }

        let maxBufferTime = min(seekbarView.videoDuration, CGFloat(endPosition))
        seekbarView.updateBuffer(time: maxBufferTime)
    }

    override open func render() {
        setupHeightSize()
        containerView = UIStackView()
        containerView.addArrangedSubview(seekbarView)
        seekbarView.delegate = self
    }

    private func setupHeightSize() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 38).isActive = true
    }
}

extension Seekbar: SeekbarDelegate {
    func willBeginScrubbing() {
        core?.trigger(InternalEvent.willBeginScrubbing.rawValue)
    }

    func didFinishScrubbing() {
        core?.trigger(InternalEvent.didFinishScrubbing.rawValue)
    }

    func seek(_ timeInterval: TimeInterval) {
        if shouldSyncLive(timeInterval) {
            activePlayback?.seekToLivePosition()
        } else {
            activePlayback?.seek(timeInterval)
        }
    }

    private func shouldSyncLive(_ timeInterval: TimeInterval) -> Bool {
        return timeInterval == activePlayback?.duration
    }
}
