---
title: Ler o teste do sinal
version: 1
---

O `pl compare` termina toda comparação com uma linha como
`sign test on the 2 that changed: p = 0.500`. **O número responde a uma pergunta estreita**: se a mudança não fizesse diferença nenhuma, e
cada mensagem alterada tivesse a mesma chance de ir para um lado ou para o outro, com que frequência
o acaso sozinho produziria uma divisão ao menos tão desigual, em qualquer direção?

Só as mensagens cujo resultado mudou entram no teste. As 46 que passaram nos dois prompts e as 22 que
falharam nos dois não dizem nada sobre a diferença entre eles, e é por isso que um conjunto de teste
de setenta pode guardar pouquíssima evidência sobre uma mudança em particular.

## Quantas mensagens alteradas são necessárias

Quando todas as mensagens alteradas vão para o mesmo lado, a conta é curta. Cada mensagem é um
lançamento de moeda, e a chance de todas as *n* caírem do mesmo lado é um meio multiplicado por si mesmo *n* vezes. Qualquer um dos lados conta, então p é o dobro disso. A função do próprio
laboratório, a que o `pl compare` chama, dá os mesmos números:

```
ana@lab:~/triage$ python3 -c 'from promptlab.cli import sign_test; [print(n, sign_test(n, 0)) for n in range(1, 9)]'
1 1.0
2 0.5
3 0.25
4 0.125
5 0.0625
6 0.03125
7 0.015625
8 0.0078125
```

Leia como *mensagens alteradas, depois p*. Duas mensagens alteradas, as duas no mesmo sentido, dão
0.5. Cinco dão 0.0625. **Seis é o menor número que consegue ficar abaixo de 0.05**, e só quando as
seis foram para o mesmo lado. Uma mensagem no sentido contrário sobe a exigência:

```
ana@lab:~/triage$ python3 -c 'from promptlab.cli import sign_test; [print(n, 1, round(sign_test(n, 1), 3)) for n in range(5, 10)]'
5 1 0.219
6 1 0.125
7 1 0.07
8 1 0.039
9 1 0.021
```

Com uma quebrada, são necessárias oito corrigidas para p cair abaixo de 0.05. O experimento da prosa teve
duas mensagens alteradas, então **nenhum resultado que ele pudesse produzir contaria como
evidência**. Vale saber disso antes de rodar um experimento, e não depois.

## O que p não é

- Não é a probabilidade de a mudança ter ajudado. Diz quão surpreendente a divisão seria se a
  mudança não fizesse nada.
- Não diz nada sobre o porquê. A execução com a temperatura esquecida deu p = 0.001: as duas
  execuções eram mesmo diferentes, e o teste não tem como dizer que a redação não teve parte nisso.
- 0.05 é uma convenção. É uma linha que as pessoas combinam traçar, e um p de 0.06 não prova
  ausência de efeito. Quer dizer que este conjunto de teste não mostrou um.

Quando uma mudança mexe em poucas mensagens demais para medir, há duas saídas honestas: um conjunto
de teste maior, ou uma mudança com efeito maior. Escrever *um pouco melhor* na mensagem de commit
não é uma delas.
