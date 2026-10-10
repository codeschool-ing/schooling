---
title: Quanto custa, tudo incluído
version: 1
---

**O custo total de uma tecnologia é a conta dela, mais as horas das pessoas que a mantêm, mais o preço
de sair dela.** A imagem comum para no primeiro termo, em geral num único preço unitário: tanto por
gigabyte guardado, tanto por hora de servidor. Duas coisas tornam essa imagem errada. A maioria das
contas é moldada muito mais pelo jeito como a ferramenta é *usada* do que pelos preços unitários. E
numa empresa do tamanho da Roda Livre, a maior linha raramente está em alguma conta.

Um programa curto deixa as duas coisas visíveis. **Todos os preços nele foram inventados para esta
aula**, em reais por mês, escolhidos por serem redondos e não para bater com nenhum fornecedor; os
preços reais variam com o fornecedor, a região e o ano, e o que vale levar é o método. Salve como
`cost.py`:

```python
# choose/cost.py
# EVERY PRICE HERE IS INVENTED FOR THIS LESSON, in reais a month.
STORE_GB = 0.15       # keeping one gigabyte for a month
SCAN_TB = 30.00       # a query engine reading one terabyte
SERVER_H = 0.60       # one hour of a small server we run ourselves
PERSON_H = 120.00     # one hour of an engineer's time

# 150 docks, one reading a minute, about 60 bytes a reading, kept a year
year_gb = 150 * 24 * 60 * 365 * 60 / 1e9


def month(scans, gb_per_scan, server_hours, person_hours):
    return {
        "storage": year_gb * STORE_GB,
        "queries": scans * gb_per_scan / 1000 * SCAN_TB,
        "server": server_hours * SERVER_H,
        "people": person_hours * PERSON_H,
    }


PLANS = {
    "managed, every 5 min": month(12 * 24 * 30, year_gb, 0, 2),
    "managed, once a day": month(30, year_gb / 365, 0, 2),
    "our own server": month(0, 0, 24 * 30, 10),
}

print(f"a year of dock readings: {year_gb:.2f} GB")
print(f"{'':21}{'storage':>9}{'queries':>9}{'server':>9}{'people':>9}{'total':>10}")
for name, lines in PLANS.items():
    cells = "".join(f"{v:9.2f}" for v in lines.values())
    print(f"{name:21}{cells}{sum(lines.values()):10.2f}")
```

Três planos para o mesmo ano de leituras das docas. Os dois primeiros usam um motor gerenciado que
cobra por terabyte que uma consulta lê: um atualiza um painel a cada cinco minutos e lê o ano inteiro
toda vez, o outro roda uma vez por dia e lê só o dia anterior. O terceiro é um servidor que o próprio
time roda, que não cobra nada por consulta e precisa de dez horas do mês de alguém.

```
ana@lab:~/roda/choose$ python cost.py
a year of dock readings: 4.73 GB
                       storage  queries   server   people     total
managed, every 5 min      0.71  1226.12     0.00   240.00   1466.83
managed, once a day       0.71     0.01     0.00   240.00    240.72
our own server            0.71     0.00   432.00  1200.00   1632.71
```

## Lendo a conta

**Armazenamento quase não custa nada em nenhum dos planos.** Um ano de leituras de 150 docas ocupa
4,73 GB, e guardá-lo custa 0,71 por mês. Apagar dados antigos para economizar armazenamento, a porta
de mão única de antes nesta aula, economizaria menos de um real por mês.

**O jeito de usar o motor muda a conta por um fator de mais de cem mil.** O mesmo motor gerenciado, ao
mesmo preço unitário, custa 1.226,12 por mês em consultas quando um painel relê um ano de dados a cada
cinco minutos, e 0,01 quando um job lê um dia, uma vez. Nada na ferramenta é diferente. O primeiro
plano responde a cada cinco minutos uma pergunta que ninguém fez; a pergunta da seção 04,
*quando você precisa?*, vale mais de mil e duzentos reais por mês aqui.

**As pessoas são a maior linha dos dois planos sensatos.** Em "managed, once a day" a conta fica abaixo
de um real e as duas horas de um engenheiro são 240,00. Em "our own server" não há cobrança nenhuma por
consulta, e o plano é o mais caro dos três, com 1.632,71, porque dez horas de manutenção custam
1.200,00. "Hospedar por conta própria é mais barato" costuma comparar a conta de um plano com o total do
outro.

## O terceiro termo: sair

O programa não tem uma linha para a saída, e toda escolha real tem uma. Sair de uma tecnologia custa
as horas para reescrever o que depende dela, o risco da própria mudança e, muitas vezes, uma cobrança
do fornecedor por tirar os dados da rede dele, que muitos cobram por gigabyte. Esse custo é pago uma
vez e muito depois, e é por isso que é fácil deixá-lo fora de uma comparação e caro descobri-lo. O
aprisionamento, entre os critérios de antes nesta aula, é esta linha vista com antecedência.

A aula 7 faz a mesma conta para a coleta de dados: volume, frequência e o preço de cada um. Os números
de uma comparação de verdade vêm da tabela de preços do próprio fornecedor e da sua própria medida de
como a ferramenta vai ser usada, e `tech-strategy` e `cloud` vão mais fundo nos dois.
