//

import Foundation
import UIKit

// MARK: Implementations

private let _snapshotStorage: NSMapTable<NSString, UIView> = .strongToWeakObjects()

private func _makeSnapshotViewIfNeeded(
  from fromView: UICoordinateSpace,
  to toView: UICoordinateSpace,
  in containerView: UICoordinateSpace,
  make: () -> UIView
) -> UIView {

  let key =
    "\(ObjectIdentifier(fromView)),\(ObjectIdentifier(toView)),\(ObjectIdentifier(containerView))"
    as NSString

  if let view = _snapshotStorage.object(forKey: key) {
    return view
  }

  let newView = make()

  _snapshotStorage.setObject(newView, forKey: key)

  return newView
}

extension UIView {

  fileprivate var isAnimatingByPropertyAnimator: Bool {
    (layer.animationKeys() ?? []).contains(where: {
      $0.hasPrefix("UIPacingAnimationForAnimatorsKey")
    })
  }

  /**
   Returns a relative frame in view without applying transform.
   */
  fileprivate func relativeFrameWithoutTransforming(in view: UICoordinateSpace) -> CGRect {
    let currentTransform = transform
    self.transform = .identity
    let rect = self.convert(bounds, to: view)
    self.transform = currentTransform
    return rect
  }

}

extension UIViewPropertyAnimator {

  public enum MovingMode {
    case center
    case frame
    case transform
  }

  public func addMovingAnimation(
    makeSnapshotViewIfNeeded: () -> UIView,
    from fromView: UIView,
    to toView: UIView,
    isReversed: Bool,
    in containerView: UIView,
    movingMode: MovingMode = .transform
  ) {

    let view = _makeSnapshotViewIfNeeded(
      from: fromView,
      to: toView,
      in: containerView,
      make: makeSnapshotViewIfNeeded
    )

    addMovingAnimation(
      snapshotView: view,
      from: fromView,
      to: toView,
      isReversed: isReversed,
      in: containerView,
      movingMode: movingMode
    )

  }

  public func addMovingAnimation(
    snapshotView: UIView,
    from fromView: UIView,
    to toView: UIView,
    isReversed: Bool,
    in containerView: UIView,
    movingMode: MovingMode = .transform
  ) {

    assert(
      snapshotView !== fromView || snapshotView !== toView,
      "SnapshotView must be another instance from fromView:\(fromView) and toView:\(toView)"
    )

    let fromFrameInContainerView = fromView.relativeFrameWithoutTransforming(in: containerView)
    let toFrameInContainerView = toView.relativeFrameWithoutTransforming(in: containerView)

    switch movingMode {
    case .center:

      preparation: do {

        if snapshotView.superview != containerView {

          // TODO: Consider if no issues.
          containerView.addSubview(snapshotView)

          snapshotView.frame.size = fromFrameInContainerView.size

          if isReversed {

            /// To apply transform correctly with setting up the frame without transforming

            let f = toFrameInContainerView

            snapshotView.center = .init(
              x: f.midX,
              y: f.midY
            )

          } else {

            /// To apply transform correctly with setting up the frame without transforming

            let f = fromFrameInContainerView

            snapshotView.center = .init(
              x: f.midX,
              y: f.midY
            )

          }

        }

      }

      addAnimations {

        if isReversed {
          assert(containerView.subviews.contains(fromView))
          assert(fromView.isDescendant(of: containerView))

          let f = fromFrameInContainerView
          snapshotView.center = .init(
            x: f.midX,
            y: f.midY
          )

        } else {
          assert(containerView.subviews.contains(toView))
          assert(toView.isDescendant(of: containerView))

          let f = toFrameInContainerView
          snapshotView.center = .init(
            x: f.midX,
            y: f.midY
          )

        }

      }

    case .frame:

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

          assert(containerView.subviews.contains(fromView))
          assert(fromView.isDescendant(of: containerView))
          snapshotView.frame = fromFrameInContainerView

        } else {

          assert(containerView.subviews.contains(toView))
          assert(toView.isDescendant(of: containerView))
          snapshotView.frame = toFrameInContainerView

        }

      }

    case .transform:

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

  }

  public func addMovingAnimation(
    from fromView: UIView,
    to toView: UIView,
    sourceView: UIView,
    isReversed: Bool,
    in containerView: UIView,
    movingMode: MovingMode = .transform
  ) {

    let fromFrameInContainerView = fromView.relativeFrameWithoutTransforming(in: containerView)
    let toFrameInContainerView = toView.relativeFrameWithoutTransforming(in: containerView)

    switch movingMode {
    case .center:
      break
    case .frame:
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
