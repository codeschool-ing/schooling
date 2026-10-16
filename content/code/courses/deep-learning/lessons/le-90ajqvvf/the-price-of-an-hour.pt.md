---
title: O preço de uma hora
version: 1
---

Quem aluga uma máquina para treinar paga por hora, não por operação. **A conta é o tempo que a execução
levou vezes o preço de uma hora**, e o tempo é decidido por tudo o que esta aula mediu: a aritmética, o
custo fixo em volta dela, a precisão, o lote.

Comece por uma execução deste curso. O `compare.py` da aula 11 treina o MLP da aula 9, um MLP mais largo
e a CNN, 30 épocas cada: a comparação inteira da aula 11 num comando só. Ponha `time` na frente do comando
e o shell informa quanto ele levou:

```
ana@vm:~/dl$ time python compare.py
dense, lesson 9: 2410 parameters
epoch  10  train loss 0.3170  val loss 0.3068  val acc 0.922
epoch  20  train loss 0.1661  val loss 0.2004  val acc 0.936
epoch  30  train loss 0.1205  val loss 0.1461  val acc 0.950
dense, 512 wide: 38410 parameters
epoch  10  train loss 0.2126  val loss 0.2165  val acc 0.936
epoch  20  train loss 0.1238  val loss 0.1642  val acc 0.944
epoch  30  train loss 0.0921  val loss 0.1223  val acc 0.961
convolutional: 38282 parameters
epoch  10  train loss 0.1558  val loss 0.1291  val acc 0.969
epoch  20  train loss 0.0249  val loss 0.1526  val acc 0.947
epoch  30  train loss 0.0055  val loss 0.0776  val acc 0.978
4800 of them in the two convolutions

real	0m8.275s
user	0m19.603s
sys	0m0.647s
```

`real` é o tempo no relógio, do início ao fim. `user` é tempo de processador, somado em todos os
processadores que o programa usou, e é por isso que ele pode sair maior que o `real`: o PyTorch divide um
produto grande entre os quatro processadores da máquina. Estes são os números da máquina do curso, e
os seus vão ser diferentes.

## Um preço é uma variável

O programa abaixo transforma um tempo numa conta. **O preço no topo dele é ilustrativo**: 2,50 por hora,
sem moeda, escolhido em outubro de 2026 para deixar a conta fácil de acompanhar. Não é o que algum
provedor cobra, e os preços da mesma máquina variam entre provedores e mudam de um mês para o outro.
Ponha o preço que lhe passarem no dia. Salve como `~/dl/bill.py`:

```schooling-example
{
  "language": "python",
  "file": "bill.py",
  "parts": [
    {
      "code": "\"\"\"bill: what training costs, from a time and a price per hour that you look up yourself.\"\"\"\nimport sys\n\nPRICE_PER_HOUR = 2.50   # ILLUSTRATIVE, set in October 2026 for the arithmetic. Not a quote.\n\nseconds = float(sys.argv[1])\nhours = seconds / 3600\nprint(f\"this run: {seconds:.0f} s = {hours:.4f} h, {hours * PRICE_PER_HOUR:.4f} at {PRICE_PER_HOUR:.2f} an hour\")",
      "note": "O preço é uma variável no topo, sem moeda, porque é o único número aqui que você precisa fornecer. 2,50 por hora foi escolhido para deixar a conta legível, em outubro de 2026, e não é o que algum provedor cobra. O tempo de uma execução chega pela linha de comando."
    },
    {
      "code": "# A large language model, by the 6 x N x D rule. Every number below is an assumption.\nN = 7e9         # parameters\nD = 20 * N      # training tokens, about twenty per parameter\nPEAK = 1e15     # FLOP/s that a card's data sheet promises in bfloat16\nKEPT = 0.40     # the share of that peak a real training job sustains\n\nflops = 6 * N * D\ncard_hours = flops / (PEAK * KEPT) / 3600\nprint(f\"6 x N x D = {flops:.2e} FLOPs\")\nprint(f\"{card_hours:,.0f} card-hours, {card_hours * PRICE_PER_HOUR:,.0f} at {PRICE_PER_HOUR:.2f} an hour\")\nfor cards in (8, 256):\n    print(f\"  on {cards:3d} cards: {card_hours / cards / 24:5.1f} days\")",
      "note": "Quatro suposições, cada uma em sua linha para poder ser mudada. Vinte tokens por parâmetro é a proporção que um estudo de 2022 de Hoffmann e colegas achou o melhor uso de um orçamento fixo. Mil trilhões de operações por segundo é a ordem de grandeza que as fichas técnicas davam para placas grandes em bfloat16, e 40% disso é uma fração que treinos reais alcançam quando bem ajustados."
    }
  ]
}
```

Rode-o com os segundos da linha `real` acima, arredondados:

```
ana@vm:~/dl$ python bill.py 8
this run: 8 s = 0.0022 h, 0.0056 at 2.50 an hour
6 x N x D = 5.88e+21 FLOPs
4,083 card-hours, 10,208 at 2.50 an hour
  on   8 cards:  21.3 days
  on 256 cards:   0.7 days
```

**A execução do curso custa 0,0056 a esse preço**, uma pequena fração de uma unidade, seja qual for a
moeda. A segunda metade é a mesma conta para um modelo que precisa mesmo de orçamento, feita antes de
treiná-lo, com a regra 6 × N × D da primeira seção. Um modelo de 7 bilhões de parâmetros treinado com 20
tokens por parâmetro precisa de 5.88e+21 operações. Em placas que sustentam 40% de um pico de 1e15 por
segundo, isso dá 4.083 horas de placa, ou 10.208 ao preço ilustrativo.

**Mais placas compram tempo, não dinheiro.** Oito placas levam 21,3 dias e 256 levam 0,7 dia, e as horas
de placa, portanto a conta, são as mesmas 4.083 nos dois casos. Na prática o grupo maior custa um pouco
mais, porque as placas gastam parte de cada passo trocando gradientes, o que o `KEPT` teria de absorver.

## A suposição que mais mexe na conta

Cada linha abaixo do comentário no `bill.py` é uma suposição, e a conta acompanha cada uma delas, para
cima ou para baixo. A que mais erra é o `KEPT`, a fração do pico da placa que o treino de fato sustenta.
A primeira seção desta aula mediu um dos motivos pelos quais ela cai, o custo fixo em volta de matrizes
pequenas, e a aula 10 outro, a espera pelos dados. Com 20% em vez de 40%, o mesmo modelo custa o dobro, e
nada na ficha técnica avisa.

Daí saem dois hábitos. **Meça antes de orçar**: treine algumas centenas de passos, cronometre-os e
calcule a execução completa a partir disso, não de uma ficha técnica. E **salve pelo caminho**, os pesos e
o estado do otimizador, com o `state_dict` da aula 9. As máquinas alugadas mais baratas são as que o
provedor pode tomar de volta com pouco aviso, e uma execução que retoma do último salvamento perde minutos
quando isso acontece, não dias.
