//
//  Scribblable.swift
//  SmoothScribble
//
//  Created by Simon Gladman on 05/11/2015.
//  Copyright © 2015 Simon Gladman. All rights reserved.
//

import UIKit

// MARK: Scribblable protocol

protocol Scribblable
{
    func beginScribble(point: CGPoint)
    func appendScribble(point: CGPoint)
    func endScribble()
    func clearScribble()
}

// MARK: ScribbleView base class

class ScribbleView: UIView
{
    let backgroundLayer = CAShapeLayer()
    let drawingLayer = CAShapeLayer()
    
    let titleLabel = UILabel()
    
    required init(title: String)
    {
        super.init(frame: CGRect.zero)
        
        backgroundLayer.strokeColor = UIColor.darkGray.cgColor
        backgroundLayer.fillColor = nil
        backgroundLayer.lineWidth = 2
        
        drawingLayer.strokeColor = UIColor.black.cgColor
        drawingLayer.fillColor = nil
        drawingLayer.lineWidth = 2
        
        layer.addSublayer(backgroundLayer)
        layer.addSublayer(drawingLayer)
        
        titleLabel.text = title
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.textColor = UIColor.blue
        addSubview(titleLabel)
        
        layer.borderColor = UIColor.blue.cgColor
        layer.borderWidth = 1
        
        layer.masksToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews()
    {
        titleLabel.frame = CGRect(x: 0,
                                  y: frame.height - titleLabel.intrinsicContentSize.height - 2,
                                  width: frame.width,
                                  height: titleLabel.intrinsicContentSize.height)
    }
}

// MARK: Simple line drawing from point to point

class SimpleScribbleView: ScribbleView, Scribblable
{
    let simplePath = UIBezierPath()
    
    func beginScribble(point: CGPoint)
    {
        simplePath.removeAllPoints()
        
        simplePath.move(to: point)
    }
    
    func appendScribble(point: CGPoint)
    {
        simplePath.addLine(to: point)
        
        drawingLayer.path = simplePath.cgPath
    }
    
    func endScribble()
    {
        if let backgroundPath = backgroundLayer.path
        {
            simplePath.append(UIBezierPath(cgPath: backgroundPath))
        }
        
        backgroundLayer.path = simplePath.cgPath
        
        simplePath.removeAllPoints()
        
        drawingLayer.path = simplePath.cgPath
    }
    
    func clearScribble()
    {
        backgroundLayer.path = nil
    }
}

// MARK: Hermite interpolation implementation of ScribbleView

class HermiteScribbleView: ScribbleView, Scribblable
{
    let hermitePath = UIBezierPath()
    var interpolationPoints = [CGPoint]()
    
    func beginScribble(point: CGPoint)
    {
        interpolationPoints = [point]
    }
    
    func appendScribble(point: CGPoint)
    {
        interpolationPoints.append(point)
        
        hermitePath.removeAllPoints()
        hermitePath.interpolatePointsWithHermite(interpolationPoints: interpolationPoints)
        
        drawingLayer.path = hermitePath.cgPath
    }
    
    func endScribble()
    {
        if let backgroundPath = backgroundLayer.path
        {
            hermitePath.append(UIBezierPath(cgPath: backgroundPath))
        }
        
        backgroundLayer.path = hermitePath.cgPath
        
        hermitePath.removeAllPoints()
        
        drawingLayer.path = hermitePath.cgPath
    }
    
    func clearScribble()
    {
        backgroundLayer.path = nil
    }
}

