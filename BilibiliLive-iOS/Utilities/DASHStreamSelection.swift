import Foundation

enum DASHStreamSelection {
  struct SelectedVideo {
    let id: Int
    let primaryURL: URL
    let allURLs: [URL]
  }

  struct SelectedAudio {
    let id: Int
    let primaryURL: URL
    let allURLs: [URL]
  }

  struct Selection {
    let video: SelectedVideo
    let audio: SelectedAudio
  }

  enum SelectionError: Error {
    case missingDash
    case missingVideoStreams
    case missingAudioStreams
    case invalidURL(String)
  }

  private static let preferredAudioIDs = [30216, 30232, 30251]

  static func select(from playInfo: VideoPlayURLInfo) throws -> Selection {
    guard let dash = playInfo.dash else {
      throw SelectionError.missingDash
    }

    let videoStream = try selectVideoStream(from: dash.video)
    let audioStream = try selectAudioStream(from: dash.audio)

    return Selection(
      video: try makeSelectedVideo(from: videoStream),
      audio: try makeSelectedAudio(from: audioStream)
    )
  }

  private static func selectVideoStream(from streams: [VideoPlayURLInfo.Dash.VideoStream]) throws
    -> VideoPlayURLInfo.Dash.VideoStream
  {
    guard !streams.isEmpty else {
      throw SelectionError.missingVideoStreams
    }

    let highestQuality = streams.map(\.id).max() ?? streams[0].id
    let qualityGroup = streams.filter { $0.id == highestQuality }
    if let avc = qualityGroup.first(where: isAvcStream) {
      return avc
    }
    if let hevc = qualityGroup.first(where: \.isHevc) {
      return hevc
    }
    return qualityGroup.first ?? streams[0]
  }

  private static func selectAudioStream(from streams: [VideoPlayURLInfo.Dash.AudioStream]?) throws
    -> VideoPlayURLInfo.Dash.AudioStream
  {
    guard let streams else {
      throw SelectionError.missingAudioStreams
    }
    guard !streams.isEmpty else {
      throw SelectionError.missingAudioStreams
    }

    for preferredID in preferredAudioIDs {
      if let audio = streams.first(where: { $0.id == preferredID }) {
        return audio
      }
    }

    return streams[0]
  }

  private static func makeSelectedVideo(from stream: VideoPlayURLInfo.Dash.VideoStream) throws
    -> SelectedVideo
  {
    guard let primaryURL = URL(string: stream.baseUrl) else {
      throw SelectionError.invalidURL(stream.baseUrl)
    }
    let allURLs = try makeURLs(from: stream.allUrls)
    return SelectedVideo(id: stream.id, primaryURL: primaryURL, allURLs: allURLs)
  }

  private static func makeSelectedAudio(from stream: VideoPlayURLInfo.Dash.AudioStream) throws
    -> SelectedAudio
  {
    guard let primaryURL = URL(string: stream.baseUrl) else {
      throw SelectionError.invalidURL(stream.baseUrl)
    }
    let allURLs = try makeURLs(from: stream.allUrls)
    return SelectedAudio(id: stream.id, primaryURL: primaryURL, allURLs: allURLs)
  }

  private static func makeURLs(from strings: [String]) throws -> [URL] {
    var urls = [URL]()
    for string in strings {
      guard let url = URL(string: string) else {
        throw SelectionError.invalidURL(string)
      }
      urls.append(url)
    }
    return urls
  }

  private static func isAvcStream(_ stream: VideoPlayURLInfo.Dash.VideoStream) -> Bool {
    if let codecs = stream.codecs {
      return codecs.starts(with: "avc")
    }
    return stream.codecid == 7
  }
}
