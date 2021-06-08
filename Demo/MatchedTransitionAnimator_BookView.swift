//

import Foundation
import MatchedTransition
import StorybookKit
import StorybookKitTextureSupport
import TextureSwiftSupport
import TypedTextAttributes

// MARK: Storybook

enum MatchedTransitionAnimator_BookView {

  static var body: BookView {
    BookGroup {
      BookNavigationLink(title: "MatchedTransition - Texture") {
        BookPush(title: "Sample") {
          ExampleViewController()
        }
        BookPush(title: "MultipleAnimation") {
          MultipleAnimationViewController()
        }

        BookSection(title: "Snapshot") {

          BookForEach(data: [.center, .frame, .transform] as [UIViewPropertyAnimator.MovingMode]) {
            mode in
            BookNodePreview(expandsWidth: true) {
              AnimationContainerNode()
            }
            .addButton("Toggle") { node in

              let makeView: () -> UIView = {
                let view = UIView()
                view.backgroundColor = .black
                view.layer.setContinuousCornerRadius(10)
                return view
              }

              let a = UIViewPropertyAnimator(duration: 3, dampingRatio: 1)

              a.addSnapshotMovingAnimation(
                makeSnapshotViewIfNeeded: makeView,
                from: node.fromBox.view,
                to: node.toBox.view,
                isReversed: node.flag,
                in: node.view,
                movingMode: mode
              )

              a.startAnimation()

              node.flag.toggle()

            }
            .title("Mode: \(mode) - Animates a snapshot between `From` and To view.")
          }
        }

        BookSection(title: "Concrete using toView") {

          BookForEach(
            data: [
              //            .center,
              //            .frame,
              .transform
            ] as [UIViewPropertyAnimator.MovingMode]
          ) {
            mode in
            BookNodePreview(expandsWidth: true) {
              AnimationContainerNode()
            }
            .addButton("Toggle") { node in

              let a = UIViewPropertyAnimator(duration: 3, dampingRatio: 1)

              a.addMovingAnimation(
                from: node.fromBox.view,
                to: node.toBox.view,
                sourceView: node.toBox.view,
                isReversed: node.flag,
                in: node.view
              )

              a.startAnimation()

              node.flag.toggle()

            }
            .title("Mode: \(mode) - Animates a concrete view - Source: toView")
          }
        }

        BookSection(title: "Concrete using fromView") {
          BookForEach(
            data: [
              //            .center,
              //            .frame,
              .transform
            ] as [UIViewPropertyAnimator.MovingMode]
          ) {
            mode in
            BookNodePreview(expandsWidth: true) {
              AnimationContainerNode()
            }
            .addButton("Toggle") { node in

              let a = UIViewPropertyAnimator(duration: 3, dampingRatio: 1)

              a.addMovingAnimation(
                from: node.fromBox.view,
                to: node.toBox.view,
                sourceView: node.fromBox.view,
                isReversed: node.flag,
                in: node.view
              )

              a.startAnimation()

              node.flag.toggle()

            }
            .title("Mode: \(mode) - Animates a concrete view - Source: fromView")
          }
        }

      }

      BookNavigationLink(title: "MatchedTransition - UIKit") {
        BookText("TODO")
      }
    }
  }

  private final class AnimationContainerNode: NamedDisplayNodeBase {

    let fromBox = ShapeLayerNode.roundedCorner(radius: 10).setShapeFillColor(.systemRed)
    let toBox = ShapeLayerNode.roundedCorner(radius: 10).setShapeFillColor(.systemGreen)
    var flag = false

    override init() {
      super.init()
      automaticallyManagesSubnodes = true
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
      LayoutSpec {
        HStackLayout(justifyContent: .spaceBetween) {
          fromBox.preferredSize(.init(square: 20))
          SpacerLayout()
          toBox.preferredSize(.init(square: 40))
        }
        .padding(24)
      }
    }

  }

  private final class MultipleAnimationViewController: DisplayNodeViewController {

    private let toggleButton = InteractiveNode(animation: .bodyShrink) {
      let textNode = ASTextNode()
      textNode.attributedText = "Toggle".styled(
        .init().foregroundColor(.systemBlue).font(.preferredFont(forTextStyle: .headline))
      )
      return textNode
    }

    private let box1 = ShapeLayerNode.roundedCorner(radius: 10).setShapeFillColor(.systemRed)
    private let box2 = ShapeLayerNode.roundedCorner(radius: 10).setShapeFillColor(.systemGreen)
    private let box3 = ShapeLayerNode.roundedCorner(radius: 10).setShapeFillColor(.systemBlue)
    private var flag = false

    override init() {
      super.init()

      view.backgroundColor = .white

      node.automaticallyManagesSubnodes = true
    }

    override func viewDidLoad() {
      super.viewDidLoad()

      toggleButton.onTap { [unowned self] in

        flag.toggle()

        do {
          let a = UIViewPropertyAnimator(duration: 5, dampingRatio: 1) { [self] in
            if flag {
              box1.view.transform = .init(translationX: 100, y: 0)
            } else {
              box1.view.transform = .identity
            }
          }

          a.startAnimation()
        }

        do {
          let a = UIViewPropertyAnimator(duration: 4, dampingRatio: 1) { [self] in
            if flag {
              box2.view.transform = .init(translationX: 100, y: 0)
            } else {
              box2.view.transform = .identity
            }
          }

          a.startAnimation()
        }

        do {
          let a = UIViewPropertyAnimator(duration: 3, dampingRatio: 1) { [self] in
            if flag {
              box3.view.transform = .init(translationX: 100, y: 0)
            } else {
              box3.view.transform = .identity
            }
          }

          a.startAnimation()
        }

      }
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
      LayoutSpec {
        VStackLayout(spacing: 10, justifyContent: .center) {
          toggleButton
          box1.preferredSize(.init(square: 44))
          box2.preferredSize(.init(square: 44))
          box3.preferredSize(.init(square: 44))
        }
        .padding(capturedSafeAreaInsets)
      }
    }

  }

  private final class ExampleViewController: DisplayNodeViewController {

    private let toggleButton = InteractiveNode(animation: .bodyShrink) {
      let textNode = ASTextNode()
      textNode.attributedText = "Toggle".styled(
        .init().foregroundColor(.systemBlue).font(.preferredFont(forTextStyle: .headline))
      )
      return textNode
    }

    private let listNode = ListNode()

    override init() {
      super.init()

      view.backgroundColor = .white

      node.automaticallyManagesSubnodes = true
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
      LayoutSpec {
        VStackLayout(justifyContent: .center) {
          toggleButton
          listNode
            .flexGrow(1)
        }
        .padding(capturedSafeAreaInsets)
      }
    }

    final class ListNode: ASDisplayNode {

      private let nodes = (0..<10).map { _ in ListCellNode() }

      override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        LayoutSpec {
          VStackLayout {
            nodes
          }
        }
      }

    }

    final class ListCellNode: ASDisplayNode {

    }

    final class DetailNode: ASDisplayNode {

    }

  }

}
