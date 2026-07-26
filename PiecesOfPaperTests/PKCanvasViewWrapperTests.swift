import PencilKit
import SwiftUI
import Testing
@testable import Pieces_of_Paper

@MainActor
struct PKCanvasViewWrapperTests {
    private final class SaveRecorder {
        private(set) var drawings: [PKDrawing] = []

        func record(_ drawing: PKDrawing) {
            drawings.append(drawing)
        }
    }

    private func makeCanvas(frame: CGRect = CGRect(x: 0, y: 0, width: 200, height: 300)) -> PKCanvasView {
        let canvas = PKCanvasView(frame: frame)
        canvas.drawing = .stub()
        // Sized to the drawing so it sits past the 90% threshold the wrapper grows on
        canvas.contentSize = CGSize(width: canvas.drawing.bounds.maxX,
                                    height: canvas.drawing.bounds.maxY)
        return canvas
    }

    private func makeCoordinator(store: PreferenceStore,
                                 canvas: PKCanvasView,
                                 recorder: SaveRecorder) -> PKCanvasViewWrapper.Coordinator {
        PKCanvasViewWrapper(canvasView: .constant(canvas),
                            toolPicker: .constant(PKToolPicker()),
                            isToolPickerVisible: false,
                            isAutoSaveEnabled: { store.enabledAutoSave },
                            isInfiniteScrollEnabled: { store.enabledInfiniteScroll },
                            saveAction: { recorder.record($0) })
            .makeCoordinator()
    }

    @Test func test_drawingDidChange_savesWhenAutoSaveIsEnabled() {
        let mock = PreferenceRepositoryMock()
        mock.enabledAutoSave = true
        mock.enabledInfiniteScroll = false
        let store = PreferenceStore(repository: mock)
        let canvas = makeCanvas()
        let recorder = SaveRecorder()
        let coordinator = makeCoordinator(store: store, canvas: canvas, recorder: recorder)

        coordinator.canvasViewDrawingDidChange(canvas)

        #expect(recorder.drawings == [canvas.drawing])
    }

    @Test func test_drawingDidChange_doesNotSaveWhenAutoSaveIsDisabled() {
        let mock = PreferenceRepositoryMock()
        mock.enabledAutoSave = false
        mock.enabledInfiniteScroll = false
        let store = PreferenceStore(repository: mock)
        let canvas = makeCanvas()
        let recorder = SaveRecorder()
        let coordinator = makeCoordinator(store: store, canvas: canvas, recorder: recorder)

        coordinator.canvasViewDrawingDidChange(canvas)

        #expect(recorder.drawings.isEmpty)
    }

    // The coordinator is built once and never rebuilt, so a copied Bool would
    // keep the canvas on the value the setting had when it opened
    @Test func test_drawingDidChange_followsAutoSaveChangedAfterTheCoordinatorWasMade() {
        let mock = PreferenceRepositoryMock()
        mock.enabledAutoSave = false
        mock.enabledInfiniteScroll = false
        let store = PreferenceStore(repository: mock)
        let canvas = makeCanvas()
        let recorder = SaveRecorder()
        let coordinator = makeCoordinator(store: store, canvas: canvas, recorder: recorder)

        coordinator.canvasViewDrawingDidChange(canvas)
        #expect(recorder.drawings.isEmpty)

        store.enabledAutoSave = true
        coordinator.canvasViewDrawingDidChange(canvas)

        #expect(recorder.drawings == [canvas.drawing])
    }

    @Test func test_drawingDidChange_growsContentSizeWhenInfiniteScrollIsEnabled() {
        let mock = PreferenceRepositoryMock()
        mock.enabledAutoSave = false
        mock.enabledInfiniteScroll = true
        let store = PreferenceStore(repository: mock)
        let canvas = makeCanvas()
        let expected = CGSize(width: canvas.contentSize.width + canvas.frame.width,
                              height: canvas.contentSize.height + canvas.frame.height)
        let coordinator = makeCoordinator(store: store, canvas: canvas, recorder: SaveRecorder())

        coordinator.canvasViewDrawingDidChange(canvas)

        #expect(canvas.contentSize == expected)
    }

    @Test func test_drawingDidChange_leavesContentSizeWhenInfiniteScrollIsDisabled() {
        let mock = PreferenceRepositoryMock()
        mock.enabledAutoSave = false
        mock.enabledInfiniteScroll = false
        let store = PreferenceStore(repository: mock)
        let canvas = makeCanvas()
        let contentSize = canvas.contentSize
        let coordinator = makeCoordinator(store: store, canvas: canvas, recorder: SaveRecorder())

        coordinator.canvasViewDrawingDidChange(canvas)

        #expect(canvas.contentSize == contentSize)
    }

    @Test func test_drawingDidChange_followsInfiniteScrollChangedAfterTheCoordinatorWasMade() {
        let mock = PreferenceRepositoryMock()
        mock.enabledAutoSave = false
        mock.enabledInfiniteScroll = false
        let store = PreferenceStore(repository: mock)
        let canvas = makeCanvas()
        let contentSize = canvas.contentSize
        let coordinator = makeCoordinator(store: store, canvas: canvas, recorder: SaveRecorder())

        coordinator.canvasViewDrawingDidChange(canvas)
        #expect(canvas.contentSize == contentSize)

        store.enabledInfiniteScroll = true
        coordinator.canvasViewDrawingDidChange(canvas)

        #expect(canvas.contentSize == CGSize(width: contentSize.width + canvas.frame.width,
                                             height: contentSize.height + canvas.frame.height))
    }
}
