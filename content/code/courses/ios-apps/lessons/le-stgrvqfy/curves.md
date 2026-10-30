---
title: Timing curves, computed
version: 1
---

**An animation's curve is a function from time to progress, and it can be computed on any computer.**
SwiftUI draws the frames, which needs a Mac; what it draws on each frame is a number between the old
value and the new one, and which number depends on the curve. This section computes those numbers for
the curves an animation can be given, in a small package of its own that has nothing to do with the
planner's. It runs on Linux like every capture in the course.

Apple's documentation for `Animation.timingCurve(_:_:_:_:duration:)` describes the shape: a cubic
Bézier curve from `(0, 0)` to `(1, 1)` with two control points, where the slope at a moment is the
speed of the animation at that moment. It does not publish the control points of SwiftUI's own
`.easeIn`, `.easeOut` and `.easeInOut`, which it describes in words. The four curves below use the
control points the CSS standard gives curves of the same names, and `timingCurve` asks SwiftUI for
exactly these shapes whenever you want them.

Make a directory `~/l11` with `Sources/Motion` and `Sources/curves` in it. Save this as
`Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Motion",
    targets: [
        .target(name: "Motion"),
        .executableTarget(name: "curves", dependencies: ["Motion"]),
    ]
)
```

Save this as `Sources/Motion/Curve.swift`:

```schooling-example
{"language": "swift", "file": "Sources/Motion/Curve.swift", "parts": [{"code": "// Sources/Motion/Curve.swift\nimport Foundation\n\n/// A cubic Bézier timing curve from (0, 0) to (1, 1): the shape that\n/// `Animation.timingCurve(_:_:_:_:duration:)` takes four numbers for.\npublic struct TimingCurve: Sendable {\n    public let x1, y1, x2, y2: Double\n\n    public init(_ x1: Double, _ y1: Double, _ x2: Double, _ y2: Double) {\n        (self.x1, self.y1, self.x2, self.y2) = (x1, y1, x2, y2)\n    }\n\n", "note": "The four numbers are the two control points. The curve always starts at (0, 0) and ends at (1, 1): no time has passed and nothing has moved, then all the time and all the way. The control points bend what happens between."}, {"code": "    private func bezier(_ s: Double, _ p1: Double, _ p2: Double) -> Double {\n        3 * (1 - s) * (1 - s) * s * p1 + 3 * (1 - s) * s * s * p2 + s * s * s\n    }\n\n", "note": "One coordinate of a cubic Bézier at parameter `s`. The same formula gives x from `x1`, `x2` and y from `y1`, `y2`."}, {"code": "    /// How far the value has moved, 0 to 1, when `time` of the duration, 0 to 1, has passed.\n    public func progress(at time: Double) -> Double {\n        var low = 0.0, high = 1.0\n        for _ in 0..<50 {                        // find s where the curve's x is `time`\n            let mid = (low + high) / 2\n            if bezier(mid, x1, x2) < time { low = mid } else { high = mid }\n        }\n        return bezier((low + high) / 2, y1, y2)  // and answer its y\n    }\n}\n\n", "note": "Time is the curve's x and progress is its y, but the curve is defined by a parameter `s`, not by x. So the code searches for the `s` whose x is the time asked about, halving the interval fifty times, and answers that point's y."}, {"code": "/// A spring with no bounce: critically damped, one period of `response` seconds.\npublic func criticalSpring(response: Double, at seconds: Double) -> Double {\n    let omega = 2 * Double.pi / response\n    return 1 - (1 + omega * seconds) * exp(-omega * seconds)\n}\n\n", "note": "A spring has no control points; it has physics. With no bounce it rises and settles without passing 1. `response` is read here as the period of the spring, which is the textbook meaning; Apple documents it only as \"an approximate duration\", so these numbers are a model and not SwiftUI's own."}, {"code": "/// The value on screen at a given progress: where it started, plus that share of the way.\npublic func interpolate(from start: Double, to end: Double, progress: Double) -> Double {\n    start + (end - start) * progress\n}\n", "note": "What SwiftUI does with a progress: the old value, plus that share of the distance to the new one. Every animatable property goes through a step like this on every frame."}]}
```

And this as `Sources/curves/main.swift`. It prints each curve every 50 milliseconds through SwiftUI's
default duration of 0.35 seconds, then the planner's week bar going from 120 minutes done of 180 to
all 180, then the spring:

```swift
// Sources/curves/main.swift
import Foundation
import Motion

let curves: [(String, TimingCurve)] = [
    ("linear", TimingCurve(0, 0, 1, 1)),
    ("ease-in", TimingCurve(0.42, 0, 1, 1)),
    ("ease-out", TimingCurve(0, 0, 0.58, 1)),
    ("ease-in-out", TimingCurve(0.42, 0, 0.58, 1)),
]
let duration = 0.35

print("seconds", curves.map { $0.0.padding(toLength: 11, withPad: " ", startingAt: 0) }.joined())
for step in 0...7 {
    let seconds = Double(step) * 0.05
    let row = curves.map { String(format: "%.3f", $0.1.progress(at: seconds / duration)) }
    print(String(format: "%-7.2f", seconds), row.map { $0.padding(toLength: 11, withPad: " ", startingAt: 0) }
        .joined().trimmingCharacters(in: .whitespaces))
}

// The week bar, from 120 of 180 minutes done to all 180, eased in and out
let easeInOut = curves[3].1
for seconds in [0.0, 0.1, 0.175, 0.25, 0.35] {
    let fraction = interpolate(from: 120.0 / 180, to: 1, progress: easeInOut.progress(at: seconds / duration))
    print(String(format: "bar at %.3f s: %.1f%% full", seconds, fraction * 100))
}

for seconds in [0.1, 0.2, 0.3, 0.4, 0.55, 0.8] {
    print(String(format: "spring at %.2f s: %.3f", seconds, criticalSpring(response: 0.55, at: seconds)))
}

for hertz in [60.0, 120.0] {
    print("frames in \(duration) s at \(Int(hertz)) Hz:", Int((duration * hertz).rounded()))
}
```

```
ana@vm:~/l11$ swift build
Building for debugging...
[Pre-planning 1 / 66]
[18 / 32] Motion
[24 / 35] Motion
[32 / 38] curves-product
[33 / 38] Motion
[40 / 40] curves-product
Build complete! (4.79 secs)
ana@vm:~/l11$ .build/debug/curves
seconds linear     ease-in    ease-out   ease-in-out
0.00    0.000      0.000      0.000      0.000
0.05    0.143      0.033      0.225      0.041
0.10    0.286      0.119      0.426      0.170
0.15    0.429      0.242      0.605      0.378
0.20    0.571      0.395      0.758      0.622
0.25    0.714      0.574      0.881      0.830
0.30    0.857      0.775      0.967      0.959
0.35    1.000      1.000      1.000      1.000
bar at 0.000 s: 66.7% full
bar at 0.100 s: 72.3% full
bar at 0.175 s: 83.3% full
bar at 0.250 s: 94.3% full
bar at 0.350 s: 100.0% full
spring at 0.10 s: 0.316
spring at 0.20 s: 0.666
spring at 0.30 s: 0.856
spring at 0.40 s: 0.942
spring at 0.55 s: 0.986
spring at 0.80 s: 0.999
frames in 0.35 s at 60 Hz: 21
frames in 0.35 s at 120 Hz: 42
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l11-curves\" aria-label=\"A chart of progress against time, both from 0 to 1 over 0.6 seconds. Four timing curves end at 0.35 seconds, the default duration: linear is a straight line, ease-in starts flat and ends steep, ease-out starts steep and ends flat, ease-in-out is flat at both ends and crosses the middle at 0.175 seconds. A fifth line, the critically damped spring with a response of 0.55 seconds, rises fast and is still short of 1 at 0.35 seconds, reaching about 0.99 at 0.55.\"><defs><marker id=\"l11-curves-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l11-curves-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l11-curves-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l11-curves-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 290 L600 290\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M70 290 L70 30\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"70.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.0</text><text x=\"156.66666666666669\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.1</text><text x=\"243.33333333333334\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.2</text><text x=\"330.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.3</text><text x=\"416.6666666666667\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.4</text><text x=\"503.33333333333337\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><text x=\"590.0\" y=\"306\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.6</text><text x=\"330.0\" y=\"326\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seconds</text><text x=\"60\" y=\"290\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><text x=\"60\" y=\"165.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.5</text><text x=\"60\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><text x=\"30\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">progress</text><path d=\"M373.33333333333337 290 L373.33333333333337 34\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"373.33333333333337\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0.35 s</text><path d=\"M70.0 290.0 L73.0 287.5 L76.1 285.0 L79.1 282.5 L82.1 280.0 L85.2 277.5 L88.2 275.0 L91.2 272.5 L94.3 270.0 L97.3 267.5 L100.3 265.0 L103.4 262.5 L106.4 260.0 L109.4 257.5 L112.5 255.0 L115.5 252.5 L118.5 250.0 L121.6 247.5 L124.6 245.0 L127.6 242.5 L130.7 240.0 L133.7 237.5 L136.7 235.0 L139.8 232.5 L142.8 230.0 L145.8 227.5 L148.9 225.0 L151.9 222.5 L154.9 220.0 L158.0 217.5 L161.0 215.0 L164.0 212.5 L167.1 210.0 L170.1 207.5 L173.1 205.0 L176.2 202.5 L179.2 200.0 L182.2 197.5 L185.3 195.0 L188.3 192.5 L191.3 190.0 L194.4 187.5 L197.4 185.0 L200.4 182.5 L203.5 180.0 L206.5 177.5 L209.5 175.0 L212.6 172.5 L215.6 170.0 L218.6 167.5 L221.7 165.0 L224.7 162.5 L227.7 160.0 L230.8 157.5 L233.8 155.0 L236.8 152.5 L239.9 150.0 L242.9 147.5 L245.9 145.0 L249.0 142.5 L252.0 140.0 L255.0 137.5 L258.1 135.0 L261.1 132.5 L264.1 130.0 L267.2 127.5 L270.2 125.0 L273.2 122.5 L276.3 120.0 L279.3 117.5 L282.3 115.0 L285.4 112.5 L288.4 110.0 L291.4 107.5 L294.5 105.0 L297.5 102.5 L300.5 100.0 L303.6 97.5 L306.6 95.0 L309.6 92.5 L312.7 90.0 L315.7 87.5 L318.7 85.0 L321.8 82.5 L324.8 80.0 L327.8 77.5 L330.9 75.0 L333.9 72.5 L336.9 70.0 L340.0 67.5 L343.0 65.0 L346.0 62.5 L349.1 60.0 L352.1 57.5 L355.1 55.0 L358.2 52.5 L361.2 50.0 L364.2 47.5 L367.3 45.0 L370.3 42.5 L373.3 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70.0 290.0 L73.0 290.0 L76.1 289.8 L79.1 289.6 L82.1 289.3 L85.2 288.9 L88.2 288.4 L91.2 287.9 L94.3 287.2 L97.3 286.5 L100.3 285.7 L103.4 284.9 L106.4 284.0 L109.4 283.0 L112.5 282.0 L115.5 280.9 L118.5 279.7 L121.6 278.5 L124.6 277.2 L127.6 275.8 L130.7 274.4 L133.7 273.0 L136.7 271.5 L139.8 269.9 L142.8 268.3 L145.8 266.6 L148.9 264.9 L151.9 263.2 L154.9 261.4 L158.0 259.5 L161.0 257.6 L164.0 255.7 L167.1 253.7 L170.1 251.6 L173.1 249.6 L176.2 247.5 L179.2 245.3 L182.2 243.1 L185.3 240.9 L188.3 238.6 L191.3 236.3 L194.4 233.9 L197.4 231.5 L200.4 229.1 L203.5 226.7 L206.5 224.2 L209.5 221.6 L212.6 219.1 L215.6 216.5 L218.6 213.8 L221.7 211.2 L224.7 208.5 L227.7 205.7 L230.8 203.0 L233.8 200.2 L236.8 197.3 L239.9 194.5 L242.9 191.6 L245.9 188.7 L249.0 185.7 L252.0 182.7 L255.0 179.7 L258.1 176.7 L261.1 173.6 L264.1 170.5 L267.2 167.4 L270.2 164.2 L273.2 161.0 L276.3 157.8 L279.3 154.6 L282.3 151.3 L285.4 148.0 L288.4 144.7 L291.4 141.3 L294.5 137.9 L297.5 134.5 L300.5 131.1 L303.6 127.6 L306.6 124.2 L309.6 120.6 L312.7 117.1 L315.7 113.5 L318.7 109.9 L321.8 106.3 L324.8 102.6 L327.8 99.0 L330.9 95.3 L333.9 91.5 L336.9 87.8 L340.0 84.0 L343.0 80.1 L346.0 76.3 L349.1 72.4 L352.1 68.5 L355.1 64.5 L358.2 60.6 L361.2 56.5 L364.2 52.5 L367.3 48.4 L370.3 44.2 L373.3 40.0\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70.0 290.0 L73.0 285.8 L76.1 281.6 L79.1 277.5 L82.1 273.5 L85.2 269.4 L88.2 265.5 L91.2 261.5 L94.3 257.6 L97.3 253.7 L100.3 249.9 L103.4 246.0 L106.4 242.2 L109.4 238.5 L112.5 234.7 L115.5 231.0 L118.5 227.4 L121.6 223.7 L124.6 220.1 L127.6 216.5 L130.7 212.9 L133.7 209.4 L136.7 205.8 L139.8 202.4 L142.8 198.9 L145.8 195.5 L148.9 192.1 L151.9 188.7 L154.9 185.3 L158.0 182.0 L161.0 178.7 L164.0 175.4 L167.1 172.2 L170.1 169.0 L173.1 165.8 L176.2 162.6 L179.2 159.5 L182.2 156.4 L185.3 153.3 L188.3 150.3 L191.3 147.3 L194.4 144.3 L197.4 141.3 L200.4 138.4 L203.5 135.5 L206.5 132.7 L209.5 129.8 L212.6 127.0 L215.6 124.3 L218.6 121.5 L221.7 118.8 L224.7 116.2 L227.7 113.5 L230.8 110.9 L233.8 108.4 L236.8 105.8 L239.9 103.3 L242.9 100.9 L245.9 98.5 L249.0 96.1 L252.0 93.7 L255.0 91.4 L258.1 89.1 L261.1 86.9 L264.1 84.7 L267.2 82.5 L270.2 80.4 L273.2 78.4 L276.3 76.3 L279.3 74.3 L282.3 72.4 L285.4 70.5 L288.4 68.6 L291.4 66.8 L294.5 65.1 L297.5 63.4 L300.5 61.7 L303.6 60.1 L306.6 58.5 L309.6 57.0 L312.7 55.6 L315.7 54.2 L318.7 52.8 L321.8 51.5 L324.8 50.3 L327.8 49.1 L330.9 48.0 L333.9 47.0 L336.9 46.0 L340.0 45.1 L343.0 44.3 L346.0 43.5 L349.1 42.8 L352.1 42.1 L355.1 41.6 L358.2 41.1 L361.2 40.7 L364.2 40.4 L367.3 40.2 L370.3 40.0 L373.3 40.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70.0 290.0 L73.0 290.0 L76.1 289.8 L79.1 289.6 L82.1 289.2 L85.2 288.8 L88.2 288.3 L91.2 287.6 L94.3 286.9 L97.3 286.0 L100.3 285.1 L103.4 284.0 L106.4 282.8 L109.4 281.6 L112.5 280.2 L115.5 278.7 L118.5 277.1 L121.6 275.4 L124.6 273.6 L127.6 271.6 L130.7 269.6 L133.7 267.4 L136.7 265.2 L139.8 262.8 L142.8 260.3 L145.8 257.7 L148.9 255.0 L151.9 252.2 L154.9 249.3 L158.0 246.3 L161.0 243.2 L164.0 239.9 L167.1 236.6 L170.1 233.2 L173.1 229.7 L176.2 226.1 L179.2 222.5 L182.2 218.7 L185.3 214.9 L188.3 211.0 L191.3 207.0 L194.4 203.0 L197.4 198.9 L200.4 194.8 L203.5 190.6 L206.5 186.4 L209.5 182.2 L212.6 177.9 L215.6 173.6 L218.6 169.3 L221.7 165.0 L224.7 160.7 L227.7 156.4 L230.8 152.1 L233.8 147.8 L236.8 143.6 L239.9 139.4 L242.9 135.2 L245.9 131.1 L249.0 127.0 L252.0 123.0 L255.0 119.0 L258.1 115.1 L261.1 111.3 L264.1 107.5 L267.2 103.9 L270.2 100.3 L273.2 96.8 L276.3 93.4 L279.3 90.1 L282.3 86.8 L285.4 83.7 L288.4 80.7 L291.4 77.8 L294.5 75.0 L297.5 72.3 L300.5 69.7 L303.6 67.2 L306.6 64.8 L309.6 62.6 L312.7 60.4 L315.7 58.4 L318.7 56.4 L321.8 54.6 L324.8 52.9 L327.8 51.3 L330.9 49.8 L333.9 48.4 L336.9 47.2 L340.0 46.0 L343.0 44.9 L346.0 44.0 L349.1 43.1 L352.1 42.4 L355.1 41.7 L358.2 41.2 L361.2 40.8 L364.2 40.4 L367.3 40.2 L370.3 40.0 L373.3 40.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M70.0 290.0 L75.2 289.4 L80.4 287.9 L85.6 285.4 L90.8 282.2 L96.0 278.3 L101.2 273.9 L106.4 269.0 L111.6 263.7 L116.8 258.1 L122.0 252.3 L127.2 246.3 L132.4 240.2 L137.6 233.9 L142.8 227.7 L148.0 221.4 L153.2 215.1 L158.4 208.8 L163.6 202.6 L168.8 196.5 L174.0 190.5 L179.2 184.6 L184.4 178.8 L189.6 173.1 L194.8 167.6 L200.0 162.3 L205.2 157.0 L210.4 152.0 L215.6 147.1 L220.8 142.3 L226.0 137.7 L231.2 133.3 L236.4 129.0 L241.6 124.9 L246.8 121.0 L252.0 117.2 L257.2 113.5 L262.4 110.0 L267.6 106.6 L272.8 103.4 L278.0 100.3 L283.2 97.3 L288.4 94.5 L293.6 91.8 L298.8 89.2 L304.0 86.7 L309.2 84.4 L314.4 82.1 L319.6 80.0 L324.8 77.9 L330.0 75.9 L335.2 74.1 L340.4 72.3 L345.6 70.6 L350.8 69.0 L356.0 67.5 L361.2 66.0 L366.4 64.7 L371.6 63.3 L376.8 62.1 L382.0 60.9 L387.2 59.8 L392.4 58.7 L397.6 57.7 L402.8 56.8 L408.0 55.8 L413.2 55.0 L418.4 54.2 L423.6 53.4 L428.8 52.6 L434.0 52.0 L439.2 51.3 L444.4 50.7 L449.6 50.1 L454.8 49.5 L460.0 49.0 L465.2 48.5 L470.4 48.0 L475.6 47.6 L480.8 47.1 L486.0 46.7 L491.2 46.4 L496.4 46.0 L501.6 45.7 L506.8 45.3 L512.0 45.0 L517.2 44.7 L522.4 44.5 L527.6 44.2 L532.8 44.0 L538.0 43.8 L543.2 43.5 L548.4 43.3 L553.6 43.1 L558.8 43.0 L564.0 42.8 L569.2 42.6 L574.4 42.5 L579.6 42.3 L584.8 42.2 L590.0 42.1\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M612 70 L636 70\" stroke=\"var(--paper-dim)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"642\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">linear</text><path d=\"M612 92 L636 92\" stroke=\"var(--paper)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"642\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ease-in</text><path d=\"M612 114 L636 114\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"642\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ease-out</text><path d=\"M612 136 L636 136\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"642\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ease-in-out</text><path d=\"M612 158 L636 158\" stroke=\"var(--phosphor-dim)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"642\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">spring, 0.55</text></svg>", "caption": "The same 0.35 seconds, four shapes. The spring has no duration, so it is still rising when the timing curves have finished."}
```

**Read the table across a row, not down a column.** At 0.10 seconds a linear animation has moved 28.6%
of the way, an ease-out 42.6% and an ease-in 11.9%: same time, same distance to cover, three different
positions on the screen. Ease-out is fast first and slow last, which is why it suits something arriving
because somebody tapped, it answers at once. Ease-in is the opposite and suits something leaving.
Ease-in-out is slow at both ends and crosses halfway at 0.175 seconds, half the duration, which is why
the bar is at 83.3% then: halfway between 66.7% and 100%.

**The spring is still moving when the curves have stopped.** At 0.35 seconds every timing curve is at
1.000 by definition, because the duration is part of a timing curve. A spring has no duration, only a
response: at 0.40 seconds it is at 0.942 and at 0.55, its response, at 0.986. Apple's documentation
for `Animation.default` says that since iOS 17 the default animation is a spring with a response of
0.55 and a damping fraction of 1.0, which is to say this curve's shape with no bounce; before iOS 17
it was `easeInOut`. So the same `withAnimation { }` with no argument settles differently on an
iPhone running iOS 16 and one running iOS 17.

The last two lines are why duration is felt rather than counted. A display refreshing 60 times a second
draws 21 frames of a 0.35-second animation; a 120 Hz display draws 42, and the curve is sampled twice
as often. Neither changes what the animation is, which is the reason a curve is defined against time
and not against frames.
