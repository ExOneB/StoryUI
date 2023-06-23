//
//  VideoLoader.swift
//  StoryUI (iOS)
//
//  Created by Tolga İskender on 30.04.2022.
//

import Foundation
import UIKit
import AVKit

class PlayerView: UIView {
    
    // MARK: Public Properties
    var player: AVPlayer?
    var duration: Double = 0.0
    var state: MediaState = .notStarted
    var mediaState: ((MediaState,Double) -> ())?
    
    let contentView = UIView()
    
    // MARK: Private Properties
    private let playerLayer = AVPlayerLayer()
    private var previewTimer: Timer?
    private var url: URL?
    
     // MARK: - Initializers
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 12
        self.clipsToBounds = true
        setupPlayer()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    
    func startVideo(url: URL?) {
        guard let validatedUrl = url else { return }
        if self.url == url { return }
        self.url = validatedUrl
        addActivityIndicatory()
        addObserverToVideo()
        // stop video if it's playing before video request
        stopVideo()
        guard let url = url else { return }
        CacheManager.shared.getFileWith(stringUrl: url.absoluteString) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let url):
                self.setupPlayer(url)
            case .failure(let error):
                print(error)
            }
        }
    }
  
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus" {
            if player?.timeControlStatus == .playing {
                removeActivityIndicatory()
                mediaState?(state, duration)
            } else if player?.timeControlStatus == .waitingToPlayAtSpecifiedRate {
                addActivityIndicatory()
            }
        }
    }
    
    private func getVideoLength(videoURL: URL) {
        duration = AVURLAsset(url: videoURL).duration.seconds
    }
    
    private func stopAndRestartVideo() {
        player?.seek(to: .zero)
    }
    
    private func stopVideo() {
        if player?.timeControlStatus == .playing {
            player?.pause()
            player?.seek(to: .zero)
            state = .stopped
        }
    }
    
    func restartVideo() {
        if player?.timeControlStatus == .paused {
            player?.seek(to: .zero)
            player?.play()
            state = .restart
        }
    }
    

    
    private func setupPlayer(_ url: URL) {
        self.player?.replaceCurrentItem(with: nil)
        self.player?.replaceCurrentItem(with: AVPlayerItem(url: url))
        self.player?.addObserver(self, forKeyPath: "timeControlStatus", options: .new, context: nil)
        self.player?.automaticallyWaitsToMinimizeStalling = false
        self.getVideoLength(videoURL: url)
        if player?.timeControlStatus != .playing {
            self.player?.play()
            state = .started
        }
        self.playerLayer.player = self.player
        self.playerLayer.videoGravity = .resizeAspectFill
        self.playerLayer.backgroundColor = UIColor.black.cgColor
        playerLayer.removeFromSuperlayer()
        self.contentView.layer.addSublayer(self.playerLayer)
        mediaState?(state, duration)
    }
    
    private func addObserverToVideo() {
        NotificationCenter.default.addObserver(self, selector: #selector(restartVideoObserver), name: .restartVideo, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopVideoObserver), name: .stopVideo, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(stopAndRestartVideoObserver), name: .stopAndRestartVideo, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(replaceCurrentItemObserver), name: .replaceCurrentItem, object: nil)
    }
}

extension PlayerView {
    private func addActivityIndicatory() {
        removeActivityIndicatory()
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        let view = UIView(frame: CGRect(x: 0, y: 0, width: w, height: h))
        view.backgroundColor = .black
        view.tag = 999
        self.addSubview(view)
        let activityView = UIActivityIndicatorView(style: .large)
        activityView.color = UIColor.lightGray.withAlphaComponent(0.7)
        activityView.frame = CGRect(x: w / 2, y: h / 2, width: .zero, height: .zero)
        view.addSubview(activityView)
        addConst(view: activityView)
        activityView.startAnimating()
    }
    
    private func setupPlayer() {
        self.addSubview(contentView)
        contentView.frame.size.width = self.frame.size.width
        contentView.frame.size.height = self.frame.size.height
        self.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: self.leadingAnchor,constant: 0),
            contentView.rightAnchor.constraint(equalTo: self.rightAnchor,constant: 0),
            contentView.bottomAnchor.constraint(equalTo: self.safeAreaLayoutGuide.bottomAnchor,constant: 0),
            contentView.topAnchor.constraint(equalTo: self.topAnchor,constant: 0),
        ])
        playerLayer.frame = contentView.frame
    }
    
    private func removeActivityIndicatory() {
       self.subviews.forEach { (view) in
            if view.tag == 999 {
                view.removeFromSuperview()
            }
        }
    }
    
    private func addConst(view: UIActivityIndicatorView) {
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: view.superview!.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: view.superview!.centerYAnchor)
        ])
    }
    
    @objc private func stopAndRestartVideoObserver() {
        stopAndRestartVideo()
    }
    
    @objc private func restartVideoObserver() {
        restartVideo()
    }
    
    @objc private func stopVideoObserver() {
        stopVideo()
    }
    
    @objc private func replaceCurrentItemObserver() {
        self.player?.replaceCurrentItem(with: nil)
    }
    
}
