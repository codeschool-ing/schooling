---
title: A proposta técnica
version: 1
---

**Uma proposta técnica existe para que os revisores achem a falha antes do código.** É nela que um
design é comparado com as alternativas, com detalhe suficiente para que alguém que discorde possa
dizer exatamente onde. O Google chama o mesmo documento de design doc, outras empresas de
especificação técnica; os nomes variam e as partes não.

O documento de uma página da seção anterior perguntou a Renata e Caio se o dinheiro deveria ser
gasto. A proposta por trás dele pergunta a Bruna, Henrique e ao time de plataforma se este é o jeito
certo de gastá-lo. Leitores diferentes, decisão diferente, portanto documento diferente.

## As partes, e para que serve cada uma

| parte | o que responde | o que dá errado sem ela |
|---|---|---|
| contexto e objetivos | por que agora, e como é o sucesso, de forma mensurável | os revisores julgam o design por objetivos próprios |
| **não objetivos** | o que isto deliberadamente não tenta fazer | cada revisor acrescenta seu problema favorito ao escopo |
| o design | o que muda, com um diagrama das partes que se movem | os revisores discutem um design que cada um imaginou de um jeito |
| **alternativas consideradas** | o que mais foi avaliado, e por que perdeu | o primeiro comentário é "por que não simplesmente…?", cinquenta vezes |
| custo e risco | tempo de engenharia, dinheiro e o que pode quebrar | quem decide aprova um número que ninguém escreveu |
| implantação e rollback | como é ligado, e como é desligado | o plano só funciona se nada der errado |
| questões em aberto | o que o autor ainda não sabe | os revisores acham as lacunas e as leem como descuido |

Duas delas merecem mais que uma linha.

## Os não objetivos seguram o escopo

A proposta de Lívia lista três não objetivos: não tira o checkout do PostgreSQL, não muda como os
pedidos são armazenados e não dá a nenhum outro serviço acesso à réplica nesta fase. Cada um é uma
frase que evita uma longa discussão nos comentários. O terceiro foi o mais útil: dois outros times
queriam acesso à réplica, e o não objetivo permitiu à revisão dizer "sim, depois, numa proposta
separada" em vez de absorver os requisitos deles.

**Um não objetivo não é uma coisa sem importância.** É uma coisa importante que não está sendo
decidida aqui.

## Alternativas consideradas é onde se ganha confiança

Uma proposta com uma opção só soa como uma decisão já tomada, e os revisores respondem atacando-a.
Uma proposta que mostra duas ou três alternativas, cada uma com um motivo honesto para ter perdido,
soa como uma escolha que o autor pensou até o fim, e os revisores respondem conferindo o
raciocínio.

A de Lívia tem quatro, e a primeira é sempre a mesma:

1. **Não fazer nada.** A linha de base contra a qual toda outra opção é medida. Não custa nada
   agora, e as falhas crescem com o volume de pedidos.
2. **Um servidor de banco de dados maior.** Um dia de trabalho e R$ 9.000 a mais por mês. Ele muda
   o limite de lugar em vez de acabar com a disputa, então o problema volta conforme o volume cresce.
3. **Pool de conexões na frente do banco.** Barato e vale a pena de qualquer jeito, mas ele raciona
   as conexões entre o planejador de rotas e o checkout em vez de separá-los; numa sexta ruim, um
   dos dois ainda espera.
4. **Uma réplica de leitura para o planejador de rotas** (a proposta). Seis semanas-engenheiro e
   R$ 4.000 por mês, e ela tira as leituras do planejador de rotas do primário por completo.

Repare no que a opção 3 diz: *vale a pena de qualquer jeito*. **Uma alternativa que perde ainda
pode estar em parte certa**, e dizer isso é o que faz os revisores acreditarem que a comparação foi
justa.

## Escreva para ser revisado

Numere as questões em aberto para que os comentários possam se referir a elas ("sobre a Q2: …").
Ponha o diagrama antes do texto que o explica. Date o documento e dê a ele um status no topo
(*rascunho*, *em revisão*, *aprovado*). E mantenha-o curto o bastante para ser lido: uma proposta
com mais de dez páginas costuma ser duas propostas, ou uma proposta com as notas de pesquisa ainda
grudadas.
