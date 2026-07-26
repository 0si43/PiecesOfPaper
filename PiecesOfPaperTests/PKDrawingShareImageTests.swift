import Testing
import UIKit
import PencilKit
@testable import Pieces_of_Paper

@MainActor
struct PKDrawingShareImageTests {
    // The share sheet hands this UIImage straight to another app, so a transparent
    // background is composited on black by any viewer in dark mode and swallows the
    // dark ink the light trait deliberately preserves
    @Test func test_lightModeImage_isFullyOpaque() throws {
        let pixels = try Self.rgbaPixels(of: PKDrawing.stub().lightModeImage(scale: 1))
        #expect(pixels.lazy.map(\.alpha).min() == 255)
    }

    @Test func test_lightModeImage_keepsTheInkVisible() throws {
        let pixels = try Self.rgbaPixels(of: PKDrawing.stub().lightModeImage(scale: 1))
        #expect(pixels.contains { $0.alpha == 255 && $0.red < 128 })
    }

    private struct Pixel {
        let red: UInt8
        let alpha: UInt8
    }

    /// Draws the image into a context that starts as transparent black, so any area
    /// the image does not cover opaquely comes back with alpha below 255.
    private static func rgbaPixels(of image: UIImage) throws -> [Pixel] {
        let cgImage = try #require(image.cgImage)
        let width = cgImage.width
        let height = cgImage.height
        var buffer = [UInt8](repeating: 0, count: width * height * 4)
        let context = try #require(CGContext(data: &buffer,
                                             width: width,
                                             height: height,
                                             bitsPerComponent: 8,
                                             bytesPerRow: width * 4,
                                             space: CGColorSpaceCreateDeviceRGB(),
                                             bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        return stride(from: 0, to: buffer.count, by: 4).map {
            Pixel(red: buffer[$0], alpha: buffer[$0 + 3])
        }
    }
}
