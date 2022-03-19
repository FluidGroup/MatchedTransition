//

import Foundation
import UIKit
import os.log

enum Log {
  
  static func debug(_ log: OSLog, _ object: Any...) {
    os_log(.debug, log: log, "%@", object.map { "\($0)" }.joined(separator: " "))
  }
  
  static func error(_ log: OSLog, _ object: Any...) {
    os_log(.error, log: log, "%@", object.map { "\($0)" }.joined(separator: " "))
  }
  
}

extension OSLog {
  
  @inline(__always)
  private static func makeOSLogInDebug(_ factory: () -> OSLog) -> OSLog {
#if DEBUG
    return factory()
#else
    return .disabled
#endif
  }
  
  static let animator: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "MatchedTransitionAnimator", category: "MatchedTransitionAnimator/Animator") }
}

// MARK: Implementations

func error(_ condition: @autoclosure () -> Bool, _ message: String, file: StaticString = #file, line: UInt = #line) {
  #if DEBUG
  if condition() == false {
    Log.error(.animator, "\(message) \(file):\(line)")
  }
  #endif
}

/*
private struct Key: Hashable {
  let fromKey: ObjectIdentifier
  let toKey: ObjectIdentifier
  let containerKey: ObjectIdentifier
  let snapshotTypeName: String
}
 */

private let _snapshotStorage: NSMapTable<NSString, UIView> = .strongToWeakObjects()

private func _makeSnapshotViewIfNeeded<SnapshotView: UIView>(
  from fromView: UICoordinateSpace,
  to toView: UICoordinateSpace,
  in containerView: UICoordinateSpace,
  make: () -> SnapshotView
) -> SnapshotView {

  let key =
  "\(ObjectIdentifier(fromView)),\(ObjectIdentifier(toView)),\(ObjectIdentifier(containerView)),\(String(reflecting: SnapshotView.self))"
    as NSString

  func makeAndStore() -> SnapshotView {
    let newView = make()
    _snapshotStorage.setObject(newView, forKey: key)
    return newView
  }

  guard let view = _snapshotStorage.object(forKey: key) else {
    return makeAndStore()
  }

  guard let typedView = view as? SnapshotView else {
    assertionFailure("Unable to cast to \(SnapshotView.self)")
    return makeAndStore()
  }

  return typedView
}

extension UIView {

  public var _matchedTransition_layerAnimations: [CAAnimation] {
    (layer.animationKeys() ?? []).compactMap {
      layer.animation(forKey: $0)
    }
  }

  fileprivate var isAnimatingByPropertyAnimator: Bool {
    (layer.animationKeys() ?? []).contains(where: {
      $0.hasPrefix("UIPacingAnimationForAnimatorsKey")
    })
  }

  /**
   Returns a relative frame in view.
   */
  public func _matchedTransition_relativeFrame(in view: UICoordinateSpace, ignoresTransform: Bool) -> CGRect {

    if ignoresTransform {

      CATransaction.begin()
      CATransaction.setDisableActions(true)

      let currentTransform = transform
      let currentAlpha = alpha
      self.transform = .identity
      self.alpha = 0
      let rect = self.convert(bounds, to: view)
      self.transform = currentTransform
      self.alpha = currentAlpha
      
      CATransaction.commit()
      return rect
    } else {
      let rect = self.convert(bounds, to: view)
      return rect
    }

  }

  fileprivate func setFrameIgnoringTransforming(_ newFrame: CGRect) {
    bounds.size = newFrame.size
    center = newFrame.center
  }

}

extension UIViewPropertyAnimator {

  public enum MovingMode {
    case center
    case frame
    case transform
  }

  /**
   [For intruptible transition]
   Adds the moving animation between from and to

   - Parameters:
     - makeSnapshotViewIfNeeded: A closure to create a view that moves between from and to. this closure won't run when found the current snapshot view.
   */
  @discardableResult
  public func addSnapshotMovingAnimation<SnapshotView: UIView>(
    makeSnapshotViewIfNeeded: () -> SnapshotView,
    from fromView: UIView,
    to toView: UIView,
    isReversed: Bool,
    in containerView: UIView,
    movingMode: MovingMode = .transform
  ) -> SnapshotView {

    let view = _makeSnapshotViewIfNeeded(
      from: fromView,
      to: toView,
      in: containerView,
      make: makeSnapshotViewIfNeeded
    )

    let snapshotView = addSnapshotMovingAnimation(
      snapshotView: view,
      from: fromView,
      to: toView,
      isReversed: isReversed,
      in: containerView,
      movingMode: movingMode
    )

    return snapshotView

  }

  /**
   Adds the moving animation between from and to

   - Parameters:
     - snapshotView: A view that moves between from and to.
   */
  @discardableResult
  public func addSnapshotMovingAnimation<SnapshotView: UIView>(
    snapshotView: SnapshotView,
    from fromView: UIView,
    to toView: UIView,
    isReversed: Bool,
    in containerView: UIView,
    movingMode: MovingMode = .transform
  ) -> SnapshotView {

    assert(
      snapshotView !== fromView || snapshotView !== toView,
      "SnapshotView must be another instance from fromView:\(fromView) and toView:\(toView)"
    )

    /// a necessary operation to get the correct relative position.
    containerView.layoutIfNeeded()

    switch movingMode {
    case .center:

      let fromFrameInContainerView = fromView._matchedTransition_relativeFrame(in: containerView, ignoresTransform: false)
      let toFrameInContainerView = toView._matchedTransition_relativeFrame(in: containerView, ignoresTransform: false)

      preparation: do {

        if snapshotView.superview != containerView {

          // TODO: Consider if no issues.
          containerView.addSubview(snapshotView)

          snapshotView.frame.size = fromFrameInContainerView.size

          if isReversed {

            /// To apply transform correctly with setting up the frame without transforming

            snapshotView.center = toFrameInContainerView.center

          } else {

            /// To apply transform correctly with setting up the frame without transforming

            snapshotView.center = fromFrameInContainerView.center

          }

        }

      }

      addAnimations {

        if isReversed {
          error(containerView.subviews.contains(fromView), "\(fromView) is not in suitable state.")
          error(fromView.isDescendant(of: containerView), "\(fromView) is not in suitable state.")

          snapshotView.center = fromFrameInContainerView.center

        } else {
          error(containerView.subviews.contains(toView), "\(toView) is not in suitable state.")
          error(toView.isDescendant(of: containerView), "\(toView) is not in suitable state.")

          snapshotView.center = toFrameInContainerView.center

        }

      }

    case .frame:

      let fromFrameInContainerView = fromView._matchedTransition_relativeFrame(in: containerView, ignoresTransform: false)
      let toFrameInContainerView = toView._matchedTransition_relativeFrame(in: containerView, ignoresTransform: false)

      preparation: do {

        if snapshotView.superview != containerView {

          // TODO: Consider if no issues.
          containerView.addSubview(snapshotView)

          if isReversed {

            /// To apply transform correctly with setting up the frame without transforming
            snapshotView.setFrameIgnoringTransforming(toFrameInContainerView)
            snapshotView.layoutIfNeeded()

          } else {

            /// To apply transform correctly with setting up the frame without transforming
            snapshotView.setFrameIgnoringTransforming(fromFrameInContainerView)
            snapshotView.layoutIfNeeded()

          }

        }

      }


      addAnimations {

        if isReversed {

          error(toView.isDescendant(of: containerView), "The target view for moving is not in the hierarchy of container view, snapshot might move the wrong position.")
          snapshotView.frame = fromFrameInContainerView

        } else {

          error(toView.isDescendant(of: containerView), "The target view for moving is not in the hierarchy of container view, snapshot might move the wrong position.")
          snapshotView.frame = toFrameInContainerView

        }

      }

    case .transform:

      let fromFrameInContainerView = fromView._matchedTransition_relativeFrame(in: containerView, ignoresTransform: true)
      let toFrameInContainerView = toView._matchedTransition_relativeFrame(in: containerView, ignoresTransform: true)
      preparation: do {

        if snapshotView.superview != containerView {

          // TODO: Consider if no issues.
          containerView.addSubview(snapshotView)

          if isReversed {
            snapshotView.transform = Self.makeCGAffineTransform(
              from: fromFrameInContainerView,
              to: toFrameInContainerView
            )
          } else {
            snapshotView.transform = .identity
          }

        }

        /// To apply transform correctly with setting up the frame without transforming
        snapshotView.bounds.size = fromFrameInContainerView.size
        snapshotView.center = CGPoint(
          x: fromFrameInContainerView.midX,
          y: fromFrameInContainerView.midY
        )

      }

      addAnimations {

        if isReversed {

          snapshotView.transform = .identity

        } else {
          snapshotView.transform = Self.makeCGAffineTransform(
            from: fromFrameInContainerView,
            to: toFrameInContainerView
          )

        }

      }

    }

    addCompletion { [weak snapshotView] _ in

      if let snapshotView = snapshotView {
        if snapshotView.isAnimatingByPropertyAnimator == false {
          snapshotView.removeFromSuperview()
        }
      }

    }

    return snapshotView
  }

  public func addMovingAnimation(
    from fromView: UIView,
    to toView: UIView,
    sourceView: UIView,
    isReversed: Bool,
    in containerView: UIView
  ) {

    let fromFrameInContainerView = fromView._matchedTransition_relativeFrame(in: containerView, ignoresTransform: true)
    let toFrameInContainerView = toView._matchedTransition_relativeFrame(in: containerView, ignoresTransform: true)

    let _movingMode: MovingMode = .transform

    switch _movingMode {
    case .center:

      // FIXME: Find ways to how to keep the original value.
      assertionFailure("Unimplemented")

      if toView === sourceView {
//        if toView.isAnimatingByPropertyAnimator == false {
//          if isReversed == false {
//            toView.transform = Self.makeCGAffineTransform(
//              from: toFrameInContainerView,
//              to: fromFrameInContainerView
//            )
//          }
//        }
      }

      addAnimations {

        if fromView === sourceView {

          if isReversed {
            // sourceView(`fromView`) move back from `toView`.
            fromView.center = fromFrameInContainerView.center
          } else {
            // sourceView(`fromView`) moves to `toView`.
            fromView.center = toFrameInContainerView.center
          }

        } else if toView === sourceView {

          if isReversed {
            // sourceView(`toView`) move to `fromView`.
            toView.center = fromFrameInContainerView.center
          } else {
            // sourceView(`toView`) moves back from `fromView`.
            toView.center = toFrameInContainerView.center
          }

        } else {
          assertionFailure("sourceView must be either fromView or toView.")
        }

      }

    case .frame:

      // FIXME: Find ways to how to keep the original value.
      assertionFailure("Unimplemented")

      break
    case .transform:
      if toView === sourceView {
        if toView.isAnimatingByPropertyAnimator == false {
          if isReversed == false {
            toView.transform = Self.makeCGAffineTransform(
              from: toFrameInContainerView,
              to: fromFrameInContainerView
            )
          }
        }
      }

      addAnimations {

        if fromView === sourceView {

          if isReversed {
            // sourceView(`fromView`) move back from `toView`.
            fromView.transform = .identity
          } else {
            // sourceView(`fromView`) moves to `toView`.
            fromView.transform = Self.makeCGAffineTransform(
              from: fromFrameInContainerView,
              to: toFrameInContainerView
            )
          }

        } else if toView === sourceView {

          if isReversed {
            // sourceView(`toView`) move to `fromView`.
            toView.transform = Self.makeCGAffineTransform(
              from: toFrameInContainerView,
              to: fromFrameInContainerView
            )
          } else {
            // sourceView(`toView`) moves back from `fromView`.
            toView.transform = .identity
          }

        } else {
          assertionFailure("sourceView must be either fromView or toView.")
        }

      }

    }

  }

  private static func makeCGAffineTransform(from: CGRect, to: CGRect) -> CGAffineTransform {

    return .init(
      a: to.width / from.width,
      b: 0,
      c: 0,
      d: to.height / from.height,
      tx: to.midX - from.midX,
      ty: to.midY - from.midY
    )
  }

}

extension CGRect {

  var center: CGPoint {
    return .init(x: midX, y: midY)
  }
}
