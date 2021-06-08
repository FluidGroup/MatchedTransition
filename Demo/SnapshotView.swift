//
//  SnapshotView.swift
//  MatchedTransition
//
//  Created by Muukii on 2021/06/08.
//

import Foundation
import TinyConstraints

final class SnapshotView: UIView {

  let smallLabel = UILabel()
  let largeLabel = UILabel()

  init() {

    super.init(frame: .zero)

    backgroundColor = .init(white: 0, alpha: 0.2)

    addSubview(smallLabel)
    addSubview(largeLabel)

    smallLabel.edges(to: self, excluding: [.right, .bottom])
    largeLabel.edges(to: self, excluding: [.top, .left])

    smallLabel.text = "Small"
    largeLabel.text = "Large"
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

}
