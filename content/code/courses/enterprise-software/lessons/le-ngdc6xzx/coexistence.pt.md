---
title: Coexistência, o meio longo
version: 1
---

Os planos de um strangler gastam as páginas no começo, onde entra a fachada, e no fim, onde o
sistema antigo é desligado. **A maior parte da vida da migração não se passa em nenhum dos dois: ela
se passa no meio, em que os dois sistemas rodam, cada um é dono de parte do trabalho e os dados
precisam estar nos dois.** Na Serra Alta o meio começa em março de 2027, quando o serviço de
qualidade assume os resultados de laboratório, e dura até o Coleta ficar só para leitura, o que o
plano marca para julho de 2028. São dezesseis meses no plano, e toda migração sobre a qual a Joana
leu levou mais tempo no meio do que o plano dizia.

Então o meio não é uma transição para atravessar. É um estado em que a empresa vive, e é desenhado
com o mesmo cuidado que qualquer outra coisa que roda por um ano e meio.

## Um dono para cada dado, em cada momento

A primeira decisão de desenho é sobre posse. Para cada tipo de dado, em cada fase, exatamente um
sistema é o mestre: aquele em que o dado é criado e alterado. **O outro sistema pode ter uma cópia,
mas nunca aceita uma alteração nela.** O plano da Joana registra isso numa tabela, e a tabela é
publicada num lugar onde os funcionários, o time do SAP e o time do barramento podem ler.

| dado | hoje | fase 1, março de 2027 | fase 2, setembro de 2027 | fase 3, abril de 2028 |
|---|---|---|---|---|
| resultados de laboratório | Coleta | **novo**, copiado para o Coleta | novo, copiado para o Coleta | novo |
| coletas diárias | Coleta | Coleta, copiado para o novo | **novo**, copiado para o Coleta | novo |
| cadastro de fazendas: tanques, rotas, dias de coleta, status | Coleta | Coleta, copiado para o novo | Coleta, copiado para o novo | **novo** |
| valores do pagamento mensal | Coleta | Coleta | Coleta | **novo** |
| arquivo noturno para o SAP | Coleta | Coleta | Coleta | **novo** |
| cadastro de fornecedor e conta bancária | SAP | SAP | SAP | SAP |

Cada coluna é uma fase com data, e cada célula em negrito é uma troca de mestre naquela data. As
datas são o primeiro rascunho do plano, feito antes de alguém escolher o que substitui o pagamento,
e supõem que ele seja construído em casa; a aula 15 compara as opções, e a decisão dela move junto a
fase 3, a data em que o Coleta fica só para leitura e o desligamento. Com as datas que a aula 15
fixa, as fases 2 e 3 se fundem no cutover único que a aula 14 descreve. Lendo
uma linha de ponta a ponta, você vê a vida de um tipo de dado. Os resultados de laboratório mudam
de lado primeiro, como a captura de ativos dizia. As coletas vêm na fase 2, que é quando o serviço
de recepção dos coletores portáteis para de repassar os arquivos brutos ao Coleta e passa a mandar as
coletas que o serviço novo aceitou. O cadastro de fazendas e o pagamento mudam juntos na fase 3,
porque o pagamento precisa do status de qualidade e dos dias de coleta do cadastro, e separar os
dois significaria sincronizar nas duas direções.

A última linha está ali de propósito. As fazendas são fornecedores no SAP, e é o SAP que guarda o
CPF ou CNPJ e a conta bancária delas (aula 1). Isso não muda de lado. Uma tabela que listasse só o
que muda deixaria alguém supor que os dados bancários faziam parte da migração do Coleta, e alguém
suporia.

## As cópias correm num sentido só, a partir do mestre

Onde uma célula diz "copiado para", a cópia vai do mestre para o outro sistema e nunca volta.
**Sincronizar nas duas direções é ter dois sistemas que acham que são donos do dado, e mais cedo ou
mais tarde eles discordam sem que ninguém consiga dizer qual está certo.** Quando a direção precisa
mudar, ela muda na data de uma fase, para um tipo de dado inteiro de uma vez, e as telas que
aceitavam alterações param de aceitar naquele dia.

Cada cópia tem um caminho definido. As cópias que saem do Coleta vêm dos journals dele por captura
de mudanças, traduzidas pela camada anticorrupção. As cópias que entram no Coleta passam pelo lado de
saída da camada, gravadas nos formatos do próprio Coleta, nos arquivos e tabelas que ele já lê. Os
dois caminhos são monitorados quanto ao atraso, e os dois têm um alarme para quando nada se mexeu
por mais tempo do que deveria.

## Nada de escrita dupla

O atalho que quebra isso é previsível, e o plano da Joana o nomeia de antemão. Na fase 2 os
funcionários vão corrigir coletas no sistema novo, e alguém vai propor que a tela de correção chame
também um programa do Coleta diretamente, para que o Coleta receba a mudança na hora em vez de pela
cópia de saída, alguns minutos depois.

Isso é uma escrita dupla (*dual write*): uma ação que grava em dois sistemas que não compartilham
transação. **Quando a segunda gravação falha depois de a primeira dar certo, os dois sistemas
discordam e nada registra que discordam.** O funcionário vê a correção salva; o Coleta nunca
recebeu; a fazenda é paga pelo número antigo. Falha raramente, que é o pior jeito de falhar, porque
falha justo no caso que ninguém testou e é descoberta semanas depois por um produtor.

A alternativa é a que a tabela já sugere. Grave uma vez, no mestre, e deixe a cópia seguir a partir
do registro de alterações do próprio mestre, com novas tentativas até chegar. A aula 10 mostra o
outbox transacional, que faz isso num sistema que você escreve, e a aula 9 apresentou a captura de
mudanças, que faz isso num sistema que você não pode alterar. O preço são alguns minutos em que o
Coleta fica atrás, e o plano deixa isso visível em vez de fingir que não existe: as telas de coleta
do Coleta mostram o horário da última cópia recebida.

## Conciliação, toda manhã

As cópias se desencontram mesmo quando todas as peças funcionam, porque uma mensagem fica presa, um
arquivo chega atrasado ou uma entrada de journal não é traduzida. Por isso, toda manhã às 06:00, um
job compara os dois lados. Para cada fábrica e cada dia, ele conta as coletas e soma os litros no
serviço novo e no Coleta, e cada diferença vai para a fila dos funcionários com as fazendas
envolvidas. **Uma diferença achada na manhã seguinte custa uma correção; a mesma diferença achada no
dia do pagamento custa a confiança de uma fazenda.** A aula 14 trata da conciliação como técnica,
com contagens, totais de controle e comparação registro a registro; aqui ela é a rotina diária que
torna a coexistência segura para se viver nela.

## A execução em paralelo, antes de mexer no dinheiro

A fase 3 muda o pagamento de lado, que é a capacidade em que um erro chega a 1.900 contas bancárias.
A proteção padrão é rodar o cálculo novo ao lado do antigo com as mesmas entradas, por alguns meses,
e comparar os resultados fazenda por fazenda enquanto os valores pagos continuam sendo os do sistema
antigo. Sam Newman descreve isso como *parallel run* em *Monolith to Microservices* (2019).

A Joana não esperou a fase 3 para começar uma. O que quer que substitua o pagamento do Coleta,
comprado, construído ou acrescentado ao SAP, vai ter de reproduzir as regras dele, e ninguém ainda
sabia dizer quais eram todas. Então, no meio de 2026, o time escreveu o pagamento como um
cálculo-sombra: um programa pequeno, alimentado com os próprios dados do Coleta através da camada
anticorrupção, que calcula quanto cada fazenda deveria receber. Ele rodou ao lado do Coleta por três
meses, sobre o leite de julho, agosto e setembro de 2026. Os valores pagos foram sempre os do
Coleta; os do cálculo-sombra não foram para lugar nenhum além da comparação.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l13-parallel\" aria-label=\"Os três meses do cálculo-sombra, uma barra por mês, contando só as fazendas cujo pagamento diferiu do do Coleta; as outras ficaram idênticas até o centavo. Julho de 2026: 1.871 idênticas e 29 diferentes, sendo 17 de arredondamento, 9 de uma regra não escrita e 3 de um defeito no lado novo. Agosto: 1.897 idênticas e 3 diferentes, todas uma mudança de regra aceita. Setembro: 1.898 idênticas e 2 diferentes, as duas a mesma mudança aceita.\"><text x=\"186.0\" y=\"33.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">julho de 2026</text><text x=\"186.0\" y=\"49.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1.871 idênticas</text><rect x=\"200.0\" y=\"28.0\" width=\"204.0\" height=\"24.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><rect x=\"404.0\" y=\"28.0\" width=\"108.0\" height=\"24.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><rect x=\"512.0\" y=\"28.0\" width=\"36.0\" height=\"24.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"558.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">29 diferentes</text><text x=\"186.0\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">agosto de 2026</text><text x=\"186.0\" y=\"101.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1.897 idênticas</text><rect x=\"200.0\" y=\"80.0\" width=\"36.0\" height=\"24.0\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"246.0\" y=\"92.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 diferentes</text><text x=\"186.0\" y=\"137.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">setembro de 2026</text><text x=\"186.0\" y=\"153.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1.898 idênticas</text><rect x=\"200.0\" y=\"132.0\" width=\"24.0\" height=\"24.0\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"234.0\" y=\"144.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 diferentes</text><rect x=\"40.0\" y=\"198.0\" width=\"14.0\" height=\"14.0\" rx=\"1\" fill=\"var(--wire)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"62.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">17 arredondamento: uma decisão, não um defeito</text><rect x=\"380.0\" y=\"198.0\" width=\"14.0\" height=\"14.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"402.0\" y=\"205.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">9 uma regra escrita em lugar nenhum</text><rect x=\"40.0\" y=\"222.0\" width=\"14.0\" height=\"14.0\" rx=\"1\" fill=\"var(--phosphor)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"62.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 um defeito no lado novo</text><rect x=\"380.0\" y=\"222.0\" width=\"14.0\" height=\"14.0\" rx=\"1\" fill=\"var(--paper-dim)\" stroke=\"var(--paper-dim)\" stroke-width=\"0.8\"></rect><text x=\"402.0\" y=\"229.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma mudança de regra aceita</text></svg>", "caption": "Só as diferenças estão desenhadas, porque são elas que importam: cada uma foi explicada antes do mês seguinte, e nenhuma foi escondida atrás de uma tolerância."}
```

O primeiro mês comparou 1.900 fazendas. **1.871 ficaram idênticas até o centavo e 29 deram
diferença**, ou seja, 1.871 ÷ 1.900, 98,5% idênticas. Cada uma das 29 foi explicada antes da rodada
do mês seguinte:

- 17 eram arredondamento. O Coleta arredonda o valor de cada coleta para o centavo e soma os valores
  arredondados; o cálculo-sombra somava o mês primeiro e arredondava uma vez só. Nenhuma das 17
  diferia em mais de seis centavos.
- 9 eram uma regra que não estava escrita em lugar nenhum. Uma cooperativa de nove fazendas ao norte
  de Barbacena tem um bônus de inverno desde 2009, combinado por um diretor que já se aposentou, e
  ele só existe como uma sub-rotina RPG. O Sebastião lembrou quando viu a lista de nomes.
- 3 eram um defeito do lado novo. A camada anticorrupção não reconhecia uma coleta que os
  funcionários tinham cancelado no Coleta, então o cálculo-sombra pagou por leite que tinha sido
  jogado fora.

O defeito foi corrigido, e o bônus foi documentado e implementado. O arredondamento não era defeito
de nenhum dos lados, e esse é o caso que ensina. **Uma diferença não se resolve definindo uma
tolerância que a esconde; ela se resolve com alguém decidindo qual resposta está certa.** O Marcos
decidiu: o substituto arredonda por coleta, como o Coleta, porque os produtores comparam o extrato
com o do mês anterior, e uma mudança de método é anunciada a eles, não enfiada às escondidas. Uma
tolerância de dez centavos teria deixado passar as 17 e escondido o fato de que os dois cálculos
funcionavam de jeitos diferentes.

O segundo mês teve 3 diferenças, todas de um caso novo: uma fazenda liberada de uma suspensão por
qualidade no meio do mês. O Coleta pagava o preço base a partir do dia seguinte à liberação, o
cálculo-sombra a partir do próprio dia. Aqui o Marcos e a Cláudia concluíram que o sistema antigo
estava errado havia anos, e que a regra vai mudar, com aviso às fazendas, no dia em que o pagamento
mudar de lado. O terceiro mês teve 2 diferenças, as duas desse mesmo tipo já aceito.

O que os três meses produziram vale mais do que a porcentagem. **O cálculo-sombra agora é o teste de
aceitação de qualquer coisa que substitua o pagamento do Coleta**: a opção que a aula 15 escolher vai
ter de bater com ele, fazenda por fazenda, por mais três meses antes que a fase 3 mude um único
pagamento de lado.

## Feito para se viver nele

O meio dura mais do que o planejado porque cada fase encontra alguma coisa, e porque a empresa não
para de pedir mudanças enquanto ele dura. Por isso o plano trata a coexistência como um sistema com
a sua própria operação:

- a tabela de mestres, publicada e datada;
- os caminhos de cópia, monitorados, com alarmes que alguém atende;
- a conciliação da manhã, com um responsável nomeado;
- um runbook para "a cópia para o Coleta parou", testado antes de ser preciso;
- um processo de mudança que sabe, para cada pedido do negócio, em qual lado ele precisa ser feito
  naquele mês.

Nada disso é desperdício. É o que a empresa está pagando quando escolhe não apostar tudo num fim de
semana.
