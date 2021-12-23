import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

    let newWindow = UIWindow()
    newWindow.rootViewController = RootContainerViewController()
    newWindow.makeKeyAndVisible()
    self.window = newWindow
    return true
  }

}


extension CALayer {

  func dumpAllAnimations() {

    let animations = (animationKeys() ?? []).compactMap {
      animation(forKey: $0)
    }

    let result = animations.map {
      "- \($0.debugDescription)"
    }
      .joined(separator: "\n")

    print(result)

  }
}
