---
title: Quanto custa, e o que multiplica o custo
version: 1
---

**A conta do dado raramente é o tamanho do dado. É o tamanho, vezes o tempo que ele fica guardado,
vezes a frequência com que é lido e movido.** O primeiro fator é o que as pessoas estimam, e os outros
dois são os que as surpreendem, porque são decididos depois, por outras pessoas, uma decisão razoável de
cada vez.

Uma plataforma de dados paga por quatro coisas, e por uma quinta que não aparece em fatura nenhuma:

| o quê | cobrado por | o que faz crescer |
|---|---|---|
| **armazenamento** | o gigabyte, por mês | o volume, e cada mês em que fica guardado |
| **processamento** | a hora de uma máquina, ou o terabyte que um motor de consulta lê | quanto se lê, com que frequência |
| **transferência** | o gigabyte que sai da rede de um provedor | cópias para fora: para um notebook, outra nuvem, um parceiro |
| **chamadas** | o milhar de requisições a uma API paga | com que frequência você consulta |
| pessoas | as horas gastas para manter tudo rodando | cada execução que pode falhar, cada regra que precisa de dono |

## Um ano de leituras de sensor, com preço

Os preços neste programa foram **inventados para esta aula**. São de uma ordem de grandeza plausível, e
não são de nenhum provedor: os preços reais variam por provedor, região e ano, e mudam sem pedir licença.
O que se aproveita é o formato da soma. O volume é o de 22,2 MB por dia que a seção 03 mediu. Salve como
`collect/cost.py`:

```python
# collect/cost.py
# Unit prices INVENTED FOR THIS LESSON, in reais. Real ones differ by
# provider, by region and by year; the shape of the sum is what carries over.
KEEP_GB_MONTH = 0.15      # to keep 1 GB stored for a month
READ_TB = 30.00           # for a query engine to read 1 TB
OUT_GB = 0.50             # for 1 GB to leave the provider's network
CALLS_1000 = 0.02         # for 1,000 calls to a paid API

GB_A_DAY = 22.2 / 1000    # the dock sensors, as volume.py measured them
stored = GB_A_DAY * 365   # a year of them, all kept

refreshes = 24 * 60 // 5 * 30            # a dashboard refreshed every 5 minutes, for a month
costs = {
    "keeping a year of it": stored * KEEP_GB_MONTH,
    "polling an API every minute": 24 * 60 * 30 / 1000 * CALLS_1000,
    "copying the year out weekly": stored * 4 * OUT_GB,
    "a dashboard reading the year": stored * refreshes / 1000 * READ_TB,
    "the same, reading only today": GB_A_DAY * refreshes / 1000 * READ_TB,
}
print(f"stored after a year: {stored:.1f} GB; refreshes a month: {refreshes}")
for what, reais in costs.items():
    print(f"{what:30} R$ {reais:8.2f} a month")
```

```
ana@lab:~/roda/collect$ python cost.py
stored after a year: 8.1 GB; refreshes a month: 8640
keeping a year of it           R$     1.22 a month
polling an API every minute    R$     0.86 a month
copying the year out weekly    R$    16.21 a month
a dashboard reading the year   R$  2100.30 a month
the same, reading only today   R$     5.75 a month
```

Guardar o ano inteiro custa R$ 1,22 por mês, e o polling minuto a minuto, R$ 0,86. Nenhum dos dois vale
uma reunião. Copiar o ano para o notebook de alguém toda semana custa mais do que guardá-lo, R$ 16,21,
porque o dado é guardado uma vez e a transferência é paga de novo a cada cópia. **O painel é a conta**:
R$ 2.100,30 por mês, porque ele lê os 8,1 GB inteiros em cada uma das suas 8640 atualizações. O mesmo
painel lendo só o dado de hoje custa R$ 5,75, que é o mesmo número dividido pelos 365 dias que ele deixou
de ler.

Nada no dado mudou entre essas duas linhas. O que mudou é se uma consulta consegue achar o dia de hoje
sem ler o resto. Isso depende de como o dado foi organizado quando foi coletado: num diretório por
dia, como a aula 3 guardou as viagens brutas, uma consulta sobre hoje abre um diretório.
Organizada como um único arquivo que só cresce, a mesma consulta lê o ano. **O momento mais barato para
decidir a organização é antes da primeira cópia**, porque mudá-la depois significa reescrever tudo o que
já foi guardado.

## Onde olhar primeiro

- Ache o multiplicador. Um custo que cresce com as atualizações, ou com os usuários, ou com o número de
  cópias, vai ultrapassar um custo que cresce com o volume. Aqui ele é o 8640.
- Pergunte de novo sobre a frequência. Um painel atualizado a cada cinco minutos para um relatório que
  Marta lê às nove é a pergunta do frescor da seção 04, feita pela conta.
- Decida quanto tempo cada coisa fica guardada. O dado bruto é guardado, e a aula 3 diz por quê; isso
  não quer dizer guardado onde é mais caro guardar. Classes de armazenamento e o resto da tabela de
  preços de um provedor são `cloud`.
- Ponha um preço ao lado de toda estimativa. Uma estimativa de volume sem custo do lado é meia resposta
  para Caio, e a metade mais fácil de aceitar.
