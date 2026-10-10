---
title: Lendo o teste do sinal
version: 2
---

O `pl compare` termina toda comparação com uma linha como `sign test on the 13 that changed: p =
1.000`. **O número responde a uma pergunta estreita**: se a mudança não fizesse diferença nenhuma, e
cada mensagem que mudou tivesse a mesma chance de ir para um lado ou para o outro, com que
frequência o acaso sozinho produziria uma divisão pelo menos tão desigual, em qualquer direção?

Só as mensagens cujo resultado mudou entram no teste. As vinte que passaram com os dois prompts e as
trinta e sete que falharam com os dois não dizem nada sobre a diferença entre eles, e é por isso que
um conjunto de teste de setenta pode guardar pouquíssima evidência sobre uma mudança específica.

## De quantas mensagens que mudaram você precisa

Quando toda mensagem que mudou vai para o mesmo lado, a conta é curta. Cada mensagem é um cara ou
coroa, e a chance de todas as *n* caírem do mesmo lado é meio multiplicado por si mesmo *n* vezes.
Qualquer um dos lados conta, então p é o dobro disso. A `cmd_compare` do `pl.py` calcula isso com
`math.comb`, e esta linha também:

```
ana@lab:~/triage$ python3 -c 'from math import comb; [print(n, 2 * comb(n, 0) / 2 ** n) for n in range(1, 9)]'
1 1.0
2 0.5
3 0.25
4 0.125
5 0.0625
6 0.03125
7 0.015625
8 0.0078125
```

Leia como *mensagens que mudaram, depois p*. Duas mensagens que mudaram, as duas na mesma direção,
dão 0,5. Cinco dão 0,0625. **Seis é o menor número que consegue ficar abaixo de 0,05**, e só quando
as seis se mexeram para o mesmo lado. Uma mensagem indo para o outro lado sobe a barra:

```
ana@lab:~/triage$ python3 -c 'from math import comb; [print(n, 1, round(2 * (comb(n, 0) + comb(n, 1)) / 2 ** n, 3)) for n in range(5, 10)]'
5 1 0.375
6 1 0.219
7 1 0.125
8 1 0.07
9 1 0.039
```

Leia como *mensagens que mudaram, quantas foram para o outro lado, depois p*. Com uma delas contra,
são precisas nove mensagens que mudaram para p cair abaixo de 0,05. O experimento da prosa teve
treze mensagens que mudaram, divididas sete a seis, e **nenhuma divisão tão equilibrada conta como
evidência**, por mais mensagens que cubra. Vale saber disso antes de rodar um experimento, não
depois.

## O que p não é

- Não é a probabilidade de a mudança ter ajudado. Ele diz o quanto a divisão seria surpreendente se
  a mudança não tivesse feito nada.
- Não diz nada sobre o porquê. A execução com a temperatura esquecida deu p = 0.774: o teste não
  consegue dizer se a redação ou a temperatura fizeram alguma coisa, só que a divisão do total
  parece acaso.
- Não diz nada sobre o que os totais escondem. O p = 1.000 estava em cima de doze categorias mudadas
  e de um viés de urgência invertido.
- 0,05 é uma convenção. É uma linha que as pessoas combinam de traçar, e um p de 0,06 não é prova de
  ausência de efeito. Quer dizer que este conjunto de teste não mostrou um.

Quando uma mudança mexe em poucas mensagens para ser medida, há dois movimentos honestos: um conjunto
de teste maior, ou uma mudança com efeito maior. Escrever *um pouco melhor* na mensagem de commit não
é um deles.
