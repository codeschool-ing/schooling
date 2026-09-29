---
title: Uma segunda região, e para que ela serve
version: 1
---

O atalho tentador é "vamos rodar em duas regiões", dito como se fosse multi-AZ com um cabo mais comprido.
**Uma segunda região é um plano de recuperação de desastre, e quanto dele você compra é definido por
dois números** que o negócio, não a engenharia, precisa declarar primeiro.

**RPO, o objetivo de ponto de recuperação, é quantos dados você pode perder**, medido
em tempo. Um RPO de uma hora quer dizer que depois de um desastre você pode voltar com o estado de uma
hora atrás, e tudo o que foi escrito nessa hora se perdeu. Um RPO perto de zero quer dizer que toda
escrita confirmada já precisa estar em outro lugar quando a região cai.

**RTO, o objetivo de tempo de recuperação, é quanto tempo você pode ficar fora do ar.** Um RTO de um
dia quer dizer que o negócio sobrevive a um dia sem o sistema; um RTO de cinco minutos quer dizer que
alguém precisa conseguir trocar de região em cinco minutos, às três da manhã, e tem que funcionar na
primeira vez.

Os dois são decisões de negócio ditas na linguagem do tempo, e a pergunta a fazer é "quanto nos custa
uma hora deste sistema fora do ar, e quanto nos custa uma hora de pedidos perdidos?". As respostas
escolhem um ponto numa escala.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro estratégias de recuperação de desastre em fila, da esquerda para a direita: backup e restauração, pilot light, warm standby e ativo-ativo. Uma seta em cima diz que o custo mensal sobe para a direita. Uma seta embaixo diz que o tempo de recuperação, e os dados que se podem perder, diminuem para a direita. Na segunda região, backup e restauração guarda só cópias dos dados; pilot light mantém os dados replicados e os servidores desligados; warm standby mantém uma cópia pequena de tudo rodando; ativo-ativo atende tráfego real pelas duas regiões.\"><defs><marker id=\"drs-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"60\" width=\"152\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Backup e restauração</text><text x=\"30\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na segunda região:</text><text x=\"30\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópias dos dados</text><text x=\"30\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nada rodando</text><text x=\"30\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">reconstruir do zero</text><rect x=\"196\" y=\"60\" width=\"152\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"206\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Pilot light</text><text x=\"206\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na segunda região:</text><text x=\"206\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dados replicados</text><text x=\"206\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">servidores prontos, off</text><text x=\"206\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">ligar e escalar</text><rect x=\"372\" y=\"60\" width=\"152\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"382\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Warm standby</text><text x=\"382\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na segunda região:</text><text x=\"382\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópia pequena rodando</text><text x=\"382\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dados replicados</text><text x=\"382\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aumentar a escala</text><rect x=\"548\" y=\"60\" width=\"152\" height=\"138\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"558\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Ativo-ativo</text><text x=\"558\" y=\"102\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na segunda região:</text><text x=\"558\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cópia inteira rodando</text><text x=\"558\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">atendendo usuários</text><text x=\"558\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">desviar o tráfego</text><text x=\"20\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">mais barato de manter</text><text x=\"700\" y=\"32\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">mais caro de manter</text><path d=\"M20 46 L700 46\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#drs-ah)\"></path><path d=\"M700 222 L20 222\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#drs-ah)\"></path><text x=\"20\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">volta mais rápido, perde menos</text><text x=\"700\" y=\"244\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">horas para recuperar</text><text x=\"360\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Nenhum ponto da escala é o certo em geral: RPO e RTO escolhem.</text></svg>", "caption": "As quatro estratégias são uma escala só. Ir para a direita compra RTO e RPO menores com dinheiro gasto todo mês numa região que, na maioria dos dias, não faz nada.", "same": ["Pilot light", "Warm standby"]}
```

## Quatro pontos numa escala

Backup e restauração guarda cópias dos dados na segunda região e nada rodando lá. Depois de um
desastre, você constrói o sistema inteiro de novo a partir das cópias. É o mais barato de manter, o
RPO é o tempo desde a última cópia, e o RTO é o quanto uma reconstrução demora, muitas vezes horas.

Pilot light mantém os dados replicados continuamente, então o RPO encolhe para o atraso da
replicação, e mantém os servidores definidos mas desligados, prontos para serem ligados e escalados. O
nome vem da chama-piloto de um aquecedor a gás, sempre acesa para o queimador poder acender.

Warm standby mantém uma cópia pequena mas completa do sistema rodando na segunda região, sem receber
tráfego de clientes. Recuperar é aumentar a escala dela e desviar o tráfego, o que leva minutos, não
horas.

Ativo-ativo atende usuários reais pelas duas regiões ao mesmo tempo. Perder uma quer dizer que a outra
carrega todo mundo, e ela precisa ter tamanho para isso. Tem o menor RTO e a maior conta, e traz um
problema que os outros evitam: duas regiões aceitando escritas ao mesmo tempo precisam concordar sobre
qual é o estado dos dados.

## Por que o RPO raramente é zero entre regiões

O piso calculado antes nesta aula decide isso. Um commit síncrono espera até a outra cópia ter a
escrita. Entre duas zonas é uma espera curta; entre São Paulo e a Virgínia são pelo menos 76,6 ms em
cada commit, antes de qualquer atraso real de rede. **Por isso a maior parte da replicação entre
regiões é assíncrona**: o primário confirma na hora e manda a mudança depois, e o que estava a caminho
quando a região caiu se perde. Essa janela em trânsito é o RPO, e é por isso que "zero perda de dados
entre regiões" é uma frase bem mais cara do que parece.

## A conta de transferência, e o seu sentido

A replicação move dados entre regiões, e a planilha precifica isso na linha "to the other region". As
duas colunas são o preço dos dados saindo de cada região: 0,1380 por GB saindo da `sa-east-1`, e
0,0200 por GB saindo da `us-east-1`. **O sentido decide o preço.**

Replique 500 GB por mês de um primário em São Paulo para um standby na Virgínia: 500 × 0,1380 = 69,00
dólares por mês. Rode a mesma replicação ao contrário, primário na Virgínia e standby em São Paulo:
500 × 0,0200 = 10,00 dólares. Os mesmos bytes, o mesmo cabo, 6,9 vezes o preço, e o sentido barato
poria o primário fora do Brasil, o que a primeira pergunta do checklist talvez já tenha descartado.

Some à transferência os recursos próprios da segunda região: nada rodando no backup e restauração, uma
cópia do armazenamento no pilot light, uma frota pequena no warm standby, uma inteira no ativo-ativo. A
escala da figura são esses custos postos em ordem.

**Um plano que ninguém testou é uma esperança.** Seja qual for o ponto escolhido, o RTO só é real se a
troca tiver sido ensaiada: restaurar o backup na segunda região, promover a réplica, desviar o tráfego,
e cronometrar. O primeiro ensaio costuma achar o passo que ninguém anotou.
