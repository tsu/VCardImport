import UIKit

class VCardToolbar: UIView {
  let importButton: UIButton!
  let backupButton: UIButton!
  let progressLabel: UILabel!
  let progressView: UIProgressView!
  let border: CALayer!

  override var frame: CGRect {
    get {
      return super.frame
    }

    set {
      super.frame = newValue
      if border != nil {
        border.frame = getBorderLayerRect(newValue)
      }
    }
  }

  override init() {
    super.init()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)

    importButton = makeButton("Import", align: .Left)
    backupButton = makeButton("Backup", align: .Right)
    progressLabel = makeProgressLabel()
    progressView = makeProgressView()
    border = makeBorderLayer(frame)

    addSubview(importButton)
    addSubview(backupButton)
    addSubview(progressLabel)

    // add before border sublayer before progressView so that the latter
    // obscures the former when shown
    layer.addSublayer(border)
    addSubview(progressView)

    backgroundColor = UIColor.whiteColor()

    setupLayout()
  }

  required init(coder decoder: NSCoder) {
    fatalError("not implemented")
  }

  func beginProgress(text: String) {
    progressLabel.text = text
    progressView.setProgress(0, animated: false)

    UIView.animateWithDuration(
      0.5,
      delay: 0,
      options: .CurveEaseIn,
      animations: {
        self.progressLabel.alpha = 1
        self.progressView.alpha = 1
      },
      completion: nil)
  }

  func endProgress() {
    UIView.animateWithDuration(
      0.5,
      delay: 0,
      options: .CurveEaseOut,
      animations: {
        self.progressLabel.alpha = 0
        self.progressView.alpha = 0
      },
      completion: { _ in
        self.progressLabel.text = nil
        self.progressView.setProgress(0, animated: false)
      })
  }

  func inProgress(text: String, progress: Float) {
    progressLabel.text = text
    progressView.setProgress(progress, animated: true)
  }

  // MARK: Helpers

  private func makeButton(
    title: String,
    align labelAlignment: UIControlContentHorizontalAlignment)
    -> UIButton
  {
    let button = UIButton.buttonWithType(.System) as UIButton
    button.setTitle(title, forState: .Normal)
    if let label = button.titleLabel {
      label.font = label.font.fontWithSize(16)
    }
    button.contentHorizontalAlignment = labelAlignment
    return button
  }

  private func makeProgressLabel() -> UILabel {
    let label = UILabel()
    label.textAlignment = .Center
    label.textColor = UIColor(white: 0.3, alpha: 1)
    label.adjustsFontSizeToFitWidth = true
    label.font = label.font.fontWithSize(14)
    label.minimumScaleFactor = 0.7
    label.lineBreakMode = .ByWordWrapping
    label.numberOfLines = 2
    label.alpha = 0
    return label
  }

  private func makeProgressView() -> UIProgressView {
    let view = UIProgressView(progressViewStyle: .Bar)
    view.alpha = 0
    return view
  }

  private func makeBorderLayer(frame: CGRect) -> CALayer {
    let layer = CALayer()
    layer.frame = getBorderLayerRect(frame)
    layer.backgroundColor = UIColor(white: 0.8, alpha: 1).CGColor
    return layer
  }

  private func getBorderLayerRect(frame: CGRect) -> CGRect {
    return CGRect(x: 0, y: 0, width: frame.size.width, height: 1)
  }

  private func setupLayout() {
    importButton.setTranslatesAutoresizingMaskIntoConstraints(false)
    importButton.setContentHuggingPriority(251, forAxis: .Horizontal)
    backupButton.setTranslatesAutoresizingMaskIntoConstraints(false)
    backupButton.setContentHuggingPriority(251, forAxis: .Horizontal)
    progressLabel.setTranslatesAutoresizingMaskIntoConstraints(false)
    progressLabel.setContentCompressionResistancePriority(749, forAxis: .Horizontal)
    progressView.setTranslatesAutoresizingMaskIntoConstraints(false)

    let viewNamesToObjects = [
      "importButton": importButton,
      "backupButton": backupButton,
      "progressLabel": progressLabel,
      "progressView": progressView
    ]

    addConstraint(NSLayoutConstraint(
      item: importButton,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: self,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0))

    addConstraint(NSLayoutConstraint(
      item: backupButton,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: self,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0))

    addConstraint(NSLayoutConstraint(
      item: importButton,
      attribute: .Width,
      relatedBy: .Equal,
      toItem: backupButton,
      attribute: .Width,
      multiplier: 1,
      constant: 0))

    addConstraint(NSLayoutConstraint(
      item: progressLabel,
      attribute: .CenterY,
      relatedBy: .Equal,
      toItem: self,
      attribute: .CenterY,
      multiplier: 1,
      constant: 0))

    addConstraint(NSLayoutConstraint(
      item: progressView,
      attribute: .Width,
      relatedBy: .Equal,
      toItem: self,
      attribute: .Width,
      multiplier: 1,
      constant: 0))

    addConstraint(NSLayoutConstraint(
      item: progressView,
      attribute: .Top,
      relatedBy: .Equal,
      toItem: self,
      attribute: .Top,
      multiplier: 1,
      constant: 0))

    addConstraint(NSLayoutConstraint(
      item: progressView,
      attribute: .Height,
      relatedBy: .Equal,
      toItem: nil,
      attribute: .NotAnAttribute,
      multiplier: 1,
      constant: 4))

    addConstraints(NSLayoutConstraint.constraintsWithVisualFormat(
      "H:|-[importButton(>=50)]-10-[progressLabel]-10-[backupButton(>=50)]-|",
      options: nil,
      metrics: nil,
      views: viewNamesToObjects))
  }
}
