---
title: Os quatro lado a lado
version: 1
---

Cinco versões de uma API estão agora em `~/fw`. Três números se leem de cada uma com comandos que
você já conhece: as linhas não vazias do `main.go`, os módulos no grafo de módulos dela (o `go list
-m all` conta também o módulo do próprio programa) e o tamanho do binário em bytes.

```
ana@vm:~/fw/std$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
75
1
9807673
ana@vm:~/fw/gin$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
62
56
31606863
ana@vm:~/fw/echo$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
64
9
11094543
ana@vm:~/fw/fiber$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
60
26
15285110
ana@vm:~/fw/beego$ grep -c . main.go; go list -m all | wc -l; ls -l server | cut -d" " -f5
73
103
21684349
```

| | linhas | módulos além do seu | binário |
|---|---|---|---|
| biblioteca padrão | 75 | 0 | 9,8 MB |
| Gin | 62 | 55 | 31,6 MB |
| Echo | 64 | 8 | 11,1 MB |
| Fiber | 60 | 25 | 15,3 MB |
| Beego | 73 | 102 | 21,7 MB |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Dois gráficos de barras lado a lado para as cinco versões. Tamanho do binário: biblioteca padrão 9,8 MB, Gin 31,6, Echo 11,1, Fiber 15,3, Beego 21,7. Módulos além do próprio programa: biblioteca padrão 0, Gin 55, Echo 8, Fiber 25, Beego 102.\"><defs><marker id=\"gb-l4-weight-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"240\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">binário, MB</text><text x=\"545\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">módulos além do seu</text><text x=\"120\" y=\"52\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">biblioteca padrão</text><rect x=\"130\" y=\"40\" width=\"62.1\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"198.1\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">9,8</text><rect x=\"440\" y=\"40\" width=\"1\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"447\" y=\"52\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"120\" y=\"92\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Gin</text><rect x=\"130\" y=\"80\" width=\"200.0\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"336.0\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">31,6</text><rect x=\"440\" y=\"80\" width=\"107.8\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"553.8\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">55</text><text x=\"120\" y=\"132\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Echo</text><rect x=\"130\" y=\"120\" width=\"70.2\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"206.2\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">11,1</text><rect x=\"440\" y=\"120\" width=\"15.7\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"461.7\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">8</text><text x=\"120\" y=\"172\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Fiber</text><rect x=\"130\" y=\"160\" width=\"96.7\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"232.7\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">15,3</text><rect x=\"440\" y=\"160\" width=\"49.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"495.0\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">25</text><text x=\"120\" y=\"212\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Beego</text><rect x=\"130\" y=\"200\" width=\"137.2\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></rect><text x=\"273.2\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">21,7</text><rect x=\"440\" y=\"200\" width=\"200.0\" height=\"24\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"646.0\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">102</text></svg>", "caption": "A mesma API cinco vezes. As linhas de código quase não mudam; o binário e os módulos que vêm com ele, sim.", "same": ["Gin", "Echo", "Fiber", "Beego"]}
```

**As linhas quase não diferem.** Um framework economiza umas doze linhas aqui, quase todas dos dois
utilitários que escrevem JSON, e a versão da biblioteca padrão é a mais longa por essa margem. Numa
API de quarenta rotas a economia cresce com as rotas, e o código que os frameworks trazem também.

**As dependências diferem em duas ordens de grandeza.** Cada um desses módulos é código que roda
dentro do seu processo, que precisa ser atualizado quando tem uma vulnerabilidade, e cuja licença a
sua organização talvez precise aprovar. O `go.mod` do Gin nomeia 31 desses módulos diretamente, e
eles explicam a contagem: uma biblioteca para cada formato que o binding dele lê além de JSON (YAML,
TOML, MessagePack, BSON, Protocol Buffers), três codificadores JSON alternativos com que ele pode ser
compilado, e uma implementação de HTTP/3. Os tamanhos de binário acompanham, e um binário três vezes
maior é uma imagem de container três vezes maior para enviar e baixar.

## Como cada um respondeu às mesmas seis perguntas

| pergunta | biblioteca padrão | Gin | Echo | Fiber | Beego |
|---|---|---|---|---|---|
| método errado | 405, `Allow: GET, HEAD` | **404** | 405, `Allow: OPTIONS, GET`, JSON | 405, `Allow: GET, HEAD` | **404, página HTML** |
| caminho desconhecido | 404, texto | 404, texto | 404, JSON | 404, texto | 404, página HTML |
| valor inválido | a verificação do handler | **tags do validator**, nomes de campos Go na mensagem | a verificação do handler | a verificação do handler | a verificação do handler |
| tipo errado | a mensagem do `encoding/json` | a mensagem do `encoding/json` | **só `Bad Request`**, detalhe no log | a mensagem, como texto | a mensagem do `encoding/json` |
| log de acesso | nenhum | ligado por padrão | um middleware que você acrescenta, JSON | um middleware que você acrescenta | só na subida |
| roda sobre `net/http` | sim | sim | sim | **não, fasthttp** | sim |

Nada disso está errado, e cada item é uma decisão tomada em seu nome. **O 404 do Gin para método
errado, o detalhe escondido do Echo e a página HTML do Beego são padrões**, e cada um é mudado por
quem sabe que ele existe. Esse é o custo de verdade de um framework, e a aula 5 o pesa contra o que
ele economiza: não os bytes, mas o número de comportamentos do seu serviço que você não escolheu.

## Qual, se algum

Se o time já usa um, use esse: consistência dentro de uma base de código vale mais que qualquer linha
da tabela acima. Começando do zero, o resumo honesto desta aula é curto. **Echo e Gin são `net/http`
por baixo e fáceis de largar**; o Echo traz menos coisa junto, e o Gin mais gente conhece. **O Fiber
combina com quem vem do Express e com serviços em que se mediu que a velocidade dele importa**, e
pede que você viva fora do `net/http`. **O Beego combina com um time que quer a pilha inteira
escolhida por ele**, e é o que mais custa para mudar de ideia. E a primeira coluna é o assunto da
aula 5.
