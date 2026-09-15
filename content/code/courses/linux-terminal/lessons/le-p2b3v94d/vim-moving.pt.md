---
title: Mover, sem tocar nas setas
version: 1
---

As setas funcionam. Use-as por uma semana e então pare, porque todo movimento
desta seção também é um **argumento para um operador** na próxima, e é aí que o
vim deixa de ser um bloco de notas pior.

## Caracteres e linhas

```
      k
   h     l
      j
```

| | |
|---|---|
| `h` `l` | esquerda, direita |
| `j` `k` | baixo, cima |
| `0` | o começo exato da linha |
| `^` | o primeiro caractere não branco |
| `$` | o fim da linha |

O `j` para baixo é o único que precisa de mnemônico: é a letra com uma perna,
pendurada abaixo da linha.

O `^` e o `0` diferem numa linha indentada, e o `^` é quase sempre o que você
quer.

## Palavras

| | |
|---|---|
| `w` | adiante, ao começo da próxima **palavra** |
| `b` | atrás, ao começo da palavra anterior |
| `e` | adiante, ao **fim** desta palavra |
| `W` `B` `E` | o mesmo, mas "palavra" é qualquer coisa sem espaço |

**As versões maiúsculas tratam pontuação como parte da palavra**, que é o que
você quer para um nome de arquivo ou uma URL: o `w` em `/var/log/app.log` para em
toda barra e todo ponto; o `W` pula a coisa inteira.

## Linhas, telas e o arquivo

| | |
|---|---|
| `gg` | a primeira linha |
| `G` | a **última** linha |
| `42G` ou `:42` | a linha 42 |
| `Ctrl-d` `Ctrl-u` | meia tela para baixo, para cima |
| `Ctrl-f` `Ctrl-b` | uma tela inteira adiante, atrás |
| `H` `M` `L` | a linha do **alto**, do **meio** e de **baixo** da tela |
| `{` `}` | atrás e adiante um parágrafo — um bloco de linhas não vazias |
| `%` | ao delimitador correspondente |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 586 245\" role=\"img\" aria-label=\"A captured vim screen after pressing G: the same six lines of server.conf, and the ruler at the bottom right reading 6,1 instead of 1,1.\"><rect x=\"26\" y=\"0\" width=\"560\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40.00\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\" textLength=\"182.00\" lengthAdjust=\"spacingAndGlyphs\"># the server configuration</tspan><tspan fill=\"var(--paper)\" textLength=\"350.00\" lengthAdjust=\"spacingAndGlyphs\">                                                  </tspan></text><text x=\"40.00\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">listen 8080                                                                 </tspan></text><text x=\"40.00\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">workers 4                                                                   </tspan></text><text x=\"40.00\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">timeout 30                                                                  </tspan></text><text x=\"40.00\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">log_level info                                                              </tspan></text><text x=\"40.00\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">log_file /var/log/app.log                                                   </tspan></text><text x=\"40.00\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                           </tspan></text><text x=\"40.00\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                           </tspan></text><text x=\"40.00\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                           </tspan></text><text x=\"40.00\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                           </tspan></text><text x=\"40.00\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                           </tspan></text><text x=\"40.00\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                           </tspan></text><text x=\"40.00\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                           </tspan></text><text x=\"40.00\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"532.00\" lengthAdjust=\"spacingAndGlyphs\">&#34;server.conf&#34; 6L, 101B                                    6,1           All </tspan></text></g></svg>", "caption": "O `server.conf` no vim depois de `G`, capturado de um terminal de verdade. A r\u00e9gua no canto inferior direito \u00e9 a \u00fanica coisa que mudou."}
```

**Nada na tela mudou a não ser os números da direita** — `6,1` onde dizia `1,1`.
O vim moveu o cursor e disse isso no único lugar em que ele diz qualquer coisa.

O `%` vale mais do que parece: ponha o cursor numa `{` e aperte, e você vai para
a `}` correspondente. Num arquivo de configuração com blocos aninhados, é assim
que você descobre onde um bloco termina sem contar.

## O `f`, o que muda como você se move

O `f` quer dizer **find**, nesta linha:

| | |
|---|---|
| `fx` | adiante, ao próximo `x` desta linha |
| `Fx` | atrás, ao `x` anterior |
| `tx` | adiante, até logo antes do próximo `x` |
| `;` | repete o último `f`, `t`, `F` ou `T` |
| `,` | repete ao contrário |

O `f=` numa linha de configuração põe o cursor no sinal de igual em duas teclas.
O `f/` te leva por um caminho, uma barra por vez, com o `;`.

**É esse o movimento que separa quem se move pelo vim de quem segura o `l`.**

## Marcas, e as duas que vêm de graça

```sh
ma        # set mark a here
'a        # jump to the line of mark a
`a        # jump to the exact position of mark a
```

Duas marcas são definidas por você e valem conhecer:

| | |
|---|---|
| `` `` `` | onde você estava antes do **último salto**. Aperte duas vezes para alternar |
| `` `. `` | onde você fez a **última mudança** |
| `` `" `` | onde você estava quando fechou este arquivo pela última vez |

**O `` `` `` é o de lembrar.** Você buscou, caiu em algum lugar, olhou, e agora
quer voltar para onde estava: duas crases.

E o `` `" `` é por que o vim às vezes abre um arquivo com o cursor no meio — ele
lembrou, do arquivo `viminfo` dele, e é um recurso e não um defeito.

## Contagens

**Todo movimento aceita um número na frente**, e ele quer dizer "faça isso tantas
vezes":

```sh
5j        # five lines down
3w        # three words forward
d2w       # delete two words — the next section
```

O `5j` não é um atalho para apertar `j` cinco vezes no sentido de poupar teclas;
é a gramática sobre a qual o editor inteiro é construído, e a próxima seção é
onde ela se paga.
