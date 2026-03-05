//
//  QRCodeGenerator.swift
//  BilibiliLive-iOS
//
//  Created by iOS Implementation on 2026/3/5.
//

import CoreImage
import UIKit

enum QRCodeGenerator {
  /// Generate a QR code image from a string
  /// - Parameter string: The content to encode in the QR code
  /// - Returns: A UIImage of the QR code, or nil if generation fails
  static func generateQRCode(from string: String) -> UIImage? {
    guard let data = string.data(using: .utf8) else {
      return nil
    }

    guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
      return nil
    }

    filter.setValue(data, forKey: "inputMessage")

    // Scale up the QR code for better quality
    let transform = CGAffineTransform(scaleX: 10, y: 10)

    guard let output = filter.outputImage?.transformed(by: transform) else {
      return nil
    }

    // Convert CIImage to UIImage
    let context = CIContext()
    guard let cgImage = context.createCGImage(output, from: output.extent) else {
      return nil
    }

    return UIImage(cgImage: cgImage)
  }
}
