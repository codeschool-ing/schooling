---
title: O sistema no seu ambiente
version: 1
---

É tentador pensar na arquitetura como algo que acontece dentro do código, entre serviços e bancos de
dados. **A maior parte das forças que dão forma a uma arquitetura vem de fora dela.** São as pessoas
que usam o sistema e pagam por ele, as regras que ele precisa obedecer, os times que o constroem,
quem o mantém de pé às três da manhã e o negócio que ele existe para servir. A norma falava em "um
sistema no seu ambiente", e o ambiente é onde começa a maior parte das perguntas de um arquiteto.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Três regiões, uma dentro da outra. No centro, o software da Carreto: o monólito e os outros serviços. Em volta, a Carreto como empresa: sete times cuja estrutura o software copia, e o time de Platform que o opera. Fora das duas: embarcadores, motoristas e transportadoras, a secretaria da fazenda que autoriza cada CT-e, a agência nacional de transportes que publica o piso do frete, os bancos que fazem os pagamentos por Pix e os concorrentes.\"><defs><marker id=\"env-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"340\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"5 4\"></rect><text x=\"360\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">fora da Carreto</text><rect x=\"170\" y=\"60\" width=\"380\" height=\"230\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">a Carreto, a empresa</text><rect x=\"250\" y=\"130\" width=\"220\" height=\"90\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"159.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o software:</text><text x=\"360\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o monólito e</text><text x=\"360\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">os outros serviços</text><text x=\"360\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">7 times: a estrutura que</text><text x=\"360\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o software acaba copiando</text><text x=\"360\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Platform opera tudo;</text><text x=\"360\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">produto e finanças pagam</text><rect x=\"22\" y=\"60\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">embarcadores: cotação,</text><text x=\"90.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">CT-e, onde está a carga</text><rect x=\"22\" y=\"230\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">motoristas: sinal fraco,</text><text x=\"90.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">receber rápido</text><rect x=\"562\" y=\"60\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">SEFAZ: autoriza</text><text x=\"630.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">cada CT-e</text><rect x=\"562\" y=\"140\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ANTT: o piso</text><text x=\"630.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mínimo do frete</text><rect x=\"562\" y=\"230\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"250.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">bancos: pagamentos</text><text x=\"630.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">por Pix</text><rect x=\"22\" y=\"145\" width=\"136\" height=\"54\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">concorrentes: cotação</text><text x=\"90.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lenta perde a carga</text><text x=\"360\" y=\"320\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cada força de fora vira um atributo de qualidade pelo qual a estrutura é julgada</text></svg>", "caption": "Um sistema no seu ambiente. O software fica dentro de uma empresa, e a empresa dentro de um mundo de clientes, reguladores e parceiros; cada camada empurra a estrutura do centro."}
```

## As pessoas com algo em jogo

Uma *parte interessada* é qualquer pessoa afetada pelo sistema ou capaz de afetá-lo. Na Carreto a
lista é longa, e cada item se importa com uma coisa diferente:

- os embarcadores querem uma cotação em segundos, um CT-e emitido sem erro e saber onde está a
  carga;
- os motoristas querem que o app funcione com sinal fraco no acostamento de uma estrada, e receber
  rápido e certo;
- Sílvio Matos, o diretor financeiro, quer que cada fatura bata com cada pagamento, e uma trilha de
  auditoria quando o fisco perguntar;
- Helena Prado, a diretora de produto, quer que as funcionalidades novas cheguem aos embarcadores
  sem um trimestre de espera;
- os sete times querem mudar a própria parte sem esperar pelos outros seis.

Esses desejos puxam uns contra os outros. A trilha de auditoria do diretor financeiro custa
armazenamento e código que a diretora de produto preferiria gastar em funcionalidades; o sinal fraco
dos motoristas pede um app que funcione off-line, o que torna o fluxo de pagamento mais difícil de
manter consistente. **Uma arquitetura é em parte o registro de como esses puxões foram resolvidos**,
e um arquiteto que só conversa com engenheiros os resolve sem saber que existiam. A aula 7 trata de
tirar esses desejos de quem os tem, e a aula 10 de trabalhar com essas pessoas ao longo do tempo.

## As regras

O frete no Brasil é regulado, e as regras entram na estrutura do sistema em vez de ficarem na borda
dele.

**O conhecimento de transporte eletrônico.** Todo serviço de frete precisa de um CT-e — Conhecimento
de Transporte Eletrônico — autorizado pela secretaria da fazenda do estado (SEFAZ) antes de o
caminhão sair. Então um passo do fluxo mais importante da Carreto depende de um serviço que a
Carreto não opera e não consegue consertar. A arquitetura precisa dizer o que acontece quando essa
autorização está lenta ou indisponível, e quem fica sabendo.

**O piso do frete.** A agência nacional de transportes, a ANTT, publica um piso mínimo do frete —
criado pela lei 13.703 de 2018 — e nenhuma cotação pode ficar abaixo dele. É uma regra que o Pricing
precisa aplicar, e ela tem uma consequência fácil de esquecer. A tabela do piso muda com o tempo,
então quando um embarcador contesta uma cotação meses depois, a Carreto precisa mostrar qual tabela
valia quando a cotação foi feita. **Uma regra regulatória virou um requisito de retenção de dados.**

**Pagar os motoristas.** Motoristas autônomos pagam combustível e pedágio antes de receber, e muitos
querem o dinheiro por Pix assim que a entrega é comprovada. Isso faz da velocidade e da correção de
Payments um motivo para o motorista escolher a Carreto em vez de um concorrente, e não um detalhe de
retaguarda.

Nenhuma delas é uma escolha técnica, e as três restringem escolhas técnicas. Um arquiteto não
precisa ser tributarista, e este curso não vai fingir ser, mas **um arquiteto que não sabe que as
regras existem vai desenhar um sistema que as quebra**.

## A organização

Em 1968, Melvin Conway observou que as organizações que projetam sistemas acabam produzindo desenhos
que copiam as suas próprias estruturas de comunicação. A observação ficou conhecida como **lei de
Conway**, e a Carreto a ilustra bem. O Tracking tem time próprio, e tem serviço próprio e banco
próprio. A tabela `loads` do monólito é lida e escrita por Payments, Matching e o app Shipper, três
times que já foram um só — e a tabela compartilhada é o rastro que o time antigo deixou no código.

A lei de Conway corta dos dois lados para um arquiteto. **Uma estrutura que ignora a organização é
dobrada de volta à forma dela**: um desenho com um serviço compartilhado por quatro times vira, em
um ano, quatro times na fila para mudar um serviço. E uma mudança de estrutura muitas vezes precisa
de uma mudança de times para pegar. A aula 10 volta a isso, inclusive ao uso deliberado da lei que
ficou conhecido como a manobra inversa de Conway.

## A operação

Alguém precisa implantar, monitorar e consertar o que quer que a arquitetura contenha. O time de
Platform da Carreto é um punhado de engenheiros cuidando da infraestrutura dos sete times, e cada um
dos 14 serviços implantáveis precisa de pipeline, painéis, alertas e de alguém que o entenda quando
ele falha. **Um desenho que exige mais habilidade de operação do que a empresa tem é um desenho ruim
para essa empresa**, por melhor que funcione num lugar com dez vezes mais gente. A aula 12 conta
quanto cada serviço da Carreto custa para ser mantido e pergunta quais se pagam.

## O negócio

Por fim, o sistema existe para a Carreto ganhar a vida. A empresa cobra uma taxa sobre o frete que
intermedeia, então a receita cresce com o número de cargas que se movem. Parte da demanda é sazonal:
as cooperativas de grãos publicam muito mais cargas na colheita do que no resto do ano. **O negócio
decide que qualidades valem o que custam**: uma cotação que leva dez segundos em vez de dois perde
embarcadores para um concorrente, enquanto um relatório mensal que leva uma hora para sair não perde
ninguém.

## Atributos de qualidade: para que serve a arquitetura

Junte as cinco e aparece um padrão. Quase qualquer funcionalidade — publicar uma carga, cotá-la,
pagar um motorista — poderia ser construída sobre quase qualquer estrutura: o monólito, catorze
serviços ou duzentos. O que a estrutura decide é **o quão bem** o sistema faz essas coisas: com que
rapidez, com que confiabilidade, com que segurança, com que custo de mudança, com que facilidade de
auditoria. Isso se chama *atributos de qualidade* (um nome mais antigo é requisitos não funcionais),
e **é para eles que uma arquitetura existe.**

Cada força desta seção aparece como um deles. O sinal fraco dos motoristas vira um requisito de
disponibilidade e de funcionamento off-line. A secretaria da fazenda vira um requisito de
resiliência a uma dependência externa. O piso do frete vira auditabilidade. Os sete times viram
modificabilidade e facilidade de implantação. O tamanho do time de Platform vira operabilidade. **Um
atributo de qualidade é o ambiente traduzido em algo pelo qual uma estrutura pode ser julgada.** A
aula 6 mostra como escrever um com precisão suficiente para ser testado, e a aula 7 como descobrir
de quais o negócio de fato precisa.

Isso completa a definição com que esta aula começou: elementos, as relações entre eles e o ambiente
a que respondem, julgados pelo que cada decisão custaria para mudar. A próxima aula tira do caminho
três coisas que costumam ser confundidas com arquitetura.
