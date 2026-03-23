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

  let video: DASHStreamSelection.SelectedVideo
  let audio: DASHStreamSelection.SelectedAudio
  let aid: Int

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
    #EXT-X-STREAM-INF:BANDWIDTH=1,AUDIO="audio"
    \(URLs.video)
    """
  }

  func videoPlaylist() -> String {
    """
    #EXTM3U
    #EXT-X-VERSION:6
    #EXT-X-TARGETDURATION:1
    #EXT-X-MEDIA-SEQUENCE:1
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXTINF:1,
    \(video.primaryURL.absoluteString)
    #EXT-X-ENDLIST
    """
  }

  func audioPlaylist() -> String {
    """
    #EXTM3U
    #EXT-X-VERSION:6
    #EXT-X-TARGETDURATION:1
    #EXT-X-MEDIA-SEQUENCE:1
    #EXT-X-PLAYLIST-TYPE:VOD
    #EXTINF:1,
    \(audio.primaryURL.absoluteString)
    #EXT-X-ENDLIST
    """
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
      content = videoPlaylist()
    case URLs.audio:
      content = audioPlaylist()
    default:
      return false
    }

    guard let data = content.data(using: .utf8) else {
      loadingRequest.finishLoading(with: NSError(domain: NSURLErrorDomain, code: 455))
      return true
    }

    if let contentInformationRequest = loadingRequest.contentInformationRequest {
      contentInformationRequest.contentType = UTType.m3uPlaylist.preferredMIMEType
      contentInformationRequest.contentLength = Int64(data.count)
      contentInformationRequest.isByteRangeAccessSupported = false
    }

    loadingRequest.dataRequest?.respond(with: data)
    loadingRequest.finishLoading()
    return true
  }
}
