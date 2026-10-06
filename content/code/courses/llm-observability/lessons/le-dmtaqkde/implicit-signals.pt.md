---
title: O que os clientes fazem, além do que dizem
version: 1
---

A maioria dos clientes nunca clica num polegar. Todos fazem alguma coisa em seguida, e parte do que
fazem é um veredito sobre a resposta. Os dois que os clientes simulados desta semana fazem são os que
equipes de atendimento mais acompanham:

- **Perguntar de novo com outras palavras**, na mesma sessão, logo depois. Quem conseguiu o que
  precisava não reformula a pergunta.
- **Pedir uma pessoa.** A confissão mais clara de que o assistente não ajudou, e a mais cara, já que o
  tempo de uma pessoa é o custo que o assistente existe para economizar.

Os dois estão na mesma tabela do `signals.py`, como taxas por cem pedidos:

```
ana@lab:~/obs$ python signals.py
release    requests  rated  down  down % rephrased  person  per 100 requests
2026.09.4       789    123    44     36%      15.7     4.4
2026.10.1       432     68    35     51%      21.8     9.0
```

**As reformulações foram de 15,7 para 21,8 por cem, e os pedidos de uma pessoa dobraram, de 4,4 para
9,0.** Elas são contadas sobre todo pedido, não sobre os 15% que avaliaram, então se mexem com muito
menos ruído que os polegares. Também são mais difíceis de manipular: nenhum desenho de tela muda quantas
vezes um cliente que recebeu uma recusa pergunta de novo.

## Detectando-os em tráfego real

Nesta semana as reformulações vêm rotuladas, porque o `replay.py` as escreveu. O tráfego real chega sem
rótulo, e elas precisam ser inferidas:

- **uma segunda pergunta na mesma sessão dentro de um ou dois minutos**, o que é fácil, e pega também
  perguntas de continuação;
- **cujo embedding está perto do da primeira**, o que separa "how long do I have to return a book"
  seguido de "return window for books" (uma reformulação) da mesma primeira pergunta seguida de "and
  who pays the postage" (uma continuação). O limiar de similaridade é uma escolha como o piso, feita do
  mesmo jeito: sobre uma amostra que alguém rotulou à mão.

Pedir uma pessoa em geral é um evento que a aplicação já tem: um botão, uma passagem para a fila de
atendimento. Ele precisa ter o id de trace da última resposta anexado, para que a resposta que falhou
seja a contada, e isso é uma mudança de uma linha onde quer que o botão esteja.

**A regra que amarra tudo isso:** um sinal só é útil se puder ser ligado à resposta que ele julga. Um
polegar sem id de trace é uma pesquisa de satisfação. Uma passagem para atendimento sem id de trace é um
número de equipe. Com o id, os dois são avaliações de respostas específicas, e a aula 13 transforma as
piores delas em casos de teste.
