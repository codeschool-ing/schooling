---
title: O Update, e as mensagens que ele recebe
version: 1
---

Código que reage a teclas costuma ser escrito como handlers: uma função por tecla, cada uma mudando
algum estado compartilhado como efeito colateral. **O `Update` é uma função só, com uma tarefa só:
dado o modelo atual e uma mensagem, devolver o próximo modelo.** Toda mudança na tela passa por ele,
na ordem em que as mensagens chegaram, e nada mais guarda estado que possa discordar dele. Salve-o
ao lado do modelo, como `internal/tui/update.go`:

```schooling-example
{
  "language": "go",
  "file": "internal/tui/update.go",
  "parts": [
    {
      "code": "package tui\n\nimport tea \"charm.land/bubbletea/v2\"\n",
      "note": "Um segundo arquivo no mesmo pacote. O Go compila juntos todos os arquivos de um diretório, então o `Update` enxerga o `Model` e o `row` do `model.go`."
    },
    {
      "code": "// Update is the only place the model changes. It receives one message and\n// returns the next model, and a command when something has to happen\n// outside: here, only quitting.\nfunc (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {",
      "note": "**O receptor é uma cópia, e é a cópia que volta.** O programa guarda o que o `Update` devolver como o novo modelo, então uma mudança feita em `m` e devolvida é o próximo estado, e uma mudança feita e não devolvida se perde."
    },
    {
      "code": "\tswitch msg := msg.(type) {\n\tcase loaded:\n\t\tm.rows, m.err = msg.rows, msg.err\n\t\tif m.err != nil {\n\t\t\treturn m, tea.Quit\n\t\t}",
      "note": "Uma mensagem é qualquer valor Go, e um type switch as distingue. `loaded` é a mensagem do próprio programa, o resultado da contagem da seção 04; os outros dois casos são mensagens que o Bubble Tea envia."
    },
    {
      "code": "\tcase tea.WindowSizeMsg:\n\t\tm.width = msg.Width",
      "note": "O tamanho do terminal chega uma vez no início e de novo a cada redimensionamento. Guardar a largura é tudo o que o `Update` faz com ele; o `View` a transforma no comprimento de uma barra."
    },
    {
      "code": "\tcase tea.KeyPressMsg:\n\t\tswitch msg.String() {\n\t\tcase \"q\", \"ctrl+c\":\n\t\t\treturn m, tea.Quit\n\t\tcase \"up\", \"k\":\n\t\t\tif !m.open && m.cursor > 0 {\n\t\t\t\tm.cursor--\n\t\t\t}\n\t\tcase \"down\", \"j\":\n\t\t\tif !m.open && m.cursor < len(m.rows)-1 {\n\t\t\t\tm.cursor++\n\t\t\t}\n\t\tcase \"enter\":\n\t\t\tm.open = len(m.rows) > 0\n\t\tcase \"esc\":\n\t\t\tm.open = false\n\t\t}\n\t}",
      "note": "**Uma tecla é uma mensagem como qualquer outra, e o `String` dá o nome dela**: `\"up\"`, `\"j\"`, `\"enter\"`, `\"esc\"`, `\"ctrl+c\"`. As setas e `j`/`k` dividem um caso, e é isso que faz as duas funcionarem. O cursor para nas duas pontas e só se move enquanto a lista está na tela."
    },
    {
      "code": "\treturn m, nil\n}",
      "note": "Toda mensagem que chega a esta linha sai sem comando. Isso inclui as mensagens que ninguém pediu, que a seção 04 lista."
    }
  ]
}
```

## Uma mensagem é qualquer valor

`tea.Msg` é uma interface que todo tipo satisfaz, então uma mensagem pode ser uma struct do Bubble
Tea, uma struct sua ou qualquer outra coisa. **O type switch é como o `Update` lê uma.** Uma
mensagem que nenhum caso nomeia cai em `return m, nil`, que é o certo a fazer com algo que você não
pediu, e a seção 04 mostra que chegam várias que ninguém pediu.

A versão 2 mudou as mensagens de tecla mais do que qualquer outra coisa. Na versão 1, `tea.KeyMsg`
era a struct de uma tecla apertada. Na versão 2, **`tea.KeyMsg` é uma interface que cobre tanto
apertar quanto soltar uma tecla, e o aperto é `tea.KeyPressMsg`**. Código escrito como `case
tea.KeyMsg:` ainda compila com a versão 2 e parece funcionar, até a view pedir ao terminal eventos
de soltura com `KeyboardEnhancements.ReportEventTypes`. A partir daí, num terminal que os suporta,
esse caso vê cada tecla duas vezes: uma descendo e outra subindo.

Os nomes que o `String` devolve são o que os casos comparam:

| tecla | `String()` | o que o `hits browse` faz |
|---|---|---|
| seta para cima, `k` | `"up"`, `"k"` | sobe o cursor uma linha, parando no topo |
| seta para baixo, `j` | `"down"`, `"j"` | desce o cursor uma linha, parando no fim |
| Enter | `"enter"` | abre o caminho destacado |
| Esc | `"esc"` | volta para a lista |
| `q`, Ctrl+C | `"q"`, `"ctrl+c"` | devolve `tea.Quit`, o comando da seção 04 |

**Aqui o Ctrl+C é uma tecla, não um sinal.** O Bubble Tea põe o terminal em modo raw, em que o
driver do terminal deixa de transformar Ctrl+C em `SIGINT`, e a tecla chega como uma mensagem comum.
Um programa cujo `Update` esquece esse caso não para com Ctrl+C de jeito nenhum, e o usuário fica
procurando outro terminal de onde matá-lo.

## O tamanho da janela também é mensagem

A `tea.WindowSizeMsg` chega uma vez quando o programa começa e de novo toda vez que o terminal muda
de tamanho. O `hits browse` guarda a largura e mais nada, e o `View` a usa para dar escala às barras
da segunda tela. Esta é a tela depois de a lista acima receber mais três teclas, `j`, `j` e Enter,
num terminal de 72 colunas:

```schooling-figure
{"caption": "A mesma execução depois de j, j e Enter: os status de /static/app.js, cada um com uma barra na escala da largura do terminal.", "svg": "<svg viewBox=\"0 0 558 319\" role=\"img\" aria-label=\"A tela de detalhe de /static/app.js, 2526 requisições, num terminal de 72 colunas. Cada código de status aparece com sua contagem e uma barra de caracteres #: 200 tem 944 e a barra mais longa, de 56 caracteres; 404 tem 340 e uma barra de 20; os outros oito status têm entre 141 e 174 e barras de 8 a 10. A última linha diz esc: back, q: quit.\"><rect x=\"26\" y=\"0\" width=\"532\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">requests to /static/app.js: 2526</tspan></text><text x=\"40\" y=\"41.00\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271 278 285 292 299 306 313 320 327 334 341 348 355 362 369 376 383 390 397 404 411 418 425 432 439 446 453 460 467 474 481 488 495 502 509 516 523\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  200    944  ########################################################</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  201    148  ########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  204    152  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  301    155  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  304    156  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  400    159  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  401    157  #########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201 208 215 222 229 236 243 250 257 264 271\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  404    340  ####################</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187 194 201\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  500    174  ##########</tspan></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166 173 180 187\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">  503    141  ########</tspan></text><text x=\"40\" y=\"211.50\" xml:space=\"preserve\"></text><text x=\"40 47 54 61 68 75 82 89 96 103 110 117 124 131 138 145 152 159 166\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\">esc: back   q: quit</tspan></text></g><text x=\"13.00\" y=\"25.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"13.00\" y=\"56.50\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"13.00\" y=\"165.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"13.00\" y=\"283.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"30.00\" y=\"283.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o caminho que estava destacado, e o seu total</text><text x=\"13.00\" y=\"299.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"30.00\" y=\"299.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">a maior contagem ocupa a largura menos 16 colunas</text><text x=\"13.00\" y=\"315.00\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"30.00\" y=\"315.00\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o 404, listado duas vezes no genlog, tem barra quase dupla</text></svg>"}
```

A barra do `200` é a maior contagem e ocupa 72 menos 16 colunas. **Antes da primeira `WindowSizeMsg`
a largura é 0 e o `View` não desenha barra nenhuma**, que é uma resposta honesta a "qual a largura
da tela" quando ninguém disse ainda. Um terminal arrastado para ficar mais estreito manda uma
mensagem nova, o próximo `View` desenha barras mais curtas, e nenhum código sai procurando o
tamanho.

## O programa é uma função das suas mensagens

Junte o `Update` e o `View` e o programa inteiro cabe numa frase: **a tela é o `View` aplicado ao
que o `Update` fez das mensagens, em ordem.** Duas execuções que recebem as mesmas mensagens
desenham as mesmas telas, seja qual for o terminal e por mais rápido que as teclas tenham vindo.

Os dois limites do cursor mostram por que isso importa. Apertar `k` na primeira linha não deve fazer
nada, nem `j` na última; o Esc deve fechar o detalhamento e deixar o cursor na linha que ele abriu.
**Cada um desses é uma mensagem e um modelo esperado**, e a seção 05 confere dois deles mandando as
mensagens direto ao `Update`, sem terminal nem teclado em parte alguma do teste.
