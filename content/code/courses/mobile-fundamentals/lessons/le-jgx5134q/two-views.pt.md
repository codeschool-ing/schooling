---
title: O que o usuário vê, e o que o sistema vê
version: 1
---

**Num celular, um app não roda do momento em que abre até o momento em que é fechado; o sistema o
move entre estados, e pode tirar o processo dele quando decidir.** A imagem que a maioria das pessoas
traz do notebook tem dois estados: o programa está aberto, ou foi encerrado. Quem usa um celular
carrega a mesma imagem, e ela está errada de um jeito que importa para quem escreve o app.

## O que o usuário acha que aconteceu

Do lado do usuário há três situações, e nenhuma parece uma decisão:

- o app está **na tela**, e ele está usando;
- o app está **em algum lugar atrás**, na lista de apps recentes, e ele espera encontrá-lo exatamente
  como deixou;
- o app foi **fechado**, porque ele o arrastou para fora.

**A segunda é a que o usuário confia e o sistema não garante.** O app que o usuário vê na lista de
recentes pode ainda estar na memória, pode estar congelado na memória, ou pode não ter processo
nenhum porque o sistema o matou uma hora atrás para abrir espaço para um jogo. A lista de recentes
mostra uma imagem da tela em todos esses casos, e o usuário não consegue distingui-los.

## O que o sistema sabe

O sistema acompanha mais que isso, e acompanha por app. Android e iOS dão nomes diferentes aos
estados e traçam as linhas em lugares um pouco diferentes, mas os dois distinguem as mesmas cinco
situações, que este curso usa como um modelo só:

| estado neste curso | o que é verdade |
|---|---|
| **ativo** | na tela, na frente, recebendo os toques do usuário |
| **inativo** | ainda visível, mas tem algo na frente: uma ligação, um painel do sistema, um diálogo |
| **em segundo plano** | não visível; o código ainda pode rodar, por pouco tempo |
| **suspenso** | na memória, mas sem rodar; nada do que o app escreveu executa |
| **não rodando** | nenhum processo: nunca começou, ou foi morto |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 290\" role=\"img\" data-fig=\"l04-states\" aria-label=\"Os cinco estados do ciclo de vida compartilhado e os movimentos entre eles. Not running leva, por launch, a active. Active e inactive passam um para o outro por interrupt e resume. Inactive leva, por leave, a background. Background leva, por suspend, a suspended. Background e suspended levam os dois, por return, a active. Background e suspended levam os dois, por kill, a not running, e nenhuma plataforma chama o app quando isso acontece. Cada estado traz também os seus nomes: active é resumed no Android, .active no iOS, active no React Native; inactive é paused, .inactive, inactive só no iOS; background é stopped, .background, background; suspended é um processo em cache no Android, suspended no iOS, e nada no React Native.\"><defs><marker id=\"l04-states-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04-states-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"50\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"90.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">não rodando</text><text x=\"90.0\" y=\"76.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">nenhum processo</text><rect x=\"220\" y=\"40\" width=\"160\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">ativo</text><text x=\"300.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Android: resumed</text><text x=\"300.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iOS: .active</text><text x=\"300.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">RN: active</text><rect x=\"430\" y=\"40\" width=\"160\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">inativo</text><text x=\"510.0\" y=\"67.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Android: paused</text><text x=\"510.0\" y=\"79.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iOS: .inactive</text><text x=\"510.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">RN: inactive (iOS)</text><rect x=\"430\" y=\"180\" width=\"160\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">em segundo plano</text><text x=\"510.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Android: stopped</text><text x=\"510.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iOS: .background</text><text x=\"510.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">RN: background</text><rect x=\"220\" y=\"180\" width=\"160\" height=\"66\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">suspenso</text><text x=\"300.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Android: processo em cache</text><text x=\"300.0\" y=\"219.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iOS: suspended</text><text x=\"300.0\" y=\"231.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">RN: nada</text><path d=\"M170 70 L218 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"195\" y=\"60\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">launch</text><path d=\"M380 58 L428 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"405\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">interrupt</text><path d=\"M430 88 L382 88\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"405\" y=\"99\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">resume</text><path d=\"M510 106 L510 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"518\" y=\"143\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">leave</text><path d=\"M430 205 L382 205\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"405\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">suspend</text><path d=\"M300 180 L300 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><path d=\"M440 180 L372 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-states-ah-paper-dim)\"></path><text x=\"306\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--phosphor)\">return</text><path d=\"M220 225 L90 225 L90 92\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-states-ah-amber)\"></path><path d=\"M510 246 L510 262 L70 262 L70 92\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l04-states-ah-amber)\"></path><text x=\"300\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">kill: nenhum callback em plataforma nenhuma</text></svg>", "caption": "Um modelo, três vocabulários. As duas setas tracejadas são as que nenhuma plataforma anuncia: o app não fica sabendo que foi congelado, nem que foi morto.", "same": ["Android: resumed", "iOS: .active", "RN: active", "Android: paused", "iOS: .inactive", "RN: inactive (iOS)", "Android: stopped", "iOS: .background", "RN: background", "iOS: suspended"]}
```

**Duas setas dessa figura não levam o nome de callback nenhum**, e elas são o motivo desta aula
existir. Passar de segundo plano para suspenso acontece sem avisar o app, nas duas plataformas, e o
mesmo vale para ser morto em segundo plano ou suspenso. O app está rodando código num momento e não
tem processo no seguinte.

## Por que o sistema faz isso

**Memória, e bateria.** Um celular tem bem menos memória do que os apps instalados usariam se todos
ficassem vivos, e todo processo rodando gasta bateria. Então o sistema mantém rodando o app da frente,
deixa os de trás terminarem rapidamente, congela-os e recupera a memória deles quando outra coisa
precisa. A documentação do Android diz que o sistema mata processos quando precisa liberar RAM, e que
a probabilidade depende do estado: menor para o app em primeiro plano, maior para um processo sem
nada visível. A da Apple diz que o sistema encerra apps em segundo plano conforme a necessidade, para
deixar memória e outros recursos disponíveis para o primeiro plano.

**Não foi o usuário quem fez, então o usuário espera que nada tenha mudado.** Essa é a dificuldade
inteira. Um processo morto enquanto o usuário estava numa ligação é, do lado do usuário, o mesmo app
que ele deixou vinte minutos atrás, e ele espera a mesma tela com o mesmo texto meio digitado. A
aula 5 trata de devolver isso a ele. Esta aula trata de saber quando isso pode ser tirado.
