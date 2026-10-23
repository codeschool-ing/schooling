---
title: O que DevSecOps muda, e o que não muda
version: 1
---

A imagem comum de DevSecOps é uma compra: alguém compra um scanner, pluga no pipeline, e o time
passa a "fazer segurança". Um mês depois o job do scanner está vermelho em todo branch, alguém o
marcou como "pode falhar", e ninguém lê a saída. **Nada mudou na rotina, então nada mudou na
segurança também.** A ferramenta era a parte barata.

O que DevSecOps muda é **quem acha um defeito de segurança, quando, e para onde vai o achado**. As
práticas de DevOps continuam: mudanças pequenas, um pipeline que checa cada uma delas, as pessoas
que constroem um serviço também operando esse serviço. DevSecOps acrescenta checagens de segurança
ao mesmo pipeline e põe os resultados no mesmo lugar de um teste que falha. A ideia inteira é essa,
e cada metade é mais difícil do que parece.

### O modelo que ele substitui

No arranjo de onde a maioria das empresas partiu, segurança era uma fase. Um time montava um
release; um time de segurança o revisava, ou contratava uma empresa de fora para testar, pouco antes
ou pouco depois de ele sair; os achados voltavam como relatório, e o relatório virava tickets. Três
coisas decorrem desse formato, e nenhuma é culpa de ninguém:

- **O achado chega muito depois de o código ser escrito.** O desenvolvedor já passou para outro
  trabalho, o contexto se perdeu, e a correção disputa espaço com o que está planejado em seguida.
- **O achado chega em outro lugar.** Um PDF, uma planilha, um ticket na fila de outra pessoa. Um
  teste que falha impede um merge; um relatório não impede.
- **Os revisores estão em minoria.** Um engenheiro de segurança para dezenas de desenvolvedores não
  consegue ler toda mudança, então a revisão é por amostragem, e o que fica fora da amostra fica sem
  revisão.

DevOps tinha eliminado o mesmo tipo de passagem de bastão entre construir e operar software.
DevSecOps elimina a passagem entre construir software e checar que ele é seguro.

### O que muda de fato

| | segurança como fase | DevSecOps |
|---|---|---|
| quando um defeito é achado | na revisão, antes ou depois de um release | no pipeline da mudança que o introduziu |
| para onde vai o achado | um relatório, depois tickets | o log do build, ao lado dos testes que falharam |
| quem corrige | quem recebe o ticket | o autor da mudança, enquanto ainda tem tudo na cabeça |
| o que o time de segurança faz | revisa releases | escolhe as checagens, ajusta, decide os casos difíceis, ensina |
| o que significa "passou" | o revisor não achou nada | toda checagem combinada pelo time rodou, e passou ou ficou em exceção registrada |

**A última linha é a que as pessoas esquecem.** Um pipeline não deixa o software seguro. Ele faz
uma lista específica e escrita de checagens rodar em toda mudança, e assim a pergunta "alguém
olhou?" sempre tem resposta. A lista é uma decisão que o time toma e revisita, e é código no
repositório, que a aula 7 transforma numa regra sobre quando uma checagem pode parar um release.

### O que não muda

Automatizar as checagens não elimina a necessidade de gente que entende as ameaças. Um scanner acha
as falhas para as quais alguém já escreveu uma regra. Ele não acha um design que confia na parte
errada, que é para isso que existe `threat-modeling`, e não consegue julgar se um achado importa
neste sistema. **O trabalho do engenheiro de segurança passa de ler toda mudança para decidir o que
a máquina procura**, e para os casos que ela não consegue decidir.

Também não elimina a troca entre velocidade e segurança. Cada checagem custa minutos em todo push,
e a aula 2 trata de gastar esse tempo onde ele rende. Um pipeline que leva quarenta minutos para
dizer qualquer coisa é um pipeline que as pessoas contornam.

### Este curso, num pipeline só

Daqui até a aula 20 o curso acrescenta checagens a um único pipeline, de um serviço pequeno que você
vai montar nesta aula. Cada aula acrescenta uma classe de checagem, acha o que ela acha no serviço,
corrige e mantém a checagem no pipeline. Ao final o pipeline varre o código, as dependências, os
segredos, a imagem e a infraestrutura, e assina o que entrega. A ordem dos estágios com que ele
termina não é a ordem das aulas, e a figura mostra por quê:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 228\" role=\"img\" data-fig=\"sp-l01-stages\" aria-label=\"Os estágios de ci/stages na ordem em que rodam ao fim do curso, cada um com a aula que o acrescenta: secrets 6, workflows 16, policy 19, test 1, sast 3, sca 5, build 1, image 8, push 8, sbom 13, sign 14. A lista noturna tem rebuild, da aula 2, e dast, da aula 4.\"><defs><marker id=\"sp-l01-stages-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ci/stages: a cada push</text><rect x=\"15\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"45.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">secrets</text><text x=\"45.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">6</text><rect x=\"78\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"108.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">workflows</text><text x=\"108.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">16</text><rect x=\"141\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"171.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">policy</text><text x=\"171.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19</text><rect x=\"204\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"234.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">test</text><text x=\"234.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"267\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"297.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">sast</text><text x=\"297.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">3</text><rect x=\"330\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">sca</text><text x=\"360.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">5</text><rect x=\"393\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"423.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">build</text><text x=\"423.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1</text><rect x=\"456\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"486.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">image</text><text x=\"486.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"519\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"549.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">push</text><text x=\"549.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">8</text><rect x=\"582\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"612.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">sbom</text><text x=\"612.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">13</text><rect x=\"645\" y=\"40\" width=\"60\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"675.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">sign</text><text x=\"675.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">14</text><path d=\"M15 100 L703 100\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l01-stages-ah-paper-dim)\"></path><text x=\"15\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a ordem em que rodam; o número é a aula que acrescenta o estágio</text><text x=\"20\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">ci/nightly: uma vez por dia</text><rect x=\"15\" y=\"168\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">rebuild</text><text x=\"65.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">2</text><rect x=\"140\" y=\"168\" width=\"100\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"190.0\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">dast</text><text x=\"190.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4</text><path d=\"M117 191 L138 191\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l01-stages-ah-paper-dim)\"></path></svg>", "caption": "A aula 1 começa com dois estágios. Cada aula seguinte que acrescenta um o põe no lugar dele na ordem, e por isso a ordem não é a das aulas."}
```

Os estágios que custam menos e barram mais vêm primeiro. Um segredo num commit é a coisa mais barata
de detectar e a mais cara de deixar passar, então a aula 6 põe essa checagem no topo da lista, mesmo
ela vindo depois de outras três no curso.
