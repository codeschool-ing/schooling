---
title: O arquiteto de PowerPoint
version: 1
---

**O arquiteto de PowerPoint descreve um sistema que só existe nos slides.** Os diagramas são
limpos, o estado-alvo é convincente, e os times constroem outra coisa, não por rebeldia, mas porque
os slides respondiam a perguntas que ninguém no código estava fazendo. A aula 2 traçou a linha que
esse anti-padrão cruza: um diagrama é uma visão da arquitetura, e a arquitetura é o que roda. Um
arquiteto que trabalha só na visão acaba sendo o autor de um documento com o qual o sistema não
bate.

Todo anti-padrão desta aula começa como um hábito razoável levado longe demais, e este não é
exceção. Desenhar o sistema faz parte do trabalho (aula 8), e descrever para onde ele deveria ir
também. A falha acontece quando o desenho substitui o sistema como aquilo para o qual o arquiteto
olha.

Esta aula descreve cada anti-padrão por meio de uma versão de Renata que pegou o caminho errado.
Essas versões são inventadas, como a própria Carreto; a Renata de verdade das aulas 1 a 16 não fez
essas coisas, e o motivo de imaginá-la fazendo é ver como o primeiro passo é pequeno.

## Como se parece

Imagine Renata daqui a dezoito meses, tendo passado a maior parte deles numa apresentação chamada
*Carreto 2028*. São 46 slides. O slide 12 mostra o fluxo de pagamento dos motoristas: o Tracking
publica um evento quando uma entrega é comprovada, o Payments o assina, e o app do Shipper lê as
faturas pela API do Payments. É um bom desenho. Enquanto isso, no código:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"Dois desenhos lado a lado. À esquerda, o slide 12 da apresentação Carreto 2028: o Tracking envia ao Payments um evento de entrega comprovada, e o app do Shipper lê as faturas do Payments por uma API. À direita, o código na mesma semana: o Payments consulta o Tracking a cada 5 minutos; o Payments escreve as faturas no banco do monólito e o app do Shipper as lê de lá; um job noturno copia os comprovantes de entrega do Tracking para o mesmo banco. O banco do monólito não está no slide.\"><defs><marker id=\"sl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M360 30 L360 300\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><text x=\"183\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">slide 12 de Carreto 2028</text><text x=\"537\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o código, na mesma semana</text><rect x=\"36\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"91\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper app</text><rect x=\"220\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Tracking</text><rect x=\"128\" y=\"200\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"183\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Payments</text><path d=\"M262 112 L210 196\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"250\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">evento:</text><text x=\"250\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">entrega comprovada</text><path d=\"M150 198 L104 114\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"108\" y=\"160\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">API de faturas</text><rect x=\"390\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"445\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper app</text><rect x=\"574\" y=\"70\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"629\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Tracking</text><rect x=\"574\" y=\"170\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"629\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Payments</text><rect x=\"390\" y=\"250\" width=\"150\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"465\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">banco do monólito</text><path d=\"M629 168 L629 114\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"638\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">consulta a cada</text><text x=\"638\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">5 minutos</text><path d=\"M445 112 L445 246\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"438\" y=\"180\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lê</text><path d=\"M590 212 L532 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sl-ah)\"></path><text x=\"584\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">escreve</text><path d=\"M580 112 L512 246\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\" marker-end=\"url(#sl-ah)\"></path><text x=\"538\" y=\"168\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">cópia noturna</text></svg>", "caption": "Os mesmos três serviços. O slide tem duas conexões; o código tem três, e duas delas passam por um banco de dados que o slide não desenha.", "same": ["Shipper app", "Tracking", "Payments"]}
```

Três conexões onde o slide tem duas, e duas delas passando por um banco de dados que ninguém
desenhou. Nenhuma das três era segredo; cada uma foi acrescentada por um time resolvendo um problema
daquela semana, e nenhum desses times tinha motivo para abrir a apresentação. Os sintomas que
denunciam o anti-padrão:

- **Os diagramas são datados pela reunião, não pelo código.** Ninguém sabe dizer qual commit o slide
  12 descreve, porque ele não descreve nenhum.
- **Os times concordam na revisão e constroem outra coisa.** Contestar um slide custa uma reunião;
  ignorá-lo não custa nada.
- **O arquiteto fica sabendo da produção pelos incidentes.** Ela não está de plantão, não lê pull
  requests e não abre o repositório desde que a apresentação começou.
- **Perguntas sobre hoje são respondidas com o alvo.** "Como o Payments fica sabendo que uma entrega
  foi comprovada?" recebe "na arquitetura-alvo, por um evento", o que é verdade na apresentação e
  falso no sistema.

## Por que acontece

As causas são comuns, e é isso que torna o anti-padrão frequente.

**Slides são recompensados onde são vistos.** A plateia de uma apresentação de arquitetura-alvo é
Tomás, Helena e Sílvio, que veem uma história clara e não têm como conferi-la contra o código.
Ninguém naquela sala está em posição de dizer "o slide 12 não é assim que funciona".

**Um alvo é mais fácil de desenhar que um caminho.** Desenhar 2028 leva uma semana. Ir de hoje até
lá significa negociar com sete times, ordenar os passos de modo que cada um vá para produção e
aceitar que o desenho vai mudar no caminho. O primeiro é um trabalho satisfatório e o segundo é a
maior parte do trabalho.

**O arquiteto parou de escrever e de ler código.** A aula 15 chamou isso de perder a calibração: o
arquiteto que já não sente quanto um desenho custa para construir deixa de perceber que o desenho
não está sendo construído.

**Ninguém é dono do desenho depois que ele é apresentado.** A aula 8 mostrou como um documento sem
dono apodrece, e como o documento desatualizado em que ainda se acredita faz mais mal do que um que
falta.

## Quanto custa

O primeiro custo são **decisões tomadas com base numa figura**. Um engenheiro novo, lendo a
apresentação na primeira semana, constrói uma funcionalidade sobre o evento de entrega comprovada e
passa três dias descobrindo que ele não existe. A Carreto contrata cerca de doze engenheiros por ano;
três dias cada são **36 dias por ano** perdidos para um diagrama, sem contar os gestores que
prometeram aos embarcadores uma funcionalidade porque o slide a fazia parecer a um passo de
distância.

O segundo custo é mais lento e pior: **a credibilidade do arquiteto**. Quando um time descobre que
os slides não são o sistema, passa a descontar tudo o que o arquiteto diz, inclusive as partes que
estavam certas. A aula 3 descreveu a autoridade como algo conquistado com histórico; o arquiteto de
PowerPoint a gasta num documento e não recebe nada em troca.

## A alternativa

A alternativa não é parar de desenhar. É amarrar o desenho ao sistema nas duas pontas:

- **Desenhe primeiro o que existe, e date o desenho.** A visão do estado atual mora ao lado do
  código, é revisada em pull requests como o código e diz qual versão descreve (aula 8). Um alvo
  desenhado ao lado de um estado atual honesto mostra a própria distância da realidade.
- **Faça do alvo uma sequência de passos, cada um entregável.** "O Payments assina o evento de
  entrega comprovada" vira um primeiro passo do time do Tracking, com uma data. **Um alvo sem
  primeiro passo é um desejo.**
- **Deixe o build conferir o desenho onde for possível.** A fitness function da aula 9 falha quando o
  Payments importa os internos do Matching; é um diagrama que não consegue se afastar do código,
  porque quebra o build no dia em que o código discorda dele.
- **Continue no código** (aula 15), para que o desenho seja feito por alguém que perceberia quando
  ele deixasse de ser verdade.

Uma pergunta separa os dois tipos de arquiteto: **quem desenhou esta seta consegue apontar o código
em que ela vive?** A Renata de verdade consegue. A versão com a apresentação só conseguiria apontar o
slide.
