---
title: No fio
version: 1
---

**Uma mensagem de Protocol Buffers é uma sequência de campos, e cada campo é uma tag seguida de um
valor.** A tag junta o número do campo e o seu **tipo de fio**, que diz a quem lê o tamanho do valor.
Não há nomes, nem aspas, nem chaves, nem vírgulas. Tudo o mais de que o leitor precisa ele traz da
própria cópia do `.proto`.

O `protoc`, o compilador que a aula 1 instalou, consegue codificar uma mensagem escrita no formato de
texto do Protocol Buffers. Escreva o nível de estoque de Dom Casmurro como texto, codifique com o
`stock.proto` e olhe os bytes com o `od`, que imprime cada um em hexadecimal:

```
ana@api:~/shelf$ echo 'isbn: "9786500000016" title: "Dom Casmurro" copies: 12 availability: IN_STOCK' > dom.txt
ana@api:~/shelf$ protoc --encode=shelf.stock.v1.StockLevel stock.proto < dom.txt > dom.bin
ana@api:~/shelf$ od -An -tx1 dom.bin
 0a 0d 39 37 38 36 35 30 30 30 30 30 30 31 36 12
 0c 44 6f 6d 20 43 61 73 6d 75 72 72 6f 18 0c 20
 01
```

Trinta e três bytes, e a figura abaixo os separa campo por campo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Os 33 bytes de um StockLevel em quatro linhas, uma por campo. Campo 1, isbn: tag 0a, comprimento 0d, depois 13 bytes de dígitos. Campo 2, title: tag 12, comprimento 0c, depois 12 bytes que soletram Dom Casmurro. Campo 3, copies: tag 18, depois o varint 0c, que é 12. Campo 4, availability: tag 20, depois 01, que é IN_STOCK.\"><rect x=\"18\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"29.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0a</text><rect x=\"40\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"51.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0d</text><rect x=\"62\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"73.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">39</text><rect x=\"84\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">37</text><rect x=\"106\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"117.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">38</text><rect x=\"128\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"139.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">36</text><rect x=\"150\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"161.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">35</text><rect x=\"172\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"183.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"194\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"216\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"227.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"238\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"249.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"260\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"271.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"282\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"293.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">30</text><rect x=\"304\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">31</text><rect x=\"326\" y=\"26\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"337.0\" y=\"38.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">36</text><text x=\"62\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&quot;9786500000016&quot;</text><text x=\"400\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">isbn</text><text x=\"400\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">campo 1 · tipo 2</text><text x=\"560\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seguem 13 bytes</text><rect x=\"18\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"29.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12</text><rect x=\"40\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"51.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0c</text><rect x=\"62\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"73.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">44</text><rect x=\"84\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6f</text><rect x=\"106\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"117.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6d</text><rect x=\"128\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"139.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">20</text><rect x=\"150\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"161.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">43</text><rect x=\"172\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"183.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">61</text><rect x=\"194\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"205.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">73</text><rect x=\"216\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"227.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6d</text><rect x=\"238\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"249.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">75</text><rect x=\"260\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"271.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">72</text><rect x=\"282\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"293.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">72</text><rect x=\"304\" y=\"88\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"315.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6f</text><text x=\"62\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">&quot;Dom Casmurro&quot;</text><text x=\"400\" y=\"94\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">title</text><text x=\"400\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">campo 2 · tipo 2</text><text x=\"560\" y=\"110\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">seguem 12 bytes</text><rect x=\"18\" y=\"150\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"29.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">18</text><rect x=\"40\" y=\"150\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"51.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0c</text><text x=\"40\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">12</text><text x=\"400\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">copies</text><text x=\"400\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">campo 3 · tipo 0</text><text x=\"560\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um varint</text><rect x=\"18\" y=\"212\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"29.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">20</text><rect x=\"40\" y=\"212\" width=\"22\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"51.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">01</text><text x=\"40\" y=\"248\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--phosphor)\">1 = IN_STOCK</text><text x=\"400\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">availability</text><text x=\"400\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">campo 4 · tipo 0</text><text x=\"560\" y=\"234\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um varint</text><rect x=\"18\" y=\"274\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"38\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tag: número do campo e tipo</text><rect x=\"250\" y=\"274\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"270\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">comprimento</text><rect x=\"360\" y=\"274\" width=\"14\" height=\"14\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"380\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">valor</text><text x=\"702\" y=\"282\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os nomes à direita vêm do stock.proto</text></svg>", "caption": "Os 33 bytes que o protoc escreveu para Dom Casmurro, uma linha por campo. Nada neles diz isbn ou title: quem lê traz esses nomes da própria cópia do stock.proto."}
```

## Lendo uma tag à mão

A tag tem um byte aqui, porque todo número de campo é menor que 16. **Os três bits mais baixos são o
tipo de fio, e o resto é o número do campo.** O primeiro byte é `0a`:

```localised
0a = 00001010
     00001        campo número 1: os bits acima dos três últimos
          010     tipo de fio 2: os três últimos bits
```

O tipo de fio 2 quer dizer "vem um comprimento, depois essa quantidade de bytes", então `0d` diz que
seguem 13 bytes, e eles são os treze dígitos do ISBN como texto: `39` é o caractere `9`. A tag
seguinte, `12`, é o campo 2 com o mesmo tipo de fio, e doze bytes soletram `Dom Casmurro`. Depois,
`18` é o campo 3 com tipo de fio 0, um varint, e `20` é o campo 4, também um varint.

| tipo de fio | quer dizer | usado para |
|---|---|---|
| 0 | um varint | `int32`, `int64`, `bool`, enums |
| 1 | oito bytes | `double`, `fixed64` |
| 2 | um comprimento, depois essa quantidade de bytes | `string`, `bytes`, mensagens, `repeated` empacotado |
| 5 | quatro bytes | `float`, `fixed32` |

## Lendo um varint à mão

**Um varint gasta sete bits de cada byte com o número e o oitavo para dizer se vem mais um byte.**
Doze exemplares cabem num byte, `0c`. Trezentos não cabem:

```
ana@api:~/shelf$ echo 'copies: 300' | protoc --encode=shelf.stock.v1.StockLevel stock.proto | od -An -tx1
 18 ac 02
```

Depois da tag `18` vêm `ac 02`. Os sete bits mais baixos vêm primeiro:

```localised
ac = 1 0101100    bit de cima 1: vem outro byte      0101100 = 44
02 = 0 0000010    bit de cima 0: este é o último     0000010 = 2, que vale 2 × 128
                                                     44 + 256 = 300
```

É por isso que números pequenos saem baratos e um `int32` negativo não: o complemento de dois liga o
bit de cima, e o varint vai até os seus dez bytes inteiros.

## Com o schema e sem ele

O `--decode` lê os bytes com o `stock.proto`; o `--decode_raw` lê sem nada:

```
ana@api:~/shelf$ protoc --decode=shelf.stock.v1.StockLevel stock.proto < dom.bin
isbn: "9786500000016"
title: "Dom Casmurro"
copies: 12
availability: IN_STOCK
ana@api:~/shelf$ protoc --decode_raw < dom.bin
1: "9786500000016"
2: "Dom Casmurro"
3: 12
4: 1
```

**Sem o schema os nomes somem, e o enum é só o número 1.** Essa segunda saída é o que um estranho vê
numa captura do seu tráfego, e o que você vê nos seus próprios logs se registrar os bytes. Dá para
depurar com ela quando o `.proto` está aberto ao lado, e nada que se compare ao JSON da aula 1, que
se explicava sozinho para quem o lesse.

## Quanto menor

Os mesmos quatro valores em JSON, compactados pelo `jq` sem espaços e sem a quebra de linha final,
contra o arquivo de Protocol Buffers:

```
ana@api:~/shelf$ wc -c < dom.bin
33
ana@api:~/shelf$ echo '{"isbn": "9786500000016", "title": "Dom Casmurro", "copies": 12, "availability": "IN_STOCK"}' | jq -cj . | wc -c
85
```

85 bytes contra 33. **Quase toda a diferença são os nomes**: `isbn`, `title`, `copies` e
`availability` com as aspas somam 35 bytes sozinhos, e `"IN_STOCK"` ocupa dez bytes onde o enum
ocupa um. Os valores em si, o ISBN e o título, custam o mesmo nos dois. Mensagens menores ajudam,
mas não são o motivo mais forte para escolher gRPC, e a seção sobre a escolha diz qual é.
