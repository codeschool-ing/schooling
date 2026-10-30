---
title: Downsampling, decodificar só o que a tela precisa
version: 1
---

**A correção para os números da seção 04 não é um download menor. É uma decodificação menor.** Uma
fotografia de 4032 por 3024 mostrada num quadrado de 80 pontos precisa de 240 por 240 pixels numa tela
3x, e um app que decodifica esses pixels e nenhum outro gasta 230.400 bytes em vez de 48.771.072. O
arquivo é o mesmo arquivo; só a decodificação muda.

O `AsyncImage` não faz isso. Ele decodifica no tamanho do arquivo e deixa o frame reduzir o resultado
para desenhar, o que é barato de desenhar e caro de segurar. **O trabalho tem de acontecer antes de a
`Image` existir**, com o framework que decodifica imagens nos sistemas da Apple, o ImageIO. Nada nesta
seção foi executado: o ImageIO faz parte dos SDKs da Apple e não do toolchain de código aberto. Ela foi
escrita a partir da documentação da Apple para `CGImageSourceCreateThumbnailAtIndex` e as opções dela,
lida em 30 de outubro de 2026.

## A função

```swift
// Downsample.swift
import ImageIO
import UIKit

/// Decode `data` at no more than `maxPixels` on its longer side.
func downsample(_ data: Data, maxPixels: Int) -> UIImage? {
    let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
    let options = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: maxPixels,
    ] as CFDictionary
    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
    return UIImage(cgImage: thumbnail)
}
```

Cada opção diz uma coisa específica. `ShouldCache: false` na origem diz ao ImageIO para não decodificar
a imagem inteira quando a abre. `ThumbnailMaxPixelSize` é o lado maior do resultado, em pixels.
`CacheImmediately` decodifica a imagem pequena agora, na thread que chamou a função, em vez de depois,
na thread principal, quando ela for desenhada pela primeira vez. `WithTransform` aplica a orientação da
fotografia, para uma imagem tirada em retrato não chegar deitada.

**O número a passar é o que a seção 04 calculou**, os pontos que a view ocupa vezes a escala da tela:
`pixels(points: 80, scale: 3)`, 240. Num Mac a escala da tela atual está no ambiente como
`displayScale`, e a função pertence ao código que carrega a capa, antes de qualquer coisa chegar a uma
view.

## Onde ela entra no planner

O downsampling é trabalho de CPU, e decodificar uma fotografia de 12 megapixels demora o bastante para
perder quadros se acontecer no main actor enquanto uma lista rola. Então ele roda onde o download
rodou, fora do main actor, e só o resultado pequeno passa para a view. No `ImageCache` da seção 06,
isso quer dizer que o cache guarda a imagem reduzida em vez dos bytes, e o custo dela é os 230.400 da
miniatura em vez dos 48.771.072 da fotografia. **O cache então guarda duzentas capas na memória que uma
fotografia ocupava.**
