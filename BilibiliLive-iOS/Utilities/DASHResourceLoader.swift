import Alamofire
import AVFoundation
import Foundation
import UniformTypeIdentifiers

final class DASHResourceLoader: NSObject, AVAssetResourceLoaderDelegate {
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
  let playbackURL = URL(string: URLs.master)!

  init(video: DASHStreamSelection.SelectedVideo, audio: DASHStreamSelection.SelectedAudio, aid: Int) {
    self.video = video
    self.audio = audio
    self.aid = aid
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
    simplePlaylist(url: video.primaryURL)
  }

  func audioPlaylist() -> String {
    simplePlaylist(url: audio.primaryURL)
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
    """
    #EXTM3U
    #EXT-X-VERSION:6
    #EXT-X-TARGETDURATION:\(Constants.fallbackTargetDuration)
    #EXT-X-MEDIA-SEQUENCE:1
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXTINF:\(Constants.fallbackTargetDuration),
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

  private func detailedPlaylist(for stream: DASHStreamSelection.SelectedVideo) async -> String? {
    await detailedPlaylist(
      url: stream.primaryURL,
      duration: 0,
      segmentBase: stream.segmentBase
    )
  }

  private func detailedPlaylist(for stream: DASHStreamSelection.SelectedAudio) async -> String? {
    await detailedPlaylist(
      url: stream.primaryURL,
      duration: 0,
      segmentBase: stream.segmentBase
    )
  }

  private func detailedPlaylist(
    url: URL,
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

    guard let sidx = await downloadSidx(from: url, indexRange: segmentBase.indexRange) else {
      return nil
    }

    let mapLength = initialization.upperBound - initialization.lowerBound + 1
    let mapOffset = initialization.lowerBound
    var offset = indexRange.upperBound + 1

    var playlist = """
    #EXTM3U
    #EXT-X-VERSION:7
    #EXT-X-TARGETDURATION:\(max(sidx.maxSegmentDuration() ?? duration, Constants.fallbackTargetDuration))
    #EXT-X-MEDIA-SEQUENCE:1
    #EXT-X-INDEPENDENT-SEGMENTS
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXT-X-MAP:URI="\(url.absoluteString)",BYTERANGE="\(mapLength)@\(mapOffset)"

    """

    for segment in sidx.segments {
      let segmentDuration = Double(segment.duration) / Double(sidx.timescale)
      playlist.append(
        """
        #EXTINF:\(segmentDuration),
        #EXT-X-BYTERANGE:\(segment.size)@\(offset)
        \(url.absoluteString)

        """
      )
      offset += segment.size
    }

    playlist.append("#EXT-X-ENDLIST")
    return playlist
  }

  private func downloadSidx(from url: URL, indexRange: String) async -> Sidx? {
    let response = await AF.request(
      url,
      headers: [
        "Range": "bytes=\(indexRange)",
        "Referer": referer,
        "User-Agent": userAgent,
      ]
    ).serializingData().result

    guard case let .success(data) = response else {
      return nil
    }

    return SidxParseUtility.processIndexData(data: data)
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
}

private struct Sidx {
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

private enum SidxParseUtility {
  static func processIndexData(data: Data) -> Sidx? {
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

  private static func processSIDX(data: Data) -> Sidx? {
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

    var segments = [Sidx.Segment]()
    for _ in 0..<referenceCount {
      let sizeCode = data.getUInt32(offset: &offset)
      let referencedSize = Int(sizeCode & 0x7fff_ffff)
      let duration = Int(data.getUInt32(offset: &offset))
      _ = data.getUInt32(offset: &offset)
      segments.append(Sidx.Segment(size: referencedSize, duration: duration))
    }

    return Sidx(timescale: timescale, segments: segments)
  }
}

private extension Data {
  func getUInt32(offset: inout UInt64) -> UInt32 {
    getValue(type: UInt32.self, offset: &offset).bigEndian
  }

  func getUInt8(offset: inout UInt64) -> UInt8 {
    getValue(type: UInt8.self, offset: &offset).bigEndian
  }

  func getValue<T>(type: T.Type, offset: inout UInt64) -> T {
    let size = UInt64(MemoryLayout<T>.size)
    defer { offset += size }
    return Data(self[offset..<offset + size]).withUnsafeBytes { $0.load(as: T.self) }
  }
}

private protocol UIntToUInt8sConvertible {
  var toUInt8s: [UInt8] { get }
}

private extension UIntToUInt8sConvertible {
  func toUInt8Array<T>(endian: T, count: Int) -> [UInt8] {
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
