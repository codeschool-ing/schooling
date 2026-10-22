---
title: Tamanhos, alinhamento e o preenchimento entre campos
version: 1
---

A imagem comum de uma struct é uma fileira de campos encostados um no outro, de modo que o tamanho
dela seja a soma dos deles. **O compilador muitas vezes deixa lacunas entre os campos, e o `unsafe`
tem três funções que mostram onde elas estão.** `unsafe.Sizeof` responde quantos bytes um valor
ocupa, `unsafe.Alignof` em que endereços ele pode começar, e `unsafe.Offsetof` onde, dentro da
struct, um campo começa. Elas não leem memória nem escrevem nela. **Cada chamada é uma constante
que o compilador calcula enquanto monta o programa**, o que faz delas o único canto do pacote que
não tem como corromper nada; elas moram no `unsafe` porque as respostas dependem da máquina para a
qual o programa é compilado, como a seção 05 mostra.

Esta lição trabalha em `~/unsafe`, um módulo chamado `example.com/hits` com cópias de dois arquivos
da lição 1: o pacote `tally` e o `genlog`. Ponha ali `internal/tally/tally.go` e
`tools/genlog/main.go` como a lição 1 os imprime, e rode `go mod init example.com/hits` no
diretório. O primeiro programa mede `tally.Entry` e duas structs que guardam os mesmos cinco campos
em ordens diferentes. Salve-o como `layout/main.go`:

```schooling-example
{
  "language": "go",
  "file": "layout/main.go",
  "parts": [
    {
      "code": "// Command layout prints where the compiler puts the fields of three structs,\n// and what a million of two of them cost on the heap.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"runtime\"\n\t\"unsafe\"\n\n\t\"example.com/hits/internal/tally\"\n)\n",
      "note": "Um programa próprio no módulo que guarda uma cópia do `tally` da lição 1. **Importar `unsafe` é toda a cerimônia**: nenhuma flag, nenhuma tag de build, nenhum aviso do compilador."
    },
    {
      "code": "// Loose is what a request did, in the order somebody thought of it.\ntype Loose struct {\n\tCached bool\n\tBytes  int64\n\tTLS    bool\n\tStatus int32\n\tRetry  bool\n}\n",
      "note": "Cinco campos que somam 15 bytes: três `bool`s de um byte, um `int32` de quatro e um `int64` de oito. A ordem é a ordem em que uma pessoa os listaria."
    },
    {
      "code": "// Tight holds the same five fields, largest first.\ntype Tight struct {\n\tBytes  int64\n\tStatus int32\n\tCached bool\n\tTLS    bool\n\tRetry  bool\n}\n",
      "note": "**Os mesmos campos, do maior alinhamento para o menor.** Nada mais muda: um programa que use `Tight` no lugar de `Loose` lê e escreve os mesmos nomes."
    },
    {
      "code": "func row(name string, off, size uintptr) {\n\tfmt.Printf(\"  %-9s offset %2d  size %2d\\n\", name, off, size)\n}\n",
      "note": "As três funções devolvem um `uintptr`, o tipo inteiro grande o bastante para guardar um endereço. Aqui ele é só uma contagem de bytes."
    },
    {
      "code": "func main() {\n\tvar e tally.Entry\n\tfmt.Printf(\"tally.Entry  size %d  align %d\\n\", unsafe.Sizeof(e), unsafe.Alignof(e))\n\trow(\"Time\", unsafe.Offsetof(e.Time), unsafe.Sizeof(e.Time))\n\trow(\"Method\", unsafe.Offsetof(e.Method), unsafe.Sizeof(e.Method))\n\trow(\"Path\", unsafe.Offsetof(e.Path), unsafe.Sizeof(e.Path))\n\trow(\"Status\", unsafe.Offsetof(e.Status), unsafe.Sizeof(e.Status))\n\trow(\"Duration\", unsafe.Offsetof(e.Duration), unsafe.Sizeof(e.Duration))\n",
      "note": "`unsafe.Offsetof` recebe um seletor de campo, `e.Time`, e responde a quantos bytes do começo da struct esse campo começa."
    },
    {
      "code": "\tvar l Loose\n\tfmt.Printf(\"Loose        size %d  align %d\\n\", unsafe.Sizeof(l), unsafe.Alignof(l))\n\trow(\"Cached\", unsafe.Offsetof(l.Cached), unsafe.Sizeof(l.Cached))\n\trow(\"Bytes\", unsafe.Offsetof(l.Bytes), unsafe.Sizeof(l.Bytes))\n\trow(\"TLS\", unsafe.Offsetof(l.TLS), unsafe.Sizeof(l.TLS))\n\trow(\"Status\", unsafe.Offsetof(l.Status), unsafe.Sizeof(l.Status))\n\trow(\"Retry\", unsafe.Offsetof(l.Retry), unsafe.Sizeof(l.Retry))\n\n\tvar t Tight\n\tfmt.Printf(\"Tight        size %d  align %d\\n\", unsafe.Sizeof(t), unsafe.Alignof(t))\n\trow(\"Bytes\", unsafe.Offsetof(t.Bytes), unsafe.Sizeof(t.Bytes))\n\trow(\"Status\", unsafe.Offsetof(t.Status), unsafe.Sizeof(t.Status))\n\trow(\"Cached\", unsafe.Offsetof(t.Cached), unsafe.Sizeof(t.Cached))\n\trow(\"TLS\", unsafe.Offsetof(t.TLS), unsafe.Sizeof(t.TLS))\n\trow(\"Retry\", unsafe.Offsetof(t.Retry), unsafe.Sizeof(t.Retry))\n"
    },
    {
      "code": "\tconst n = 1_000_000\n\tlb := grown(func() { looseSink = make([]Loose, n) })\n\ttb := grown(func() { tightSink = make([]Tight, n) })\n\tfmt.Printf(\"%d Loose  %d bytes\\n\", n, lb)\n\tfmt.Printf(\"%d Tight  %d bytes\\n\", n, tb)\n}\n",
      "note": "A mesma pergunta feita ao heap: um slice de um milhão de cada, e quantos bytes o alocador entregou para montá-lo."
    },
    {
      "code": "// Package variables keep both slices alive until main returns.\nvar (\n\tlooseSink []Loose\n\ttightSink []Tight\n)\n\n// grown reports how many bytes the heap handed out while f ran.\nfunc grown(f func()) uint64 {\n\tvar before, after runtime.MemStats\n\truntime.ReadMemStats(&before)\n\tf()\n\truntime.ReadMemStats(&after)\n\treturn after.TotalAlloc - before.TotalAlloc\n}",
      "note": "`runtime.ReadMemStats` antes e depois: `TotalAlloc` só cresce, então a diferença é o que `f` alocou, faça o coletor o que fizer no meio-tempo. A lição 19 trata do heap e do coletor de onde vêm esses números."
    }
  ]
}
```

E rode:

```
ana@vm:~/unsafe$ go run ./layout
tally.Entry  size 72  align 8
  Time      offset  0  size 24
  Method    offset 24  size 16
  Path      offset 40  size 16
  Status    offset 56  size  8
  Duration  offset 64  size  8
Loose        size 32  align 8
  Cached    offset  0  size  1
  Bytes     offset  8  size  8
  TLS       offset 16  size  1
  Status    offset 20  size  4
  Retry     offset 24  size  1
Tight        size 16  align 8
  Bytes     offset  0  size  8
  Status    offset  8  size  4
  Cached    offset 12  size  1
  TLS       offset 13  size  1
  Retry     offset 14  size  1
1000000 Loose  32010416 bytes
1000000 Tight  16007168 bytes
```

## De onde vem o preenchimento

`tally.Entry` tem 72 bytes e seus campos somam 72: um `time.Time` de 24, duas strings de 16 (um
ponteiro e um tamanho cada), um `int` e um `time.Duration` de 8. Cada campo começa onde o anterior
terminou. **Isso é sorte, não regra**, e `Loose` mostra a regra.

**Um campo cujo alinhamento é k começa num deslocamento múltiplo de k.** Nesta máquina um `int64`
tem alinhamento 8, um `int32` tem 4 e um `bool` tem 1; então, depois do único byte de `Cached`, o
compilador pula sete bytes para pôr `Bytes` no deslocamento 8. `TLS` fica no 16, três bytes são
pulados para `Status` ficar no 20, e `Retry` cai no 24. Quinze bytes de campos já ocupam 25 bytes.
**O tamanho da struct é então arredondado para um múltiplo do alinhamento dela**, que é o maior
alinhamento entre seus campos, 8, e `Loose` termina em 32: os sete bytes depois de `Retry` também
são dela. Eles existem para que, num slice de valores `Loose`, o `Bytes` do elemento seguinte também
caia num múltiplo de 8.

`Tight` põe o maior primeiro. `Bytes` no 0, `Status` no 8, e os três `bool`s no 12, 13 e 14, que
não precisam de alinhamento nenhum. Quinze bytes de campos arredondam para 16. **Mesmos campos,
mesmos nomes, metade da memória**, e as lacunas estão onde o compilador as pôs:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas structs desenhadas em linhas de oito bytes. Loose ocupa quatro linhas, 32 bytes: Cached no byte 0 e sete bytes de preenchimento, Bytes nos bytes 8 a 15, TLS no 16 e três bytes de preenchimento, Status do 20 ao 23, Retry no 24 e sete bytes de preenchimento até o fim. Tight ocupa duas linhas, 16 bytes: Bytes de 0 a 7, Status de 8 a 11, Cached, TLS e Retry em 12, 13 e 14, e um byte de preenchimento.\"><text x=\"44.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Loose</text><text x=\"44.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">32 bytes, 17 deles de preenchimento</text><text x=\"62.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"98.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"134.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"170.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"206.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"242.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"278.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"314.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"36.0\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"36.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><text x=\"36.0\" y=\"152.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><text x=\"36.0\" y=\"184.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">24</text><rect x=\"45.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">Cached</text><rect x=\"45.5\" y=\"105.5\" width=\"285.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"188.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bytes</text><rect x=\"45.5\" y=\"137.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">TLS</text><rect x=\"189.5\" y=\"137.5\" width=\"141.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Status</text><rect x=\"45.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"62.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">Retry</text><rect x=\"81.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"117.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"153.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"189.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"225.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"261.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"297.5\" y=\"73.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"81.5\" y=\"137.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"117.5\" y=\"137.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"153.5\" y=\"137.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"81.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"117.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"153.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"189.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"225.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"261.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"297.5\" y=\"169.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"404.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Tight</text><text x=\"404.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">16 bytes, 1 deles de preenchimento</text><text x=\"422.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"458.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><text x=\"494.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><text x=\"530.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><text x=\"566.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><text x=\"602.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><text x=\"638.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"674.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">7</text><text x=\"396.0\" y=\"88.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><text x=\"396.0\" y=\"120.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"405.5\" y=\"73.5\" width=\"285.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"548.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bytes</text><rect x=\"405.5\" y=\"105.5\" width=\"141.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"476.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Status</text><rect x=\"549.5\" y=\"105.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"566.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">Cached</text><rect x=\"585.5\" y=\"105.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"602.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">TLS</text><rect x=\"621.5\" y=\"105.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"638.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">Retry</text><rect x=\"657.5\" y=\"105.5\" width=\"33.0\" height=\"29.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><rect x=\"405.5\" y=\"161.5\" width=\"33.0\" height=\"23.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um campo</text><rect x=\"405.5\" y=\"195.5\" width=\"33.0\" height=\"23.0\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></rect><text x=\"450.0\" y=\"207.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">preenchimento que o compilador pôs</text></svg>", "caption": "Os deslocamentos que o programa layout imprimiu, desenhados com oito bytes por linha. Os mesmos cinco campos ocupam 32 bytes na ordem em que Loose os declara e 16 na de Tight, em que nenhum campo maior vem depois de um menor."}
```

Metade de 32 bytes não merece um segundo de atenção para um valor só. Para um milhão, merece: as
duas últimas linhas da execução mostram o heap crescendo **32.010.416 bytes** para um milhão de
`Loose` e **16.007.168** para um milhão de `Tight`. Cada número fica a menos de um décimo por cento
de 32 e de 16 milhões de bytes, e os últimos dígitos mudam de uma execução para outra. A proporção
não muda.

## Uma ferramenta que faz a conta

Ninguém deveria calcular deslocamentos à mão para cada struct de um programa. O analisador
`fieldalignment`, do `golang.org/x/tools`, faz isso para toda struct de um pacote e diz quais
ficariam menores em outra ordem. Ele não faz parte do `go vet`, então é instalado à parte, com
versão fixada como toda ferramenta deste curso:

```
ana@vm:~/unsafe$ go install golang.org/x/tools/go/analysis/passes/fieldalignment/cmd/fieldalignment@v0.52.0
ana@vm:~/unsafe$ fieldalignment ./...; echo $?
/home/ana/unsafe/internal/tally/tally.go:47:14: Summary has 24 leading bytes of pointer data but optimal value is 16
/home/ana/unsafe/layout/main.go:14:12: Loose has size 32 but the optimal size is 16 leading to a waste of 16 bytes (50%)
3
```

**Ele achou `Loose`, com os mesmos 32 e 16 que o programa imprimiu**, e não achou nada de errado em
`Tight` nem em `tally.Entry`. O status de saída 3 é o jeito como os analisadores construídos sobre o
`golang.org/x/tools/go/analysis` avisam que reportaram algo, então um passo de CI que o rode falha
em qualquer achado.

A primeira linha é o outro diagnóstico que ele faz, e trata de uma struct da lição 1, o
`tally.Summary`. **"Bytes de ponteiro" é até onde, dentro de um valor, o coletor de lixo precisa procurar
ponteiros.** `Summary` começa com `Lines`, um `int`, e seus dois mapas são ponteiros; então o
coletor varre 24 bytes de cada `Summary`, e com os mapas na frente poderia parar em 16. A própria
documentação do analisador é franca sobre quanto isso vale: esses diagnósticos "very rarely indicate
a significant problem", raramente indicam um problema sério, e é por isso que ele não está no
`go vet` nem no `gopls` por padrão. **O `hits` cria um `Summary` por execução, então oito bytes de
varredura economizados uma vez não são nada.** Um slice de um milhão de `Loose` é o caso para o
qual ele existe.

A documentação dá mais um motivo para não obedecê-lo às cegas. A ordem mais compacta pode pôr dois
campos que duas goroutines atualizam cada uma por sua conta na mesma linha de cache do processador,
e cada escrita passa a atrasar a outra. Isso se chama false sharing, e é o caso em que o
preenchimento era justamente o objetivo. **Reordene uma struct quando uma medição disser que o
tamanho dela importa**, e deixe-a na ordem que se lê melhor em todo o resto.
