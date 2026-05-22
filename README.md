# Chaptr Mobile Challenge — Vertical Video Feed

A highly optimized, full-screen vertical scrolling video feed built using native Swift and SwiftUI. This implementation prioritizes seamless 60fps scrolling performance, strict memory safety via active item purging, synchronized stream-derived countdown metrics, and state persistence.

### 🎥 Narration & Code Walkthrough
* **Video Demonstration URL:** https://youtu.be/9YYSL9GbiEc

---

## 🚀 How to Build and Run the Project

### Prerequisites
* **macOS:** Version 14.0 (Sonoma) or newer.
* **Xcode:** Version 15.0 or newer.
* **Target Device:** iOS 16.0+ (Tested extensively on iOS 17+ Simulator and physical iPhone hardware).

### Step-by-Step Setup
1.  **Clone the Repository:**
    ```bash
    git clone https://github.com/arunlj561/ChaptrReelFeed.git
    cd ChaptrReelFeed
    ```
2.  **Open in Xcode:**
    * Double-click `ChaptrChallenge.xcodeproj` (or your customized `.xcodeproj` name) to open the project file.
3.  **Verify Data Assets:**
    * Ensure that the bundled `for-you.json` catalog file is properly assigned target membership to your main app target.
4.  **Select Build Destination:**
    * Choose a modern simulator (e.g., iPhone 15 / 16 Pro) or your attached developer iOS device from the Xcode target schemes dropdown menu.
5.  **Compile & Run:**
    * Press `Cmd + R` to build and initiate execution.

---

## 🛠️ Stack & Architecture Choice

* **UI Framework:** 100% Native **SwiftUI**.
* **Video Engine:** **AVFoundation** (`AVPlayer`, `AVURLAsset`, `AVPlayerItem`).
* **Asynchronous Pipeline:** Modern **Swift Concurrency** (Structured `Task` instances with async/await).

### Structural Decisions
Instead of relying on third-party dependencies, this layout utilizes a custom-engineered `VideoCacheManager` acting as a single source of truth for media resources. It manages a specialized sliding pool window of exactly **4 active player frames** (1 item retained behind the current index for smooth back-swiping transitions, and 2 preloaded upcoming items ahead). This structure guarantees low latency while keeping RAM allocation perfectly predictable.

---

## 📈 What Was Built vs. Skipped

### What Was Built (Implemented)
* **Fluid Vertical Pagination:** A customized full-screen paging container that enforces one video item per viewport focus frame.
* **Asynchronous $O(1)$ Optimization Pool:** A preloading engine using iOS 16+ `asset.load(.isPlayable)` async structures. When purging old offscreen references, indices are verified using a constant-time mapping layout dictionary rather than linear array searches.
* **Direct Time Synchronization UI:** A countdown overlay pill that reads frame timings directly from the `AVPlayer` object instance on a regular heartbeat pulse, freezing instantly if streaming buffers drop frames or stall.
* **Expandable Text Overlays:** Smoothly animated, text-constrained description rows supporting native "...more" expand/collapse toggles.
* **Session State Persistence:** Integrates `UserDefaults` tracking keys to seamlessly preserve the user's focus position across app relaunches.
* **App Lifecycle Synchronization:** Connects to native `@Environment(\.scenePhase)` observers to immediately cut off video audio playback whenever the app is backgrounded or the device screen locks.

### What Was Skipped
* **Interactive Engagement Triggers:** The right-hand action buttons (Like, Comment, Share) are static visual anchors with hardcoded metric badges to mirror production short-form mockups without bloating core engineering scopes.

---

## ⚖️ Engineering Trade-offs & Current Risks

### Trade-offs Made
1.  **SwiftUI `LazyVStack` vs. UIKit `UIPageViewController` Wrapper:** Utilizing native SwiftUI stacks speeds up declarative UI updates but introduces subtle lifecycle anomalies regarding item visibility thresholds during rapid swipes. This was solved by linking custom view updates strictly to structural identifier selections (`activeVideoID`) rather than depending on layout-driven `.onAppear` signals.

### Scaling Risks (Thousands of Videos & Users)
1.  **Local Memory Management Boundaries:** Right now, the flat local JSON array is fully parsed in memory. If scaled to thousands of entries, it would cause memory bloat on initial boot. Solution: It must be swapped for an un-cached local SQL database sequence or a remote paginated API layout.
2.  **Network Bandwidth Degradation:** Preloading 2 assets ahead can waste significant cellular data if users skip clips quickly. Scaling would necessitate dynamic stream bit-rate adjustments (HLS streams using `.m3u8` master files instead of straight `.mp4` file allocations).

