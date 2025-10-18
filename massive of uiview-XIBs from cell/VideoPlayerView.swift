// Файл: VideoPlayerView.swift (ПОЛНАЯ ФИНАЛЬНАЯ ВЕРСИЯ)
import UIKit
import AVKit
import Kingfisher

class VideoPlayerView: UIView {

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var playerView: UIView!

    private var playerLayer: AVPlayerLayer?
    private var playerLooper: AVPlayerLooper?
    private var queuePlayer: AVQueuePlayer?
    
    private let thumbnailImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // Свойство для безопасного хранения наблюдаемого объекта
    private var observedItem: AVPlayerItem?
    private var playerItemContext = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        Bundle.main.loadNibNamed("VideoPlayerView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        contentView.insertSubview(thumbnailImageView, at: 0)
        thumbnailImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
        ])
        
        playerView.backgroundColor = .clear
    }

    func configure(with url: URL, thumbnailURL: URL?) {
        cleanup() // Сначала очищаем старый плеер
        
        thumbnailImageView.kf.setImage(with: thumbnailURL)
        let playerItem = AVPlayerItem(url: url)
        
        // Добавляем наблюдателя
        playerItem.addObserver(self,
                               forKeyPath: #keyPath(AVPlayerItem.status),
                               options: [.new],
                               context: &playerItemContext)
        
        // Сохраняем ссылку на объект, за которым наблюдаем
        self.observedItem = playerItem
        
        self.queuePlayer = AVQueuePlayer(playerItem: playerItem)
        
        if let queuePlayer = self.queuePlayer {
            self.playerLooper = AVPlayerLooper(player: queuePlayer, templateItem: playerItem)
            self.playerLayer = AVPlayerLayer(player: queuePlayer)
            playerLayer?.videoGravity = .resizeAspectFill // Значение по умолчанию
            playerLayer?.backgroundColor = UIColor.clear.cgColor
            playerLayer?.frame = playerView.bounds
            
            if let playerLayer = self.playerLayer {
                playerView.layer.addSublayer(playerLayer)
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == #keyPath(AVPlayerItem.status) {
            // Исправленный способ получения статуса
            var status: AVPlayerItem.Status = .unknown
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue) ?? .unknown
            }

            DispatchQueue.main.async {
                if status == .readyToPlay {
                    print("✅ [VideoPlayerView] Status: Ready to play.")
                    self.adjustVideoGravity()
                } else if status == .failed {
                    print("❌ [VideoPlayerView] Status: Failed.")
                }
            }
        }
    }
    
    /// Анализирует видео и подстраивает его отображение
    private func adjustVideoGravity() {
        guard let playerItem = queuePlayer?.currentItem else { return }
        let asset = playerItem.asset

        guard let videoTrack = asset.tracks(withMediaType: .video).first else {
            playerLayer?.videoGravity = .resizeAspectFill
            return
        }
        
        let naturalSize = videoTrack.naturalSize
        
        if naturalSize.width == 0 || naturalSize.height == 0 {
            playerLayer?.videoGravity = .resizeAspectFill
            return
        }
        
        let aspectRatio = naturalSize.width / naturalSize.height
        
        if aspectRatio > 1 {
            print("↔️ Горизонтальное видео. Устанавливаем .resizeAspectFill для вертикального отображения.")
            // ИЗМЕНЕНИЕ: Теперь горизонтальные видео будут заполнять экран, а не вписываться.
            playerLayer?.videoGravity = .resizeAspectFill
        } else {
            print("↕️ Вертикальное видео. Устанавливаем .resizeAspectFill")
            playerLayer?.videoGravity = .resizeAspectFill
        }
    }

    func play() {
        queuePlayer?.play()
    }

    func pause() {
        queuePlayer?.pause()
    }
    
    func cleanup() {
        pause()
        
        // Безопасно удаляем наблюдателя
        if let item = observedItem {
            item.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.status), context: &playerItemContext)
            self.observedItem = nil // Обнуляем ссылку
        }
        
        queuePlayer?.removeAllItems()
        queuePlayer = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        playerLooper = nil
        
        thumbnailImageView.kf.cancelDownloadTask()
        thumbnailImageView.image = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = playerView.bounds
    }
}
