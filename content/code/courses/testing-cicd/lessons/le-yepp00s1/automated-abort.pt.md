---
title: Um canário que para sozinho
version: 1
---

A produção voltou para onde a aula 10 a encontrou: o blue no 1.5.0 com todo o tráfego, o green no
1.6.0, o release que não cota Alagoas. Desta vez ninguém edita os pesos. O `canary.py` edita:

```
ana@laptop:~/shipquote$ curl -s http://127.0.0.1:8302/version; echo
{"version": "1.6.0", "env": "production-green", "carrier": "table"}
ana@laptop:~/shipquote$ python3 ops/canary.py ~/envs/routes.json http://127.0.0.1:8300; echo "exit $?"
canary at   5%: green 0/21 = 0.0%, blue 0/379 = 0.0%
        21 answers is too few to judge; carrying on
canary at  25%: green 2/98 = 2.0%, blue 0/302 = 0.0%
abort: green is 2.0 points worse than blue; all traffic back to blue
exit 1
ana@laptop:~/shipquote$ cat ~/envs/routes.json; echo
{"backends": {"blue": "http://127.0.0.1:8301", "green": "http://127.0.0.1:8302"}, "weights": {"blue": 100, "green": 0}}
```

A 5%, o green respondeu 21 requisições, menos que as 50 que a regra exige, então o script avisou e
seguiu. A 25%, o green respondeu 98 e falhou 2, enquanto o blue não falhou nenhuma. A diferença de
2,0 pontos passou do limite de 1,0, os pesos voltaram para 100 e 0, e o script saiu com 1. Ninguém
precisou estar olhando. O código de saída é o que um pipeline lê: um job de release que roda o
`canary.py` para ali, vermelho, e o próximo job não começa.

Dois clientes em 400 no segundo passo encontraram o bug. Com o blue-green da aula 10, foram 77.

## Leia a regra, além do resultado

A regra funcionou aqui, e tem uma falha que vale a pena ver. Com 98 respostas, **um** erro dá uma
taxa de 1,02%, o que já está mais de 1,0 ponto acima de um blue sem nenhum. Então, entre 50 e 99
respostas, a regra na verdade é "pare no primeiro erro". A aula 10 seção 08 mostrou quanto vale um
erro: muito pouco. Um canário com esta regra vai às vezes abortar um release bom por uma única
requisição azarada.

Há duas correções honestas, e elas puxam para lados opostos:

- **Exigir mais evidência**: subir o `MIN_REQUESTS` até um erro sozinho não cruzar a diferença. Com
  uma diferença de 1 ponto, isso quer dizer pelo menos 100 respostas. Os bugs são pegos mais tarde,
  numa parte maior.
- **Usar um teste estatístico** em vez de uma diferença fixa: perguntar se a diferença entre as duas
  taxas é maior do que o acaso produziria com esse tamanho de amostra. É o que fazem as ferramentas
  dedicadas à análise de canário.

Qualquer uma é melhor que a terceira opção para onde as equipes escorregam: rodar de novo um canário
abortado até ele passar. Cada nova rodada é mais um sorteio, e um release com um bug raro acaba
passando num deles.
