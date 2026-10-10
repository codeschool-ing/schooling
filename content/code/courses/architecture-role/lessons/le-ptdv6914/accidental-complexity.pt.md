---
title: A complexidade que o problema traz, e a que nós acrescentamos
version: 1
---

Um sistema com muitas partes parece um sistema sério, e uma arquiteta ouve a pergunta "o que
acrescentar?" muito mais vezes do que "o que tirar?". Por baixo existe a crença de que complexidade
é sinal de maturidade: o negócio cresce, então os serviços, as camadas e as ferramentas se
multiplicam junto. **Parte da complexidade vem do problema, e não sai sem levar junto um pedaço do
negócio. O resto foi acrescentado por quem construiu o sistema, e cada pedaço dele poderia, em
princípio, sair de novo.** Separar as duas é onde a simplificação começa.

## Brooks: essência e acidente

Fred Brooks traçou essa linha em 1986, num ensaio chamado "No Silver Bullet — Essence and Accident
in Software Engineering". Ele dividiu a dificuldade de construir software em duas. **A complexidade
essencial pertence ao problema**: os conceitos que o software precisa representar e as regras que
precisa obedecer. **A complexidade acidental pertence ao jeito como construímos**: as linguagens, as
ferramentas, as máquinas e as estruturas que usamos para expressar esses conceitos.

A palavra "acidental" engana, então vale acertá-la. Brooks não falava de complexidade criada por
engano ou por descuido. Ele usou a palavra no velho sentido filosófico, vindo de Aristóteles: um
acidente é uma propriedade que uma coisa por acaso tem, em oposição à essência, as propriedades que
ela precisa ter para ser o que é. A complexidade acidental muitas vezes é o resultado de uma decisão
perfeitamente sensata. Ela é acidental porque outra decisão teria resolvido o mesmo problema sem ela.

O argumento dele era este. Os grandes ganhos da programação até os anos 1980, como as linguagens de
alto nível e o tempo compartilhado, tinham vindo de atacar a complexidade acidental, e o que sobrava
era sobretudo essencial; por isso nenhuma técnica nova traria, sozinha, uma melhora de dez vezes em
uma década. Quarenta anos depois, a parte do ensaio que uma arquiteta usa toda semana é a própria
distinção.

## A essência da Carreto

Na Carreto a complexidade essencial é grande, e nada dela é opcional.

- **O CT-e.** Todo serviço de frete precisa de um conhecimento de transporte eletrônico autorizado
  pela autoridade fiscal estadual antes de o caminhão sair (aula 1). O leiaute, as regras de
  validação e as rejeições são da autoridade fiscal, não da Carreto.
- **O piso mínimo do frete.** A ANTT publica o piso abaixo do qual uma cotação não pode ficar, então
  Pricing precisa conhecê-lo e aplicá-lo, pague o mercado o que pagar.
- **O próprio Matching.** Uma carga tem peso, tipo de mercadoria, janela de coleta e destino; um
  motorista tem veículo, posição, agenda e histórico. Oferecer a carga certa aos motoristas certos é
  o negócio.
- **Pagar as pessoas.** Os motoristas recebem por Pix e os embarcadores são faturados, e os dois
  lados precisam fechar até o centavo.

Nenhuma arquitetura remove nada disso. Um design só consegue expressar tudo isso com mais ou menos
clareza. **Uma arquiteta que promete simplificar a emissão do CT-e está prometendo simplificar a
autoridade fiscal.**

## O acidente da Carreto

A complexidade acidental é tudo o que a Carreto acrescentou no caminho para lidar com essa essência.
Eis parte da lista que Renata fez no primeiro mês:

- 14 serviços implantáveis para 50 engenheiros em 7 times, vários deles chamados por exatamente um
  outro serviço;
- dois jeitos de os serviços conversarem, chamadas HTTP e o broker de mensagens, sem regra para
  escolher, de modo que alguns pares de serviços usam os dois;
- três jeitos de configurar um serviço: variáveis de ambiente, um serviço de configuração feito em
  casa e, em dois lugares, um arquivo de configuração versionado no repositório;
- dois lugares que guardam o status de uma carga, a tabela do monólito e uma cópia no serviço de
  busca de cargas, sincronizadas por um job noturno que falha mais ou menos uma vez por mês.

Cada item tinha um motivo no dia em que entrou. **Nada disso é exigido pelo frete, pelo fisco ou
pelo dinheiro**, e cada item é algo que uma pessoa recém-chegada precisa aprender antes de mudar o
sistema com segurança.

## Cada peça custa, todo mês

Isso importa porque uma peça de software não é paga uma vez só. Construir é o custo visível. Manter é
o maior, e ninguém manda a conta. Renata contou quatro tipos de custo que todo serviço implantável
carrega, mude alguém o código dele ou não.

- **Plantão.** Alguém carrega o pager dele, precisa de um runbook para ele e é acordado por ele. Nos
  90 dias anteriores, os 14 serviços da Carreto tinham acionado gente 112 vezes.
- **Atualizações.** A versão da linguagem, o framework, as bibliotecas e a imagem base envelhecem
  quer alguém mexa no serviço quer não, e as correções de segurança chegam no ritmo delas. Paula
  Reis, de Platform, mediu o trabalho rotineiro de atualização em cerca de 6 horas por serviço por
  mês: 84 horas por mês nos 14, mais ou menos metade de um engenheiro.
- **Documentação.** Um serviço sem documentação só pode ser mudado por quem o escreveu, e um
  documentado tem documentos que apodrecem (aula 8).
- **Conhecimento.** Alguém precisa lembrar por que ele existe, quem o chama e o que quebra quando ele
  para. Quando essa pessoa sai, o conhecimento sai junto, a não ser que o serviço tenha saído antes.

A conta de um único serviço pequeno mostra o formato. Suponha que ele tenha levado três
semanas-engenheiro para ser construído, 120 horas, e custe 10 horas por mês para ser mantido: 6 de
atualizações e 4 de plantão e dúvidas. No primeiro aniversário, manter já custou o mesmo que
construir, e em três anos custa três vezes mais.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 312\" role=\"img\" aria-label=\"Um gráfico de horas somadas contra meses, de 0 a 36. Uma linha plana em 120 horas: construir o serviço, pago uma vez. Uma linha que sobe 10 horas por mês: mantê-lo. A linha que sobe cruza a plana no mês 12, quando manter já custou o mesmo que construir, e chega a 360 horas no mês 36, três vezes o custo de construir.\"><defs><marker id=\"keepcost-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 270 L690 270\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#keepcost-ah)\"></path><path d=\"M80 270 L80 36\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#keepcost-ah)\"></path><text x=\"80.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">0</text><text x=\"280.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">12</text><text x=\"480.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">24</text><text x=\"680.0\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">36</text><text x=\"70\" y=\"204.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">120</text><path d=\"M80 204.0 L680 204.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"70\" y=\"138.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">240</text><path d=\"M80 138.0 L680 138.0\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"70\" y=\"71.99999999999997\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">360</text><path d=\"M80 71.99999999999997 L680 71.99999999999997\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"0.5\"></path><text x=\"690\" y=\"304\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">meses</text><text x=\"90\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">horas, somadas</text><path d=\"M80 204.0 L680 204.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></path><text x=\"676\" y=\"220.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">construir: 120 horas, uma vez</text><path d=\"M80 270 L680 71.99999999999997\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></path><text x=\"676\" y=\"55.99999999999997\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">manter: 10 horas por mês, 360 no mês 36</text><circle cx=\"280.0\" cy=\"204.0\" r=\"5\" fill=\"var(--paper)\"></circle><text x=\"270.0\" y=\"228.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mês 12: manter já custou</text><text x=\"270.0\" y=\"243.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o mesmo que construir</text></svg>", "caption": "Um serviço pequeno, construir contra manter. A linha plana é o custo que todo mundo vê; a que sobe não vem com conta, e no terceiro ano vale três vezes a outra."}
```

**Uma peça do sistema é um passivo que às vezes se paga, não um ativo que às vezes custa alguma
coisa.** A pergunta a fazer sobre cada uma é se o que ela compra vale o que ela custa todo mês. Um
deploy independente, uma falha mantida longe do resto, uma escala que o monólito não alcança: essas
são compras de verdade. O curso `architecture` fez o mesmo argumento sobre microsserviços na aula 2
dele. A próxima seção o aplica a um inventário real, uma linha de cada vez.
