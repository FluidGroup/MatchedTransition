//

import Foundation
import UIKit

// MARK: Implementations

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

  public var __layerAnimations: [CAAnimation] {
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
  fileprivate func relativeFrame(in view: UICoordinateSpace, ignoresTransform: Bool) -> CGRect {

    if ignoresTransform {
      let currentTransform = transform
      self.transform = .identity
      let rect = self.convert(bounds, to: view)
      self.transform = currentTransform
      return rect
    } else {
      let rect = self.convert(bounds, to: view)
      return rect
    }

  }

}

extension UIViewPropertyAnimator {

  public enum MovingMode {
    case center
    case frame
    case transform
  }
  
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

    switch movingMode {
    case .center:

      let fromFrameInContainerView = fromView.relativeFrame(in: containerView, ignoresTransform: false)
      let toFrameInContainerView = toView.relativeFrame(in: containerView, ignoresTransform: false)

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
          assert(containerView.subviews.contains(fromView))
          assert(fromView.isDescendant(of: containerView))

          snapshotView.center = fromFrameInContainerView.center

        } else {
          assert(containerView.subviews.contains(toView))
          assert(toView.isDescendant(of: containerView))

          snapshotView.center = toFrameInContainerView.center

        }

      }

    case .frame:

      let fromFrameInContainerView = fromView.relativeFrame(in: containerView, ignoresTransform: false)
      let toFrameInContainerView = toView.relativeFrame(in: containerView, ignoresTransform: false)

      preparation: do {

        if snapshotView.superview != containerView {

          // TODO: Consider if no issues.
          containerView.addSubview(snapshotView)

          if isReversed {

            /// To apply transform correctly with setting up the frame without transforming

            let f = toFrameInContainerView

            snapshotView.bounds.size = f.size
            snapshotView.center = CGPoint(
              x: f.midX,
              y: f.midY
            )

          } else {

            /// To apply transform correctly with setting up the frame without transforming

            let f = fromFrameInContainerView

            snapshotView.bounds.size = f.size
            snapshotView.center = CGPoint(
              x: f.midX,
              y: f.midY
            )

          }

        }

      }

      addAnimations {

        if isReversed {

          assert(toView.isDescendant(of: containerView), "The target view for moving is not in the hierarchy of container view, snapshot might move the wrong position.")
          snapshotView.frame = fromFrameInContainerView

        } else {

          assert(toView.isDescendant(of: containerView), "The target view for moving is not in the hierarchy of container view, snapshot might move the wrong position.")
          snapshotView.frame = toFrameInContainerView

        }

      }

    case .transform:

      let fromFrameInContainerView = fromView.relativeFrame(in: containerView, ignoresTransform: true)
      let toFrameInContainerView = toView.relativeFrame(in: containerView, ignoresTransform: true)
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

    let fromFrameInContainerView = fromView.relativeFrame(in: containerView, ignoresTransform: true)
    let toFrameInContainerView = toView.relativeFrame(in: containerView, ignoresTransform: true)

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
