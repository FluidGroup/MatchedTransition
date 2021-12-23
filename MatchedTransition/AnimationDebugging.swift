import Foundation
import CoreGraphics

#if DEBUG
fileprivate var isDebugModeEnabled: Bool = false
fileprivate var factor: CGFloat = 25
#endif

public func _matchedTransition_setIsAnimationDebugModeEnabled(_ value: Bool) {
  isDebugModeEnabled = value
}

extension TimeInterval {

  /**
   [MatchedTransition]
   Returns time interval with debugging mode
   */
  public static func _matchedTransition_debuggable(_ value: Self) -> Self {
#if DEBUG
    if isDebugModeEnabled {
      return value * factor
    } else {
      return value
    }
#else
    return value
#endif
  }

}
