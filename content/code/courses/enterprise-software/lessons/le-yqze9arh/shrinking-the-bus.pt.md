---
title: Encolhendo o barramento
version: 1
---

A resposta tentadora para um barramento que cresceu é um projeto para trocá-lo: escolher uma
plataforma de integração moderna, passar os 70 fluxos para ela, desligar o IBM Integration Bus. Há
fornecedores que oferecem ferramentas de migração que fazem exatamente isso. **Mover todos os
fluxos do jeito que estão para um produto novo dá a você o mesmo barramento com uma licença nova.** O desconto continua morando no cano, a decisão da fábrica continua morando no cano, e o time que
precisa mudá-los continua sendo o único que consegue. O que encolhe um barramento é uma resposta diferente, fluxo a fluxo, para a pergunta *a que lugar isto pertence?*

## Congele antes de encolher

O primeiro passo não custa nada e é o mais esquecido. Enquanto os fluxos antigos estão sendo
tirados, os novos continuam chegando, e cada regra nova posta no barramento é mais uma para tirar
depois. O primeiro registro de decisão de Joana sobre o barramento, aceito por Regina em novembro
de 2026, diz uma coisa só: **a partir daquela data, nenhum fluxo novo pode conter lógica de
negócio**, pelo teste da seção 05 desta aula. Um fluxo novo pode rotear, mudar um formato ou fazer a
ponte entre protocolos. Um time que precisa de uma decisão a põe no seu próprio serviço, ou pede ao
dono da decisão que a ponha no dele.

Um congelamento precisa de alguém que o sustente. Rui revisa todo fluxo novo contra o registro e
tem autorização para dizer não, e Regina concordou por escrito que um prazo perdido não é motivo
para abrir exceção.

## O inventário

Não dá para classificar o que você não listou. Joana e Rui passaram três semanas nos 70 fluxos e,
para cada um, anotaram os mesmos fatos:

| o que anotaram | de onde veio |
|---|---|
| os sistemas em cada ponta, e o protocolo de cada lado | os nós de entrada e de saída do fluxo |
| o tráfego dos últimos 90 dias: mensagens, falhas, última mensagem vista | as estatísticas de fluxo do próprio barramento e as estatísticas de fila do MQ |
| o que acontece dentro: só roteamento, mudanças de formato, chamadas a outros sistemas, decisões | a leitura do ESQL e dos mapeamentos, fluxo a fluxo |
| quem pediu, e quem é dono dos sistemas em cada ponta | o histórico de mudanças, e perguntando |

A terceira linha tomou a maior parte do tempo, porque só a leitura do código a responde. Um fluxo
chamado `SF_ACCOUNT_SYNC` parece uma tradução; descobriu-se que guardava o bloqueio de crédito da
seção 05.

## Quatro classes

Todo fluxo caiu numa de quatro classes, e cada classe tem o seu destino:

| classe | o que há dentro | para onde vai | Serra Alta |
|---|---|---|---|
| roteamento e protocolo | tira uma mensagem de um lugar e entrega em outro, talvez atravessando um protocolo: MQ para HTTP, um arquivo para uma fila | fica num barramento pequeno, ou vira mensageria simples no MQ, de que trata a aula 10 | 24 |
| transformação | muda um formato: EDI para IDoc, um registro do SAP para os campos do Salesforce | para a ponta dona do formato de origem ou de destino | 17 |
| orquestração com lógica de negócio | chama vários sistemas e decide alguma coisa: um desconto, uma fábrica, um bloqueio de crédito | para o serviço dono da decisão, ou para um motor de processos quando a decisão é um processo | 18 |
| sem tráfego | nenhuma mensagem em 90 dias | desligado | 11 |

**Uma transformação pertence à ponta dona de um dos seus formatos**, em geral a mais fácil de mudar.
Quando o time do Portal B2B mapeia o seu próprio pedido para o que o SAP espera, uma mudança no
pedido do portal mexe num time só. Onde nenhuma das pontas muda com facilidade — o SAP de um lado,
o EDI de um supermercado do outro —, a tradução vira um adaptador do time responsável por aquela
ponta, implantado junto com ela, como a seção 06 construiu para o Rota. A aula 11 discute a outra
opção, um formato canônico compartilhado, e por que ele tantas vezes vira um comitê.

As orquestrações são a parte difícil, porque cada uma precisa de um dono que aceite uma regra que
não sabia ter. O desconto vai para o preço do SAP, onde o comercial já muda os preços. A decisão da
fábrica vai para o lado do SAP dos planejadores de logística. O bloqueio de crédito é removido,
porque a gestão de crédito do próprio SAP já faz o trabalho e a cópia do fluxo usava outro limite.
Duas orquestrações que são processos de verdade — esperar um resultado de laboratório, depois uma
assinatura, depois um banco — vão para o motor de processos que roda o cadastro de fazendas, o
assunto das aulas 6 e 7.

## Morto não é o mesmo que quieto

Onze fluxos não mostraram tráfego em 90 dias, e o movimento óbvio é apagá-los. Rui pediu antes um
ano inteiro de estatísticas, e dois dos onze tinham rodado, uma vez cada: um fluxo que manda a toda
fazenda o seu informe anual de rendimentos em fevereiro, para a declaração de imposto da fazenda, e
um fluxo que manda a contagem de estoque de fim de ano aos auditores em dezembro. **Noventa dias de
silêncio não provam nada sobre um fluxo que roda uma vez por ano**, e os dois são necessários. São
transformações, e mudaram para essa classe. Sobram 9 fluxos mortos, 19 transformações, 18
orquestrações e 24 fluxos de roteamento, ainda 70 no total.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" data-fig=\"l08-classes\" aria-label=\"Um gráfico de barras dos 70 fluxos de mensagem da Serra Alta por classe, depois de conferido um ano de tráfego. Roteamento e protocolo: 24, que ficam num barramento pequeno ou viram MQ simples. Transformação: 19, que vão para a ponta dona do formato. Orquestração com lógica de negócio: 18, que vão para o dono da decisão. Mortos: 9, desligados. Uma nota diz que 11 fluxos não tiveram tráfego em 90 dias, e 2 deles rodam uma vez por ano e foram contados como transformação.\"><text x=\"20.0\" y=\"22.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">70 fluxos no barramento, por classe</text><text x=\"20.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">roteamento e protocolo</text><text x=\"20.0\" y=\"73.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fica: um barramento pequeno, ou MQ simples</text><rect x=\"330.0\" y=\"51.0\" width=\"300.0\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"64.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">24</text><text x=\"20.0\" y=\"106.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">transformação</text><text x=\"20.0\" y=\"123.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para a ponta dona do formato</text><rect x=\"330.0\" y=\"101.0\" width=\"237.5\" height=\"26.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"577.5\" y=\"114.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">19</text><text x=\"20.0\" y=\"156.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">orquestração com lógica de negócio</text><text x=\"20.0\" y=\"173.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">para o dono da decisão</text><rect x=\"330.0\" y=\"151.0\" width=\"225.0\" height=\"26.0\" rx=\"2\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"565.0\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">18</text><text x=\"20.0\" y=\"206.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mortos</text><text x=\"20.0\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">desligados</text><rect x=\"330.0\" y=\"201.0\" width=\"112.5\" height=\"26.0\" rx=\"2\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"452.5\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">9</text><path d=\"M330.0 40.0 L330.0 256.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"20.0\" y=\"274.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">11 fluxos não tiveram tráfego em 90 dias; 2 deles rodam uma vez por ano, então 9 estão mortos</text></svg>", "caption": "Os 70 fluxos depois do inventário. As classes, e não o produto, decidem para onde vai cada fluxo; 46 saem do barramento e 24 ficam."}
```

Os nove são desligados de um jeito que pode ser desfeito. Cada um é parado, não apagado; os donos
dos sistemas nas duas pontas são avisados; e o fluxo fica parado durante um fechamento de mês
inteiro, porque alguns fluxos só acordam na semana em que o financeiro fecha o mês, que a aula 1
descreveu. Depois disso, o código vai para o arquivo e o fluxo sai do barramento. Dois meses depois
do congelamento, o barramento roda 61 fluxos, e nada quebrou.

## A ordem do trabalho

As classes também dão a ordem:

1. Congelar lógica nova, para o inventário parar de crescer.
2. Inventariar todo fluxo com um ano de tráfego, não noventa dias.
3. Desligar os mortos, com cuidado, porque é barato e encolhe tudo o que vem depois.
4. Tirar as transformações à medida que os times donos de cada ponta mexem nela por outros motivos.
5. Tirar as orquestrações uma decisão de cada vez, cada uma com o seu dono e a sua data.
6. Decidir o que os fluxos de roteamento viram: um barramento pequeno, ou mensageria simples.

Os passos 4 e 5 seguem o ritmo de outros trabalhos, em vez de rodar como um programa à parte. Uma
transformação muda de lugar quando o time do Portal B2B já está mudando o formato do seu pedido, ou
quando o Salesforce está sendo atualizado; tirá-la nessa hora custa pouco teste a mais. **Um
barramento encolhe do jeito que uma figueira-estranguladora substitui a sua árvore hospedeira, um
galho de cada vez, com tudo continuando a funcionar**, e a aula 13 desenvolve esse padrão para o
próprio Coleta.

## Medindo o progresso

Joana acompanha dois números todo mês e os mostra a Regina: fluxos que ainda contêm lógica de
negócio, e pedidos de mudança esperando pelo time de integração. O primeiro cai de 18 em direção a
zero. O segundo é o que o negócio sente. Quando uma transformação vai para o time do portal, as
mudanças nela deixam de esperar na fila de Rui, e o plano espera que, no fim de 2027, a fila tenha
menos de cinco pedidos a qualquer momento.

O que sobra no fim não é nada. Se tudo andar como planejado, 9 + 19 + 18 = 46 fluxos saem do
barramento, e 24 ficam: roteamento e ponte entre protocolos, o trabalho em que um barramento sempre
foi bom. Se esses 24 ficam no IBM Integration Bus, passam para uma versão mais nova ou viram MQ
simples é uma decisão menor, sem nenhuma regra de negócio dentro, e é exatamente isso que a torna
fácil. **O objetivo nunca foi não ter barramento. Era ter um barramento pelo qual ninguém precise
esperar.**
