import UIKit
import AVKit
import Kingfisher
protocol VideoFeedCellDelegate: AnyObject {
func shouldTransitionToNextCell(from cell: VideoFeedCell)
func cell(_ cell: VideoFeedCell, didUpdatePlaybackProgress progress: TimeInterval)
func cell(_ cell: VideoFeedCell, didTapFavoriteFor activity: TodayActivity)
func cellDidFinishPreparing(_ cell: VideoFeedCell)
func cellDidTapHRVButton(_ cell: VideoFeedCell)
}
class VideoFeedCell: UICollectionViewCell {


static let identifier = "VideoFeedCell"
weak var delegate: VideoFeedCellDelegate?

// MARK: - Состояние
private var preparingTimer, videoPlaybackTimer, restTimer: Timer?
private enum State { case stopped, preparing, playing, resting, paused }
private var currentState: State = .stopped
private var pausedState: State = .stopped

private var preparingCountdown = 3
private var videoCountdown = 30
private var restCountdown = 5

private var isLastInQueue = false
private var currentActivity: TodayActivity?
private var isDrillMode = false

// MARK: - UI Элементы
private var videoPlayerView: VideoPlayerView!
private var backgroundImageView: UIImageView!
private var darkOverlay: UIView!
private let gradientLayer = CAGradientLayer()

private let titleBackgroundView: UIVisualEffectView = {
    let blurEffect = UIBlurEffect(style: .dark)
    let view = UIVisualEffectView(effect: blurEffect)
    view.translatesAutoresizingMaskIntoConstraints = false
    view.layer.cornerRadius = 20
    view.clipsToBounds = true
    return view
}()

private let videoTitleLabel: UILabel = {
    let label = UILabel()
    label.textColor = AppColors.accent
    label.numberOfLines = 0
    label.textAlignment = .center
    return label
}()

private let durationLabel: UILabel = {
    let label = UILabel()
    label.textColor = AppColors.accent
    label.font = .monospacedDigitSystemFont(ofSize: 30, weight: .semibold)
    return label
}()

private let centralStatusLabel: UILabel = {
    let label = UILabel()
    label.textColor = AppColors.accent
    label.font = .systemFont(ofSize: 80, weight: .bold)
    label.textAlignment = .center
    label.numberOfLines = 0
    return label
}()

private lazy var playbackControlButton: UIButton = {
    let button = createControlButton(systemName: "pause.fill", pointSize: 30)
    button.addTarget(self, action: #selector(togglePlayback), for: .touchUpInside)
    return button
}()

private lazy var hrvButton: UIButton = {
    let button = createControlButton(systemName: "waveform.path.ecg", pointSize: 24)
    button.addTarget(self, action: #selector(hrvButtonTapped), for: .touchUpInside)
    return button
}()

private lazy var favoriteButton: UIButton = {
    let button = createControlButton(systemName: "star", pointSize: 22)
    button.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
    return button
}()

private var bottomControlsStackView: UIStackView!
private var titleCenterYConstraint: NSLayoutConstraint!
private var titleCenterXConstraint: NSLayoutConstraint!
private var titleTopConstraint: NSLayoutConstraint!

private var videoPlayerCenteredConstraints: [NSLayoutConstraint] = []
private var videoPlayerFullscreenConstraints: [NSLayoutConstraint] = []

// MARK: - Инициализация и настройка
override init(frame: CGRect) {
    super.init(frame: frame)
    setupViews()
    setupConstraints()
}

required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer.frame = contentView.bounds
}

private func setupViews() {
    contentView.backgroundColor = .black

    backgroundImageView = UIImageView()
    backgroundImageView.contentMode = .scaleAspectFill
    backgroundImageView.clipsToBounds = true
    contentView.addSubview(backgroundImageView)

    darkOverlay = UIView()
    contentView.addSubview(darkOverlay)

    gradientLayer.colors = [
        UIColor.black.withAlphaComponent(0.6).cgColor, UIColor.clear.cgColor,
        UIColor.clear.cgColor, UIColor.black.withAlphaComponent(0.6).cgColor
    ]
    gradientLayer.locations = [0.0, 0.4, 0.6, 1.0]
    contentView.layer.addSublayer(gradientLayer)

    videoPlayerView = VideoPlayerView()
    contentView.addSubview(videoPlayerView)
    
    bottomControlsStackView = UIStackView(arrangedSubviews: [durationLabel, playbackControlButton, hrvButton, favoriteButton])
    bottomControlsStackView.distribution = .equalSpacing
    bottomControlsStackView.alignment = .center
    
    contentView.addSubview(titleBackgroundView)
    titleBackgroundView.contentView.addSubview(videoTitleLabel)
    
    [centralStatusLabel, bottomControlsStackView].forEach { contentView.addSubview($0) }
    
    [backgroundImageView, darkOverlay, videoPlayerView, videoTitleLabel, centralStatusLabel, bottomControlsStackView, titleBackgroundView].forEach {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
}

private func setupConstraints() {
    NSLayoutConstraint.activate([
        backgroundImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
        backgroundImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        backgroundImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        backgroundImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        
        darkOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
        darkOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        darkOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        darkOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        
        centralStatusLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        centralStatusLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        centralStatusLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
        centralStatusLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
        
        bottomControlsStackView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -40),
        bottomControlsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 40),
        bottomControlsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -40),
        bottomControlsStackView.heightAnchor.constraint(equalToConstant: 44)
    ])
    
    titleTopConstraint = videoTitleLabel.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 20)
    titleCenterXConstraint = videoTitleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
    titleCenterYConstraint = videoTitleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
    
    titleTopConstraint.isActive = false
    titleCenterXConstraint.isActive = true
    titleCenterYConstraint.isActive = true

    NSLayoutConstraint.activate([
        videoTitleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: contentView.leadingAnchor, constant: 20),
        videoTitleLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -20),
        
        titleBackgroundView.centerXAnchor.constraint(equalTo: videoTitleLabel.centerXAnchor),
        titleBackgroundView.centerYAnchor.constraint(equalTo: videoTitleLabel.centerYAnchor),
        titleBackgroundView.leadingAnchor.constraint(equalTo: videoTitleLabel.leadingAnchor, constant: -24),
        titleBackgroundView.trailingAnchor.constraint(equalTo: videoTitleLabel.trailingAnchor, constant: 24),
        titleBackgroundView.topAnchor.constraint(equalTo: videoTitleLabel.topAnchor, constant: -16),
        titleBackgroundView.bottomAnchor.constraint(equalTo: videoTitleLabel.bottomAnchor, constant: 16)
    ])
    
    videoPlayerFullscreenConstraints = [
        videoPlayerView.topAnchor.constraint(equalTo: contentView.topAnchor),
        videoPlayerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        videoPlayerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
        videoPlayerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
    ]
    
    videoPlayerCenteredConstraints = [
        videoPlayerView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
        videoPlayerView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
        videoPlayerView.widthAnchor.constraint(equalTo: contentView.widthAnchor),
        videoPlayerView.heightAnchor.constraint(equalTo: videoPlayerView.widthAnchor, multiplier: 9.0/16.0),
    ]
}

public func configure(with item: VideoItem, isLastVideo: Bool) {
    // --- ИЗМЕНЕНИЕ: Сбрасываем UI в исходное (скрытое) состояние при конфигурации ---
    setInitialUIState()
    
    self.currentActivity = item.activity
    self.isDrillMode = item.activity.title == item.activity.title.uppercased()

    if isDrillMode {
        gradientLayer.isHidden = true
        darkOverlay.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        backgroundImageView.kf.setImage(with: item.activity.imageURL)
        videoPlayerView.configure(with: item.url, thumbnailURL: nil)
        NSLayoutConstraint.deactivate(videoPlayerFullscreenConstraints)
        NSLayoutConstraint.activate(videoPlayerCenteredConstraints)
    } else {
        gradientLayer.isHidden = false
        darkOverlay.backgroundColor = .clear
        backgroundImageView.image = nil
        videoPlayerView.configure(with: item.url, thumbnailURL: item.activity.imageURL)
        NSLayoutConstraint.deactivate(videoPlayerCenteredConstraints)
        NSLayoutConstraint.activate(videoPlayerFullscreenConstraints)
    }
    
    videoTitleLabel.text = item.activity.title
    self.isLastInQueue = isLastVideo
    updateFavoriteButtonState()
}

private func createControlButton(systemName: String, pointSize: CGFloat) -> UIButton {
    let button = UIButton(type: .system)
    let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
    button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
    button.tintColor = AppColors.accent
    return button
}

private func setInitialUIState() {
    durationLabel.alpha = 0
    playbackControlButton.alpha = 0
    favoriteButton.alpha = 0
    hrvButton.alpha = 0
    centralStatusLabel.isHidden = true
    videoTitleLabel.alpha = 0
    titleBackgroundView.alpha = 0
}

public func start() {
    guard currentState == .stopped else { return }
    runPhase(.preparing)
}

public func stop() {
    currentState = .stopped
    invalidateTimers()
    videoPlayerView.pause()
}

override func prepareForReuse() {
    super.prepareForReuse()
    stop()
    videoPlayerView.cleanup()
    backgroundImageView.kf.cancelDownloadTask()
    backgroundImageView.image = nil
    currentActivity = nil
    setInitialUIState()
    
    titleTopConstraint.isActive = false
    titleCenterYConstraint.isActive = true
}

private func invalidateTimers() {
    preparingTimer?.invalidate()
    videoPlaybackTimer?.invalidate()
    restTimer?.invalidate()
}

private func runPhase(_ phase: State) {
    invalidateTimers()
    currentState = phase
    
    switch phase {
    case .preparing:
        preparingCountdown = 3
        videoTitleLabel.alpha = 0
        titleBackgroundView.alpha = 0
        
        centralStatusLabel.isHidden = false
        updateCentralStatusLabelForPreparing(countdown: preparingCountdown)
        
        preparingTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updatePreparing), userInfo: nil, repeats: true)
    
    case .playing:
        videoPlayerView.play()
        videoCountdown = 30
        durationLabel.text = "\(videoCountdown)"
        delegate?.cell(self, didUpdatePlaybackProgress: 0)
        videoPlaybackTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updatePlayback), userInfo: nil, repeats: true)
    
    case .resting:
        videoPlayerView.pause()
        restCountdown = 5
        centralStatusLabel.isHidden = false
        centralStatusLabel.font = .systemFont(ofSize: 40, weight: .medium)
        centralStatusLabel.text = "Rest: \(restCountdown)s"
        restTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateRest), userInfo: nil, repeats: true)
    
    case .paused, .stopped:
        videoPlayerView.pause()
    }
    updatePlaybackControlButtonIcon()
}

private func updateCentralStatusLabelForPreparing(countdown: Int) {
    guard let title = currentActivity?.title else {
        centralStatusLabel.text = "\(countdown)"
        return
    }

    let numberFont = UIFont.systemFont(ofSize: 80, weight: .bold)
    let titleFont = UIFont.systemFont(ofSize: 28, weight: .bold)

    let numberAttributes: [NSAttributedString.Key: Any] = [
        .font: numberFont,
        .foregroundColor: AppColors.accent
    ]
    let titleAttributes: [NSAttributedString.Key: Any] = [
        .font: titleFont,
        .foregroundColor: AppColors.accent
    ]

    let attributedString = NSMutableAttributedString(string: "\(countdown)\n", attributes: numberAttributes)
    attributedString.append(NSAttributedString(string: title.uppercased(), attributes: titleAttributes))

    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.alignment = .center
    paragraphStyle.lineSpacing = 8
    attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSRange(location: 0, length: attributedString.length))

    centralStatusLabel.attributedText = attributedString
}

@objc private func updatePreparing() {
    preparingCountdown -= 1
    if preparingCountdown > 0 {
        updateCentralStatusLabelForPreparing(countdown: preparingCountdown)
    } else {
        invalidateTimers()
        startWorkout()
    }
}

private func startWorkout() {
    delegate?.cellDidFinishPreparing(self)
    centralStatusLabel.isHidden = true
    centralStatusLabel.attributedText = nil
    
    animateTitleToTop()
    
    runPhase(.playing)
}

private func animateTitleToTop() {
    self.videoTitleLabel.text = self.currentActivity?.title
    self.videoTitleLabel.font = .systemFont(ofSize: 30, weight: .bold)

    UIView.animate(withDuration: 0.5, animations: {
        self.titleCenterYConstraint.isActive = false
        self.titleTopConstraint.isActive = true
        
        self.durationLabel.alpha = 1
        self.playbackControlButton.alpha = 1
        self.favoriteButton.alpha = 1
        self.hrvButton.alpha = 1
        self.videoTitleLabel.alpha = 1
        
        self.titleBackgroundView.alpha = 0
        
        self.contentView.layoutIfNeeded()
    })
}

@objc private func updatePlayback() {
    if videoCountdown > 0 {
        videoCountdown -= 1
        durationLabel.text = "\(videoCountdown)"
        delegate?.cell(self, didUpdatePlaybackProgress: TimeInterval(30 - videoCountdown))
    }

    if videoCountdown <= 0 {
        videoPlaybackTimer?.invalidate()
        
        if isLastInQueue {
            delegate?.shouldTransitionToNextCell(from: self)
        } else {
            runPhase(.resting)
        }
    }
}

@objc private func updateRest() {
    restCountdown -= 1
    centralStatusLabel.text = "Rest: \(restCountdown)s"
    if restCountdown <= 0 { delegate?.shouldTransitionToNextCell(from: self) }
}

public func pausePlayback() {
    guard currentState == .playing else { return }
    
    pausedState = .playing
    currentState = .paused
    
    videoPlayerView.pause()
    videoPlaybackTimer?.invalidate()
    
    updatePlaybackControlButtonIcon()
}

public func resumePlayback() {
    guard currentState == .paused else { return }
    
    currentState = pausedState
    
    videoPlayerView.play()
    videoPlaybackTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updatePlayback), userInfo: nil, repeats: true)
    
    updatePlaybackControlButtonIcon()
}

@objc private func togglePlayback() {
    if currentState == .playing {
        pausePlayback()
    } else if currentState == .paused {
        resumePlayback()
    }
}

public func updateFavoriteButtonState() {
    guard let activity = currentActivity else { return }
    let isPlanned = WorkoutPlanManager.shared.isPlannedOnAnyDay(workout: activity)
    let starImageName = isPlanned ? "star.fill" : "star"
    let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
    favoriteButton.setImage(UIImage(systemName: starImageName, withConfiguration: config), for: .normal)
}

@objc private func favoriteButtonTapped() {
    guard let activity = currentActivity else { return }
    delegate?.cell(self, didTapFavoriteFor: activity)
}

@objc private func hrvButtonTapped() {
    delegate?.cellDidTapHRVButton(self)
}

private func updatePlaybackControlButtonIcon() {
    let imageName = (currentState == .paused) ? "play.fill" : "pause.fill"
    let config = UIImage.SymbolConfiguration(pointSize: 30, weight: .bold)
    playbackControlButton.setImage(UIImage(systemName: imageName, withConfiguration: config), for: .normal)
}
}
