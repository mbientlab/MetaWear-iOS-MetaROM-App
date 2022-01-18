//
//  GaugeView.swift
//  MetaClinic
//
//  Created by Stephen Schiffli on 7/10/19.
//  Copyright © 2019 MBIENTLAB, INC. All rights reserved.
//

import Foundation
import UIKit


@IBDesignable
open class GaugeView: UIView {
    // MARK: - properties
    fileprivate var containerView: UIView!
    fileprivate var backgroundCircleLayer = CAShapeLayer()
    fileprivate var progressCircleLayer = CAShapeLayer()
    fileprivate var knobLayer = CAShapeLayer()
    fileprivate var subdivisionLayer = CAShapeLayer()
    fileprivate var goalBarLayer = CAShapeLayer()
    fileprivate var goalDotLayer = CAShapeLayer()
    fileprivate var backingValue: Float = 0
    fileprivate var backingGoal: Float = 0
    fileprivate var subdivisionLowerBuffer: CGFloat = 15
    fileprivate var outerBounds: CGRect {
        let x = (bounds.width - ((arcRadius * 2) + lineWidth)) / 2
        return CGRect(x: x, y: 0, width: (arcRadius * 2) + lineWidth, height: (arcRadius * 2) + lineWidth)
    }
    fileprivate var arcRect: CGRect {
        let ed = CGRect(x: bounds.origin.x + (lineWidth / 2),
                        y: bounds.origin.y + (lineWidth / 2),
                        width: bounds.width - lineWidth,
                        height: bounds.height - lineWidth - subdivisionLowerBuffer)
        return ed
    }
    fileprivate var startAngle: CGFloat {
        return .pi + acos(arcRect.width / (2 * arcRadius))
    }
    fileprivate var endAngle: CGFloat {
        return (2 * .pi) - acos(arcRect.width / (2 * arcRadius))
    }
    fileprivate var angleRange: CGFloat {
        return endAngle - startAngle
    }
    fileprivate var valueRange: Float {
        return maximumValue - minimumValue
    }
    fileprivate var arcCenter: CGPoint {
        return CGPoint(x: arcRect.origin.x + arcRect.width / 2, y: arcRect.origin.y + arcRadius)
    }
    fileprivate var arcRadius: CGFloat {
        let ed = (arcRect.height / 2) + (pow(arcRect.width, 2) / (8 * arcRect.height))
        return ed
    }
    fileprivate var normalizedValue: Float {
        return (value - minimumValue) / (maximumValue - minimumValue)
    }
    fileprivate var knobAngle: CGFloat {
        return CGFloat(normalizedValue) * angleRange + startAngle
    }
    fileprivate var goalAngle: CGFloat {
        let normalizedGoal = CGFloat((goal - minimumValue) / (maximumValue - minimumValue))
        return normalizedGoal * angleRange + startAngle
    }
    fileprivate var knobMidAngle: CGFloat {
        return (2 * .pi + startAngle - endAngle) / 2 + endAngle
    }
    fileprivate var knobRotationTransform: CATransform3D {
        return CATransform3DMakeRotation(knobAngle, 0.0, 0.0, 1)
    }
    fileprivate var goalRotationTransform: CATransform3D {
        return CATransform3DMakeRotation(goalAngle, 0.0, 0.0, 1)
    }
    fileprivate var points: Int {
        return 19 //Int(round(angleRange / subdivisionsStepValue))
    }
    
    @IBInspectable
    open var value: Float {
        get {
            return backingValue
        }
        set {
            backingValue = min(maximumValue, max(minimumValue, newValue))
        }
    }
    @IBInspectable
    open var goal: Float {
        get {
            return backingGoal
        }
        set {
            backingGoal = min(maximumValue, max(minimumValue, newValue))
        }
    }
    @IBInspectable
    open var minimumValue: Float = 0
    @IBInspectable
    open var maximumValue: Float = 500
    @IBInspectable
    open var lineWidth: CGFloat = 5 {
        didSet {
            appearanceProgressLayer()
        }
    }
    @IBInspectable
    open var bgLineWidth: CGFloat = 5 {
        didSet {
            appearanceBackgroundLayer()
        }
    }
    @IBInspectable
    open var bgColor: UIColor = UIColor.lightGray {
        didSet {
            appearanceBackgroundLayer()
        }
    }
    @IBInspectable
    open var pgNormalColor: UIColor = UIColor.darkGray {
        didSet {
            appearanceProgressLayer()
        }
    }
    @IBInspectable
    open var pgHighlightedColor: UIColor = UIColor.green {
        didSet {
            appearanceProgressLayer()
        }
    }
    @IBInspectable
    open var knobRadius: CGFloat = 20 {
        didSet {
            appearanceKnobLayer()
        }
    }
    @IBInspectable
    open var highlighted: Bool = true {
        didSet {
            appearanceProgressLayer()
            appearanceKnobLayer()
        }
    }
    @IBInspectable
    open var bgGoalColor: UIColor = UIColor.green {
        didSet {
            appearanceGoalDotLayer()
            appearanceGoalBarLayer()
        }
    }
    @IBInspectable
    open var bgGoalWidth: CGFloat = 4 {
        didSet {
            appearanceGoalDotLayer()
            appearanceGoalBarLayer()
        }
    }
    @IBInspectable
    open var subdivisionLength: CGFloat = 20 {
        didSet {
            appearanceSubdivisionLayer()
        }
    }
    
    // MARK: - init
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configure()
    }
    
    // MARK: - drawing methods
    override open func draw(_ rect: CGRect) {
        backgroundCircleLayer.bounds = outerBounds
        progressCircleLayer.bounds = outerBounds
        knobLayer.bounds = outerBounds
        subdivisionLayer.bounds = outerBounds
        goalBarLayer.bounds = outerBounds
        goalDotLayer.bounds = outerBounds

        backgroundCircleLayer.position = arcCenter
        progressCircleLayer.position = arcCenter
        knobLayer.position = arcCenter
        subdivisionLayer.position = arcCenter
        goalBarLayer.position = arcCenter
        goalDotLayer.position = arcCenter

        backgroundCircleLayer.path = getCirclePath()
        progressCircleLayer.path = getCirclePath()
        knobLayer.path = getKnobPath()
        subdivisionLayer.path = getSubdivisionPath()
        goalBarLayer.path = getGoalBarPath()
        goalDotLayer.path = getGoalDotPath()

        setValue(value)
        setGoal(goal)
    }
    
    
    fileprivate func getCirclePath() -> CGPath {
        return UIBezierPath(arcCenter: arcCenter,
                            radius: arcRadius,
                            startAngle: startAngle,
                            endAngle: endAngle,
                            clockwise: true).cgPath
    }
    
    fileprivate func getKnobPath() -> CGPath {
        return UIBezierPath(roundedRect:
            CGRect(x: (arcCenter.x + arcRadius - knobRadius / 2), y: (arcCenter.y - knobRadius / 2), width: knobRadius, height: knobRadius),
                            cornerRadius: knobRadius / 2).cgPath
    }
    
    fileprivate func getSubdivisionPath() -> CGPath {
        let indicatorPath = UIBezierPath()
        let centerPoint = arcCenter
        
        let startVal = arcRadius - (knobRadius / 2) - subdivisionLength
        let endRad = startVal + subdivisionLength
        
        for i in 0...points {
            let baseAngle = calcAngle(point: i)
            let startPoint = CGPoint(x: cos(baseAngle) * startVal + centerPoint.x, y: sin(baseAngle) * startVal + centerPoint.y)
            let endPoint = CGPoint(x: cos(baseAngle) * endRad+centerPoint.x, y: sin(baseAngle) * endRad + centerPoint.y)
            
            indicatorPath.move(to: startPoint)
            indicatorPath.addLine(to: endPoint)
        }
        
        return indicatorPath.cgPath
    }
    
    fileprivate func getGoalDotPath() -> CGPath {
        let centerPoint = arcCenter
        let endRad = arcRadius
        let endPoint = CGPoint(x: endRad + centerPoint.x, y: centerPoint.y)

        let dotSize = bgLineWidth
        return UIBezierPath(roundedRect:
            CGRect(x: endPoint.x - (dotSize / 2),
                   y: endPoint.y - (dotSize / 2),
                   width: dotSize,
                   height: dotSize),
                               cornerRadius: dotSize / 2).cgPath
    }
    
    fileprivate func getGoalBarPath() -> CGPath {
        let indicatorPath = UIBezierPath()
        let centerPoint = arcCenter
        
        let startVal = arcRadius - (knobRadius / 2) - subdivisionLength
        let endRad = arcRadius
        
        let startPoint = CGPoint(x: startVal + centerPoint.x, y: centerPoint.y)
        let endPoint = CGPoint(x: endRad + centerPoint.x, y: centerPoint.y)
        
        indicatorPath.move(to: startPoint)
        indicatorPath.addLine(to: endPoint)
        
        return indicatorPath.cgPath
    }
    
    fileprivate func calcAngle(point: Int) -> CGFloat {
        return startAngle + (angleRange * (CGFloat(point) / CGFloat(points)))
    }
    
    // MARK: - configure
    fileprivate func configure() {
        print("CONFIGURE")

        clipsToBounds = false
        configureBackgroundLayer()
        configureSubdivisionLayer()
        configureGoalBarLayer()
        configureGoalDotLayer()
        configureProgressLayer()
        configureKnobLayer()
    }
    
    fileprivate func configureBackgroundLayer() {
        backgroundCircleLayer.frame = outerBounds
        layer.addSublayer(backgroundCircleLayer)
        appearanceBackgroundLayer()
    }
    
    fileprivate func configureProgressLayer() {
        progressCircleLayer.frame = outerBounds
        progressCircleLayer.strokeEnd = 0
        layer.addSublayer(progressCircleLayer)
        appearanceProgressLayer()
    }
    
    fileprivate func configureKnobLayer() {
        knobLayer.frame = outerBounds
        layer.addSublayer(knobLayer)
        appearanceKnobLayer()
    }
    
    fileprivate func configureSubdivisionLayer() {
        subdivisionLayer.frame = outerBounds
        layer.addSublayer(subdivisionLayer)
        appearanceSubdivisionLayer()
    }
    
    fileprivate func configureGoalDotLayer() {
        goalDotLayer.frame = outerBounds
        layer.addSublayer(goalDotLayer)
        appearanceGoalDotLayer()
    }
    
    fileprivate func configureGoalBarLayer() {
        goalBarLayer.frame = outerBounds
        layer.addSublayer(goalBarLayer)
        appearanceGoalBarLayer()
    }
    
    // MARK: - appearance
    fileprivate func appearanceBackgroundLayer() {
        backgroundCircleLayer.lineWidth = bgLineWidth
        backgroundCircleLayer.fillColor = UIColor.clear.cgColor
        backgroundCircleLayer.strokeColor = bgColor.cgColor
        backgroundCircleLayer.lineCap = CAShapeLayerLineCap.round
    }
    
    fileprivate func appearanceProgressLayer() {
        progressCircleLayer.lineWidth = lineWidth
        progressCircleLayer.fillColor = UIColor.clear.cgColor
        progressCircleLayer.strokeColor = highlighted ? pgHighlightedColor.cgColor : pgNormalColor.cgColor
        progressCircleLayer.lineCap = CAShapeLayerLineCap.round
    }
    
    fileprivate func appearanceKnobLayer() {
        knobLayer.lineWidth = 2
        knobLayer.fillColor = highlighted ? pgHighlightedColor.cgColor : pgNormalColor.cgColor
        knobLayer.strokeColor = UIColor.white.cgColor
    }
    
    fileprivate func appearanceSubdivisionLayer() {
        subdivisionLayer.lineWidth = 1
        subdivisionLayer.fillColor = UIColor.clear.cgColor
        subdivisionLayer.strokeColor = bgColor.cgColor
    }
    
    fileprivate func appearanceGoalDotLayer() {
        goalDotLayer.lineWidth = 2
        goalDotLayer.fillColor = bgGoalColor.cgColor
        goalDotLayer.strokeColor = UIColor.white.cgColor
    }
    
    fileprivate func appearanceGoalBarLayer() {
        goalBarLayer.lineWidth = bgGoalWidth
        goalBarLayer.fillColor = UIColor.clear.cgColor
        goalBarLayer.strokeColor = bgGoalColor.cgColor
        goalBarLayer.lineCap = CAShapeLayerLineCap.round
    }
    
    // MARK: - update
    open func setValue(_ value: Float) {
        self.value = value

        setStrokeEnd()
        setKnobRotation()
    }
    
    open func setGoal(_ goal: Float) {
        self.goal = goal
        
        setGoalRotation()
    }
    
    fileprivate func setStrokeEnd() {
        progressCircleLayer.strokeEnd = CGFloat(normalizedValue)
    }
    
    fileprivate func setKnobRotation() {
        knobLayer.transform = knobRotationTransform
    }
    
    fileprivate func setGoalRotation() {
        goalDotLayer.transform = goalRotationTransform
        goalBarLayer.transform = goalRotationTransform
    }
}
