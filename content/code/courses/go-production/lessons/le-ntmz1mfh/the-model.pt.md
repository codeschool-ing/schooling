---
title: Um modelo, uma view e um laço que você não escreve
version: 1
---

O jeito óbvio de escrever uma tela interativa é um laço seu: ler uma tecla, mudar algumas variáveis,
limpar a tela, imprimir tudo de novo. Funciona para uma página de código, e então as variáveis se
multiplicam, o redesenho acontece em três lugares e nada pode ser testado sem uma pessoa apertando
teclas. **O Bubble Tea vira esse laço do avesso. Você escreve o estado e as regras, e a biblioteca
roda o laço.** A forma vem do Elm, uma linguagem para páginas web, e é conhecida como arquitetura
Elm.

Esta lição constrói o `hits browse`, uma tela interativa sobre o mesmo log de acesso que a lição 1
contou. Aqui está ela num terminal de verdade, depois de `j` apertado duas vezes:

```schooling-figure
{"caption": "Um terminal real, com 72 colunas, rodando hits browse access.log depois de j apertado duas vezes: o tools/term-capture desenhou a tela que o programa tinha pintado.", "svg": "<svg viewBox=\"0 0 558 288\" role=\"img\" aria-label=\"A tela do hits browse num terminal real, com 72 colunas. O título diz access.log: 8 paths. Abaixo, os oito caminhos com suas contagens de requisições, de /login com 2576 a /health com 2364. Um &gt; marca /static/app.js, a terceira linha, depois de j apertado duas vezes. A última linha lista as teclas: up/down ou j/k para mover, enter para os status, q para sair.\"><rect x=\"26\" y=\"0\" width=\"532\" height=\"214\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">access.log: 8 paths</tspan></text><text x=\"40\" y=\"41.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /login             2576</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /api/orders        2542</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">&gt; /static/app.js     2526</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /api/users         2512</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /api/orders/42     2503</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /static/app.css    2490</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /                  2487</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  /health            2364</tspan></text><text x=\"40\" y=\"180.50\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">up/down or j/k: move   enter: statuses   q: quit</tspan></text></g><text x=\"13.00\" y=\"25.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"13.00\" y=\"87.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"13.00\" y=\"196.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"13.00\" y=\"252.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"30.00\" y=\"252.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o log e quantos caminhos ele tem</text><text x=\"13.00\" y=\"268.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"30.00\" y=\"268.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o cursor, depois de j apertado duas vezes</text><text x=\"13.00\" y=\"284.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"30.00\" y=\"284.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">as teclas que esta tela atende</text></svg>"}
```

Os caminhos e as contagens são os do `hits top`, na mesma ordem. O que o `top` não faz é deixar você
escolher um: o Enter abre o caminho destacado e mostra suas requisições por código de status, e o
Esc volta para a lista.

## Quatro peças

No Bubble Tea, um programa é **um valor de um tipo que você escreve, chamado modelo, com três
métodos**. A biblioteca os chama; o seu código nunca os chama por conta própria:

| peça | o que recebe | o que devolve | quando a biblioteca chama |
|---|---|---|---|
| o modelo | | | ele é o estado: uma struct sua |
| `Init` | nada | o primeiro comando, ou `nil` | uma vez, antes da primeira tela |
| `Update` | uma mensagem | o próximo modelo, e um comando ou `nil` | para cada mensagem, uma de cada vez |
| `View` | nada | o que a tela deve mostrar, um `tea.View` | depois de cada `Update` |

Uma **mensagem** é qualquer coisa que aconteceu: uma tecla apertada, a janela redimensionada, um
arquivo que terminou de ser lido. Um **comando** é trabalho a fazer fora do laço, cujo resultado
volta como outra mensagem. A seção 03 trata de mensagens e a seção 04 de comandos. O laço que liga
as duas coisas é da biblioteca, e é curto o bastante para desenhar:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 730 310\" role=\"img\" aria-label=\"O laço que o Bubble Tea executa. O terminal envia teclas, tamanhos e respostas para uma fila de mensagens, tiradas uma de cada vez. Cada mensagem vai para Update(msg), que devolve o próximo modelo e um comando ou nil. O próximo modelo vai para View(), que o desenha, e a tela é redesenhada no terminal. Um comando, tea.Cmd, roda numa goroutine própria, e o resultado volta para a fila como mensagem; o comando do Init entra na fila do mesmo jeito.\"><defs><marker id=\"lp-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"lp-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"lp-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"40\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o terminal</text><text x=\"105\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">teclas, tamanhos, respostas</text><rect x=\"250\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma fila de mensagens</text><text x=\"350\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tiradas uma de cada vez</text><rect x=\"510\" y=\"40\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">Update(msg)</text><text x=\"610\" y=\"79\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">devolve um modelo e um comando</text><rect x=\"510\" y=\"200\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">View()</text><text x=\"610\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">desenha esse modelo</text><rect x=\"250\" y=\"200\" width=\"200\" height=\"56\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">tea.Cmd</text><text x=\"350\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">roda numa goroutine própria</text><path d=\"M190 68 H246\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-wire)\"></path><path d=\"M450 68 H506\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-wire)\"></path><path d=\"M610 96 V196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-phosphor)\"></path><text x=\"618\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o próximo modelo</text><path d=\"M560 96 V150 H420 V196\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-amber)\"></path><text x=\"490\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um comando, ou nil</text><path d=\"M290 200 V100\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-amber)\"></path><text x=\"282\" y=\"150\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o resultado, como mensagem</text><path d=\"M610 256 V284 H105 V100\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-wire)\"></path><text x=\"357\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a tela, redesenhada</text><text x=\"350\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o comando do Init entra aqui também</text><path d=\"M350 30 V36\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#lp-wire)\"></path></svg>", "caption": "O laço é da biblioteca. O seu código é o que roda nas caixas coloridas, e só o Update muda o modelo."}
```

**Nada mais muda o modelo.** Uma tecla não move o cursor; ela vira mensagem, e o `Update` decide
qual é o próximo modelo. É essa regra que a seção 05 testa sem terminal.

## O projeto

O `hits browse` mora num diretório próprio, `~/tea-hits`, para o programa da lição 1 ficar como
estava. Crie o módulo com `go mod init example.com/hits`, copie para ele três arquivos da lição 1,
`tools/genlog/main.go`, `internal/tally/tally.go` e `main_test.go`, e gere com o `genlog` o
`access.log` de 20.000 linhas, como na lição 1. O `main.go` vem na seção 04, com um subcomando novo.
Depois, duas dependências: o Bubble Tea e o pacote que responde "isto é um terminal?":

```
ana@vm:~/tea-hits$ go get charm.land/bubbletea/v2@v2.1.0 golang.org/x/term@v0.47.0
go: added charm.land/bubbletea/v2 v2.1.0
go: added github.com/charmbracelet/colorprofile v0.4.3
go: added github.com/charmbracelet/ultraviolet v0.0.0-20261008173134-6b8d4baf91b4
go: added github.com/charmbracelet/x/ansi v0.11.9
go: added github.com/charmbracelet/x/term v0.2.2
go: added github.com/charmbracelet/x/termios v0.1.1
go: added github.com/charmbracelet/x/windows v0.2.2
go: added github.com/clipperhouse/displaywidth v0.11.0
go: added github.com/clipperhouse/uax29/v2 v2.7.0
go: added github.com/lucasb-eyer/go-colorful v1.4.1
go: added github.com/mattn/go-runewidth v0.0.30
go: added github.com/muesli/cancelreader v0.2.2
go: added github.com/rivo/uniseg v0.4.7
go: added github.com/xo/terminfo v1.0.0
go: added golang.org/x/sync v0.22.0
go: added golang.org/x/sys v0.49.0
go: added golang.org/x/term v0.47.0
```

**O caminho do import é `charm.land/bubbletea/v2`**, e a versão 2 difere da versão 1 de formas que
quebram a maior parte do código escrito para ela. Numa primeira execução o comando go também imprime
uma linha `go: downloading` para cada módulo que baixa; estes módulos já estavam no cache.

## O modelo

O estado da tela e a função que a desenha ficam num pacote novo, `internal/tui`, em `model.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tui/model.go",
  "parts": [
    {
      "code": "// Package tui is an interactive screen over an access log: the paths with\n// their request counts, and the statuses of the one under the cursor.\npackage tui\n\nimport (\n\t\"fmt\"\n\t\"io\"\n\t\"maps\"\n\t\"slices\"\n\t\"strings\"\n\n\ttea \"charm.land/bubbletea/v2\"\n)\n",
      "note": "Um pacote próprio em `internal/`, ao lado do `tally`. O import é renomeado para `tea` por convenção, e o caminho é `charm.land/bubbletea/v2`: a versão 2 saiu do `github.com`, então o import de um tutorial antigo aponta para outro módulo."
    },
    {
      "code": "// row is one path and what it was answered with.\ntype row struct {\n\tpath     string\n\thits     int\n\tbyStatus map[int]int\n}\n",
      "note": "Uma linha da lista, com o detalhamento que o Enter mostra. O `tally.Summary` da lição 1 conta caminhos e status separadamente, então os status por caminho pedem um tipo próprio."
    },
    {
      "code": "// Model is everything the screen knows. It is passed by value: Update\n// returns a changed copy, and View only reads it.\ntype Model struct {\n\tname   string    // the file, as the title shows it\n\tin     io.Reader // where Init's command reads the log from\n\trows   []row     // nil until the log has been read\n\terr    error     // what stopped the reading, if anything\n\tcursor int       // the index of the highlighted row\n\topen   bool      // showing the statuses of rows[cursor]\n\twidth  int       // the terminal's width, 0 until it is known\n}\n",
      "note": "**Tudo o que a tela pode mostrar está nestes sete campos.** Qual linha está destacada, se ela está aberta, qual a largura do terminal: nada disso mora numa global ou no terminal. `rows` é `nil` até a contagem terminar, e esse fato sozinho diz ao `View` qual das três telas desenhar."
    },
    {
      "code": "// New returns a model for the log in r. Nothing is read yet.\nfunc New(name string, r io.Reader) Model {\n\treturn Model{name: name, in: r}\n}\n\n// Err is what stopped the reading. The screen is gone by the time anybody\n// can read a message, so the caller prints it.\nfunc (m Model) Err() error { return m.err }\n",
      "note": "O `New` só guarda o leitor. Ler é tarefa do comando do `Init`, na seção 04. O `Err` existe porque a tela é limpa na saída, então um erro precisa ser devolvido e impresso depois."
    },
    {
      "code": "// View draws the model. It is called after every Update.\nfunc (m Model) View() tea.View {\n\tvar b strings.Builder\n\tswitch {\n\tcase m.rows == nil:\n\t\tfmt.Fprintf(&b, \"counting %s ...\\n\", m.name)\n\tcase m.open:\n\t\tr := m.rows[m.cursor]\n\t\tfmt.Fprintf(&b, \"requests to %s: %d\\n\\n\", r.path, r.hits)\n\t\tmost := slices.Max(slices.Collect(maps.Values(r.byStatus)))\n\t\tfor _, status := range slices.Sorted(maps.Keys(r.byStatus)) {\n\t\t\tn := r.byStatus[status]\n\t\t\tfmt.Fprintf(&b, \"  %d %6d  %s\\n\", status, n, bar(n, most, m.width-16))\n\t\t}\n\t\tb.WriteString(\"\\nesc: back   q: quit\\n\")\n\tdefault:\n\t\tfmt.Fprintf(&b, \"%s: %d paths\\n\\n\", m.name, len(m.rows))\n\t\tfor i, r := range m.rows {\n\t\t\tmark := \" \"\n\t\t\tif i == m.cursor {\n\t\t\t\tmark = \">\"\n\t\t\t}\n\t\t\tfmt.Fprintf(&b, \"%s %-16s %6d\\n\", mark, r.path, r.hits)\n\t\t}\n\t\tb.WriteString(\"\\nup/down or j/k: move   enter: statuses   q: quit\\n\")\n\t}\n\tv := tea.NewView(b.String())\n\tv.AltScreen = true\n\treturn v\n}\n",
      "note": "**O `View` lê o modelo e devolve o que a tela deve mostrar; ele não muda nada.** Um `strings.Builder` junta o texto e o `tea.NewView` o embrulha. Ligar `AltScreen` pede a tela alternativa do terminal, a mesma que o `less` e o `vim` usam, e assim as linhas do shell voltam intactas na saída."
    },
    {
      "code": "// bar draws n as a run of # characters, the largest count filling width.\nfunc bar(n, most, width int) string {\n\tif width < 1 {\n\t\treturn \"\"\n\t}\n\treturn strings.Repeat(\"#\", n*width/most)\n}",
      "note": "A barra acompanha o terminal: a maior contagem ocupa a largura menos 16 colunas para os rótulos. Enquanto a largura não é conhecida ela vale 0, e nenhuma barra é desenhada."
    }
  ]
}
```

**O `View` desenha uma de três telas, e só o modelo decide qual.** Enquanto `rows` for `nil`, o log
ainda está sendo lido. Com `open` ligado, os status do caminho destacado aparecem, cada um com uma
barra. Fora isso, a lista é desenhada com um `>` ao lado do cursor. O cursor é um caractere e não
uma cor de propósito: ele sobrevive a um copiar e colar, a um terminal sem cores e a uma captura de
tela impressa em cinza.

Duas diferenças em relação à versão 1 importam aqui, porque a maioria dos tutoriais da web é
anterior a elas. **O `View` devolve um `tea.View`, não uma `string`**, e a tela alternativa é um
campo desse valor, não uma opção passada ao programa. A view agora diz o que o terminal deve estar
fazendo, toda vez que é desenhada, e o Bubble Tea calcula o que mudar.

Um campo quebra a regra de que o modelo é só dados: `in`, o leitor de onde vem o log. Ele está ali
para o `Init` poder iniciar a contagem, e nada no `View` ou no `Update` lê dele. O `Model` ainda não
é um `tea.Model`, porque o `Update` e o `Init` moram em mais dois arquivos do mesmo pacote, um em
cada uma das duas próximas seções.
