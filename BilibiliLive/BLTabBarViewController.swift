//
//  BLTabBarViewController.swift
//  BilibiliLive
//
//  Created by Etan Chen on 2021/4/5.
//

import UIKit

protocol BLTabBarContentVCProtocol {
    func reloadData()
}

let selectedIndexKey = "BLTabBarViewController.selectedIndex"

class BLTabBarViewController: UITabBarController, UITabBarControllerDelegate {
    static func clearSelected() {
        UserDefaults.standard.removeObject(forKey: selectedIndexKey)
    }

    deinit {
        print("BLTabBarViewController deinit")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        var vcs = [UIViewController]()

        let followVC = FollowsViewController()
        followVC.tabBarItem.title = "关注"
        vcs.append(followVC)

        let fav = FavoriteViewController()
        fav.tabBarItem.title = "收藏"
        vcs.append(fav)

        let persionVC = PersonalViewController.create()
        persionVC.extendedLayoutIncludesOpaqueBars = true
        persionVC.tabBarItem.title = "我的"
        vcs.append(persionVC)

        setViewControllers(vcs, animated: false)

        // 处理旧的 selectedIndex 值，映射到新的 3-Tab 结构
        var savedIndex = UserDefaults.standard.integer(forKey: selectedIndexKey)
        if savedIndex >= 0 && savedIndex <= 2 {
            // 旧的推荐(0)/热门(1)/排行榜(2) → 关注(0)
            savedIndex = 0
        } else if savedIndex >= 3 && savedIndex <= 5 {
            // 旧的关注(3)/收藏(4)/我的(5) → 关注(0)/收藏(1)/我的(2)
            savedIndex = savedIndex - 3
        } else {
            // 无效索引 → 关注(0)
            savedIndex = 0
        }
        selectedIndex = savedIndex
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        guard let buttonPress = presses.first?.type else { return }
        if buttonPress == .playPause {
            if let reloadVC = topMostViewController() as? BLTabBarContentVCProtocol {
                print("send reload to \(reloadVC)")
                reloadVC.reloadData()
            }
        }
    }

    func tabBarController(
        _ tabBarController: UITabBarController, didSelect viewController: UIViewController
    ) {
        UserDefaults.standard.set(tabBarController.selectedIndex, forKey: selectedIndexKey)
    }
}
