//
//  SceneDelegate.swift
//  IrisEyeGlance
//
//  Created by 矢田翔大 on 2022/10/12.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private var mainViewController: MainViewController? {
        window?.rootViewController as? MainViewController
    }

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = MainViewController()
        self.window = window
        window.makeKeyAndVisible()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        mainViewController?.resumeCapture()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Release the camera while the app is not visible.
        mainViewController?.pauseCapture()
    }
}
