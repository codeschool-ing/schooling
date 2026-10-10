---
title: A rede não é de graça
version: 1
---

Dentro do monólito, pedir uma contagem de estoque era uma chamada de função. Agora é uma requisição
pela rede, e as duas se parecem no código: `stock_call(...)` se lê como qualquer outra função. **O
custo não se parece, e o jeito de falhar também não.**

`bench.py` faz a mesma pergunta mil vezes de cada jeito, de dentro do contêiner da loja:

```
ana@vm:~/lab/split$ docker compose exec shop python bench.py
function call        0.10 µs per call
HTTP call         1809.60 µs per call
```

Nesta máquina a chamada de função levou uma fração de microssegundo e a chamada HTTP levou 1809,60
microssegundos, quase dois milissegundos, o que é mais de dez mil vezes mais tempo. Os seus números
vão ser outros, e a chamada HTTP continua milhares de vezes mais lenta. A maior parte desses dois
milissegundos não é a rede em si, já que os dois contêineres estão na mesma máquina; é tudo em volta
dela: resolver o nome `stock`, abrir uma conexão TCP, escrever e interpretar HTTP, e um servidor
Python respondendo. Um serviço de verdade reaproveita conexões e responde mais rápido, e uma rede de
verdade entre duas máquinas acrescenta o seu próprio atraso por cima.

**Dois milissegundos não são nada uma vez e são muita coisa cem vezes.** Uma página que mostra
quarenta produtos e pergunta ao serviço de estoque uma vez por produto gasta oitenta milissegundos só
nisso, antes de qualquer outra coisa acontecer, e é por isso que a loja pede todas as contagens numa
chamada só. A aula 16 dá a isso o nome de antipadrão, I/O tagarela.

## Tudo o que pode acontecer com uma chamada

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma chamada de função dentro de um processo é uma seta, que leva cerca de um décimo de microssegundo. A mesma pergunta feita pela rede aparece em cinco passos: resolver o nome, abrir uma conexão, mandar a requisição, o outro serviço trabalhar, a resposta voltar. Cada passo está marcado como um lugar onde a chamada pode falhar ou esperar.\"><defs><marker id=\"l2-call-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"240\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"26\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">dentro de um processo: units[sku]</text><rect x=\"40\" y=\"44\" width=\"640\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">um passo, cerca de 0,1 µs</text><text x=\"26\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">pela rede: GET http://stock:8001/stock/coffee</text><rect x=\"30\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"91\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">resolver o nome</text><rect x=\"30\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"91\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nome não existe</text><path d=\"M153 139 L164 139\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-call-ah-amber)\"></path><rect x=\"166\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"227\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">abrir a conexão</text><rect x=\"166\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"227\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recusada, lenta</text><path d=\"M289 139 L300 139\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-call-ah-amber)\"></path><rect x=\"302\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"363\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mandar o pedido</text><rect x=\"302\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"363\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perdido, cortado</text><path d=\"M425 139 L436 139\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-call-ah-amber)\"></path><rect x=\"438\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"499\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o serviço trabalha</text><rect x=\"438\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"499\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lento, cai</text><path d=\"M561 139 L572 139\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l2-call-ah-amber)\"></path><rect x=\"574\" y=\"116\" width=\"122\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"635\" y=\"139\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a resposta volta</text><rect x=\"574\" y=\"180\" width=\"122\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"635\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">perdida, atrasada</text><text x=\"360\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um lugar para falhar ou esperar, embaixo de cada passo</text></svg>", "caption": "A mesma pergunta, feita de dois jeitos. Dentro do processo há um passo, e ele não falha sozinho; pela rede há cinco, e cada um tem o seu jeito de falhar ou esperar."}
```

Uma chamada de função pode estar errada, mas não pode se *perder*. Uma chamada de rede pode falhar em
qualquer um desses passos, e do lado de quem chama vários deles parecem iguais: quando nenhuma
resposta chega, a requisição pode nunca ter chegado ao serviço de estoque, ou pode ter sido processada
e a resposta se perdido na volta. **Quem chama não sabe dizer qual**, e isso importa: no segundo caso
as unidades foram baixadas. A aula 7 trata desse caso.

## As falácias

Em 1994 Peter Deutsch, na Sun Microsystems, listou as suposições que programadores novos em sistemas
distribuídos fazem e que são falsas; James Gosling acrescentou a oitava depois:

1. A rede é confiável.
2. A latência é zero.
3. A largura de banda é infinita.
4. A rede é segura.
5. A topologia não muda.
6. Existe um administrador.
7. O custo de transporte é zero.
8. A rede é homogênea.

Todas eram verdade dentro do monólito, porque não havia rede. **Dividir um programa torna todas
falsas de uma vez**, e o código que era correto não muda para avisar. `stock_call` tem um timeout de
dois segundos por causa das duas primeiras; o resto do curso trata em boa parte das outras.
