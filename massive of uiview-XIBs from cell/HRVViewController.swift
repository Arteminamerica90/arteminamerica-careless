// Файл: HRVViewController.swift (ПОЛНАЯ ФИНАЛЬНАЯ ВЕРСИЯ С ИСПРАВЛЕНИЯМИ)
import UIKit
import AVFoundation

class HRVViewController: UIViewController {

    // MARK: - Состояние
    private enum State {
        case idle
        case measuring
        case finished
    }
    private var currentState: State = .idle
    
    var onDismiss: (() -> Void)?
    
    // MARK: - AVFoundation & Signal Processing
    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    private let fps: Double = 30.0
    private lazy var signalProcessor = PPGSignalProcessor(fps: self.fps)
    
    // MARK: - Таймеры и прогресс
    private var measurementTimer: Timer?
    private let measurementDuration: TimeInterval = 20.0
    private var secondsElapsed: TimeInterval = 0.0
    private var latestBPM: Int?

    // MARK: - UI Элементы
    private lazy var previewLayer: AVCaptureVideoPreviewLayer = {
        let layer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        layer.videoGravity = .resizeAspectFill
        return layer
    }()
    
    private lazy var instructionLabel: UILabel = {
        let label = UILabel(); label.text = "Place your finger firmly on the camera and flash"; label.textColor = .white; label.font = .systemFont(ofSize: 20, weight: .medium); label.textAlignment = .center; label.numberOfLines = 0; label.layer.shadowColor = UIColor.black.cgColor; label.layer.shadowRadius = 3.0; label.layer.shadowOpacity = 0.8; label.layer.shadowOffset = CGSize(width: 2, height: 2); return label
    }()
    
    private lazy var resultLabel: UILabel = {
        let label = UILabel(); label.text = "-- ms"; label.textColor = .white; label.font = .systemFont(ofSize: 52, weight: .bold); label.textAlignment = .center; label.layer.shadowColor = UIColor.black.cgColor; label.layer.shadowRadius = 3.0; label.layer.shadowOpacity = 0.7; label.layer.shadowOffset = CGSize(width: 2, height: 2); return label
    }()
    
    private lazy var heartRateLabel: UILabel = {
        let label = UILabel(); label.text = "Pulse: -- bpm"; label.textColor = .white; label.font = .systemFont(ofSize: 22, weight: .semibold); label.textAlignment = .center; return label
    }()
    
    private lazy var infoLabel: UILabel = {
        let label = UILabel(); label.text = "Measurement takes 20 seconds"; label.textColor = .white.withAlphaComponent(0.7); label.font = .systemFont(ofSize: 14); label.textAlignment = .center; label.numberOfLines = 0; return label
    }()
    
    private lazy var startStopButton: UIButton = {
        let button = UIButton(type: .system); button.setTitle("Start Measurement", for: .normal); button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold); button.backgroundColor = AppColors.accent.withAlphaComponent(0.9); button.setTitleColor(.black, for: .normal); button.layer.cornerRadius = 15; button.addTarget(self, action: #selector(toggleMeasurement), for: .touchUpInside); return button
    }()
    
    private lazy var syncWithWatchButton: UIButton = {
        let button = UIButton(type: .system); button.setTitle("Sync with Watch", for: .normal); button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold); button.setTitleColor(.white, for: .normal); button.backgroundColor = UIColor.gray.withAlphaComponent(0.4); button.layer.cornerRadius = 15; button.addTarget(self, action: #selector(syncWithWatchTapped), for: .touchUpInside); return button
    }()
    
    private lazy var showHistoryButton: UIButton = {
        let button = UIButton(type: .system); button.setTitle("Show to Doctor", for: .normal); button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold); button.setTitleColor(.white, for: .normal); button.backgroundColor = UIColor.gray.withAlphaComponent(0.4); button.layer.cornerRadius = 15; button.addTarget(self, action: #selector(showHistoryTapped), for: .touchUpInside); return button
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system); let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .bold); button.setImage(UIImage(systemName: "xmark", withConfiguration: config), for: .normal); button.tintColor = .white; button.backgroundColor = UIColor.black.withAlphaComponent(0.4); button.layer.cornerRadius = 15; button.addTarget(self, action: #selector(closeTapped), for: .touchUpInside); return button
    }()
    
    private lazy var measurementProgressView: UIProgressView = {
        let progressView = UIProgressView(progressViewStyle: .bar)
        progressView.progressTintColor = AppColors.accent
        progressView.trackTintColor = UIColor.gray.withAlphaComponent(0.4)
        progressView.isHidden = true
        return progressView
    }()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        signalProcessor.delegate = self
        setupUI()
        checkCameraPermissions()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = view.bounds
    }

    // MARK: - Setup
    private func setupUI() {
        view.layer.addSublayer(previewLayer)
        let blurEffect = UIBlurEffect(style: .dark); let blurredView = UIVisualEffectView(effect: blurEffect); blurredView.frame = self.view.bounds; blurredView.autoresizingMask = [.flexibleWidth, .flexibleHeight]; view.addSubview(blurredView)
        
        [instructionLabel, resultLabel, heartRateLabel, measurementProgressView, infoLabel, startStopButton, syncWithWatchButton, showHistoryButton, closeButton].forEach { view.addSubview($0); $0.translatesAutoresizingMaskIntoConstraints = false }
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20), closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20), closeButton.widthAnchor.constraint(equalToConstant: 30), closeButton.heightAnchor.constraint(equalToConstant: 30),
            instructionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor), instructionLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80), instructionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40), instructionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            resultLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor), resultLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            heartRateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor), heartRateLabel.topAnchor.constraint(equalTo: resultLabel.bottomAnchor, constant: 16),
            infoLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20), infoLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30), infoLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            measurementProgressView.bottomAnchor.constraint(equalTo: infoLabel.topAnchor, constant: -16),
            measurementProgressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            measurementProgressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            measurementProgressView.heightAnchor.constraint(equalToConstant: 6),
            
            showHistoryButton.bottomAnchor.constraint(equalTo: measurementProgressView.topAnchor, constant: -16),
            showHistoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30), showHistoryButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30), showHistoryButton.heightAnchor.constraint(equalToConstant: 44),
            
            syncWithWatchButton.bottomAnchor.constraint(equalTo: showHistoryButton.topAnchor, constant: -12), syncWithWatchButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30), syncWithWatchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30), syncWithWatchButton.heightAnchor.constraint(equalToConstant: 44),
            startStopButton.bottomAnchor.constraint(equalTo: syncWithWatchButton.topAnchor, constant: -12), startStopButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30), startStopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30), startStopButton.heightAnchor.constraint(equalToConstant: 55)
        ])
    }
    
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.setupCamera()
                    } else {
                        self?.instructionLabel.text = "Camera access denied. Please allow it in Settings."
                    }
                }
            }
        default:
            instructionLabel.text = "Camera access denied. Please allow it in Settings."
        }
    }

    private func setupCamera() {
        sessionQueue.async {
            guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
            
            do {
                try captureDevice.lockForConfiguration()
                if let format = captureDevice.formats.first {
                    captureDevice.activeFormat = format
                    captureDevice.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(self.fps))
                    captureDevice.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(self.fps))
                }
                captureDevice.unlockForConfiguration()
            } catch { print("Camera configuration error: \(error)") }

            guard let input = try? AVCaptureDeviceInput(device: captureDevice) else { return }
            
            self.captureSession.sessionPreset = .low
            if self.captureSession.canAddInput(input) { self.captureSession.addInput(input) }
            
            self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if self.captureSession.canAddOutput(self.videoDataOutput) { self.captureSession.addOutput(self.videoDataOutput) }
        }
    }
    
    // MARK: - Actions & Logic
    
    @objc private func toggleMeasurement() {
        if currentState == .measuring {
            stopMeasurement(cancelledByUser: true)
        } else {
            startMeasurement()
        }
    }
    
    private func startMeasurement() {
        currentState = .measuring
        secondsElapsed = 0
        latestBPM = nil
        signalProcessor.reset()
        
        sessionQueue.async {
            self.captureSession.startRunning()
            self.toggleTorch(on: true)
        }
        
        DispatchQueue.main.async {
            self.measurementProgressView.progress = 0
            self.measurementProgressView.isHidden = false
            self.startStopButton.setTitle("Stop", for: .normal)
            self.startStopButton.backgroundColor = .systemRed.withAlphaComponent(0.9)
            self.resultLabel.text = "Measuring..."
            self.heartRateLabel.text = "Pulse: -- bpm"
            
            self.measurementTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(self.updateMeasurementState), userInfo: nil, repeats: true)
        }
    }
    
    private func stopMeasurement(cancelledByUser: Bool = false) {
        measurementTimer?.invalidate()
        currentState = .finished
        
        sessionQueue.async {
            self.captureSession.stopRunning()
            self.toggleTorch(on: false)
        }
        
        DispatchQueue.main.async {
            self.measurementProgressView.isHidden = true
            self.startStopButton.setTitle("Start Again", for: .normal)
            self.startStopButton.backgroundColor = AppColors.accent.withAlphaComponent(0.9)
            self.infoLabel.text = "Measurement takes 20 seconds"
        }
        
        if !cancelledByUser {
            resultLabel.text = "Processing..."
            signalProcessor.process()
        } else {
            resultLabel.text = "-- ms"
        }
    }

    @objc private func updateMeasurementState() {
        secondsElapsed += 0.5
        
        let progress = Float(secondsElapsed / measurementDuration)
        measurementProgressView.setProgress(progress, animated: true)
        
        let timeRemaining = Int(measurementDuration - secondsElapsed)
        infoLabel.text = "Time remaining: \(timeRemaining)s"
        
        if let bpm = latestBPM {
            heartRateLabel.text = "Pulse: \(bpm) bpm"
        }
        
        if secondsElapsed >= measurementDuration {
            stopMeasurement()
        }
    }

    @objc private func syncWithWatchTapped() {
        resultLabel.text = "Syncing..."
        heartRateLabel.text = ""

        HealthKitManager.shared.fetchLatestHRVFromWatch { [weak self] rmssdValue in
            guard let self = self else { return }
            
            if let rmssd = rmssdValue {
                HRVDataManager.shared.saveHRVResult(rmssd: rmssd)
                let status = HRVStatus(rmssd: rmssd)
                HRVPopupManager.shared.showPopup(with: status)
                self.closeTapped()
            } else {
                self.resultLabel.text = "No Data"
                self.heartRateLabel.text = "Sync your Apple Watch"
            }
        }
    }
    
    @objc private func showHistoryTapped() {
        let historyVC = HRVHistoryViewController()
        let navController = UINavigationController(rootViewController: historyVC)
        present(navController, animated: true)
    }
    
    @objc private func closeTapped() {
        if captureSession.isRunning {
             sessionQueue.async {
                self.captureSession.stopRunning()
                self.toggleTorch(on: false)
            }
        }
        dismiss(animated: true, completion: onDismiss)
    }
    
    private func toggleTorch(on: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        do {
            try device.lockForConfiguration()
            
            if on {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            } else {
                device.torchMode = .off
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Torch error: \(error)")
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension HRVViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard currentState == .measuring, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let width = CVPixelBufferGetWidth(pixelBuffer); let height = CVPixelBufferGetHeight(pixelBuffer); let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer); let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer); let buffer = baseAddress!.assumingMemoryBound(to: UInt8.self)
        var totalGreen: UInt64 = 0
        for y in 0..<height { for x in 0..<width { totalGreen += UInt64(buffer[y * bytesPerRow + x * 4 + 1]) } }
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        let averageGreen = Double(totalGreen) / Double(width * height)
        signalProcessor.add(value: averageGreen)
    }
}

// MARK: - PPGSignalProcessorDelegate
extension HRVViewController: PPGSignalProcessorDelegate {
    
    func didUpdate(bpm: Int?) {
        self.latestBPM = bpm
    }
    
    func didFinishProcessing(rmssd: Double?, averageHr: Int?) {
        DispatchQueue.main.async {
            if let rmssd = rmssd {
                HRVDataManager.shared.saveHRVResult(rmssd: rmssd)
                
                let status = HRVStatus(rmssd: rmssd)
                HRVPopupManager.shared.showPopup(with: status)

            } else {
                let errorStatus = HRVStatus(rmssd: 0)
                HRVPopupManager.shared.showPopup(with: errorStatus)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.closeTapped()
            }
        }
    }
}
