//
//  LottieView.swift
//  PhantomTap
//
//  Created by ethanlin on 2025/11/14.
//

import Foundation
import UIKit
import Lottie

@objcMembers
@IBDesignable
class LottieView : UIView
{
    private var animationView : LottieAnimationView?
    
    /// 在 Storyboard 裡可以設這個名字（等於 JSON 檔名，不用附 .json）
    @IBInspectable var animationName : String = ""
    {
        didSet
        {
            loadAnimation()
        }
    }
    
    @IBInspectable var loop : Bool = true
    {
        didSet
        {
            animationView?.loopMode = loop ? .loop : .playOnce
        }
    }
    
    override init(frame : CGRect)
    {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder : NSCoder)
    {
        super.init(coder: coder)
        commonInit()
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        animationView?.frame = bounds
    }
    
    private func commonInit()
    {
        backgroundColor = .clear
    }
    
    private func loadAnimation()
    {
        animationView?.removeFromSuperview()
        
        guard !animationName.isEmpty else { return }
        
        let anim = LottieAnimation.named(animationName)
        let view = LottieAnimationView(animation: anim)
        
        view.frame = bounds
        view.contentMode = .scaleAspectFit
        view.loopMode = loop ? .loop : .playOnce
        
        addSubview(view)
        animationView = view
        view.play()
    }
    
    // 給 Objective-C 呼叫
    @objc func play()
    {
        animationView?.play()
    }
    
    @objc func stop()
    {
        animationView?.stop()
    }
}
