---
title: What a picture costs in memory
version: 1
---

**A picture's size on the network and its size in memory are different numbers, and the second one is
the one that runs a phone out of memory.** A PNG or a JPEG is compressed; to draw it, the system
decodes it into a grid of pixels, four bytes each, red, green, blue and transparency. The file can be
tiny and the grid enormous. Nothing in `AsyncImage`'s one line tells you which one you are holding.

This section measures both, with three covers small enough to make on your own machine.

## Pictures to measure

The covers are made by a Python program rather than downloaded, so that you have exactly these
three. Each is one solid colour, which compresses to almost nothing, and that is on purpose: it
makes the gap between the two numbers as wide as it can be. Save this as `make_covers.py` in a new
directory, `~/images`:

```python
#!/usr/bin/env python3
# make_covers.py
# Writes the planner's course covers as PNG files, one solid colour each.
import os, struct, zlib


def png(path, width, height, rgb):
    row = b"\x00" + bytes(rgb) * width          # filter byte, then the pixels
    raw = zlib.compress(row * height, 9)

    def chunk(kind, data):
        body = kind + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)  # 8-bit RGB
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", header) + chunk(b"IDAT", raw) + chunk(b"IEND", b""))


os.makedirs("covers", exist_ok=True)
png("covers/sql.png", 1200, 800, (47, 111, 78))
png("covers/mobile.png", 1200, 800, (52, 98, 160))
png("covers/photo.png", 4032, 3024, (200, 120, 60))   # the size of a phone's photo
for name in sorted(os.listdir("covers")):
    print(name, os.path.getsize(os.path.join("covers", name)), "bytes")
```

The third is the size of a photograph from a recent iPhone's main camera, 4032 by 3024. Run it, and
serve the directory with the web server Python ships, on a port of its own and in its own terminal:

```
ana@vm:~/images$ python3 make_covers.py
mobile.png 3987 bytes
photo.png 40614 bytes
sql.png 3988 bytes
ana@vm:~/images$ python3 -m http.server 8015 --bind 127.0.0.1
Serving HTTP on 127.0.0.1 port 8015 (http://127.0.0.1:8015/) ...
```

## Reading the size without decoding

Decoding needs a graphics library this Linux machine does not have, and it is not needed to know the
answer: a PNG states its width and height in the first 24 bytes of the file. Save this as
`Sources/PlannerCore/ImageSize.swift` in the planner's package:

```swift
// Sources/PlannerCore/ImageSize.swift
import Foundation

/// The width and height a PNG declares, read from its header without decoding it.
public func pngSize(_ data: Data) -> (width: Int, height: Int)? {
    let bytes = [UInt8](data.prefix(24))
    guard bytes.count == 24, bytes[0..<8] == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
          bytes[12..<16] == [0x49, 0x48, 0x44, 0x52]                       // "IHDR"
    else { return nil }
    func int(_ i: Int) -> Int { bytes[i..<i + 4].reduce(0) { $0 << 8 | Int($1) } }
    return (int(16), int(20))
}

/// What an image costs in memory once it is decoded: four bytes a pixel.
public func decodedBytes(width: Int, height: Int) -> Int {
    width * height * 4
}

/// The pixels a view of `points` needs on a screen of `scale`.
public func pixels(points: Int, scale: Int) -> Int {
    points * scale
}
```

`decodedBytes` is the whole of the arithmetic: width times height times four. `pixels` turns the
points a layout speaks in into the pixels a screen has, since a 3x screen draws every point as a
square of nine pixels.

Now a program that downloads each cover and prints both numbers, and then what a thumbnail costs: the
list in section 02 draws each cover in an 80-point square. The package gains a fourth program,
`covers`. Replace `Package.swift` with this, lesson 14's with one more line:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Planner",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "PlannerCore", targets: ["PlannerCore"]),
    ],
    targets: [
        .target(name: "PlannerCore"),
        .executableTarget(name: "week", dependencies: ["PlannerCore"]),
        .executableTarget(name: "fetch", dependencies: ["PlannerCore"]),
        .executableTarget(name: "repo", dependencies: ["PlannerCore"]),
        .executableTarget(name: "covers", dependencies: ["PlannerCore"]),
        .testTarget(name: "PlannerCoreTests", dependencies: ["PlannerCore"]),
    ]
)
```

And save this as `Sources/covers/main.swift`:

```swift
// Sources/covers/main.swift
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import PlannerCore

let base = URL(string: "http://127.0.0.1:8015/covers/")!
let thumb = pixels(points: 80, scale: 3)           // an 80-point square on a 3x screen

for name in ["sql", "mobile", "photo"] {
    let (data, _) = try await URLSession.shared.data(from: base.appending(path: "\(name).png"))
    guard let size = pngSize(data) else { print(name, "is not a PNG"); continue }
    print(name)
    print("  downloaded   \(data.count) bytes")
    print("  decoded      \(decodedBytes(width: size.width, height: size.height)) bytes, \(size.width)x\(size.height)")
}
print("thumbnail      \(decodedBytes(width: thumb, height: thumb)) bytes, \(thumb)x\(thumb)")
```

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (9.64 secs)
ana@vm:~/planner$ .build/debug/covers
sql
  downloaded   3988 bytes
  decoded      3840000 bytes, 1200x800
mobile
  downloaded   3987 bytes
  decoded      3840000 bytes, 1200x800
photo
  downloaded   40614 bytes
  decoded      48771072 bytes, 4032x3024
thumbnail      230400 bytes, 240x240
```

**The photograph downloaded as 40,614 bytes and decodes to 48,771,072.** That is about 46 MiB of memory
for one picture, more than a thousand times its file. The two course covers are 3,988 bytes on the
network and 3,840,000 in memory. And the 80-point thumbnail the list actually draws needs 230,400
bytes: the photograph decoded at its own size is 211 times what the screen can show of it.

A real photograph compresses far less than a solid colour, so its file would be a few megabytes rather
than forty kilobytes. **The decoded size would not change at all**: it depends on the pixels, not on
what is in them. Section 05 is how an app decodes only the pixels it needs.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l15-pixels\" aria-label=\"Three rectangles drawn to the same scale, each the pixel grid of a decoded picture. The largest, 4032 by 3024 pixels, is the phone photograph: 48,771,072 bytes decoded, from a 40,614-byte file. Beside it, a 1200 by 800 course cover: 3,840,000 bytes. In the photograph&#x27;s top-left corner, a small square of 240 by 240 pixels, the thumbnail an 80-point square needs on a 3x screen: 230,400 bytes.\"><defs><marker id=\"l15-pixels-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l15-pixels-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-pixels-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l15-pixels-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"400\" height=\"300\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">the photograph, 4032 x 3024</text><text x=\"230.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">48,771,072 bytes decoded</text><text x=\"230.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">from a file of 40,614</text><rect x=\"34\" y=\"34\" width=\"24\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><path d=\"M60 46.0 L100 46.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"104\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the thumbnail, 240 x 240</text><text x=\"104\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">230,400 bytes</text><rect x=\"470\" y=\"30\" width=\"119\" height=\"79\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"529.5\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a course cover</text><text x=\"529.5\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1200 x 800</text><text x=\"529.5\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3,840,000 bytes</text><text x=\"360\" y=\"346\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">one scale for all three: the area is the memory</text></svg>", "caption": "Memory follows the pixels, not the file. The square in the corner is everything the list's 80-point thumbnail needs of the photograph."}
```
