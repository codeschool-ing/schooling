---
title: Quanto uma imagem custa na memória
version: 1
---

**O tamanho de uma imagem na rede e o tamanho dela na memória são números diferentes, e é o segundo
que esgota a memória de um telefone.** Um PNG ou um JPEG é comprimido; para desenhá-lo, o sistema o
decodifica numa grade de pixels, quatro bytes cada, vermelho, verde, azul e transparência. O arquivo
pode ser minúsculo e a grade, enorme. Nada na linha única do `AsyncImage` diz qual dos dois você está
segurando.

Esta seção mede os dois, com três capas pequenas o bastante para fazer na sua própria máquina.

## Imagens para medir

As capas são feitas por um programa Python em vez de baixadas, para você ter exatamente estas três.
Cada uma é uma cor só, que comprime quase a nada, e isso é de propósito: deixa a distância entre os
dois números a maior possível. Salve isto como `make_covers.py` num diretório novo, `~/images`:

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

A terceira tem o tamanho de uma fotografia da câmera principal de um iPhone recente, 4032 por 3024.
Rode o programa, e sirva o diretório com o servidor web que vem com o Python, numa porta própria e
num terminal próprio:

```
ana@vm:~/images$ python3 make_covers.py
mobile.png 3987 bytes
photo.png 40614 bytes
sql.png 3988 bytes
ana@vm:~/images$ python3 -m http.server 8015 --bind 127.0.0.1
Serving HTTP on 127.0.0.1 port 8015 (http://127.0.0.1:8015/) ...
```

## Lendo o tamanho sem decodificar

Decodificar precisa de uma biblioteca gráfica que esta máquina Linux não tem, e não é preciso para
saber a resposta: um PNG declara a largura e a altura nos primeiros 24 bytes do arquivo. Salve isto
como `Sources/PlannerCore/ImageSize.swift` no pacote do planner:

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

O `decodedBytes` é a aritmética inteira: largura vezes altura vezes quatro. O `pixels` transforma os
pontos em que um layout fala nos pixels que uma tela tem, já que uma tela 3x desenha cada ponto como
um quadrado de nove pixels.

Agora um programa que baixa cada capa e imprime os dois números, e depois quanto custa uma miniatura:
a lista da seção 02 desenha cada capa num quadrado de 80 pontos. O pacote ganha um quarto programa,
`covers`. Troque o `Package.swift` por este, o da aula 14 com mais uma linha:

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

E salve isto como `Sources/covers/main.swift`:

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

**A fotografia foi baixada com 40.614 bytes e decodifica em 48.771.072.** São cerca de 46 MiB de
memória para uma imagem, mais de mil vezes o arquivo dela. As duas capas de curso têm 3.988 bytes na
rede e 3.840.000 na memória. E a miniatura de 80 pontos que a lista de fato desenha precisa de 230.400
bytes: a fotografia decodificada no próprio tamanho é 211 vezes o que a tela consegue mostrar dela.

Uma fotografia de verdade comprime bem menos que uma cor só, então o arquivo dela teria alguns
megabytes em vez de quarenta kilobytes. **O tamanho decodificado não mudaria nada**: ele depende dos
pixels, não do que há neles. A seção 05 mostra como um app decodifica só os pixels de que precisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" data-fig=\"l15-pixels\" aria-label=\"Três retângulos desenhados na mesma escala, cada um a grade de pixels de uma imagem decodificada. O maior, de 4032 por 3024 pixels, é a fotografia do telefone: 48.771.072 bytes decodificada, a partir de um arquivo de 40.614 bytes. Ao lado, uma capa de curso de 1200 por 800: 3.840.000 bytes. No canto superior esquerdo da fotografia, um quadrado pequeno de 240 por 240 pixels, a miniatura de que um quadrado de 80 pontos precisa numa tela 3x: 230.400 bytes.\"><defs><marker id=\"l15-pixels-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l15-pixels-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-pixels-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l15-pixels-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"30\" width=\"400\" height=\"300\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">a fotografia, 4032 x 3024</text><text x=\"230.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">48.771.072 bytes decodificada</text><text x=\"230.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">de um arquivo de 40.614</text><rect x=\"34\" y=\"34\" width=\"24\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><path d=\"M60 46.0 L100 46.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"104\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a miniatura, 240 x 240</text><text x=\"104\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">230.400 bytes</text><rect x=\"470\" y=\"30\" width=\"119\" height=\"79\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"529.5\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma capa de curso</text><text x=\"529.5\" y=\"141\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1200 x 800</text><text x=\"529.5\" y=\"157\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3.840.000 bytes</text><text x=\"360\" y=\"346\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma escala só para os três: a área é a memória</text></svg>", "caption": "A memória segue os pixels, não o arquivo. O quadrado no canto é tudo o que a miniatura de 80 pontos da lista precisa da fotografia."}
```
