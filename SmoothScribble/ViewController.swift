//
//  ViewController.swift
//  SmoothScribble
//
//  Created by Simon Gladman on 04/11/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//

import UIKit

class ViewController: UIViewController
{
    let stackView = UIStackView()
    
    let hermiteScribbleView = HermiteScribbleView(title: "Hermite")
    let simpleScribbleView = SimpleScribbleView(title: "Simple")
    
    var touchOrigin: ScribbleView?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.addSubview(stackView)
        
        stackView.addArrangedSubview(hermiteScribbleView)
        stackView.addArrangedSubview(simpleScribbleView)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        guard let
            location = touches.first?.location(in: self.view) else
        {
            return
        }
        
        if(hermiteScribbleView.frame.contains(location))
        {
            touchOrigin = hermiteScribbleView
        }
        else if (simpleScribbleView.frame.contains(location))
        {
            touchOrigin = simpleScribbleView
        }
        else
        {
            touchOrigin = nil
            return
        }
        
        if let adjustedLocationInView = touches.first?.location(in: touchOrigin)
        {
            hermiteScribbleView.beginScribble(point: adjustedLocationInView)
            simpleScribbleView.beginScribble(point: adjustedLocationInView)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first,
            let coalescedTouches = event?.coalescedTouches(for: touch),
            let touchOrigin = touchOrigin
            else
        {
            return
        }
        
        coalescedTouches.forEach
            {
                hermiteScribbleView.appendScribble(point: $0.location(in: touchOrigin))
                simpleScribbleView.appendScribble(point: $0.location(in: touchOrigin))
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        hermiteScribbleView.endScribble()
        simpleScribbleView.endScribble()
    }
    
    override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
        if motion == UIEventSubtype.motionShake
        {
            hermiteScribbleView.clearScribble()
            simpleScribbleView.clearScribble()
        }
    }
    
    override func viewDidLayoutSubviews()
    {
        stackView.frame = CGRect(x: 0,
                                 y: topLayoutGuide.length,
                                 width: view.frame.width,
                                 height: view.frame.height - topLayoutGuide.length).insetBy(dx: 10, dy: 10)
        
        stackView.axis = view.frame.width > view.frame.height
            ? UILayoutConstraintAxis.horizontal
            : UILayoutConstraintAxis.vertical
        
        stackView.spacing = 10
        
        stackView.distribution = UIStackViewDistribution.fillEqually
    }
}

