//
//  LoginViewController.swift
//  BilibiliLive
//
//  Created by Etan Chen on 2021/3/28.
//

import Alamofire
import Foundation
import SnapKit
import SwiftyJSON
import UIKit

class LoginViewController: UIViewController {
    private let qrcodeImageView = UIImageView()
    private let refreshButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let instructionLabel = UILabel()
    private let dividerView = UIView()

    var currentLevel: Int = 0, finalLevel: Int = 200
    var timer: Timer?
    var oauthKey: String = ""

    static func create() -> LoginViewController {
        return LoginViewController()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        BLTabBarViewController.clearSelected()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        // 左侧容器（二维码区域）
        let leftContainer = UIView()
        leftContainer.backgroundColor = .clear
        view.addSubview(leftContainer)

        // 分割线
        dividerView.backgroundColor = UIColor(white: 0.33, alpha: 1.0)
        view.addSubview(dividerView)

        // 右侧标题
        titleLabel.text = "账号登录"
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        titleLabel.textAlignment = .natural
        view.addSubview(titleLabel)

        // 右侧说明文字
        instructionLabel.text = "1 请打开BiliBili官方手机客户端扫码登录  2. 如果登录失败尝试点击重新生成二维码"
        instructionLabel.font = .preferredFont(forTextStyle: .headline)
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .natural
        view.addSubview(instructionLabel)

        // 二维码图片
        qrcodeImageView.contentMode = .scaleAspectFit
        qrcodeImageView.clipsToBounds = true

        // 刷新按钮
        refreshButton.setTitle("重新生成二维码", for: .normal)
        refreshButton.contentEdgeInsets = UIEdgeInsets(top: 20, left: 40, bottom: 20, right: 40)
        refreshButton.addTarget(self, action: #selector(actionStart), for: .primaryActionTriggered)

        // Stack View 包含二维码和按钮
        let stackView = UIStackView(arrangedSubviews: [qrcodeImageView, refreshButton])
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.spacing = 50
        leftContainer.addSubview(stackView)

        // 布局约束
        leftContainer.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(0.5)
        }

        dividerView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.width.equalTo(2)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(dividerView.snp.trailing).offset(100)
            make.top.equalTo(view.safeAreaLayoutGuide).offset(120)
        }

        instructionLabel.snp.makeConstraints { make in
            make.leading.equalTo(dividerView.snp.trailing).offset(100)
            make.top.equalTo(titleLabel.snp.bottom).offset(50)
            make.trailing.lessThanOrEqualTo(view.safeAreaLayoutGuide).offset(-100)
        }

        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        qrcodeImageView.snp.makeConstraints { make in
            make.width.equalTo(540)
            make.height.equalTo(qrcodeImageView.snp.width)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initValidation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        qrcodeImageView.image = nil
        stopValidationTimer()
    }

    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)

            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }

    func initValidation() {
        timer?.invalidate()
        ApiRequest.requestLoginQR { [weak self] code, url in
            guard let self else { return }
            let image = self.generateQRCode(from: url)
            self.qrcodeImageView.image = image
            self.oauthKey = code
            self.startValidationTimer()
        }
    }

    func startValidationTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentLevel += 1
            if self.currentLevel > self.finalLevel {
                self.stopValidationTimer()
            }
            self.loopValidation()
        }
    }

    func stopValidationTimer() {
        timer?.invalidate()
        timer = nil
    }

    func didValidationSuccess() {
        qrcodeImageView.image = nil
        AppDelegate.shared.showTabBar()
        stopValidationTimer()
    }

    func loopValidation() {
        ApiRequest.verifyLoginQR(code: oauthKey) {
            [weak self] state in
            guard let self = self else { return }
            switch state {
            case .expire:
                self.initValidation()
            case .waiting:
                break
            case let .success(token, cookies):
                print(token)
                AccountManager.shared.registerAccount(token: token, cookies: cookies) { [weak self] _ in
                    self?.didValidationSuccess()
                }
            case .fail:
                break
            }
        }
    }

    @objc private func actionStart() {
        initValidation()
    }
}
