//
//  VideoDetailViewController.swift
//  BilibiliLive
//
//  Created by yicheng on 2021/4/17.
//

import Alamofire
import AVKit
import Combine
import Foundation
import Kingfisher
import MarqueeLabel
import SnapKit
import TVUIKit
import UIKit

class VideoDetailViewController: UIViewController {
    private var loadingView = UIActivityIndicatorView()
    private let backgroundImageView = UIImageView()
    private let effectContainerView: UIVisualEffectView = {
        let blurEffect = UIBlurEffect(style: .regular)
        return UIVisualEffectView(effect: blurEffect)
    }()

    private let titleLabel = UILabel()

    private let upButton = BLCustomTextButton()
    private let followButton = BLCustomButton()
    private let coverImageView = UIImageView()
    private let playButton = BLCustomButton()
    private let likeButton = BLCustomButton()
    private let coinButton = BLCustomButton()
    private let noteView = NoteDetailView()
    private let dislikeButton = BLCustomButton()

    private let actionButtonSpaceView = UIView()
    private let durationLabel = UILabel()
    private let playCountLabel = UILabel()
    private let danmakuLabel = UILabel()
    private let uploadTimeLabel = UILabel()
    private let bvidLabel = UILabel()
    private let followersLabel = UILabel()
    private let avatarImageView = UIImageView()
    private let favButton = BLCustomButton()
    private let pageCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 350, height: 170)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private let ugcCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.itemSize = CGSize(width: 361, height: 274)
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 30)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()

    private let pageView = UIView()

    private let ugcLabel = UILabel()
    private let ugcView = UIView()
    private var epid = 0
    private var seasonId = 0
    private var aid = 0
    private var cid = 0
    private var lastPlayCid: Int?
    private var lastPlayTitle: String?
    private var playTimeInSecond: Int?
    private var subType: Int?
    private var data: VideoDetail?
    private let scrollView = UIScrollView()
    private var didSentCoins = 0 {
        didSet {
            if didSentCoins > 0 {
                coinButton.isOn = true
            }
        }
    }

    private var isBangumi = false
    private var startTime = 0
    private var pages = [VideoPage]()
    private var subTitles: [SubtitleData]?

    private var allUgcEpisodes = [VideoDetail.Info.UgcSeason.UgcVideoInfo]()

    private var subscriptions = [AnyCancellable]()

    static func create(aid: Int, cid: Int?, epid: Int? = nil) -> VideoDetailViewController {
        let vc = VideoDetailViewController()
        vc.aid = aid
        vc.cid = cid ?? 0
        vc.epid = epid ?? 0
        return vc
    }

    static func create(epid: Int) -> VideoDetailViewController {
        let vc = VideoDetailViewController()
        vc.epid = epid
        return vc
    }

    static func create(seasonId: Int) -> VideoDetailViewController {
        let vc = VideoDetailViewController()
        vc.seasonId = seasonId
        return vc
    }

    private func setupUI() {
        // 配置背景图片
        backgroundImageView.contentMode = .scaleAspectFit
        backgroundImageView.clipsToBounds = true
        view.addSubview(backgroundImageView)

        // 配置模糊效果容器
        view.addSubview(effectContainerView)

        // ScrollView
        scrollView.contentInsetAdjustmentBehavior = .never
        scrollView.clipsToBounds = true
        effectContainerView.contentView.addSubview(scrollView)

        // 主内容 StackView
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        scrollView.addSubview(mainStackView)

        // ===== 顶部容器（标题、UP主、封面等）=====
        let topContainer = UIView()
        mainStackView.addArrangedSubview(topContainer)

        // 标题
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.numberOfLines = 2
        topContainer.addSubview(titleLabel)

        // 封面图片
        coverImageView.contentMode = .scaleToFill
        coverImageView.clipsToBounds = true
        topContainer.addSubview(coverImageView)

        // UP主信息 StackView
        let upStackView = UIStackView()
        upStackView.axis = .horizontal
        upStackView.distribution = .equalSpacing
        upStackView.alignment = .center
        upStackView.spacing = 30
        topContainer.addSubview(upStackView)

        // UP主头像
        avatarImageView.contentMode = .scaleAspectFit
        avatarImageView.clipsToBounds = true
        upStackView.addArrangedSubview(avatarImageView)

        // UP主按钮
        upButton.tintColor = UIColor(named: "bgColor")
        upButton.title = "up"
        upButton.addTarget(self, action: #selector(actionShowUpSpace), for: .primaryActionTriggered)
        upButton.setContentCompressionResistancePriority(.required, for: .vertical)
        upStackView.addArrangedSubview(upButton)

        // 关注按钮
        followButton.tintColor = UIColor(named: "bgColor")
        followButton.image = UIImage(systemName: "heart")
        followButton.onImage = UIImage(systemName: "heart.fill")
        followButton.addTarget(self, action: #selector(actionFollow), for: .primaryActionTriggered)
        upStackView.addArrangedSubview(followButton)

        // 粉丝数标签
        followersLabel.text = "100万粉丝"
        followersLabel.font = UIFont(name: "HelveticaNeue", size: 28)
        upStackView.addArrangedSubview(followersLabel)

        // 时长信息
        let timeView = UIView()
        upStackView.addArrangedSubview(timeView)

        let clockIcon = UIImageView(image: UIImage(systemName: "clock.fill"))
        clockIcon.tintColor = UIColor(named: "titleColor")
        timeView.addSubview(clockIcon)

        durationLabel.text = "1分1s"
        durationLabel.font = .systemFont(ofSize: 28)
        timeView.addSubview(durationLabel)

        // 统计信息 StackView
        let statsStackView = UIStackView()
        statsStackView.axis = .horizontal
        statsStackView.spacing = 30
        topContainer.addSubview(statsStackView)

        // 播放量
        let playCountView = UIView()
        statsStackView.addArrangedSubview(playCountView)

        let playIcon = UIImageView(image: UIImage(systemName: "play.square"))
        playIcon.tintColor = UIColor(named: "titleColor")
        playCountView.addSubview(playIcon)

        playCountLabel.text = "1"
        playCountLabel.font = .systemFont(ofSize: 28)
        playCountView.addSubview(playCountLabel)

        // 弹幕数
        let danmakuView = UIView()
        statsStackView.addArrangedSubview(danmakuView)

        let danmakuIcon = UIImageView(image: UIImage(systemName: "list.bullet.rectangle"))
        danmakuIcon.tintColor = UIColor(named: "titleColor")
        danmakuView.addSubview(danmakuIcon)

        danmakuLabel.text = "100"
        danmakuLabel.font = .systemFont(ofSize: 28)
        danmakuView.addSubview(danmakuLabel)

        // 上传时间
        uploadTimeLabel.text = "2021-11-11"
        uploadTimeLabel.font = UIFont(name: "HelveticaNeue", size: 28)
        statsStackView.addArrangedSubview(uploadTimeLabel)

        // BVID
        bvidLabel.text = "BVxxxxxx"
        bvidLabel.font = UIFont(name: "HelveticaNeue", size: 28)
        statsStackView.addArrangedSubview(bvidLabel)

        // 笔记视图
        noteView.backgroundColor = .clear
        topContainer.addSubview(noteView)

        // ===== 操作按钮栏 =====
        let actionStackView = UIStackView()
        actionStackView.axis = .horizontal
        actionStackView.spacing = 20
        mainStackView.addArrangedSubview(actionStackView)

        let leftSpacing = UIView()
        actionStackView.addArrangedSubview(leftSpacing)

        // 播放按钮
        playButton.tintColor = UIColor(named: "bgColor")
        playButton.image = UIImage(systemName: "play")
        playButton.highLightImage = UIImage(systemName: "play.fill")
        playButton.title = "播放"
        playButton.titleColor = UIColor(named: "titleColor") ?? .white
        playButton.addTarget(self, action: #selector(actionPlay), for: .primaryActionTriggered)
        actionStackView.addArrangedSubview(playButton)

        // 点赞按钮
        likeButton.tintColor = UIColor(named: "bgColor")
        likeButton.image = UIImage(systemName: "hand.thumbsup")
        likeButton.onImage = UIImage(systemName: "hand.thumbsup.fill")
        likeButton.title = "点赞"
        likeButton.titleColor = UIColor(named: "titleColor") ?? .white
        likeButton.addTarget(self, action: #selector(actionLike), for: .primaryActionTriggered)
        actionStackView.addArrangedSubview(likeButton)

        // 投币按钮
        coinButton.tintColor = UIColor(named: "bgColor")
        coinButton.image = UIImage(systemName: "bitcoinsign.circle")
        coinButton.onImage = UIImage(systemName: "bitcoinsign.circle.fill")
        coinButton.title = "投币"
        coinButton.titleColor = UIColor(named: "titleColor") ?? .white
        coinButton.addTarget(self, action: #selector(actionCoin), for: .primaryActionTriggered)
        actionStackView.addArrangedSubview(coinButton)

        // 收藏按钮
        favButton.tintColor = UIColor(named: "bgColor")
        favButton.image = UIImage(systemName: "star")
        favButton.onImage = UIImage(systemName: "star.fill")
        favButton.title = "收藏"
        favButton.titleColor = UIColor(named: "titleColor") ?? .white
        favButton.addTarget(self, action: #selector(actionFavorite), for: .primaryActionTriggered)
        actionStackView.addArrangedSubview(favButton)

        // 不喜欢按钮
        dislikeButton.tintColor = UIColor(named: "bgColor")
        dislikeButton.image = UIImage(systemName: "hand.thumbsdown")
        dislikeButton.onImage = UIImage(systemName: "hand.thumbsdown.fill")
        dislikeButton.title = "不喜欢"
        dislikeButton.titleColor = UIColor(named: "titleColor") ?? .white
        dislikeButton.addTarget(self, action: #selector(actionDislike), for: .primaryActionTriggered)
        actionStackView.addArrangedSubview(dislikeButton)

        actionStackView.addArrangedSubview(actionButtonSpaceView)

        // 间隔
        let spaceView = UIView()
        mainStackView.addArrangedSubview(spaceView)

        // ===== 视频选集区域 =====
        pageView.backgroundColor = .clear
        mainStackView.addArrangedSubview(pageView)

        let pageTitle = UILabel()
        pageTitle.text = "视频选集"
        pageTitle.font = .preferredFont(forTextStyle: .title3)
        pageView.addSubview(pageTitle)

        pageCollectionView.backgroundColor = .clear
        pageCollectionView.dataSource = self
        pageCollectionView.delegate = self
        pageView.addSubview(pageCollectionView)

        // ===== 合集区域 =====
        ugcView.backgroundColor = .clear
        mainStackView.addArrangedSubview(ugcView)

        ugcLabel.text = "合集"
        ugcLabel.font = .preferredFont(forTextStyle: .title3)
        ugcView.addSubview(ugcLabel)

        ugcCollectionView.backgroundColor = .clear
        ugcCollectionView.dataSource = self
        ugcCollectionView.delegate = self
        ugcView.addSubview(ugcCollectionView)

        // ===== 布局约束 =====
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        effectContainerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        mainStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(scrollView)
        }

        // 顶部容器约束
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(topContainer.safeAreaLayoutGuide).offset(80)
            make.trailing.equalTo(topContainer.safeAreaLayoutGuide).offset(-80)
            make.top.equalTo(topContainer.safeAreaLayoutGuide).offset(60)
        }

        coverImageView.snp.makeConstraints { make in
            make.trailing.equalTo(topContainer.safeAreaLayoutGuide).offset(-80)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.bottom.equalToSuperview().offset(-20)
            make.width.equalTo(coverImageView.snp.height).multipliedBy(16.0 / 9.0)
            make.height.equalTo(350)
        }

        upStackView.snp.makeConstraints { make in
            make.leading.equalTo(topContainer.safeAreaLayoutGuide).offset(80)
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.height.equalTo(60)
        }

        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(50)
        }

        followButton.snp.makeConstraints { make in
            make.width.equalTo(61.5)
            make.height.equalTo(54)
        }

        clockIcon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(34)
        }

        durationLabel.snp.makeConstraints { make in
            make.leading.equalTo(clockIcon.snp.trailing).offset(10)
            make.trailing.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        statsStackView.snp.makeConstraints { make in
            make.leading.equalTo(topContainer.safeAreaLayoutGuide).offset(80)
            make.top.equalTo(upStackView.snp.bottom).offset(24)
        }

        playIcon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(34)
        }

        playCountLabel.snp.makeConstraints { make in
            make.leading.equalTo(playIcon.snp.trailing).offset(10)
            make.trailing.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        danmakuIcon.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.equalTo(56)
            make.height.equalTo(34)
        }

        danmakuLabel.snp.makeConstraints { make in
            make.leading.equalTo(danmakuIcon.snp.trailing).offset(10)
            make.trailing.top.bottom.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        noteView.snp.makeConstraints { make in
            make.leading.equalTo(topContainer.safeAreaLayoutGuide).offset(80)
            make.top.equalTo(statsStackView.snp.bottom).offset(10)
            make.bottom.equalTo(topContainer.safeAreaLayoutGuide).offset(-40)
            make.trailing.lessThanOrEqualTo(coverImageView.snp.leading).offset(-20)
        }

        // 操作按钮栏约束
        actionStackView.snp.makeConstraints { make in
            make.height.equalTo(128)
        }

        leftSpacing.snp.makeConstraints { make in
            make.width.equalTo(60)
        }

        playButton.snp.makeConstraints { make in
            make.width.equalTo(160)
        }

        likeButton.snp.makeConstraints { make in
            make.width.equalTo(playButton)
        }

        coinButton.snp.makeConstraints { make in
            make.width.equalTo(playButton)
        }

        favButton.snp.makeConstraints { make in
            make.width.equalTo(playButton)
        }

        dislikeButton.snp.makeConstraints { make in
            make.width.equalTo(playButton)
        }

        // 间隔视图
        spaceView.snp.makeConstraints { make in
            make.height.equalTo(20)
        }

        // 视频选集区域
        pageTitle.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(88)
            make.top.equalToSuperview().offset(40)
        }

        pageCollectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(pageTitle.snp.bottom).offset(30)
            make.bottom.equalToSuperview().offset(-20)
            make.height.equalTo(90)
        }

        // 合集区域
        ugcLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(88)
            make.top.equalToSuperview().offset(20)
        }

        ugcCollectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(ugcLabel.snp.bottom)
            make.bottom.equalToSuperview()
            make.height.equalTo(320)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        Task { await fetchData() }

        pageCollectionView.register(
            BLTextOnlyCollectionViewCell.self,
            forCellWithReuseIdentifier: String(describing: BLTextOnlyCollectionViewCell.self)
        )
        ugcCollectionView.register(
            RelatedVideoCell.self, forCellWithReuseIdentifier: String(describing: RelatedVideoCell.self)
        )
        noteView.onPrimaryAction = {
            [weak self] note in
            let detail = ContentDetailViewController.createDesp(content: note.label.text ?? "")
            self?.present(detail, animated: true)
        }

        var focusGuide = UIFocusGuide()
        view.addLayoutGuide(focusGuide)
        NSLayoutConstraint.activate([
            focusGuide.topAnchor.constraint(equalTo: upButton.topAnchor),
            focusGuide.leftAnchor.constraint(equalTo: followButton.rightAnchor),
            focusGuide.rightAnchor.constraint(equalTo: coverImageView.leftAnchor),
            focusGuide.bottomAnchor.constraint(equalTo: upButton.bottomAnchor),
        ])
        focusGuide.preferredFocusEnvironments = [followButton]

        focusGuide = UIFocusGuide()
        view.addLayoutGuide(focusGuide)
        NSLayoutConstraint.activate([
            focusGuide.topAnchor.constraint(equalTo: actionButtonSpaceView.topAnchor),
            focusGuide.leftAnchor.constraint(equalTo: actionButtonSpaceView.leftAnchor),
            focusGuide.rightAnchor.constraint(equalTo: actionButtonSpaceView.rightAnchor),
            focusGuide.bottomAnchor.constraint(equalTo: actionButtonSpaceView.bottomAnchor),
        ])
        focusGuide.preferredFocusEnvironments = [dislikeButton]
    }

    override var preferredFocusedView: UIView? {
        return playButton
    }

    private func updatePlayProgressIfNeeded(
        progress: BangumiInfo.UserStatus.Progress?, episode: BangumiInfo.Episode
    ) {
        guard let lastEpId = progress?.last_ep_id,
              let lastTime = progress?.last_time,
              lastEpId == episode.id
        else {
            return
        }
        playTimeInSecond = lastTime
        lastPlayCid = episode.cid
        lastPlayTitle = episode.title + " " + episode.long_title
    }

    private func setupLoading() {
        effectContainerView.isHidden = true
        view.addSubview(loadingView)
        loadingView.color = .white
        loadingView.style = .large
        loadingView.startAnimating()
        loadingView.makeConstraintsBindToCenterOfSuperview()
    }

    func present(from vc: UIViewController, direatlyEnterVideo: Bool = Settings.direatlyEnterVideo) {
        if !direatlyEnterVideo {
            vc.present(self, animated: true)
        } else {
            vc.present(self, animated: false) { [weak self] in
                guard let self else { return }
                let player = VideoPlayerViewController(
                    playInfo: PlayInfo(
                        aid: self.aid, cid: self.cid, epid: self.epid,
                        seasonId: isBangumi ? self.seasonId : nil, lastPlayCid: self.lastPlayCid,
                        playTimeInSecond: self.playTimeInSecond
                    ))
                self.present(player, animated: true)
            }
        }
    }

    private func exit(with error: Error) {
        Logger.warn(error)
        let alertVC = UIAlertController(
            title: "获取失败", message: error.localizedDescription, preferredStyle: .alert
        )
        alertVC.addAction(
            UIAlertAction(
                title: "Ok", style: .cancel,
                handler: { [weak self] action in
                    self?.dismiss(animated: true)
                }
            ))
        present(alertVC, animated: true, completion: nil)
    }

    private func fetchData() async {
        scrollView.setContentOffset(.zero, animated: false)
        setNeedsFocusUpdate()
        updateFocusIfNeeded()
        backgroundImageView.alpha = 0
        setupLoading()
        pageView.isHidden = true
        ugcView.isHidden = true
        do {
            if seasonId > 0 {
                isBangumi = true
                let info = try await WebRequest.requestBangumiInfo(seasonID: seasonId)
                subType = info.type
                if let epi = info.episodes.first(where: { $0.id == info.user_status?.progress?.last_ep_id })
                    ?? info.episodes.first ?? info.section?.first?.episodes.first
                {
                    aid = epi.aid
                    cid = epi.cid
                    epid = epi.id
                    updatePlayProgressIfNeeded(progress: info.user_status?.progress, episode: epi)
                }
                pages = info.episodes.map({
                    VideoPage(
                        cid: $0.cid, page: $0.aid, epid: $0.id, from: "", part: $0.title + " " + $0.long_title
                    )
                })
            } else if epid > 0 {
                isBangumi = true
                let info = try await WebRequest.requestBangumiInfo(epid: epid)
                seasonId = info.season_id
                subType = info.type
                if let epi = info.episodes.first(where: { $0.id == epid }) ?? info.episodes.first {
                    aid = epi.aid
                    cid = epi.cid
                    updatePlayProgressIfNeeded(progress: info.user_status?.progress, episode: epi)
                } else {
                    throw NSError(domain: "get epi fail", code: -1)
                }
                pages = info.episodes.map({
                    VideoPage(
                        cid: $0.cid, page: $0.aid, epid: $0.id, from: "", part: $0.title + " " + $0.long_title
                    )
                })
            }
            let data = try await WebRequest.requestDetailVideo(aid: aid)
            self.data = data

            if let redirect = data.View.redirect_url?.lastPathComponent, redirect.starts(with: "ep"),
               let id = Int(redirect.dropFirst(2)), !isBangumi
            {
                isBangumi = true
                epid = id
                let info = try await WebRequest.requestBangumiInfo(epid: epid)
                seasonId = info.season_id
                subType = info.type
                pages = info.episodes.map({
                    VideoPage(
                        cid: $0.cid, page: $0.aid, epid: $0.id, from: "", part: $0.title + " " + $0.long_title
                    )
                })
                if let epi = info.episodes.first(where: { $0.id == epid }) {
                    updatePlayProgressIfNeeded(progress: info.user_status?.progress, episode: epi)
                }
            }
            if !isBangumi, cid == 0, let page = data.View.pages?.first {
                cid = page.cid
            }
            if !isBangumi, cid > 0, let page = data.View.pages?.first(where: { $0.cid == cid }) {
                let playInfo = try await WebRequest.requestPlayerInfo(aid: aid, cid: cid)
                if playInfo.last_play_cid == cid {
                    playTimeInSecond = playInfo.playTimeInSecond
                    lastPlayCid = playInfo.last_play_cid
                    lastPlayTitle = page.part
                }
            }
            update(with: data)
        } catch let err {
            if case let .statusFail(code, _) = err as? RequestError, code == -404 {
                // 解锁港澳台番剧处理
                if let ok = await fetchAreaLimitBangumiData(), !ok {
                    self.exit(with: err)
                }
            } else {
                self.exit(with: err)
            }
        }

        WebRequest.requestLikeStatus(aid: aid) { [weak self] isLiked in
            self?.likeButton.isOn = isLiked
        }

        WebRequest.requestCoinStatus(aid: aid) { [weak self] coins in
            self?.didSentCoins = coins
        }

        WebRequest.requestFavoriteStatus(aid: aid) { [weak self] isFavorited in
            self?.favButton.isOn = isFavorited
        }
    }

    private func fetchAreaLimitBangumiData() async -> Bool? {
        guard Settings.areaLimitUnlock else { return false }

        do {
            var info: ApiRequest.BangumiInfo?

            if seasonId > 0 {
                info = try await ApiRequest.requestBangumiInfo(seasonID: seasonId)
            } else if epid > 0 {
                info = try await ApiRequest.requestBangumiInfo(epid: epid)
            }
            guard let info = info else { return false }

            let season = try await WebRequest.requestBangumiSeasonView(seasonID: info.season_id)
            isBangumi = true
            if let epi = season.episodes.first(where: { $0.ep_id == epid }) ?? season.episodes.first {
                aid = epi.aid
                cid = epi.cid
                pages = season.episodes.filter { $0.section_type == 0 }.map({
                    VideoPage(
                        cid: $0.cid, page: $0.aid, epid: $0.ep_id, from: "",
                        part: $0.index + " " + ($0.index_title ?? "")
                    )
                })

                let userEpisodeInfo = try await WebRequest.requestUserEpisodeInfo(epid: epi.ep_id)

                let data = VideoDetail(
                    View: VideoDetail.Info(
                        aid: aid, cid: cid, title: info.title, videos: nil, pic: epi.cover, desc: info.evaluate,
                        owner: VideoOwner(
                            mid: season.up_info.mid, name: season.up_info.uname, face: season.up_info.avatar
                        ),
                        pages: nil, dynamic: nil, bvid: epi.bvid, duration: epi.durationSeconds,
                        pubdate: epi.pubdate, ugc_season: nil, redirect_url: nil,
                        stat: VideoDetail.Info.Stat(
                            favorite: info.stat.favorites, coin: info.stat.coins, like: info.stat.likes,
                            share: info.stat.share, danmaku: info.stat.danmakus, view: info.stat.views
                        )
                    ),
                    Related: [],
                    Card: VideoDetail.Owner(
                        following: userEpisodeInfo.related_up.first?.is_follow == 1,
                        follower: season.up_info.follower
                    )
                )

                self.data = data
                update(with: data)
                return true
            }

        } catch let err {
            print(err)
        }

        return false
    }

    private func update(with data: VideoDetail) {
        playCountLabel.text = data.View.stat.view.numberString()
        danmakuLabel.text = data.View.stat.danmaku.numberString()
        followersLabel.text = (data.Card.follower ?? 0).numberString() + "粉丝"
        uploadTimeLabel.text = data.View.date
        bvidLabel.text = data.View.bvid
        coinButton.title = data.View.stat.coin.numberString()
        favButton.title = data.View.stat.favorite.numberString()
        likeButton.title = data.View.stat.like.numberString()

        durationLabel.text = data.View.durationString
        titleLabel.text = data.title
        upButton.title = data.ownerName
        followButton.isOn = data.Card.following

        // 更新播放按钮标题
        if Settings.continuePlay {
            if let lastPlayCid, lastPlayCid == cid {
                playButton.title = "继续播放"
            } else {
                playButton.title = "播放"
            }
        }

        avatarImageView.kf.setImage(
            with: data.avatar,
            options: [
                .processor(DownsamplingImageProcessor(size: CGSize(width: 80, height: 80))),
                .processor(RoundCornerImageProcessor(radius: .widthFraction(0.5))),
                .cacheSerializer(FormatIndicatedCacheSerializer.png),
            ]
        )

        coverImageView.kf.setImage(with: data.pic)
        backgroundImageView.kf.setImage(with: data.pic)

        var notes = [String]()
        let status = data.View.dynamic ?? ""
        if status.count > 1, status != data.View.desc {
            notes.append(status)
        }
        notes.append(data.View.desc ?? "")
        noteView.label.text = notes.joined(separator: "\n")
        if !isBangumi {
            pages = data.View.pages ?? []
        }
        if pages.count > 1 {
            pageCollectionView.reloadData()
            pageView.isHidden = false
            let index = pages.firstIndex { $0.cid == cid } ?? 0
            pageCollectionView.scrollToItem(
                at: IndexPath(row: index, section: 0), at: .left, animated: false
            )
            if cid == 0 {
                cid = pages.first?.cid ?? 0
            }
        }
        loadingView.stopAnimating()
        loadingView.removeFromSuperview()
        effectContainerView.isHidden = false
        UIView.animate(withDuration: 0.25) {
            self.backgroundImageView.alpha = 1
        }

        if let season = data.View.ugc_season {
            if season.sections.count > 1 {
                if let section = season.sections.first(where: { section in
                    section.episodes.contains(where: { episode in episode.aid == data.View.aid })
                }) {
                    allUgcEpisodes = section.episodes
                }
            } else {
                allUgcEpisodes = season.sections.first?.episodes ?? []
            }
            allUgcEpisodes.sort { $0.arc.ctime < $1.arc.ctime }
        }

        ugcCollectionView.reloadData()
        ugcLabel.text =
            "合集 \(data.View.ugc_season?.title ?? "")  \(data.View.ugc_season?.sections.first?.title ?? "")"
        ugcView.isHidden = allUgcEpisodes.count == 0
        if allUgcEpisodes.count > 0 {
            ugcCollectionView.scrollToItem(
                at: IndexPath(item: allUgcEpisodes.map { $0.aid }.firstIndex(of: aid) ?? 0, section: 0),
                at: .left, animated: false
            )
        }
    }

    @objc private func actionShowUpSpace() {
        let upSpaceVC = UpSpaceViewController()
        upSpaceVC.mid = data?.View.owner.mid
        present(upSpaceVC, animated: true)
    }

    @objc private func actionFollow() {
        followButton.isOn.toggle()
        if let mid = data?.View.owner.mid {
            WebRequest.follow(mid: mid, follow: followButton.isOn)
        }
    }

    @objc private func actionPlay() {
        let player = VideoPlayerViewController(
            playInfo: PlayInfo(
                aid: aid, cid: cid, epid: epid, seasonId: seasonId, subType: subType,
                lastPlayCid: lastPlayCid, playTimeInSecond: playTimeInSecond, title: data?.title
            ))
        player.data = data
        if pages.count > 0, let index = pages.firstIndex(where: { $0.cid == cid }) {
            let seq = pages.dropFirst(index).map({
                PlayInfo(
                    aid: aid, cid: $0.cid, epid: $0.epid, seasonId: seasonId, subType: subType, title: $0.part
                )
            })
            if seq.count > 0 {
                let nextProvider = VideoNextProvider(seq: seq)
                player.nextProvider = nextProvider
            }
        }
        if allUgcEpisodes.count > 0, let index = allUgcEpisodes.firstIndex(where: { $0.cid == cid }) {
            let seq = allUgcEpisodes.dropFirst(index).map({
                PlayInfo(aid: $0.aid, cid: $0.cid, title: $0.title)
            })
            if seq.count > 0 {
                let nextProvider = VideoNextProvider(seq: seq)
                player.nextProvider = nextProvider
            }
        }
        present(player, animated: true, completion: nil)
    }

    @objc private func actionLike() {
        Task {
            if likeButton.isOn {
                likeButton.title? -= 1
            } else {
                likeButton.title? += 1
            }
            likeButton.isOn.toggle()
            let success = await WebRequest.requestLike(aid: aid, like: likeButton.isOn)
            if !success {
                likeButton.isOn.toggle()
            }
        }
    }

    @objc private func actionCoin() {
        guard didSentCoins < 2 else { return }
        let alert = UIAlertController(title: "投币个数", message: nil, preferredStyle: .actionSheet)
        WebRequest.requestTodayCoins { todayCoins in
            alert.message = "今日已投(\(todayCoins / 10)/5)个币"
        }
        let aid = aid
        alert.addAction(
            UIAlertAction(title: "1", style: .default) { [weak self] _ in
                guard let self else { return }
                self.coinButton.title? += 1
                if !self.likeButton.isOn {
                    self.likeButton.title? += 1
                    self.likeButton.isOn = true
                }
                self.didSentCoins += 1
                WebRequest.requestCoin(aid: aid, num: 1)
            })
        if didSentCoins == 0 {
            alert.addAction(
                UIAlertAction(title: "2", style: .default) { [weak self] _ in
                    guard let self else { return }
                    self.coinButton.title? += 2
                    if !self.likeButton.isOn {
                        self.likeButton.title? += 1
                        self.likeButton.isOn = true
                    }
                    self.likeButton.isOn = true
                    self.didSentCoins += 2
                    WebRequest.requestCoin(aid: aid, num: 2)
                })
        }
        alert.addAction(UIAlertAction(title: "取消", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func actionFavorite() {
        Task {
            guard let favList = try? await WebRequest.requestFavVideosList() else {
                return
            }
            if favButton.isOn {
                favButton.title? -= 1
                favButton.isOn = false
                WebRequest.removeFavorite(aid: aid, mid: favList.map { $0.id })
                return
            }
            let alert = UIAlertController(title: "收藏", message: nil, preferredStyle: .actionSheet)
            let aid = aid
            for fav in favList {
                alert.addAction(
                    UIAlertAction(title: fav.title, style: .default) { [weak self] _ in
                        self?.favButton.title? += 1
                        self?.favButton.isOn = true
                        WebRequest.requestFavorite(aid: aid, mid: fav.id)
                    })
            }
            alert.addAction(UIAlertAction(title: "取消", style: .cancel))
            present(alert, animated: true)
        }
    }

    @objc private func actionDislike() {
        dislikeButton.isOn.toggle()
        ApiRequest.requestDislike(aid: aid, dislike: dislikeButton.isOn)
    }
}

extension VideoDetailViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case pageCollectionView:
            let page = pages[indexPath.item]
            let player = VideoPlayerViewController(
                playInfo: PlayInfo(
                    aid: isBangumi ? page.page : aid, cid: page.cid, epid: page.epid, seasonId: seasonId,
                    subType: subType, lastPlayCid: lastPlayCid, playTimeInSecond: playTimeInSecond,
                    title: page.part
                ))
            player.data = isBangumi ? nil : data

            let seq = pages.dropFirst(indexPath.item).map({
                PlayInfo(
                    aid: isBangumi ? $0.page : aid, cid: $0.cid, epid: $0.epid, seasonId: seasonId,
                    subType: subType, title: $0.part
                )
            })
            if seq.count > 0 {
                let nextProvider = VideoNextProvider(seq: seq)
                player.nextProvider = nextProvider
            }
            present(player, animated: true, completion: nil)
        case ugcCollectionView:
            let video = allUgcEpisodes[indexPath.item]
            if Settings.showRelatedVideoInCurrentVC {
                aid = video.aid
                cid = video.cid
                Task { await fetchData() }
            } else {
                let detailVC = VideoDetailViewController.create(aid: video.aid, cid: video.cid)
                detailVC.present(from: self)
            }
        default:
            break
        }
    }
}

extension VideoDetailViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int)
        -> Int
    {
        switch collectionView {
        case pageCollectionView:
            return pages.count
        case ugcCollectionView:
            return allUgcEpisodes.count
        default:
            return 0
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell
    {
        switch collectionView {
        case pageCollectionView:
            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: "BLTextOnlyCollectionViewCell", for: indexPath
                )
                as! BLTextOnlyCollectionViewCell
            let page = pages[indexPath.item]
            cell.titleLabel.text = page.part
            return cell
        case ugcCollectionView:
            let cell =
                collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: RelatedVideoCell.self), for: indexPath
                )
                as! RelatedVideoCell
            let record = allUgcEpisodes[indexPath.row]
            cell.update(data: record)
            return cell
        default:
            return UICollectionViewCell()
        }
    }
}

class BLCardView: TVCardView {
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        subviews.first?.subviews.first?.subviews.last?.subviews.first?.subviews.first?.layer
            .cornerRadius = 12
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        cardBackgroundColor = UIColor(named: "bgColor")
    }
}

extension VideoDetailViewController {
    func makePageCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout {
            _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.14), heightDimension: .fractionalHeight(1)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 40
            return section
        }
    }

    func makeRelatedVideoCollectionViewLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout {
            _, _ in
            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .estimated(200)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(0.18), heightDimension: .estimated(200)
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 40, leading: 0, bottom: 0, trailing: 0)
            section.orthogonalScrollingBehavior = .continuous
            section.interGroupSpacing = 40
            return section
        }
    }
}

class RelatedVideoCell: BLMotionCollectionViewCell {
    let titleLabel = MarqueeLabel()
    let imageView = UIImageView()
    override func setup() {
        super.setup()
        contentView.addSubview(imageView)
        contentView.addSubview(titleLabel)
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.width.equalTo(imageView.snp.height).multipliedBy(14.0 / 9)
        }
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        titleLabel.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(imageView.snp.bottom).offset(6)
        }
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        titleLabel.font = UIFont.systemFont(ofSize: 28)
        titleLabel.fadeLength = 60
        stopScroll()
    }

    func update(data: any DisplayData) {
        titleLabel.text = data.title
        imageView.kf.setImage(
            with: data.pic,
            options: [
                .processor(DownsamplingImageProcessor(size: CGSize(width: 360, height: 202))),
                .cacheOriginalImage,
            ]
        )
    }

    override func didUpdateFocus(
        in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator
    ) {
        super.didUpdateFocus(in: context, with: coordinator)
        if isFocused {
            startScroll()
        } else {
            stopScroll()
        }
    }

    private func startScroll() {
        titleLabel.restartLabel()
        titleLabel.holdScrolling = false
    }

    private func stopScroll() {
        titleLabel.shutdownLabel()
        titleLabel.holdScrolling = true
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        stopScroll()
    }
}

class DetailLabel: UILabel {
    override func didUpdateFocus(
        in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator
    ) {
        super.didUpdateFocus(in: context, with: coordinator)
        coordinator.addCoordinatedAnimations {
            if self.isFocused {
                self.backgroundColor = .white
            } else {
                self.backgroundColor = .clear
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        isUserInteractionEnabled = true
    }

    override var canBecomeFocused: Bool {
        return true
    }

    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        super.drawText(in: rect.inset(by: insets))
    }
}

class NoteDetailView: UIControl {
    let label = UILabel()
    var onPrimaryAction: ((NoteDetailView) -> Void)?
    private let backgroundView = UIView()
    init() {
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    func setup() {
        addSubview(backgroundView)
        backgroundView.backgroundColor = UIColor(named: "bgColor")
        backgroundView.layer.shadowOffset = CGSizeMake(0, 10)
        backgroundView.layer.shadowOpacity = 0.15
        backgroundView.layer.shadowRadius = 16.0
        backgroundView.layer.cornerRadius = 20
        backgroundView.layer.cornerCurve = .continuous
        backgroundView.isHidden = !isFocused
        backgroundView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(-20)
            make.right.equalToSuperview().offset(20)
        }

        addSubview(label)
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 29)
        label.textColor = UIColor(named: "titleColor")
        label.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(14)
            make.bottom.lessThanOrEqualToSuperview().offset(-14)
        }
    }

    override func didUpdateFocus(
        in context: UIFocusUpdateContext, with coordinator: UIFocusAnimationCoordinator
    ) {
        super.didUpdateFocus(in: context, with: coordinator)
        backgroundView.isHidden = !isFocused
    }

    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
        if presses.first?.type == .select {
            sendActions(for: .primaryActionTriggered)
            onPrimaryAction?(self)
        }
    }
}

class ContentDetailViewController: UIViewController {
    private let titleLabel = UILabel()
    private let contentTextView = UITextView()

    static func createDesp(content: String) -> ContentDetailViewController {
        let vc = ContentDetailViewController()
        vc.titleLabel.text = "简介"
        vc.contentTextView.text = content
        return vc
    }

    static func createReply(content: String) -> ContentDetailViewController {
        let vc = ContentDetailViewController()
        vc.titleLabel.text = "评论"
        vc.contentTextView.text = content
        return vc
    }

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        [contentTextView]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(titleLabel)
        view.addSubview(contentTextView)
        titleLabel.font = UIFont.systemFont(ofSize: 60, weight: .semibold)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(80)
            make.centerX.equalToSuperview()
        }
        contentTextView.panGestureRecognizer.allowedTouchTypes = [
            NSNumber(value: UITouch.TouchType.indirect.rawValue),
        ]
        contentTextView.isScrollEnabled = true
        contentTextView.isUserInteractionEnabled = true
        contentTextView.isSelectable = true
        contentTextView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(60)
            make.trailing.equalToSuperview().inset(60)
            make.bottom.equalToSuperview().inset(80)
        }
    }
}
