import PencilKit

extension PKDrawing {
    static func stub(points: Int = 5) -> PKDrawing {
        let strokePoints = (0..<points).map {
            PKStrokePoint(location: CGPoint(x: $0 * 10, y: $0 * 10),
                          timeOffset: TimeInterval($0) * 0.1,
                          size: CGSize(width: 3, height: 3),
                          opacity: 1,
                          force: 1,
                          azimuth: 0,
                          altitude: .pi / 2)
        }
        let path = PKStrokePath(controlPoints: strokePoints, creationDate: Date())
        return PKDrawing(strokes: [PKStroke(ink: PKInk(.pen, color: .black), path: path)])
    }
}
