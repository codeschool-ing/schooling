---
title: Quando o app não está instalado, e o link precisa funcionar mesmo assim
version: 1
---

**Um link é tocado por alguém cujo celular pode não ter o app, e um bom link funciona dos dois jeitos.**
Esse é o argumento mais forte a favor de um link verificado sobre um esquema próprio.
`https://planner.example.com/course/sql` é um endereço web comum. Com o planner instalado e verificado,
ele abre o app naquele curso; sem ele, o navegador abre o mesmo endereço, e o site responde com uma
página sobre aquele curso. `planner://course/sql` não tem página web por trás. Num celular sem o
planner, não há nada para abrir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l11-decide\" aria-label=\"O que acontece quando um link é tocado, como um caminho de decisões. Primeiro: o link é https? Se não, usa um esquema próprio: se um app instalado reivindica o esquema, esse app abre, ou um diálogo se vários reivindicam; se nenhum, nada abre. Se o link é https: se um app instalado está verificado para o domínio, esse app abre na tela; se não, o navegador abre o endereço e o site responde.\"><defs><marker id=\"l11-decide-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l11-decide-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"285\" y=\"12\" width=\"150\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um link é tocado</text><rect x=\"285\" y=\"70\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"85.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">é um endereço</text><text x=\"360.0\" y=\"98.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">https?</text><path d=\"M360 44 L360 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><rect x=\"70\" y=\"150\" width=\"170\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"155.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um app instalado</text><text x=\"155.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">reivindica o esquema?</text><path d=\"M285 92 L155 92 L155 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><text x=\"220\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não · esquema próprio</text><rect x=\"10\" y=\"236\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"85.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">esse app abre, ou um</text><text x=\"85.0\" y=\"264.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">diálogo se forem vários</text><rect x=\"180\" y=\"236\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"235.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nada abre</text><path d=\"M115 194 L85 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><path d=\"M195 194 L235 236\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><text x=\"84\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><text x=\"232\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><rect x=\"470\" y=\"150\" width=\"180\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"560.0\" y=\"165.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um app instalado está</text><text x=\"560.0\" y=\"178.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">verificado no domínio?</text><path d=\"M435 92 L560 92 L560 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-paper-dim)\"></path><text x=\"498\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"400\" y=\"236\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"475.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o app abre, na</text><text x=\"475.0\" y=\"264.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tela que o link nomeia</text><rect x=\"560\" y=\"236\" width=\"156\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"638.0\" y=\"251.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o navegador abre a</text><text x=\"638.0\" y=\"264.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">página, e o site responde</text><path d=\"M530 194 L475 236\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-phosphor)\"></path><path d=\"M600 194 L638 236\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l11-decide-ah-phosphor)\"></path><text x=\"486\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><text x=\"636\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text></svg>", "caption": "O sistema segue este caminho antes de qualquer código do app rodar. Só um link https verificado tem resposta em todos os ramos."}
```

**O caminho da figura é decidido pelo sistema, nessa ordem, antes de o planner rodar.** O link é
`https` num domínio que um app instalado verificou? Então esse app abre, sem diálogo. Senão, o
navegador abre o endereço. A documentação da Apple sobre universal links diz o mesmo do iOS: quando a
pessoa não instalou o app, o sistema abre a URL no navegador padrão e o site trata o pedido. A
documentação do Android sobre App Links diz que quem não tem o app "vai para o seu site no lugar", e
cita isso como motivo para preferi-los.

## A página web faz parte do link

**Então o site precisa responder a todo caminho que o app responde.** O `site.ts` da seção anterior
serve uma página para todo endereço `/course/...`, e isso não é enfeite: é o que vê quem não tem o app.
Um link que abre o app num curso e dá 404 no navegador é um link que funciona para metade das pessoas
que o recebem, e a metade em que ele falha é justamente a que você queria alcançar. Na transcrição
daquela seção, `/course/sql` voltou com um `200` e uma página HTML, enquanto o mesmo caminho dentro do
app abriu `courses > course:sql`.

**Mais um caso quebra o desenho arrumado: a pessoa já está no navegador, no seu site.** A documentação
da Apple diz que um universal link tocado no Safari para uma página do mesmo domínio fica no Safari,
supondo que a pessoa queria continuar navegando; um link para esse domínio vindo de outro abre o app.
Então o site deve oferecer a própria entrada para o app, um banner ou um botão, em vez de contar com os
links dele para fazer a troca.

## Deep links adiados: sobreviver à instalação

**O link que mais importa é o tocado por alguém que nunca instalou o app.** A pessoa toca no link de
um amigo para um curso, o navegador abre a página do curso, e a página sugere o app. Ela o instala pela
loja, abre, e cai na primeira tela do planner, sem o curso que veio buscar à vista. O link se perdeu na
instalação, porque instalar pela loja não é abrir um link.

*Deferred deep linking*, o deep link adiado, é o nome de carregar o link por cima desse buraco: o app,
na primeira execução, descobre qual link trouxe a pessoa até a loja, e abre naquela tela. As
plataformas não facilitam. O Google Play passa uma string de *referrer* do link da loja para o app
recém-instalado, e a biblioteca Play Install Referrer do Android a lê. No iOS não há equivalente
entregue a todo app, e os serviços que oferecem links adiados ligam a instalação ao toque anterior por
outros meios. Cada um desses meios é uma decisão sobre os dados da pessoa, então a aula 13, sobre o
que a loja obriga a declarar e o que não vale a pena coletar, é o lugar de pesar um deles.

**Para o planner a decisão é fácil, e é a honesta para a maioria dos apps pequenos.** Quem instala o
planner por causa de um link para um curso perde um toque: abre Courses e escolhe o curso. O parser e
as pilhas estão prontos para o dia em que chegar um referrer, porque um referrer é mais uma string para
`parse` ler ou recusar, exatamente como um link.

| situação | `planner://course/sql` | `https://planner.example.com/course/sql` |
|---|---|---|
| planner instalado, link verificado | abre o planner | abre o planner, sem diálogo |
| planner instalado, arquivo ausente ou errado | abre o planner, ou um diálogo | abre o navegador |
| planner não instalado | nada para abrir | o navegador abre a página do curso |
| tocado dentro do Safari, no mesmo site | não se aplica | fica no Safari |
