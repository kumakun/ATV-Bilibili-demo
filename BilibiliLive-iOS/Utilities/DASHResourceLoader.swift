import AVFoundation
import Alamofire
import Foundation
import UniformTypeIdentifiers

final class DASHResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
  struct SidxDownloadResult {
    let timescale: Int
    let segments: [Segment]

    struct Segment {
      let size: Int
      let duration: Int
    }

    func maxSegmentDuration() -> Int? {
      guard let duration = segments.map({ Double($0.duration) / Double(timescale) }).max() else {
        return nil
      }
      return Int(duration + 1)
    }
  }

  enum URLs {
    static let customScheme = "bilibili-dash"
    static let master = "\(customScheme)://stream/master"
    static let video = "\(customScheme)://stream/video"
    static let audio = "\(customScheme)://stream/audio"
  }

  private enum Constants {
    static let fallbackTargetDuration = 1
    static let badRequestErrorCode = 455
  }

  let video: DASHStreamSelection.SelectedVideo
  let audio: DASHStreamSelection.SelectedAudio
  let aid: Int
  let duration: Int
  let playbackURL = URL(string: URLs.master)!
  private let sidxDownloader: @Sendable (URL, String) async -> SidxDownloadResult?
  private var currentVideoURLIndex = 0
  private var currentAudioURLIndex = 0

  var currentVideoURL: URL {
    video.allURLs[min(currentVideoURLIndex, video.allURLs.count - 1)]
  }

  var currentAudioURL: URL {
    audio.allURLs[min(currentAudioURLIndex, audio.allURLs.count - 1)]
  }

  init(
    video: DASHStreamSelection.SelectedVideo,
    audio: DASHStreamSelection.SelectedAudio,
    aid: Int,
    duration: Int = 0,
    sidxDownloader: (@Sendable (URL, String) async -> SidxDownloadResult?)? = nil
  ) {
    self.video = video
    self.audio = audio
    self.aid = aid
    self.duration = duration
    self.sidxDownloader = sidxDownloader ?? Self.downloadSidx
  }

  func masterPlaylist() -> String {
    """
    #EXTM3U
    #EXT-X-VERSION:6
    #EXT-X-INDEPENDENT-SEGMENTS
    #EXT-X-MEDIA:TYPE=AUDIO,DEFAULT=YES,AUTOSELECT=YES,GROUP-ID="audio",LANGUAGE="zh",NAME="Audio",URI="\(URLs.audio)"
    #EXT-X-STREAM-INF:BANDWIDTH=\(max(video.bandwidth, 1)),AUDIO="audio"\(masterVideoAttributes())
    \(URLs.video)
    """
  }

  func videoPlaylist() -> String {
    simplePlaylist(url: currentVideoURL)
  }

  func audioPlaylist() -> String {
    simplePlaylist(url: currentAudioURL)
  }

  func resourceLoader(
    _: AVAssetResourceLoader,
    shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest
  ) -> Bool {
    guard let url = loadingRequest.request.url else {
      return false
    }

    let content: String
    switch url.absoluteString {
    case URLs.master:
      content = masterPlaylist()
    case URLs.video:
      Task {
        respond(loadingRequest, content: await detailedPlaylist(for: video) ?? videoPlaylist())
      }
      return true
    case URLs.audio:
      Task {
        respond(loadingRequest, content: await detailedPlaylist(for: audio) ?? audioPlaylist())
      }
      return true
    default:
      return false
    }

    respond(loadingRequest, content: content)
    return true
  }

  private func masterVideoAttributes() -> String {
    var attributes = [String]()

    if let codecs = video.codecs, !codecs.isEmpty {
      attributes.append("CODECS=\"\(codecs)\"")
    }
    if let width = video.width, let height = video.height {
      attributes.append("RESOLUTION=\(width)x\(height)")
    }
    if let frameRate = normalizedFrameRate() {
      attributes.append("FRAME-RATE=\(frameRate)")
    }

    guard !attributes.isEmpty else {
      return ""
    }

    return "," + attributes.joined(separator: ",")
  }

  private func normalizedFrameRate() -> String? {
    guard let frameRate = video.frameRate else {
      return nil
    }

    if let numeric = Double(frameRate) {
      return String(format: "%.3f", numeric)
    }

    return nil
  }

  private func simplePlaylist(url: URL) -> String {
    let segmentDuration = max(duration, Constants.fallbackTargetDuration)
    return """
      #EXTM3U
      #EXT-X-VERSION:6
      #EXT-X-TARGETDURATION:\(segmentDuration)
      #EXT-X-MEDIA-SEQUENCE:1
      #EXT-X-PLAYLIST-TYPE:VOD
      #EXTINF:\(segmentDuration),
      \(url.absoluteString)
      #EXT-X-ENDLIST
      """
  }

  private func respond(_ loadingRequest: AVAssetResourceLoadingRequest, content: String) {
    guard let data = content.data(using: .utf8) else {
      loadingRequest.finishLoading(
        with: NSError(domain: NSURLErrorDomain, code: Constants.badRequestErrorCode)
      )
      return
    }

    if let contentInformationRequest = loadingRequest.contentInformationRequest {
      contentInformationRequest.contentType = UTType.m3uPlaylist.preferredMIMEType
      contentInformationRequest.contentLength = Int64(data.count)
      contentInformationRequest.isByteRangeAccessSupported = false
    }

    loadingRequest.dataRequest?.respond(with: data)
    loadingRequest.finishLoading()
  }

  func detailedPlaylist(for stream: DASHStreamSelection.SelectedVideo) async -> String? {
    await detailedPlaylist(
      urls: stream.allURLs,
      currentURL: { self.currentVideoURL },
      advanceURL: { self.advanceVideoURLAfterFailure() },
      duration: 0,
      segmentBase: stream.segmentBase
    )
  }

  func detailedPlaylist(for stream: DASHStreamSelection.SelectedAudio) async -> String? {
    await detailedPlaylist(
      urls: stream.allURLs,
      currentURL: { self.currentAudioURL },
      advanceURL: { self.advanceAudioURLAfterFailure() },
      duration: 0,
      segmentBase: stream.segmentBase
    )
  }

  private func detailedPlaylist(
    urls: [URL],
    currentURL: () -> URL,
    advanceURL: () -> Bool,
    duration: Int,
    segmentBase: VideoPlayURLInfo.Dash.SegmentBase?
  ) async -> String? {
    guard let segmentBase else {
      return nil
    }

    guard
      let initialization = parseRange(segmentBase.initialization),
      let indexRange = parseRange(segmentBase.indexRange)
    else {
      return nil
    }

    guard !urls.isEmpty else {
      return nil
    }

    var activeURL = currentURL()
    var resolvedSidx: SidxDownloadResult?
    resolvedSidx = await downloadSidx(from: activeURL, indexRange: segmentBase.indexRange)
    while resolvedSidx == nil {
      guard advanceURL() else {
        return nil
      }
      activeURL = currentURL()
      resolvedSidx = await downloadSidx(from: activeURL, indexRange: segmentBase.indexRange)
    }
    guard let resolvedSidx else {
      return nil
    }

    let mapLength = initialization.upperBound - initialization.lowerBound + 1
    let mapOffset = initialization.lowerBound
    var offset = indexRange.upperBound + 1

    var playlist = """
      #EXTM3U
      #EXT-X-VERSION:7
      #EXT-X-TARGETDURATION:\(max(resolvedSidx.maxSegmentDuration() ?? duration, Constants.fallbackTargetDuration))
      #EXT-X-MEDIA-SEQUENCE:1
      #EXT-X-INDEPENDENT-SEGMENTS
      #EXT-X-PLAYLIST-TYPE:VOD
      #EXT-X-MAP:URI="\(activeURL.absoluteString)",BYTERANGE="\(mapLength)@\(mapOffset)"

      """

    for segment in resolvedSidx.segments {
      let segmentDuration = Double(segment.duration) / Double(resolvedSidx.timescale)
      playlist.append(
        """
        #EXTINF:\(segmentDuration),
        #EXT-X-BYTERANGE:\(segment.size)@\(offset)
        \(activeURL.absoluteString)

        """
      )
      offset += segment.size
    }

    playlist.append("#EXT-X-ENDLIST")
    return playlist
  }

  @discardableResult
  func advanceVideoURLAfterFailure() -> Bool {
    advanceURLIndex(&currentVideoURLIndex, in: video.allURLs)
  }

  @discardableResult
  func advanceAudioURLAfterFailure() -> Bool {
    advanceURLIndex(&currentAudioURLIndex, in: audio.allURLs)
  }

  private func advanceURLIndex(_ index: inout Int, in urls: [URL]) -> Bool {
    guard index + 1 < urls.count else {
      return false
    }
    index += 1
    return true
  }

  private func downloadSidx(from url: URL, indexRange: String) async -> SidxDownloadResult? {
    let maxAttempts = 3
    for attempt in 1...maxAttempts {
      if let result = await sidxDownloader(url, indexRange) {
        return result
      }
      if attempt < maxAttempts {
        try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5s between retries
      }
    }
    return nil
  }

  private func parseRange(_ value: String) -> ClosedRange<Int>? {
    let parts = value.split(separator: "-")
    guard
      parts.count == 2,
      let lower = Int(parts[0]),
      let upper = Int(parts[1]),
      lower <= upper
    else {
      return nil
    }

    return lower...upper
  }

  private var referer: String {
    "https://www.bilibili.com/video/av\(aid)"
  }

  private var userAgent: String {
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15"
  }

  private static func downloadSidx(from url: URL, indexRange: String) async -> SidxDownloadResult? {
    let response = await AF.request(
      url,
      headers: [
        "Range": "bytes=\(indexRange)",
        "Referer": "https://www.bilibili.com/",
        "User-Agent":
          "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15",
      ],
      requestModifier: { $0.timeoutInterval = 10 }
    ).serializingData().result

    guard case .success(let data) = response else {
      return nil
    }

    return SidxParseUtility.processIndexData(data: data)
  }
}

private enum SidxParseUtility {
  static func processIndexData(data: Data) -> DASHResourceLoader.SidxDownloadResult? {
    var offset: UInt64 = 0

    while offset < data.count - 8 {
      var size = UInt64(data.getUInt32(offset: &offset))
      let typeData = data.getUInt32(offset: &offset)
      let type = String(bytes: typeData.toUInt8s, encoding: .utf8)

      if size == 1 {
        size = data.getValue(type: UInt64.self, offset: &offset)
      }

      let boxPayloadSize = Int(size) - 8
      let endIndex = Int(offset) + boxPayloadSize
      guard endIndex <= data.count else {
        return nil
      }

      if type == "sidx" {
        return processSIDX(data: Data(data[Int(offset)..<endIndex]))
      }

      offset += UInt64(boxPayloadSize)
    }

    return nil
  }

  private static func processSIDX(data: Data) -> DASHResourceLoader.SidxDownloadResult? {
    var offset: UInt64 = 0
    let version = data.getUInt8(offset: &offset)
    _ = data.getUInt8(offset: &offset)
    _ = data.getUInt8(offset: &offset)
    _ = data.getUInt8(offset: &offset)
    _ = data.getUInt32(offset: &offset)
    let timescale = Int(data.getUInt32(offset: &offset))

    if version == 0 {
      _ = data.getUInt32(offset: &offset)
      _ = data.getUInt32(offset: &offset)
    } else {
      _ = data.getValue(type: UInt64.self, offset: &offset).bigEndian
      _ = data.getValue(type: UInt64.self, offset: &offset).bigEndian
    }

    _ = data.getValue(type: UInt16.self, offset: &offset).bigEndian
    let referenceCount = Int(data.getValue(type: UInt16.self, offset: &offset).bigEndian)

    var segments = [DASHResourceLoader.SidxDownloadResult.Segment]()
    for _ in 0..<referenceCount {
      let sizeCode = data.getUInt32(offset: &offset)
      let referencedSize = Int(sizeCode & 0x7fff_ffff)
      let duration = Int(data.getUInt32(offset: &offset))
      _ = data.getUInt32(offset: &offset)
      segments.append(.init(size: referencedSize, duration: duration))
    }

    return DASHResourceLoader.SidxDownloadResult(timescale: timescale, segments: segments)
  }
}

extension Data {
  fileprivate func getUInt32(offset: inout UInt64) -> UInt32 {
    getValue(type: UInt32.self, offset: &offset).bigEndian
  }

  fileprivate func getUInt8(offset: inout UInt64) -> UInt8 {
    getValue(type: UInt8.self, offset: &offset).bigEndian
  }

  fileprivate func getValue<T>(type: T.Type, offset: inout UInt64) -> T {
    let size = UInt64(MemoryLayout<T>.size)
    defer { offset += size }
    return Data(self[offset..<offset + size]).withUnsafeBytes { $0.load(as: T.self) }
  }
}

private protocol UIntToUInt8sConvertible {
  var toUInt8s: [UInt8] { get }
}

extension UIntToUInt8sConvertible {
  fileprivate func toUInt8Array<T>(endian: T, count: Int) -> [UInt8] {
    var value = endian
    let pointer = withUnsafePointer(to: &value) {
      $0.withMemoryRebound(to: UInt8.self, capacity: count) {
        UnsafeBufferPointer(start: $0, count: count)
      }
    }
    return Array(pointer)
  }
}

extension UInt32: UIntToUInt8sConvertible {
  var toUInt8s: [UInt8] {
    toUInt8Array(endian: bigEndian, count: MemoryLayout<UInt32>.size)
  }
}
