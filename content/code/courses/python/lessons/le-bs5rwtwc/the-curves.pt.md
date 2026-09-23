---
title: Cinco formas, em mil e em um milhão
version: 2
---

| | n = 1.000 | n = 1.000.000 |
| --- | --- | --- |
| **O(1)** | 1 | 1 |
| **O(log n)** | 10 | 20 |
| **O(n)** | 1.000 | 1.000.000 |
| **O(n log n)** | 9.966 | 19.931.569 |
| **O(n²)** | 1.000.000 | 1.000.000.000.000 |

**Leia a última linha.** Um laço dentro de um laço sobre um milhão de itens é um milhão de milhões
de operações. Um laço de acumulação pelado nesta máquina roda cerca de dez milhões de iterações
por segundo, então isso dá uns noventa e quatro mil segundos — **pouco mais de um dia**, para um
relatório.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 244\" role=\"img\" aria-label=\"Cinco painéis, um por classe de crescimento, cada um desenhado na própria altura para que o que difere entre eles seja a forma. Uma constante é plana, um logaritmo sobe e quase para, um custo linear é uma reta, e um quadrático é quase plano até não ser mais.\"> <text x=\"360\" y=\"22\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">com n = 1.000.000</text> <rect x=\"16\" y=\"34\" width=\"128\" height=\"110\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <path d=\"M26 134 L134 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path> <path d=\"M26.0 44.0 L28.7 44.0 L31.4 44.0 L34.1 44.0 L36.8 44.0 L39.5 44.0 L42.2 44.0 L44.9 44.0 L47.6 44.0 L50.3 44.0 L53.0 44.0 L55.7 44.0 L58.4 44.0 L61.1 44.0 L63.8 44.0 L66.5 44.0 L69.2 44.0 L71.9 44.0 L74.6 44.0 L77.3 44.0 L80.0 44.0 L82.7 44.0 L85.4 44.0 L88.1 44.0 L90.8 44.0 L93.5 44.0 L96.2 44.0 L98.9 44.0 L101.6 44.0 L104.3 44.0 L107.0 44.0 L109.7 44.0 L112.4 44.0 L115.1 44.0 L117.8 44.0 L120.5 44.0 L123.2 44.0 L125.9 44.0 L128.6 44.0 L131.3 44.0 L134.0 44.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path> <text x=\"80\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">O(1)</text> <text x=\"80\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1</text> <rect x=\"156\" y=\"34\" width=\"128\" height=\"110\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <path d=\"M166 134 L274 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path> <path d=\"M166.0 134.0 L168.7 126.1 L171.4 119.5 L174.1 113.8 L176.8 108.9 L179.5 104.5 L182.2 100.6 L184.9 97.0 L187.6 93.8 L190.3 90.7 L193.0 87.9 L195.7 85.3 L198.4 82.9 L201.1 80.6 L203.8 78.4 L206.5 76.3 L209.2 74.4 L211.9 72.5 L214.6 70.7 L217.3 69.0 L220.0 67.4 L222.7 65.8 L225.4 64.3 L228.1 62.8 L230.8 61.4 L233.5 60.1 L236.2 58.8 L238.9 57.5 L241.6 56.3 L244.3 55.1 L247.0 54.0 L249.7 52.8 L252.4 51.8 L255.1 50.7 L257.8 49.7 L260.5 48.7 L263.2 47.7 L265.9 46.7 L268.6 45.8 L271.3 44.9 L274.0 44.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path> <text x=\"220\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">O(log n)</text> <text x=\"220\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">20</text> <rect x=\"296\" y=\"34\" width=\"128\" height=\"110\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <path d=\"M306 134 L414 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path> <path d=\"M306.0 134.0 L308.7 131.8 L311.4 129.5 L314.1 127.2 L316.8 125.0 L319.5 122.8 L322.2 120.5 L324.9 118.2 L327.6 116.0 L330.3 113.8 L333.0 111.5 L335.7 109.2 L338.4 107.0 L341.1 104.8 L343.8 102.5 L346.5 100.2 L349.2 98.0 L351.9 95.8 L354.6 93.5 L357.3 91.2 L360.0 89.0 L362.7 86.8 L365.4 84.5 L368.1 82.2 L370.8 80.0 L373.5 77.8 L376.2 75.5 L378.9 73.2 L381.6 71.0 L384.3 68.8 L387.0 66.5 L389.7 64.2 L392.4 62.0 L395.1 59.8 L397.8 57.5 L400.5 55.2 L403.2 53.0 L405.9 50.8 L408.6 48.5 L411.3 46.2 L414.0 44.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path> <text x=\"360\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">O(n)</text> <text x=\"360\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1.000.000</text> <rect x=\"436\" y=\"34\" width=\"128\" height=\"110\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <path d=\"M446 134 L554 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path> <path d=\"M446.0 134.0 L448.7 133.8 L451.4 133.3 L454.1 132.5 L456.8 131.5 L459.5 130.3 L462.2 129.0 L464.9 127.5 L467.6 126.0 L470.3 124.3 L473.0 122.5 L475.7 120.6 L478.4 118.7 L481.1 116.6 L483.8 114.5 L486.5 112.4 L489.2 110.1 L491.9 107.9 L494.6 105.5 L497.3 103.1 L500.0 100.7 L502.7 98.2 L505.4 95.7 L508.1 93.1 L510.8 90.5 L513.5 87.8 L516.2 85.1 L518.9 82.4 L521.6 79.6 L524.3 76.8 L527.0 74.0 L529.7 71.1 L532.4 68.2 L535.1 65.3 L537.8 62.3 L540.5 59.3 L543.2 56.3 L545.9 53.3 L548.6 50.2 L551.3 47.1 L554.0 44.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path> <text x=\"500\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">O(n log n)</text> <text x=\"500\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">19.931.569</text> <rect x=\"576\" y=\"34\" width=\"128\" height=\"110\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\"></rect> <path d=\"M586 134 L694 44\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path> <path d=\"M586.0 134.0 L588.7 133.9 L591.4 133.8 L594.1 133.5 L596.8 133.1 L599.5 132.6 L602.2 132.0 L604.9 131.2 L607.6 130.4 L610.3 129.4 L613.0 128.4 L615.7 127.2 L618.4 125.9 L621.1 124.5 L623.8 123.0 L626.5 121.3 L629.2 119.6 L631.9 117.7 L634.6 115.8 L637.3 113.7 L640.0 111.5 L642.7 109.2 L645.4 106.8 L648.1 104.2 L650.8 101.6 L653.5 98.8 L656.2 96.0 L658.9 93.0 L661.6 89.9 L664.3 86.7 L667.0 83.4 L669.7 79.9 L672.4 76.4 L675.1 72.7 L677.8 69.0 L680.5 65.1 L683.2 61.1 L685.9 57.0 L688.6 52.8 L691.3 48.4 L694.0 44.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path> <text x=\"640\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">O(n²)</text> <text x=\"640\" y=\"188\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">1.000.000.000.000</text> <text x=\"360\" y=\"212\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">Leia o último. Um laço dentro de um laço sobre um milhão de itens é um milhão de milhões de operações,</text> <text x=\"360\" y=\"229\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">que numa máquina que faz dez milhões por segundo é pouco mais de um dia — para um relatório.</text> </svg>", "caption": "Cada painel é desenhado na própria altura e carrega a mesma reta, então o que se compara é o quanto cada forma se afasta dela."}
```

## Como cada uma parece em código

```python
d[key]                          # O(1)     one step, whatever the size
bisect.bisect(sorted_data, x)   # O(log n) halve, halve, halve
for row in rows: ...            # O(n)     one pass
sorted(rows)                    # O(n log n)
for a in rows:
    for b in rows: ...          # O(n²)    a pass per item
```

## `O(log n)` é a que parece errada

```sh
n = 1,000        10 steps
n = 1,000,000    20 steps
n = 1,000,000,000  30 steps
```

Mil vezes mais dados e dez passos a mais. É isso que dividir ao meio faz, e é por isso que todo
índice, toda árvore balanceada e toda busca binária são construídos em volta disso. **`O(log n)` é
perto o bastante de grátis** para a diferença entre ele e `O(1)` quase nunca decidir nada.

## `O(n log n)` é o que ordenar custa

```sh
sorted, n =   1,000    0.088 ms
sorted, n =  10,000    1.277 ms      ← 10× the data, 14× the time
sorted, n = 100,000   18.112 ms      ← 10× the data, 14× the time
```

Medido. Dez vezes os dados custam cerca de catorze vezes o trabalho, toda vez — que é exatamente o
que `n log n` prevê e o que um custo linear não faria.

**Ordenar é barato o bastante para recorrer a ele.** Se ordenar os dados antes transforma uma
busca `O(n²)` numa passagem `O(n)`, ordenar saiu de graça por comparação.

## E as que passam de `O(n²)`

`O(2ⁿ)` e `O(n!)` existem — todo subconjunto, toda ordenação — e são inutilizáveis acima de uns
vinte e de uns dez respectivamente. Se você escreveu uma, em geral sabe; o perigo em código comum
é o `O(n²)`, porque ele funciona bem nos dados de teste.
