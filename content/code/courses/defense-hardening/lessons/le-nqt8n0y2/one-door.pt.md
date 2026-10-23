---
title: Uma porta para os administradores
version: 1
---

**O caminho que um administrador usa para chegar a um servidor é o caminho mais valioso da rede.**
Ele termina no root daquele servidor. Todos os outros caminhos deste curso levam a um serviço, a uma
conta, a um arquivo; este leva à máquina inteira, e dali a tudo em que a máquina confia. Então recebe
o tratamento mais cuidadoso, e a primeira parte desse tratamento é existir **um** só.

Suba o laboratório desta aula:

```sh
sudo bash hostlab.sh up admin jump web desk
```

Do jeito que o laboratório sobe, toda máquina consegue abrir SSH para todas as outras, porque toda
máquina tem a sua chave. Peça o `web` a partir de uma estação de trabalho e da máquina do
administrador:

```
ana@desk:~$ ssh web hostname
web
ana@admin:~$ ssh web hostname
web
ana@admin:~$ ssh jump hostname
jump
```

As três funcionam. Esse é o estado da maioria das redes pequenas, e quer dizer que a pergunta "quem
pode ter entrado no `web` ontem à noite" tem tantas respostas quanto há máquinas. Se o `desk` é a
máquina onde rodou o link de phishing de alguém, então o `desk` é um caminho até o `web`, com a chave
que já tem.

## A forma da correção

Um **servidor de salto** (jump server), ou bastião, é uma máquina cujo único trabalho é ser a
entrada. Os administradores chegam a ele a partir da própria estação; ele chega aos servidores; os
servidores aceitam conexões administrativas dele e de mais nada. Três propriedades decorrem disso, e
cada uma dá para conferir:

| propriedade | o que compra |
|---|---|
| os servidores só aceitam SSH vindo do servidor de salto | uma chave roubada não serve de nenhuma outra máquina |
| o servidor de salto não faz mais nada | nada de navegador, nada de e-mail, nada que busque conteúdo de estranhos, então é difícil conseguir um ponto de apoio nele |
| toda sessão administrativa atravessa uma máquina só | um lugar para registrar, para exigir um segundo fator e para cortar |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" data-fig=\"l15-one-door\" aria-label=\"Dois desenhos do acesso administrativo. À esquerda, antes: admin, desk e um notebook têm cada um uma linha direta para o web e para o db, seis caminhos ao todo. À direita, depois: o admin tem uma linha para o jump, e o jump tem uma linha para cada servidor; o desk e o notebook não têm linha para servidor nenhum.\"><defs><marker id=\"l15-one-door-dh-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l15-one-door-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"170.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">antes: toda máquina é uma entrada</text><text x=\"540.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">depois: uma porta</text><rect x=\"20.0\" y=\"50.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">admin</text><rect x=\"20.0\" y=\"120.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"20.0\" y=\"190.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"70.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">notebook</text><rect x=\"230.0\" y=\"80.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><rect x=\"230.0\" y=\"170.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"280.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">db</text><path d=\"M120.0 68.0 L230.0 98.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 68.0 L230.0 188.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 138.0 L230.0 98.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 138.0 L230.0 188.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 208.0 L230.0 98.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><path d=\"M120.0 208.0 L230.0 188.0\" stroke=\"var(--amber)\" stroke-width=\"1.1\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-amber)\"></path><rect x=\"390.0\" y=\"50.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">admin</text><rect x=\"390.0\" y=\"120.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><rect x=\"390.0\" y=\"190.0\" width=\"100.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">notebook</text><rect x=\"520.0\" y=\"50.0\" width=\"80.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560.0\" y=\"68.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">jump</text><rect x=\"620.0\" y=\"120.0\" width=\"80.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">web</text><path d=\"M580.0 86.0 L640.0 120.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-phosphor)\"></path><rect x=\"620.0\" y=\"190.0\" width=\"80.0\" height=\"36.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">db</text><path d=\"M580.0 86.0 L640.0 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-phosphor)\"></path><path d=\"M490.0 68.0 L520.0 68.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-one-door-dh-ah-phosphor)\"></path><text x=\"460.0\" y=\"255.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">desk e notebook não alcançam servidor nenhum</text></svg>", "caption": "Seis caminhos para auditar antes, um depois. Quem decide são os servidores, não os administradores."}
```

Um servidor de salto é tão forte quanto as regras que obrigam o tráfego a passar por ele. **Um
bastião em que os servidores não insistem é uma conveniência, não um controle**: os administradores o
usam nos dias bons e dão a volta no dia em que importa. O resto da aula monta a porta, depois fecha os
outros caminhos em volta dela, depois faz as chaves que a abrem expirarem e, por fim, a faz dizer
quem passou.
