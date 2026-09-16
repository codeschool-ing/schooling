---
title: Modos, que é a ideia única
version: 1
---

Tudo que é confuso no vim vem de uma decisão de projeto, e quando você a entende
o resto é vocabulário.

**Em todo outro editor, o teclado digita. No vim, o teclado digita só quando você
está no modo de inserção.** No resto do tempo as teclas de letra são comandos.

É por isso que digitar `hello` num vim recém-aberto move o cursor e apaga alguma
coisa: o `h` é esquerda, o `e` é fim-de-palavra, o `l` é direita, o segundo `l` é
direita de novo, e o `o` abre uma linha nova — o que finalmente te põe no modo de
inserção, que é por que a confusão normalmente termina com uma linha em branco
perdida.

## Os modos que você vai usar

| | como se chega | como se sai |
|---|---|---|
| **normal** | `Esc`, de qualquer lugar | você não sai — aqui é casa |
| **inserção** | `i` `a` `o` `O` `I` `A` | `Esc` |
| **visual** | `v` `V` `Ctrl-v` | `Esc` |
| **linha de comando** | `:` `/` `?` | `Enter`, ou `Esc` para abandonar |

**O modo normal é casa.** Quando você não sabe onde está, aperte `Esc`. Ele é
inofensivo no modo normal — apita ou pisca — e te leva lá de qualquer outro.

O vim abre no modo normal. É o único editor que faz isso, e é a origem da piada
inteira.

## Como saber em qual você está

```schooling-figure
{"caption": "`vim server.conf`, capturado de um terminal de verdade. A linha de baixo é toda a interface do vim.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"Uma tela do vim capturada como ele abre: as seis linhas do server.conf, tils abaixo delas, e server.conf 6L, 101B com a régua em 1,1.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40.00\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\" textLength=\"182.00\" lengthAdjust=\"spacingAndGlyphs\"># the server configuration</tspan><tspan fill=\"var(--paper)\" textLength=\"518.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                          </tspan></text><text x=\"40.00\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">listen 8080                                                                                         </tspan></text><text x=\"40.00\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">workers 4                                                                                           </tspan></text><text x=\"40.00\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">timeout 30                                                                                          </tspan></text><text x=\"40.00\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">log_level info                                                                                      </tspan></text><text x=\"40.00\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">log_file /var/log/app.log                                                                           </tspan></text><text x=\"40.00\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"227.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">&#34;server.conf&#34; 6L, 101B                                                            1,1           All </tspan></text></g></svg>"}
```

**A linha de baixo é a interface inteira do vim.** À esquerda: o que acabou de
acontecer — aqui, o arquivo que ele abriu, seis linhas, 101 bytes. À direita: o
cursor, linha 1 coluna 1, e `All`, querendo dizer que o arquivo inteiro cabe na
tela.

As linhas com `~` não fazem parte do arquivo. Elas marcam onde o arquivo termina
e a tela continua.

Aperte `i`:

```schooling-figure
{"caption": "`i`. Essa é a única diferença na tela.", "svg": "<svg viewBox=\"0 0 754 245\" role=\"img\" aria-label=\"A mesma tela do vim capturada depois de apertar i: o -- INSERT -- substituiu o nome do arquivo na linha de baixo, e nada mais se mexeu.\"><rect x=\"26\" y=\"0\" width=\"728\" height=\"245\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><g font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\"><text x=\"40.00\" y=\"25.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-cyan)\" textLength=\"182.00\" lengthAdjust=\"spacingAndGlyphs\"># the server configuration</tspan><tspan fill=\"var(--paper)\" textLength=\"518.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                          </tspan></text><text x=\"40.00\" y=\"41.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">listen 8080                                                                                         </tspan></text><text x=\"40.00\" y=\"56.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">workers 4                                                                                           </tspan></text><text x=\"40.00\" y=\"72.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">timeout 30                                                                                          </tspan></text><text x=\"40.00\" y=\"87.50\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">log_level info                                                                                      </tspan></text><text x=\"40.00\" y=\"103.00\" xml:space=\"preserve\"><tspan fill=\"var(--paper)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">log_file /var/log/app.log                                                                           </tspan></text><text x=\"40.00\" y=\"118.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"134.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"149.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"165.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"180.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"196.00\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"211.50\" xml:space=\"preserve\"><tspan fill=\"var(--term-blue)\" textLength=\"700.00\" lengthAdjust=\"spacingAndGlyphs\">~                                                                                                   </tspan></text><text x=\"40.00\" y=\"227.00\" xml:space=\"preserve\"><tspan font-weight=\"600\" fill=\"var(--paper)\" textLength=\"84.00\" lengthAdjust=\"spacingAndGlyphs\">-- INSERT --</tspan><tspan fill=\"var(--paper)\" textLength=\"616.00\" lengthAdjust=\"spacingAndGlyphs\">                                                                      1,1           All </tspan></text></g></svg>"}
```

**`-- INSERT --`.** É a única diferença na tela, e é o que olhar quando você não
tem certeza se as suas teclas estão indo para o arquivo.

`Esc`, e ele some. Um modo sem anúncio é o modo normal.

E o visual:

```
┌────────────────────────────────────────────────────────────────────────┐
│# the server configuration                                              │
│listen 8080                                                             │
│workers 4                                                               │
│timeout 30                                                              │
│log_level info                                                          │
│log_file /var/log/app.log                                               │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│~                                                                       │
│-- VISUAL LINE --                           3         3,1           All │
└────────────────────────────────────────────────────────────────────────┘
```

`V` e então `jj` — `-- VISUAL LINE --`, e o `3` no meio é quantas linhas estão
selecionadas. (Num terminal de verdade aquelas três linhas ficam destacadas.
Esta tela é desenhada em vez de fotografada, ao contrário das duas acima, porque
a cor de destaque do próprio vim não fica legível o bastante nesta página — então
a contagem é a parte a ler.)

## Os seis jeitos de entrar no modo de inserção

Eles diferem em *onde* te põem, e escolher o certo poupa um movimento:

| | |
|---|---|
| `i` | **insere** antes do cursor |
| `a` | **acrescenta** depois do cursor |
| `I` | insere no primeiro caractere não branco da linha |
| `A` | acrescenta no **fim** da linha |
| `o` | **abre** uma linha nova abaixo, e vai para lá |
| `O` | abre uma linha nova acima |

**O `A` e o `o` são os dois que você vai mais usar**, porque as duas coisas que
você normalmente quer são "acrescentar ao fim desta linha" e "acrescentar uma
linha nova".

## O `Esc` fica longe

Num teclado em que o `Esc` está onde o `Caps Lock` deveria estar, tudo bem. Num
laptop com touch bar, não.

**O `Ctrl-[` é o `Esc`.** Não um substituto — o mesmo byte, 27, que é por que o
terminal não os distingue (aula 1 seção 08). Todo usuário de vim que não remapeia
o teclado usa isso.

O `Ctrl-c` também sai do modo de inserção e não é exatamente igual: ele pula
parte do que o `Esc` faz na saída, o que importa para um punhado de plugins e
nunca para nada desta aula.
