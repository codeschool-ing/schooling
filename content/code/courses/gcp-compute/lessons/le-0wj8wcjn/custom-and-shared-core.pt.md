---
title: Tipos custom e núcleos compartilhados
version: 1
---

Dois tipos de máquina saem das três proporções. **Um tipo custom deixa você dar as próprias vCPUs
e memória, e um tipo de núcleo compartilhado vende menos de uma vCPU.** Cada um é a resposta certa
numa situação e um hábito caro nas outras.

## Tipos custom, com preço montado pelas partes

Um tipo custom é escrito com a série, a palavra `custom`, as vCPUs e a memória **em MiB**:
`n4-custom-4-10240` são quatro vCPUs e 10 GiB. O preço é por vCPU e por GiB, e o programa da seção
03 multiplica os dois:

```
ana@laptop:~/gcp$ python3 prices.py custom n4 4 10
Google Cloud public prices, us-central1, USD, 30 October 2026

n4-custom-4-10240: 4 vCPU and 10 GiB
  4 x 0.03275 per vCPU                                 0.131  per hour
  10 x 0.003717 per GiB                              0.03717  per hour
  together                                           0.16817  per hour
  together, for 730 hours                             122.76  per month
```

Contra a `n4-standard-4`, que tem 16 GiB e custa 132,42 por mês, o tipo custom economiza 9,66
dólares por não carregar 6 GiB que ninguém pediu. É para esse caso que os tipos custom existem:
**a proporção que você mediu cai entre duas predefinidas, e vale a pena pagar para fechar o
intervalo.**

Agora peça a outra ponta da faixa, 32 GiB em quatro vCPUs:

```
ana@laptop:~/gcp$ python3 prices.py custom n4 4 32
Google Cloud public prices, us-central1, USD, 30 October 2026

n4-custom-4-32768: 4 vCPU and 32 GiB
  4 x 0.03275 per vCPU                                 0.131  per hour
  32 x 0.003717 per GiB                             0.118944  per hour
  together                                          0.249944  per hour
  together, for 730 hours                             182.46  per month
```

**182,46 por mês, contra 173,77 da `n4-highmem-4`**, que tem as mesmas quatro vCPUs e os mesmos 32
GiB e está na mesma página. A diferença é um adicional que o Google declara na página de preços: o
preço sob demanda de um tipo custom fica 5% acima do tipo predefinido que ele imita. Então um tipo
custom que cai exatamente num formato predefinido é simplesmente esse formato, mais caro. Confira o
catálogo antes de escrever `custom`.

Três regras moldam o que você pode pedir, e o Compute Engine as verifica quando cria a máquina, não
quando o Terraform planeja:

- **a memória vem em múltiplos de 256 MiB**, e é por isso que o nome traz MiB e não GiB;
- cada série tem uma **faixa de memória por vCPU**, e na N4 a faixa normal termina em 8 GiB por
  vCPU;
- acima dessa faixa fica a **memória estendida**, que as séries que a permitem cobram a uma taxa
  maior por GiB, 0,008745975 por hora na N4 contra 0,003717 dentro da faixa.

## Núcleos compartilhados

`e2-micro`, `e2-small` e `e2-medium` aparecem com **2 vCPUs** na tabela, e esse número é o teto,
não a cota. Cada uma tem direito a uma fração de vCPU ao longo do tempo, um quarto na `e2-micro`,
metade na `e2-small` e uma vCPU inteira na `e2-medium`, e pode ter rajadas acima disso por períodos
curtos quando o host tem folga. No resto do tempo ela fica presa à sua cota.

Isso as torna as máquinas mais baratas da tabela, 6,11 por mês a `e2-micro`, e certas para
trabalho que é quase só espera: uma ferramenta interna pequena, um bastion, uma máquina que acorda
para um cron. E as torna erradas para qualquer coisa de carga constante, porque carga constante é
justamente o que a rajada não cobre. Um servidor web ocupado a tarde toda numa `e2-small` é um
servidor web lento a tarde toda, e nada na conta avisa.

O nível gratuito do Google inclui uma `e2-micro` por mês em algumas regiões dos Estados Unidos, o
que a torna a primeira máquina comum de uma conta pessoal. É uma possibilidade entre várias, não é
oferecida em São Paulo e muda no calendário do Google, então leia os termos atuais antes de contar
com ela.

## Qual escolher

| a situação | o tipo |
|---|---|
| a proporção medida bate com um tipo predefinido | o tipo predefinido |
| cai entre dois, e o intervalo é grande | um tipo custom |
| precisa de mais memória por vCPU que qualquer proporção padrão | `highmem`, depois um custom com memória estendida |
| a carga é leve e quase sempre ociosa | uma E2 de núcleo compartilhado |
| a carga é constante | nunca um núcleo compartilhado |
