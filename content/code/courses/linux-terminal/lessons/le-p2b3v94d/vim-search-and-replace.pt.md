---
title: Buscar e substituir, que é o `sed` com vista
version: 1
---

## Buscar

```schooling-figure
{"caption": "`/timeout` e depois Enter.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"Uma tela do vim capturada depois de uma busca: o cursor na linha 4 e /timeout na linha de baixo.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40.00\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\" textLength=\"182.00\" lengthAdjust=\"spacingAndGlyphs\"># the server configuration</tspan><tspan fill=\"var(--paper)\" textLength=\"518.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                          </tspan></text><text x=\"40.00\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">listen 8080                                                                                         </tspan></text><text x=\"40.00\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">workers 4                                                                                           </tspan></text><text x=\"40.00\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">timeout 30                                                                                          </tspan></text><text x=\"40.00\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">log_level info                                                                                      </tspan></text><text x=\"40.00\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">log_file /var/log/app.log                                                                           </tspan></text><text x=\"40.00\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">/timeout                                                                          4,1           All </tspan></text></g></svg>"}
```

`/timeout` e então Enter. O cursor está na linha 4 e a linha de baixo mostra o
que você buscou.

| | |
|---|---|
| `/texto` | busca adiante |
| `?texto` | busca para trás |
| `n` | próxima ocorrência, mesmo sentido |
| `N` | a ocorrência anterior |
| `*` | busca adiante pela **palavra sob o cursor** |
| `#` | o mesmo, para trás |

**O `*` é o de aprender.** Ponha o cursor num identificador, aperte `*`, e você
está andando por todas as ocorrências dele com o `n` — sem digitar, sem erro de
grafia.

## Ele dá a volta, e avisa

```schooling-figure
{"caption": "`G`, e depois `/timeout`. Não havia nada abaixo da linha 6, então a busca deu a volta até o topo.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"Uma tela do vim capturada depois de uma busca que deu a volta: search hit BOTTOM, continuing at TOP na linha de baixo, com o cursor de volta na linha 4.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40.00\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\" textLength=\"182.00\" lengthAdjust=\"spacingAndGlyphs\"># the server configuration</tspan><tspan fill=\"var(--paper)\" textLength=\"518.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                          </tspan></text><text x=\"40.00\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">listen 8080                                                                                         </tspan></text><text x=\"40.00\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">workers 4                                                                                           </tspan></text><text x=\"40.00\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">timeout 30                                                                                          </tspan></text><text x=\"40.00\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">log_level info                                                                                      </tspan></text><text x=\"40.00\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">log_file /var/log/app.log                                                                           </tspan></text><text x=\"40.00\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-red)\" textLength=\"252.00\" lengthAdjust=\"spacingAndGlyphs\">search hit BOTTOM, continuing at TOP</tspan><tspan fill=\"var(--paper)\" textLength=\"448.00\" lengthAdjust=\"spacingAndGlyphs\">                                              4,1           All </tspan></text></g></svg>"}
```

Aquilo é `G` — ir para a última linha — e então `/timeout`. Não há nada abaixo da
linha 6, então a busca deu a volta até o topo e caiu na linha 4.

**`search hit BOTTOM, continuing at TOP` é o vim dizendo que não havia nada
abaixo de onde você estava.** É fácil passar por cima, e é a diferença entre
"existe uma ocorrência, atrás de mim" e "existem ocorrências à frente".

O `:set nowrapscan` desliga a volta e faz a busca falhar em vez disso, que é o
que algumas pessoas preferem exatamente por essa razão.

## Os padrões são expressões regulares

A sintaxe da aula 8 seção 07, com o dialeto próprio do vim por cima:

```sh
/^listen              # lines starting with listen
/log_.*info           # log_ then anything then info
/\<log\>              # the whole word log, not log_level
/30$                  # 30 at the end of a line
```

**O `\<` e o `\>` são fronteiras de palavra** e são a grafia do `\b` no vim. E
por padrão o nível de "magia" do vim faz com que `+`, `?`, `(` e `|` precisem de
contrabarras, que é por que você vai ver `\(` e `\|` nos padrões dos outros.

O `\v` no começo de um padrão liga a "very magic" e o faz se comportar como as
expressões regulares estendidas da aula 8 seção 07: `/\v(listen|timeout)` em vez
de `/listen\|timeout`.

## Maiúsculas

| | |
|---|---|
| padrão | **diferencia** maiúsculas |
| `:set ignorecase` | não diferencia |
| `:set ignorecase smartcase` | não diferencia, a não ser que o seu padrão tenha uma maiúscula |

**`ignorecase` mais `smartcase` é o que quase todo mundo quer**, e está no
`.vimrc` da próxima seção.

## Substituir

```schooling-figure
{"caption": "`:%s/log/LOG/g`. Quatro, em duas linhas.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"Uma tela do vim capturada depois de uma substituição: as duas últimas linhas agora dizem LOG, e 4 substitutions on 2 lines na linha de baixo.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40.00\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\" textLength=\"182.00\" lengthAdjust=\"spacingAndGlyphs\"># the server configuration</tspan><tspan fill=\"var(--paper)\" textLength=\"518.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                          </tspan></text><text x=\"40.00\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">listen 8080                                                                                         </tspan></text><text x=\"40.00\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">workers 4                                                                                           </tspan></text><text x=\"40.00\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">timeout 30                                                                                          </tspan></text><text x=\"40.00\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">LOG_level info                                                                                      </tspan></text><text x=\"40.00\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">LOG_file /var/LOG/app.LOG                                                                           </tspan></text><text x=\"40.00\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">4 substitutions on 2 lines                                                        6,1           All </tspan></text></g></svg>"}
```

`:%s/log/LOG/g`, e o vim diz **`4 substitutions on 2 lines`**.

**Leia esse número.** Quatro, em duas linhas. Se você esperava uma, você acabou
de aprender uma coisa antes de salvar em vez de depois.

O formato é o mesmo do `sed` da aula 8 seção 13, com um intervalo na frente:

```
:[intervalo]s/padrão/substituição/[flags]
```

| intervalo | |
|---|---|
| nada | só esta linha |
| `%` | o arquivo inteiro |
| `1,10` | as linhas 1 a 10 |
| `.,$` | daqui até o fim |
| `'<,'>` | a seleção visual — o vim digita isso para você |

| flag | |
|---|---|
| `g` | **todas** as ocorrências de cada linha, não só a primeira |
| `c` | **confirma** uma por uma |
| `i` | ignora maiúsculas nesta substituição |
| `n` | conta as ocorrências e não muda nada |

**O `g` não é o padrão**, exatamente como no `sed`, e exatamente pela mesma
razão — e é o mesmo defeito, que aparece só nas linhas onde a coisa ocorre duas
vezes.

Duas flags valem mais do que parecem.

**`:%s/velho/novo/gc`** pergunta sobre cada ocorrência, com `y`, `n`, `a` para
todo o resto, `q` para parar e `l` para esta e então parar. Num arquivo que você
não escreveu, é a diferença entre uma mudança e um acidente.

**`:%s/padrão//gn`** não muda nada e informa quantas ocorrências existem. É o
`grep -c` sem sair do editor, e é a coisa certa para rodar *antes* da
substituição em vez de depois.

## O separador é o que você digitar

O `s#…#…#` e o `s|…|…|` funcionam do mesmo jeito, o que importa pela mesma razão
da aula 8 seção 13: um caminho cheio de barras dentro de `s/…/…/` precisa de
todas elas escapadas.

```sh
:%s#/usr/local#/opt#g        # readable
:%s/\/usr\/local/\/opt/g     # the same, and nobody can check it by eye
```

## Quando usar o `.` em vez disso

O `:%s` muda tudo de uma vez e informa um número. O `.` da seção 06 muda uma por
vez e você assiste a cada uma.

**Para um arquivo que você entende, `:%s/…/…/g`.** Para um arquivo que outra
pessoa escreveu, ou um padrão do qual você não tem certeza, `/padrão` e então
`ciwnovo<Esc>` e então `n` e `.` — mais devagar, e você vê o que está fazendo.
