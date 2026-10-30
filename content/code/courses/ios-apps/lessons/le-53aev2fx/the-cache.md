---
title: A cache the app controls
version: 1
---

**A list asks for the same picture many times, and a cache is what makes the second ask free.** The
planner's list draws a cover for every row, many rows share a course, and the same rows come back each
time the person scrolls up. Without a cache every one of those is a download and a decode. With one,
only the first is.

There are two caches an iPhone app can use, and they keep different things. **`URLCache` keeps
responses**, the bytes, on disk and in memory, following what the server's HTTP headers allow; it is
what makes the second download quick. **A memory cache of the app's own keeps decoded pictures**, ready
to draw, and it is what makes the second display free. `AsyncImage` on iOS 17 promises neither. This
section builds the second, in plain Swift, and runs it.

## The cache

Save this as `Sources/PlannerCore/ImageCache.swift`:

```schooling-example
{"language": "swift", "file": "Sources/PlannerCore/ImageCache.swift", "parts": [{"code": "// Sources/PlannerCore/ImageCache.swift\nimport Foundation\n#if canImport(FoundationNetworking)\nimport FoundationNetworking\n#endif\n\npublic actor ImageCache {\n    let session: URLSession\n    let memory = NSCache<NSString, NSData>()\n    var inFlight: [URL: Task<Data, any Error>] = [:]\n    public private(set) var downloads = 0\n\n    public init(costLimit: Int, session: URLSession = .shared) {\n        self.session = session\n        memory.totalCostLimit = costLimit\n    }\n\n", "note": "Three things kept by an actor, so that two rows asking at once cannot both see an empty cache and both start a download. `NSCache` is Foundation's memory cache: it evicts on its own when it passes `totalCostLimit`, or when the system runs short of memory. `inFlight` holds the downloads that have started and not finished."}, {"code": "    public func data(for url: URL) async throws -> Data {\n        let key = url.absoluteString as NSString\n        if let kept = memory.object(forKey: key) {\n            return kept as Data\n        }\n", "note": "The first place to look is memory. The key is the URL as text, because `NSCache` wants an object for its key."}, {"code": "        if let running = inFlight[url] {\n            return try await running.value\n        }\n", "note": "The second is a download already under way for the same URL. Awaiting its `Task` means the tenth row asking for `sql.png` waits for the first row's download instead of starting its own."}, {"code": "        let task = Task { try await session.data(from: url).0 }\n        inFlight[url] = task\n        downloads += 1\n        defer { inFlight[url] = nil }\n        let data = try await task.value\n        let size = pngSize(data) ?? (0, 0)\n        memory.setObject(data as NSData, forKey: key, cost: decodedBytes(width: size.width, height: size.height))\n        return data\n    }\n\n", "note": "Only then does a new download start. `inFlight` and `downloads` change before the first `await`, so no other caller can slip in between the look and the start. The cost given to `NSCache` is the decoded size from section 04, not the file's: that is the memory the picture will take once drawn."}, {"code": "    public func isKept(_ url: URL) -> Bool {\n        memory.object(forKey: url.absoluteString as NSString) != nil\n    }\n}\n", "note": "A way to ask, from outside, whether a picture is still held."}]}
```

On Linux the cache keeps the downloaded `Data`, since there is no image type to decode it into; in the
app it would keep the downsampled `UIImage` from section 05, at the cost of that small picture. The
structure does not change.

## Ten rows at once

Replace `Sources/covers/main.swift`. It asks for ten covers the way a list's first screen does, all at
the same moment, and then looks at what the cache kept. The limit is 50 MB of decoded pictures:

```swift
// Sources/covers/main.swift
import Foundation
import PlannerCore

let base = URL(string: "http://127.0.0.1:8015/covers/")!
let cache = ImageCache(costLimit: 50_000_000)       // 50 MB of decoded images

// Ten rows of a list appear at once, asking for three different covers.
let rows = ["sql", "mobile", "sql", "photo", "sql", "mobile", "sql", "mobile", "photo", "sql"]
try await withThrowingTaskGroup(of: Void.self) { group in
    for name in rows {
        group.addTask { _ = try await cache.data(for: base.appending(path: "\(name).png")) }
    }
    try await group.waitForAll()
}
print("\(rows.count) rows, \(await cache.downloads) downloads")

// What the cache still holds once all three are in.
for name in ["sql", "mobile", "photo"] {
    print(name, await cache.isKept(base.appending(path: "\(name).png")) ? "kept" : "evicted")
}
```

```
ana@vm:~/planner$ swift build | tail -1
Build complete! (2.97 secs)
ana@vm:~/planner$ .build/debug/covers
10 rows, 3 downloads
sql evicted
mobile evicted
photo kept
```

**Ten rows, three downloads.** Every row after the first for each cover found either the picture in
memory or the download already running, and waited for it. That is the in-flight dictionary at work:
without it, the five rows asking for `sql.png` in the same instant would each have seen an empty cache
and each started a download.

**And the photograph pushed the two covers out.** Its cost is 48,771,072 bytes, the two covers cost
3,840,000 each, and together they pass the 50,000,000 limit, so `NSCache` evicted. It chose to keep
the photograph and drop the two covers the list was showing ten times between them. `NSCache` decides
what to evict for itself, and Apple's documentation does not promise an order, so the lesson is not
which one went. It is that **one picture decoded at full size can empty a cache sized for a list**.
With section 05's downsampling, the photograph would cost 230,400 and all three would have fitted with
room for two hundred more.
