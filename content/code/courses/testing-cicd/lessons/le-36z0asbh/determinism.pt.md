---
title: Testes que dão a mesma resposta toda vez
version: 1
---

Um teste só é útil se der a mesma resposta para o mesmo código. Um teste que às vezes passa e às
vezes falha, sem mudança nenhuma entre uma vez e outra, se chama **instável** (*flaky*), e é pior do
que nenhum teste: ensina todo mundo a rodar de novo até ficar verde, que é exatamente como uma falha
real acaba ignorada. A maior parte da instabilidade vem de três fontes que o teste não controlou:
**tempo, acaso e ordem.** A seção 03 tratou da ordem. Esta seção trata das outras duas.

## Tempo

A regra de despacho do `shipquote` depende do relógio: um pedido antes das 14:00 sai no mesmo dia.
A função poderia ter lido o relógio por conta própria:

```python
def dispatch_date():
    local = datetime.now(WAREHOUSE)
    ...
```

e todo teste dela dependeria de quando rodou. Um teste afirmando "mesmo dia" passaria de manhã e
falharia depois das duas da tarde. Em vez disso, `dispatch_date` recebe o momento como argumento,
uma costura igual à da transportadora na aula 2:

```python
def dispatch_date(ordered_at: float) -> date:
    """The day an order placed at this Unix time leaves the warehouse."""
    local = datetime.fromtimestamp(ordered_at, WAREHOUSE)
    day = local.date()
    if local.time() >= CUTOFF:
        day += timedelta(days=1)
    while day.weekday() >= 5:     # Saturday and Sunday
        day += timedelta(days=1)
    return day
```

e os testes passam timestamps Unix fixos, com a data e a hora que eles representam escritas ao lado:

```python
# 2026-10-05 is a Monday, and São Paulo is three hours behind UTC.
MONDAY_1330_SP = 1791217800                    # 16:30 UTC
MONDAY_1430_SP = MONDAY_1330_SP + 3600
FRIDAY_1500_SP = MONDAY_1330_SP + 4 * 86400 + 5400
```

**O relógio é uma entrada.** Código que precisa de "agora" deveria recebê-lo, de um parâmetro ou de
um objeto relógio, e só a camada mais de fora, o handler HTTP ou o ponto de entrada da linha de
comando, consulta o relógio real. A aula 5 mostra um rascunho desta função que recebia o momento
como argumento e mesmo assim falhava em algumas máquinas, por um motivo que não tinha nada a ver com
a hora e tudo a ver com onde a máquina acha que está: repare no fuso `WAREHOUSE` da linha 11.

## Acaso

Dados aleatórios em testes às vezes são o objetivo: entradas variadas acham defeitos que as
escolhidas à mão não acham, e esse é o assunto da próxima seção. Mas dados aleatórios precisam ser
**reproduzíveis**. Um gerador iniciado com uma semente fixa produz a mesma sequência toda vez:

```
ana@laptop:~/shipquote$ python3 -c 'import random; random.seed(7); print(random.sample(range(100), 5))'
[41, 19, 50, 83, 6]
ana@laptop:~/shipquote$ python3 -c 'import random; random.seed(7); print(random.sample(range(100), 5))'
[41, 19, 50, 83, 6]
```

Mesma semente, os mesmos cinco números, em qualquer máquina rodando este Python. Um teste que usa
acaso deveria fixar a semente, ou imprimir a semente que usou quando falha, para a falha poder ser
repetida. A ferramenta da próxima seção faz a segunda coisa automaticamente.

## Achando o resto

Outras fontes de não determinismo que vale procurar na revisão: iterar sobre um `set`, cuja ordem
não é garantida; dicionários montados a partir dessas iterações; somas de ponto flutuante cuja ordem
muda; qualquer leitura de `os.environ` sem o teste definir o valor; e chamadas de rede, que a aula 2
trocou por dublês. Cada uma é um lugar onde o mesmo código pode dar duas respostas.
