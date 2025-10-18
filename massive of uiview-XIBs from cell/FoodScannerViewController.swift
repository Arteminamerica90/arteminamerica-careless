// Файл: FoodScannerViewController.swift (С УДАЛЕННОЙ КНОПКОЙ СТАТИСТИКИ)
import UIKit
import PhotosUI
import AVFoundation
import Vision

class FoodScannerViewController: UIViewController, PHPickerViewControllerDelegate, AVCapturePhotoCaptureDelegate {
    
    // MARK: - Свойства для передачи данных
    var onFoodScanned: ((FoodEntry) -> Void)?
    
    // MARK: - AVFoundation
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!

    // MARK: - UI Elements
    private lazy var previewView = UIView()
    private lazy var closeButton = createButton(systemName: "xmark", action: #selector(closeButtonTapped))
    private lazy var shutterButton = createShutterButton()
    private lazy var galleryButton = createCircleButton(systemName: "photo.fill", action: #selector(galleryButtonTapped))
    private lazy var manualEntryButton = createCustomImageCircleButton(imageName: "barcode-icon", action: #selector(manualEntryButtonTapped))
    // --- ИЗМЕНЕНИЕ: Кнопка статистики удалена ---
    // private lazy var statsButton = createCircleButton(systemName: "chart.bar.xaxis", action: #selector(statsButtonTapped))
    
    private lazy var resultOverlayView = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
    private lazy var resultImageView = UIImageView()
    private lazy var resultLabel = UILabel()
    private lazy var scanAgainButton = createActionButton(title: "Scan Again", action: #selector(scanAgainTapped))
    private lazy var activityIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkCameraPermissions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let session = captureSession, !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { session.startRunning() }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let session = captureSession, session.isRunning {
            session.stopRunning()
        }
    }
    
    // MARK: - Главная логика распознавания
    
    @MainActor
    private func processImage(_ image: UIImage) async {
        setLoading(true)
        resultOverlayView.isHidden = true // Скрываем предыдущий результат
        
        let barcode = await findBarcode(in: image)
        
        if let barcodeValue = barcode {
            print("✅ Штрихкод найден на фото: \(barcodeValue)")
            await searchBy(term: barcodeValue, image: image, isBarcode: true)
        } else {
            print("ℹ️ Штрихкод на фото не найден. Используем Google Vision.")
            await analyzeWithGoogleVision(image: image)
        }
    }
    
    @MainActor
    private func analyzeWithGoogleVision(image: UIImage) async {
        do {
            let annotations = try await VisionAPIService.shared.analyzeImage(image)
            guard let bestGuess = annotations.first?.description else {
                displayError("Could not identify the food in the photo.", image: image)
                setLoading(false)
                return
            }
            
            print("🔍 Google Vision определил: \(bestGuess)")
            await searchBy(term: bestGuess, image: image, isBarcode: false)
        } catch {
            displayError("Error analyzing image: \(error.localizedDescription)", image: image)
            setLoading(false)
        }
    }
    
    @MainActor
    private func searchBy(term: String, image: UIImage?, isBarcode: Bool) async {
        if image == nil { setLoading(true) }
        
        do {
            if let product = try await NutritionAPIService.shared.fetchNutrition(for: term) {
                let newEntry = FoodEntry(
                    name: product.productName ?? term.capitalized,
                    calories: Int(product.nutriments?.energyKcal ?? 0),
                    carbs: Int(product.nutriments?.carbohydrates ?? 0),
                    protein: Int(product.nutriments?.proteins ?? 0),
                    fat: Int(product.nutriments?.fat ?? 0)
                )
                onFoodScanned?(newEntry)
                dismiss(animated: true)
                
            } else {
                let message = "Could not find nutrition data for '\(term)'."
                displayError(message, image: image ?? UIImage())
            }
        } catch {
            displayError("Network error. Please try again.", image: image ?? UIImage())
        }
        
        setLoading(false)
    }

    private func findBarcode(in image: UIImage) async -> String? {
        guard let cgImage = image.cgImage else { return nil }
        let request = VNDetectBarcodesRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        return await withCheckedContinuation { continuation in
            do {
                try handler.perform([request])
                continuation.resume(returning: request.results?.first?.payloadStringValue)
            } catch {
                print("❌ Ошибка при поиске штрихкода: \(error)")
                continuation.resume(returning: nil)
            }
        }
    }
    
    // MARK: - Delegate Methods & Actions
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) else {
            setLoading(false)
            return
        }
        Task { await processImage(image) }
    }
    
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let result = results.first else { return }
        
        if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
            setLoading(true)
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                guard let self = self, let image = image as? UIImage else { return }
                Task { await self.processImage(image) }
            }
        }
    }
    
    @objc private func closeButtonTapped() { dismiss(animated: true) }
    @objc private func shutterButtonTapped() {
        if let photoOutput = self.photoOutput {
            setLoading(true)
            photoOutput.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
        }
    }
    @objc private func galleryButtonTapped() {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    @objc private func scanAgainTapped() {
        resultOverlayView.isHidden = true
        resultImageView.image = nil
        setLoading(false)
    }
    
    @objc private func manualEntryButtonTapped() {
        let alert = UIAlertController(title: "Enter Barcode", message: "Please enter the number from the barcode.", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "e.g., 4607065714343"
            textField.keyboardType = .numberPad
        }
        let searchAction = UIAlertAction(title: "Search", style: .default) { [weak self] _ in
            guard let barcode = alert.textFields?.first?.text, !barcode.isEmpty else { return }
            Task { await self?.searchBy(term: barcode, image: nil, isBarcode: true) }
        }
        alert.addAction(searchAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    // --- ИЗМЕНЕНИЕ: Метод для кнопки статистики удален ---
    // @objc private func statsButtonTapped() { ... }
    
    // MARK: - Setup & UI Helpers
    
    private func setupUI() {
        view.backgroundColor = .black
        previewView.backgroundColor = .black
        resultImageView.contentMode = .scaleAspectFill
        resultImageView.clipsToBounds = true
        resultImageView.layer.cornerRadius = 12
        resultLabel.numberOfLines = 0
        resultLabel.textAlignment = .left
        resultLabel.font = .systemFont(ofSize: 17)
        resultOverlayView.layer.cornerRadius = 20
        resultOverlayView.clipsToBounds = true
        resultOverlayView.isHidden = true
        activityIndicator.color = .white
        activityIndicator.hidesWhenStopped = true
        
        // --- ИЗМЕНЕНИЕ: Кнопка статистики удалена из этого массива ---
        [previewView, closeButton, shutterButton, galleryButton, manualEntryButton, activityIndicator, resultOverlayView].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        let resultStack = UIStackView(arrangedSubviews: [resultImageView, resultLabel, scanAgainButton])
        resultStack.axis = .vertical
        resultStack.spacing = 16
        resultStack.alignment = .center
        resultStack.translatesAutoresizingMaskIntoConstraints = false
        resultOverlayView.contentView.addSubview(resultStack)
        
        NSLayoutConstraint.activate([
            previewView.topAnchor.constraint(equalTo: view.topAnchor),
            previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            closeButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            
            shutterButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shutterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            shutterButton.widthAnchor.constraint(equalToConstant: 70),
            shutterButton.heightAnchor.constraint(equalToConstant: 70),
            
            galleryButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            galleryButton.trailingAnchor.constraint(equalTo: shutterButton.leadingAnchor, constant: -30),
            galleryButton.widthAnchor.constraint(equalToConstant: 44),
            galleryButton.heightAnchor.constraint(equalToConstant: 44),
            
            manualEntryButton.centerYAnchor.constraint(equalTo: shutterButton.centerYAnchor),
            manualEntryButton.leadingAnchor.constraint(equalTo: shutterButton.trailingAnchor, constant: 30),
            manualEntryButton.widthAnchor.constraint(equalToConstant: 44),
            manualEntryButton.heightAnchor.constraint(equalToConstant: 44),
            
            // --- ИЗМЕНЕНИЕ: Констрейнты для кнопки статистики удалены ---
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            resultOverlayView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resultOverlayView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            resultOverlayView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            resultOverlayView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            
            resultStack.topAnchor.constraint(equalTo: resultOverlayView.contentView.topAnchor, constant: 20),
            resultStack.bottomAnchor.constraint(equalTo: resultOverlayView.contentView.bottomAnchor, constant: -20),
            resultStack.leadingAnchor.constraint(equalTo: resultOverlayView.contentView.leadingAnchor, constant: 20),
            resultStack.trailingAnchor.constraint(equalTo: resultOverlayView.contentView.trailingAnchor, constant: -20),
            
            resultImageView.heightAnchor.constraint(equalToConstant: 150),
            resultImageView.widthAnchor.constraint(equalTo: resultStack.widthAnchor),
            
            scanAgainButton.widthAnchor.constraint(equalToConstant: 150),
            scanAgainButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    private func setLoading(_ isLoading: Bool) {
        DispatchQueue.main.async {
            self.activityIndicator.isHidden = !isLoading
            self.shutterButton.isHidden = isLoading
            self.galleryButton.isHidden = isLoading
            self.manualEntryButton.isHidden = isLoading
            // --- ИЗМЕНЕНИЕ: Кнопка статистики удалена ---
            // self.statsButton.isHidden = isLoading
            isLoading ? self.activityIndicator.startAnimating() : self.activityIndicator.stopAnimating()
        }
    }
    
    @MainActor
    private func displayError(_ message: String, image: UIImage) {
        resultImageView.image = image
        resultLabel.text = message
        resultOverlayView.isHidden = false
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
                    }
                }
            }
        default:
            break
        }
    }

    private func setupCamera() {
        #if targetEnvironment(simulator)
        return
        #endif
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let backCamera = AVCaptureDevice.default(for: .video) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            photoOutput = AVCapturePhotoOutput()
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(photoOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(photoOutput)
                
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer.videoGravity = .resizeAspectFill
                
                DispatchQueue.main.async {
                    self.previewLayer.frame = self.view.layer.bounds
                    self.previewView.layer.addSublayer(self.previewLayer)
                }
                
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.captureSession.startRunning()
                }
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    private func createButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createCircleButton(systemName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .medium)
        button.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }
    
    private func createCustomImageCircleButton(imageName: String, action: Selector) -> UIButton {
        let button = UIButton(type: .custom)
        let image = UIImage(named: imageName)?.withRenderingMode(.alwaysTemplate)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        button.layer.cornerRadius = 22
        button.addTarget(self, action: action, for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return button
    }
    
    private func createShutterButton() -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = .clear
        button.layer.cornerRadius = 35
        button.layer.borderWidth = 5
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.8).cgColor
        
        let innerCircle = UIView()
        innerCircle.backgroundColor = .white
        innerCircle.translatesAutoresizingMaskIntoConstraints = false
        innerCircle.isUserInteractionEnabled = false
        innerCircle.layer.cornerRadius = 27.5
        
        button.addSubview(innerCircle)
        NSLayoutConstraint.activate([
            innerCircle.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            innerCircle.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            innerCircle.widthAnchor.constraint(equalToConstant: 55),
            innerCircle.heightAnchor.constraint(equalToConstant: 55)
        ])
        
        button.addTarget(self, action: #selector(shutterButtonTapped), for: .touchUpInside)
        return button
    }
    
    private func createActionButton(title: String, action: Selector) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        btn.backgroundColor = AppColors.accent
        btn.setTitleColor(.black, for: .normal)
        btn.layer.cornerRadius = 12
        btn.addTarget(self, action: action, for: .touchUpInside)
        return btn
    }
}
