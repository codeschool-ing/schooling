---
title: Qual tempo usar
version: 1
---

**Use o tempo do evento sempre que a resposta for sobre o mundo, e o tempo de processamento só
quando a resposta for sobre o pipeline.** Essa frase resolve a maioria dos casos, e o resto desta
seção são os casos em que ela precisa de uma segunda olhada.

O erro comum não é escolher o tempo de processamento de propósito. É nunca escolher: o padrão de um
framework, um `now()` dentro de uma função, ou um consumidor que conta o que leu "no último minuto".
Cada um desses é tempo de processamento, em silêncio, e o resultado parece certo em todo dia em que
nada deu errado.

| a pergunta | o relógio | por quê |
|---|---|---|
| vendas por hora para o relatório do gerente | tempo do evento | a hora pertence à venda; um caixa atrasado não pode mudá-la |
| o cartão foi usado em duas cidades com dez minutos de diferença | tempo do evento | os dez minutos são entre duas compras, não entre duas chegadas |
| quantas vendas por segundo o pipeline está tratando | tempo de processamento | é uma pergunta sobre o próprio pipeline |
| quão atrasado está o consumidor | os dois | o lag em tempo é o tempo de processamento menos o tempo do evento; a lição 16 mede isso |
| um timeout: nenhuma resposta do serviço de pagamento em 30 segundos | tempo de processamento | a espera está acontecendo agora, para um programa |
| estoque que sobra na prateleira | nenhum dos dois, na verdade | estoque é estado, dobrado a partir de cada venda em ordem por livro; lição 2 |
| qual versão de um preço valia para uma venda | tempo do evento | a venda aconteceu sob um preço, não importa quando chegou |

Duas linhas merecem uma frase cada. **O lag é o único lugar em que os dois relógios são o ponto**: a
distância entre eles é a medida. E **estoque não é uma pergunta de tempo**, o que é fácil esquecer
lendo uma lição sobre tempo. Ele precisa de todas as vendas de um livro, numa ordem que respeite a
chave do livro, e o fold da lição 2 dá isso a ele.

## O que o tempo do evento custa

O tempo do evento não é de graça, e vale nomear os custos antes de escolhê-lo para tudo:

- **Os resultados esperam.** Uma hora pelo tempo do evento não está pronta no fim da hora; está
  pronta quando o processador decide que mais nada vai chegar para ela. A lição 11 é essa decisão.
- **O estado é guardado.** Enquanto uma hora está aberta, a contagem parcial dela precisa ficar
  guardada em algum lugar, para cada chave. Uma contagem por loja pelo tempo do evento com espera de
  duas horas guarda duas horas de contagens abertas para cinco lojas; por cliente, para um milhão.
- **Cada evento precisa de um horário confiável dentro dele.** A última seção mostrou o que isso
  significa para um aparelho que você não administra.

## Tempo de ingestão, o meio-termo

`LogAppendTime` fica entre os dois. Ele é carimbado por um relógio que você administra, é o mesmo em
toda releitura e, num stream bem-comportado, fica a segundos do tempo do evento. É uma escolha
razoável quando a origem **não** tem um horário próprio em que dê para confiar, como eventos de
aparelhos cujo relógio você não consegue consertar. O que ele não consegue é pôr as vendas de Natal
de volta na manhã: elas foram anexadas às 14:00, e o tempo de ingestão diz 14:00 para sempre.

**Seja qual for a escolha, escreva-a ao lado do resultado.** Uma tabela com o título "vendas por
hora" é ambígua exatamente do jeito que esta lição passou cinco seções explicando. "Vendas por hora,
pela hora da venda, sem as vendas com mais de duas horas de atraso" é um número que alguém consegue
conferir.
