import UIKit

extension CALayer {

  func setContinuousCornerRadius(_ cornerRadius: CGFloat) {
    self.cornerRadius = cornerRadius
    if #available(iOS 13.0, *) {
      self.cornerCurve = .continuous
    } else {
      // Fallback on earlier versions
    }
  }
}

extension CGSize {
  init(
    square dimension: CGFloat
  ) {
    self.init(width: dimension, height: dimension)
  }

}
