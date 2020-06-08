//
//  FloatingVideoView.swift
//  DraggleView
//
//  Created by Dinesh on 6/4/20.
//  Copyright © 2020 Dinesh. All rights reserved.
//

import UIKit
import WebRTC

protocol FloatingVideoViewControlsDelegate: class {
    func muteMic(_ status: Bool)
    func shareScreen(_ status: Bool)
    func disconnectCall()
}
class FloatingVideoView: UIView {
    
    @IBOutlet weak var minimizeButton: UIButton!
    @IBOutlet weak var expandButton: UIButton!
    @IBOutlet weak var topViewControls: UIView!
    @IBOutlet private weak var controlView: UIView!
    @IBOutlet private weak var localVideoView: RTCEAGLVideoView!
    @IBOutlet private weak var remoteVideoView: RTCEAGLVideoView!
    @IBOutlet private weak var micButton: UIButton!
    @IBOutlet private weak var screenShare: UIButton!
    @IBOutlet private weak var callEndButton: UIButton!
    @IBOutlet private weak var videoButton: UIButton!
    @IBOutlet private weak var remoteViewTopPin: NSLayoutConstraint!
    @IBOutlet private weak var remoteViewBottomPin: NSLayoutConstraint!
    @IBOutlet private weak var remoteViewLeftPin: NSLayoutConstraint!
    @IBOutlet private weak var remoteViewRightPin: NSLayoutConstraint!

    @IBOutlet weak var localVideoHeightPin: NSLayoutConstraint!
    @IBOutlet weak var localVideoWidthPin: NSLayoutConstraint!

    @IBOutlet weak var stackView: UIStackView!
    private var localViewTopLeftCornerFrame: CGRect!
    private var localViewTopRightCornerFrame: CGRect!
    private var localViewBottomLeftCornerFrame: CGRect!
    private var localViewBottomRightCornerFrame: CGRect!
    private var remoteViewTopLeftCornerFrame: CGRect!
    private var remoteViewTopRightCornerFrame: CGRect!
    private var remoteViewBottomLeftCornerFrame: CGRect!
    private var remoteViewBottomRightCornerFrame: CGRect!
    private var originalFrame: CGRect!
    private var manipulatedFrame: CGRect!
    public weak var controlDelegate: FloatingVideoViewControlsDelegate?
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func getRenderVideoView() -> (local: RTCEAGLVideoView, remote: RTCEAGLVideoView) {
        return(self.localVideoView, self.remoteVideoView)
    }
    
    func setup() {
        originalFrame = self.frame
        self.controlView.backgroundColor = .clear
        self.localVideoView.layer.borderColor = UIColor.black.cgColor
        self.remoteVideoView.layer.borderColor = UIColor.black.cgColor
        self.remoteVideoView.layer.borderWidth = 2.0
        self.localVideoView.layer.borderWidth = 2.0
        self.localVideoView.layer.masksToBounds = true
        self.remoteVideoView.layer.masksToBounds = true
        configureRoundedButtons(self.micButton)
        configureRoundedButtons(self.videoButton)
        configureRoundedButtons(self.screenShare)
        configureRoundedButtons(self.callEndButton, color: .red)
        manipulatedFrame = self.frame
        self.addRemoteViewPanGesture(self)
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.expandView(true)
            self.updateRemoteViewHotCorners()
        })
    }
    
    func configureRoundedButtons(_ button: UIButton, color: UIColor? = .black) {
        let buttonColor: UIColor = color == nil ? UIColor.black : color!
        button.layer.backgroundColor = buttonColor.withAlphaComponent(0.80).cgColor
        button.layer.cornerRadius = button.frame.width / 2
        button.layer.masksToBounds = true
    }
    
    @IBAction func micTap(_ button: UIButton) {
        guard let imageIcon = button.imageView?.image else {
            return
        }
        let muteIcon = UIImage(named: "mute.png")
        let unmuteIcon = UIImage(named: "unmute.png")
        if imageIcon == muteIcon {
            button.setImage(unmuteIcon, for: .normal)
            self.controlDelegate?.muteMic(false)
        } else {
            button.setImage(muteIcon, for: .normal)
            self.controlDelegate?.muteMic(true)
        }
    }
    
    @IBAction func screenShareTap(_ sender: Any) {
        self.controlDelegate?.shareScreen(false)
    }
    
    @IBAction func callEndTap(_ sender: Any) {
        self.controlDelegate?.disconnectCall()
    }
    
    @IBAction func expandAction(_ sender: Any) {
        expand()
    }
    
    @IBAction func minimizeAction(_ sender: Any) {
        minimise()
    }
           
    private func addRemoteViewPanGesture(_ gView: UIView) {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRemoteViewPanGesture(_:)))
        gView.addGestureRecognizer(panGesture)
    }
    
    @objc func expand() {
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            if self.originalFrame.width == self.frame.width && self.originalFrame.height ==  self.frame.height {
                self.expandView(true)
                self.updateRemoteViewHotCorners()
            } else {
                self.expandView(false)
            }
        })
    }
    
    @objc func handleRemoteViewPanGesture(_ gesture: UIPanGestureRecognizer) {
        if self.originalFrame.width == self.frame.width {
            return
        }
        if self.frame.height == CGFloat(44)  {
            return
        }
        if gesture.state == .changed {
         let translation = gesture.translation(in: self)
             self.center = CGPoint(x: self.center.x + translation.x, y: self.center.y + translation.y)
            gesture.setTranslation(.zero, in: self)
         } else if gesture.state == .ended {
            print("self.frame: \(self.frame)")
             if self.frame.intersects(self.remoteViewTopLeftCornerFrame) {
                  moveRemoteView(self.remoteViewTopLeftCornerFrame)
             } else if self.frame.intersects(self.remoteViewTopRightCornerFrame) {
                  moveRemoteView(self.remoteViewTopRightCornerFrame)
             } else if self.frame.intersects(self.remoteViewBottomRightCornerFrame) {
                  moveRemoteView(self.remoteViewBottomRightCornerFrame)
             } else if self.frame.intersects(self.remoteViewBottomLeftCornerFrame) {
                  moveRemoteView(self.remoteViewBottomLeftCornerFrame)
             } else {
                 print("Invalid corner")
                 moveRemoteView(self.remoteViewBottomRightCornerFrame)
             }
         }
    }

    private func moveRemoteView(_ frame: CGRect) {
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.frame = frame
        })
    }
    
    private func moveLocalView(_ frame: CGRect) {
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.localVideoView.frame = frame
        })
    }
    
    
    //Update this method when we do orientation
     private func expandView(_ animate: Bool) {
        self.remoteVideoView.layer.borderWidth = animate ? 2.0 : 0.0
        self.localVideoWidthPin.constant = animate ? UIConstraints.shrinkLocalVideoWidth : UIConstraints.defaultLocalVideoWidth
        self.localVideoHeightPin.constant = animate ? UIConstraints.shrinkLocalVideoHeight : UIConstraints.defaultLocalVideoHeight
        let yPin = animate ? self.frame.height - self.frame.height/2.45 : UIConstraints.constant
        let xPin = CGFloat(0)
        let height = animate ? (self.frame.height - self.frame.height/1.7) : self.originalFrame.height
        let width = animate ? (self.frame.width/2.3) : self.originalFrame.width
        let shrinkFrame = CGRect(x: xPin,
                                y: yPin,
                                width: width,
                                height: height)
        self.manipulatedFrame = animate ? shrinkFrame : originalFrame
        self.frame = self.manipulatedFrame
        self.controlView.alpha = 1.0
        //self.stackView.spacing = animate ? 10 : 30
        self.layoutIfNeeded()
    }
    
    private func minimise() {
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.5,
                       initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
           if self.frame.height != CGFloat(44) {
                self.minimizeScreen(true)
           } else {
                self.minimizeScreen(false)
           }
        })
    }
    
    private func minimizeScreen(_ animate: Bool) {
        let yPin = animate ? self.originalFrame.height - self.topViewControls.frame.height : CGFloat(0)
        let xPin = CGFloat(0)
        let height = animate ? CGFloat(44.0) : self.manipulatedFrame.height
        let minimizeFrame = CGRect(x: xPin,
                                y: yPin,
                                width: self.manipulatedFrame.width,
                                height: height)
        self.frame = animate ? minimizeFrame : self.manipulatedFrame
        self.controlView.alpha = animate ? 0.0 : 1.0
        self.layoutIfNeeded()
    }
    
    private func updateRemoteViewHotCorners() {
        self.remoteViewTopLeftCornerFrame = CGRect(x: UIConstraints.constant, y: UIConstraints.constant, width: self.frame.width, height: self.frame.height)
        
        self.remoteViewTopRightCornerFrame = CGRect(x: (self.originalFrame.width - self.frame.width), y: UIConstraints.constant, width: self.frame.width, height: self.frame.height)
        
        self.remoteViewBottomLeftCornerFrame = CGRect(x: UIConstraints.constant, y: (self.originalFrame.height - self.frame.height), width: self.frame.width, height: self.frame.height)
        
        self.remoteViewBottomRightCornerFrame = CGRect(x: (self.originalFrame.width - self.frame.width), y: (self.originalFrame.height - self.frame.height), width: self.frame.width, height: self.frame.height)
    }
}
