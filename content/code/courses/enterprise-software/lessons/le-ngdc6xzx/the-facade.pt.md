---
title: Uma fachada na frente, e o sistema antigo encolhendo atrás dela
version: 1
---

O strangler de livro começa com um movimento só: **colocar algo que você controla entre o sistema
antigo e todo mundo que o chama.** No começo isso repassa cada requisição direto, e ninguém percebe
que está ali. Depois, uma capacidade de cada vez, começa a mandar algumas requisições para outro
lugar. O sistema antigo continua respondendo tudo o que ainda não mudou de lado, e a parte que ele
responde encolhe até não sobrar nada.

Esse algo costuma se chamar fachada, ou camada de roteamento. Para uma aplicação web é um proxy
reverso ou um API gateway, e a regra de roteamento é um caminho de URL. Para um sistema cujos
clientes chegam por um barramento de integração, é o barramento. Para a Coleta, cujas entradas são
quase todas arquivos, é outra coisa ainda, e a próxima seção trata desse caso. Esta trata da fachada
em si, porque as regras dela valem qualquer que seja a forma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"l13-stages\" aria-label=\"Três estágios de um strangler lado a lado, cada um com quem chama no topo e, abaixo, uma fachada que roteia por capacidade. No primeiro estágio as quatro capacidades vão para o sistema legado, uma caixa alta, e não existe sistema novo. No segundo, duas capacidades vão para o legado, agora mais baixo, e duas para o sistema novo. No terceiro, as quatro vão para o sistema novo e o legado é um contorno tracejado marcado como desligado.\"><defs><marker id=\"l13-stages-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l13-stages-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l13-stages-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · tudo para o legado</text><rect x=\"35.0\" y=\"43.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quem chama</text><rect x=\"25.0\" y=\"97.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fachada: roteia por capacidade</text><path d=\"M120.0 73.0 L120.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-paper-dim)\"></path><rect x=\"20.0\" y=\"160.0\" width=\"90.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"65.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">legado</text><path d=\"M60.0 128.0 L47.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M70.0 128.0 L59.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M80.0 128.0 L71.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M90.0 128.0 L83.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M240.0 30.0 L240.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · algumas capacidades mudaram</text><rect x=\"275.0\" y=\"43.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quem chama</text><rect x=\"265.0\" y=\"97.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fachada: roteia por capacidade</text><path d=\"M360.0 73.0 L360.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-paper-dim)\"></path><rect x=\"260.0\" y=\"160.0\" width=\"90.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">legado</text><rect x=\"370.0\" y=\"160.0\" width=\"90.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"188.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">novo</text><text x=\"415.0\" y=\"201.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sistema</text><path d=\"M310.0 128.0 L299.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M320.0 128.0 L311.0 156.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-amber)\"></path><path d=\"M360.0 128.0 L409.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M370.0 128.0 L421.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M480.0 30.0 L480.0 300.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"600.0\" y=\"22.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">3 · o legado não responde nada</text><rect x=\"515.0\" y=\"43.0\" width=\"170.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quem chama</text><rect x=\"505.0\" y=\"97.0\" width=\"190.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"600.0\" y=\"112.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fachada: roteia por capacidade</text><path d=\"M600.0 73.0 L600.0 95.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-paper-dim)\"></path><rect x=\"500.0\" y=\"160.0\" width=\"90.0\" height=\"120.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"545.0\" y=\"220.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desligado</text><rect x=\"610.0\" y=\"160.0\" width=\"90.0\" height=\"120.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"655.0\" y=\"213.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">novo</text><text x=\"655.0\" y=\"226.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sistema</text><path d=\"M590.0 128.0 L637.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M600.0 128.0 L649.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M610.0 128.0 L661.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><path d=\"M620.0 128.0 L673.0 156.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-stages-es-ah-phosphor)\"></path><text x=\"360.0\" y=\"304.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o que muda de lado é uma capacidade inteira; quem chama nunca muda</text></svg>", "caption": "A vida de um strangler em três quadros. A fachada fica onde está; atrás dela, o legado responde menos a cada estágio, até não responder nada."}
```

## Três estágios, e o que muda de lado entre eles

A figura mostra a vida inteira de um strangler em três quadros. No primeiro, toda requisição passa
pela fachada até o legado, e o sistema novo ainda não existe. O único trabalho da fachada é estar
ali, para que as mudanças seguintes não exijam nada do lado de quem chama.

No segundo, algumas capacidades são atendidas pelo sistema novo e o resto ainda pelo legado. **O que
mudou de lado foi uma capacidade, de ponta a ponta: algo que alguém pede e que é respondido por
inteiro por um lado só.** A consulta de fazenda, por exemplo, é uma capacidade. O Rota pede uma
fazenda pelo código e recebe a localização, o tamanho do tanque e os dias em que ela é coletada. Ou
a Coleta responde isso, ou o serviço novo responde; não existe versão em que a Coleta faz metade.

No terceiro, o legado não responde nada e pode ser removido. O que acontece com a fachada nessa hora
é uma escolha. Às vezes ela é apagada junto com o legado, e quem chama passa a apontar direto para o
sistema novo. Às vezes ela fica, porque virou uma borda estável e útil, com log e versionamento, e
quem chama nunca precisou saber que houve uma migração.

## Fatie por capacidade, nunca por camada

O erro comum aqui vem do jeito como os sistemas são desenhados. Um sistema legado parece um conjunto
de camadas: um banco de dados embaixo, regras de negócio no meio, telas ou arquivos em cima. Então o
plano que se oferece é mudar as camadas uma de cada vez: primeiro os dados para um banco novo,
depois a lógica para serviços, depois as telas.

**Mudar um sistema camada por camada é um big bang com roupa de strangler.** Nada do que alguém pede
é atendido pelo sistema novo até a última camada mudar, porque cada capacidade precisa das três.
Durante dois anos o banco novo é uma cópia em que ninguém confia, os serviços novos chamam a lógica
das telas antigas através de uma tradução, e cada um desses estados intermediários precisa
funcionar em produção. O risco que o strangler deveria eliminar uma fatia de cada vez é eliminado no
fim, todo de uma vez.

Uma fatia por capacidade atravessa todas as camadas. A consulta de fazenda leva os dados da fazenda,
a regra que decide em que dias ela é coletada e a interface que o Rota chama, e muda as três juntas.
Ela é mais fina que uma camada e vai até o fundo, e quando termina, algo de verdade mudou de lado.

## As regras da fachada

A fachada é a única peça da migração que toda requisição toca, e por isso atrai trabalho e problema
ao mesmo tempo. Quatro regras a mantêm útil.

**Ela roteia e não calcula.** A tentação chega cedo: a fachada vê todas as requisições, então por que
não fazer ela ajustar um campo, juntar duas respostas ou aplicar uma regra que o legado erra? Cada
uma dessas coisas transforma a fachada num terceiro sistema com regras de negócio próprias, que não
é nem o antigo nem o novo e também vai precisar ser migrado. A fachada decide para onde vai uma
requisição e nada sobre qual é a resposta.

**Ela diz qual lado atendeu cada requisição.** Uma linha de log por requisição, com a capacidade e o
destino, é o relatório de progresso mais honesto que a migração vai ter. Ela também diz, no dia em
que algo der errado, se a reclamação veio de uma requisição que o sistema novo respondeu.

**Toda rota pode voltar atrás.** Rotear a consulta de fazenda para o serviço novo é uma mudança de
configuração, e rotear de volta também. É o desfazer barato que um big bang nunca tem: quando o
serviço novo se comporta mal numa segunda-feira de manhã, a capacidade volta para o legado em
minutos, e o time corrige o problema sem que fazendas ou caminhões percebam. Uma rota que não pode
voltar, por exemplo porque o sistema novo começou a aceitar gravações que o legado nunca viu, é uma
porta de mão única, e precisa ser tratada e planejada como tal.

**A disponibilidade dela entra em tudo o que está atrás.** Uma fachada na frente de um sistema que
precisa rodar 365 dias por ano precisa ela mesma rodar 365 dias por ano. A aula 12 faz a conta:
dois componentes em cadeia multiplicam as disponibilidades, então uma fachada com 99,9% na frente de
um serviço com 99,9% dá cerca de 99,8%. Uma migração que deixasse o sistema menos disponível do que
era antes seria difícil de defender para quem está esperando os caminhões de leite.

## Escolhendo a primeira fatia

A ordem em que as capacidades mudam de lado é uma decisão, e a primeira é diferente das outras.
**A primeira fatia é escolhida para ensinar, não para render.** Ela deve ser pequena, de baixo risco e
mesmo assim real: algo que vá até a produção, para que o time construa o caminho do código até um
serviço rodando, o monitoramento, a escala de plantão e a chave de roteamento em algo onde um erro
custa pouco. Mudar primeiro o cálculo de pagamento seria aprender tudo isso justamente na capacidade
em que um erro custa mais.

Depois da primeira fatia, a ordem segue duas pressões. O valor puxa para as capacidades que o
negócio mais quer ver melhoradas. A dependência empurra para mudar primeiro o que outras capacidades
usam, porque uma capacidade que lê dados que o legado ainda controla precisa de uma sincronização que
já é trabalho por si só. A coexistência é o assunto da seção depois da próxima.

## Onde a Coleta tem uma borda

A Coleta quase não tem interface de pergunta e resposta. Os usuários digitam em terminais de tela
verde, as entradas chegam como arquivos, e a saída principal é um arquivo. Ela tem exatamente dois
lugares em que outro sistema faz uma pergunta e espera a resposta, e os dois são fluxos no
barramento de integração que o time do Rui Andrade opera (aula 8). Um é a consulta de fazenda, que o
Rota chama toda noite ao planejar as rotas do dia seguinte. O outro é o resumo da coleta do dia, que
o painel do time de qualidade pede a cada hora.

Os dois fluxos foram construídos em 2015, muito antes de alguém falar em substituir a Coleta, e os
dois já fazem o que uma fachada faz: o Rota e o painel chamam o barramento, e só o barramento sabe
que a resposta vem de um programa RPG no IBM i. **O barramento que a Serra Alta passou anos tentando
encolher é, para essas duas capacidades, uma fachada já instalada.** Mudar a consulta de fazenda de
lado é trocar o destino de um fluxo, mais uma tradução do modelo do serviço novo para a resposta que
o Rota espera.

Isso cobre duas capacidades das doze do inventário da Joana sobre o que a Coleta faz. As outras dez
não têm borda onde se apoiar. Os coletores portáteis dos caminhões, os arquivos de resultado do
laboratório, as telas dos funcionários e o arquivo noturno para o SAP pedem outra técnica, e esse é
o assunto da próxima seção.
