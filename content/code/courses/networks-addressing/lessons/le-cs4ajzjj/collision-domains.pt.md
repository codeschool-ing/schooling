---
title: "Domínios de colisão: quem precisa esperar a vez"
version: 1
---

"Colisão" soa como um acidente que uma boa rede evita. Na Ethernet antiga, ela fazia parte do
projeto. **Um domínio de colisão é o conjunto de equipamentos cujas transmissões podem colidir:
equipamentos que dividem um meio, de modo que só um deles transmite de cada vez.** A pergunta desta
seção é o tamanho desse conjunto, e a resposta depende inteiramente do que liga os equipamentos.

## Dividindo um fio

As primeiras Ethernets eram um cabo coaxial passando por todas as máquinas, e um hub, da aula 1, é
a mesma coisa dobrada dentro de uma caixa. Cada máquina ouve cada sinal, então se duas começam
juntas, os dois quadros se embaralham. A resposta da Ethernet foi o **CSMA/CD** (*carrier sense,
multiple access, collision detection*):

1. escutar, e transmitir só quando o meio está quieto;
2. continuar escutando enquanto transmite; se o sinal no fio não é o seu, houve uma colisão;
3. parar, mandar um sinal curto de congestionamento (*jam*) para que todos percebam, e esperar um
   tempo aleatório antes de tentar de novo, para os dois remetentes não colidirem outra vez.

Funciona, e piora quanto mais máquinas dividem o meio: mais delas esperando silêncio, mais
colisões, mais esperas aleatórias. Um enlace em que um equipamento envia ou recebe, mas não os dois
ao mesmo tempo, é **half duplex**, e o CSMA/CD é o que uma Ethernet half duplex executa.

## Um por porta

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Dois painéis lado a lado. À esquerda, um hub: pc1, pc2, pc3 e srv cabeados a ele, os quatro cabos dentro de um único contorno tracejado chamado um domínio de colisão, porque um hub repete cada bit para todas as portas e só uma máquina pode transmitir por vez. À direita, um switch com as mesmas quatro máquinas, cada cabo dentro do seu próprio contorno tracejado: quatro domínios de colisão, um por porta, e num enlace full duplex nenhum deles colide.\"><defs><marker id=\"l18-coll-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">hub: camada 1</text><text x=\"540\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">switch: camada 2</text><rect x=\"16\" y=\"56\" width=\"328\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"180\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um domínio de colisão</text><rect x=\"24\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M60 98 L60 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"104\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"140\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><path d=\"M140 98 L140 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"184\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><path d=\"M220 98 L220 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"264\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"300\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><path d=\"M300 98 L300 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"24\" y=\"184\" width=\"312\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada bit, por todas as portas</text><text x=\"540\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">quatro domínios de colisão, um por porta</text><rect x=\"382\" y=\"56\" width=\"76\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"384\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"420\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc1</text><path d=\"M420 98 L420 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"462\" y=\"56\" width=\"76\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"464\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"500\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc2</text><path d=\"M500 98 L500 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"542\" y=\"56\" width=\"76\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"544\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"580\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">pc3</text><path d=\"M580 98 L580 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"622\" y=\"56\" width=\"76\" height=\"128\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><rect x=\"624\" y=\"66\" width=\"72\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">srv</text><path d=\"M660 98 L660 184\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"384\" y=\"184\" width=\"312\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cada quadro, por uma porta</text><text x=\"180\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">half duplex: um fala de cada vez</text><text x=\"540\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">full duplex: nenhuma colisão</text></svg>", "caption": "As mesmas quatro máquinas em um hub e em um switch: quem precisa esperar a vez."}
```

Um switch muda a conta. Ele recebe cada quadro inteiro antes de mandá-lo adiante, então um quadro
numa porta nunca encontra um quadro em outra: **cada porta de um switch é um domínio de colisão à
parte**. Com um equipamento por porta, as únicas duas coisas que poderiam colidir são o equipamento
e o próprio switch, e a Ethernet moderna elimina até isso. Um cabo de par trançado tem pares
separados para cada sentido, então as duas pontas transmitem no mesmo instante: isso é **full
duplex**, e num enlace full duplex não há meio compartilhado, nada para escutar e nada para colidir.
O CSMA/CD fica desligado.

A placa do pc1 informa o que negociou, e os contadores dizem o que aconteceu:

```
ana@pc1:~$ sudo ethtool eth0 | grep -E "Speed|Duplex"
	Speed: 10000Mb/s
	Duplex: Full
ana@pc1:~$ ip -s link show eth0 | tail -2
    TX:  bytes packets errors dropped carrier collsns           
          1788      24      0       0       0       0 
```

`Duplex: Full`, e **`collsns` 0** depois do tráfego dos blocos anteriores desta aula. `Speed:
10000Mb/s` pede um aviso: esta é uma placa virtual, que não carrega sinal algum, e o número é só o
que o driver `veth` declara. Uma placa física informa a velocidade que combinou com a porta da outra
ponta.

## Onde colisões ainda aparecem

Você não verá colisões numa rede comutada saudável, e é exatamente por isso que vê-las informa
alguma coisa. A causa comum é um **descasamento de duplex** (*duplex mismatch*): uma ponta do
enlace configurada à mão como full duplex, a outra deixada negociando e caindo para half. A ponta
half vê a outra transmitindo enquanto ela envia, conta colisões, recua e retransmite; a ponta full
vê quadros danificados. O enlace funciona, devagar e mal, e **contadores de colisão ou de erro
subindo num enlace comutado apontam para a configuração das duas pontas**, e não para o cabo.
Configurar as duas pontas do mesmo jeito, em geral as duas negociando, é o conserto.

O resto é história que vale reconhecer numa prova ou num prédio antigo: um hub, ou uma corrente de
hubs e repetidores, é um domínio de colisão, tenha quantas portas tiver; uma bridge ou um switch o
divide em cada porta.
