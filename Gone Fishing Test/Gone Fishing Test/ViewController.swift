import Cocoa
import ScreenSaver

class ViewController: NSViewController {

    // MARK: - Properties
    private var saver: GoneFishingView?
    private var timer: Timer?
    
    private var timerRunning = true

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSEvent.addLocalMonitorForEvents(matching: NSEvent.EventTypeMask.keyDown, handler: keyDown)
        
        addScreensaver()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30,
                                     repeats: true) { [weak self] _ in
            if (self!.timerRunning) {self?.saver?.animateOneFrame()}
        }
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Helper Functions
    private func addScreensaver() {
        if let saver = GoneFishingView(frame: view.frame, isPreview: false) {
            view.addSubview(saver)
            self.saver = saver
        }
    }
    
    func keyDown(event: NSEvent) -> NSEvent {
        if event.keyCode == 49 {
            // Space bar pressed
            timerRunning = !timerRunning
        } else if event.keyCode == 36 {
            // Enter pressed
            if !timerRunning {
                self.saver?.animateOneFrame()
            }
        } else if event.keyCode == 15 {
            // R key pressed
            addScreensaver()
        } else if event.keyCode == 14 {
            // E key pressed
            self.saver?.debug_elevateFish()
        } else {
            print("unhandled key: " + String(event.keyCode))
        }
        return event
    }

}
