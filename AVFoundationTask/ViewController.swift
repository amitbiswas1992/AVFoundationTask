//
//  ViewController.swift
//  AVFoundationTask
//
//  Created by Amit Biswas on 19/10/2022.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    
    private var playerItemContext = 0
    private let requiredAssetKeys = [
        "playable",
        "hasProtectedContent"
    ]
    
    
    private var playerItem: AVPlayerItem?
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    
    
    //MARK: - Outlets
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var positionValueLabel: UILabel!
    
    
    
    //MARK: - Override Methods
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.playVideo()
        self.addVideoAddedObserver()
        
    }
    
    
    //MARK: - Observer for Video End
    @objc
    func playerEndedPlaying(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            print("Playback video ends")
            self?.removePeriodicTimeObserver()
        }
    }
    
        
    //MARK: Periodic interval observer added
    private func addPeriodicTimeObserver() {
        // Notify every half second
        let timeScale = CMTimeScale(NSEC_PER_SEC)
        let time = CMTime(seconds: 0.5, preferredTimescale: timeScale)
        
        timeObserverToken = player?.addPeriodicTimeObserver(forInterval: time,
                                                            queue: .main) { [weak self] time in
            
            self?.positionValueLabel.text = "\(time.seconds) seconds"
            print("Playhead position :\(time.seconds)")
            
        }
    }
    
    
    //MARK: removing periodic interval observer
    private func removePeriodicTimeObserver() {
        if let timeObserverToken = timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
    }
    
        
    private func addVideoAddedObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(playerEndedPlaying), name: Notification.Name("AVPlayerItemDidPlayToEndTimeNotification"), object: nil)
    }
    
    
    //MARK: Main Function For playing video
    private func playVideo() {
        if let url = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/bipbop_4x3_variant.m3u8") {
            //2. Create AVPlayer object
            let asset = AVAsset(url: url)
            playerItem = AVPlayerItem(asset: asset,
                                      automaticallyLoadedAssetKeys: requiredAssetKeys)
            
            playerItem?.addObserver(self,
                                       forKeyPath: #keyPath(AVPlayerItem.status),
                                       options: [.old, .new],
                                       context: &playerItemContext)
            
            player = AVPlayer(playerItem: playerItem)
            
            //3. Create AVPlayerLayer object
            let playerLayer = AVPlayerLayer(player: player)
            playerLayer.frame = self.videoView.bounds //bounds of the view in which AVPlayer should be displayed
            playerLayer.videoGravity = .resizeAspect
            
            //4. Add playerLayer to view's layer
            self.videoView.layer.addSublayer(playerLayer)
            
            //5. Play Video
            player?.play()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        
        // Only handle observations for the playerItemContext
        guard context == &playerItemContext else {
            super.observeValue(forKeyPath: keyPath,
                               of: object,
                               change: change,
                               context: context)
            return
        }
        
        if keyPath == #keyPath(AVPlayerItem.status) {
            let status: AVPlayerItem.Status
            if let statusNumber = change?[.newKey] as? NSNumber {
                status = AVPlayerItem.Status(rawValue: statusNumber.intValue)!
            } else {
                status = .unknown
            }
            
            // Switch over status value
            switch status {
            case .readyToPlay:
                self.addPeriodicTimeObserver()
                print("Video played")
                // Player item is ready to play.
                break
            case .failed:
                // Player item failed. See error.
                break
            case .unknown:
                // Player item is not yet ready.
                break
            @unknown default:
                break
            }
        }
    }
    
}

