---
title: Sinalizar: manter o vazio e dizer por quê
version: 1
---

**O quarto movimento não chuta nada. Ele mantém o vazio e acrescenta uma coluna que diz o que o
vazio quer dizer.** Para dados MNAR é muitas vezes a única opção honesta, e com frequência responde
à pergunta melhor do que qualquer preenchimento.

Os tempos de entrega da frota própria, sinalizados:

```python
from minutes import own, report

own["timing"] = own["minutes"].notna().map({True: "recorded", False: "over 120"})
print(own["timing"].value_counts().to_string())
floor = own["minutes"].fillna(120)
report("blanks as 120, a floor", floor)
```

```
ana@lab:~/clean$ python flag.py
timing
recorded    14858
over 120      456
blanks as 120, a floor mean  61.2  sd 23.2  late 13.2%
```

A coluna nova, `timing`, diz `recorded` para 14.858 entregas e `over 120` para 456. Nada foi
inventado. Mas o que a aula 3 aprendeu com as operações agora está no dado: **um vazio aqui quer
dizer pelo menos 120 minutos.** Isso transforma um valor faltante num limite, e um limite se usa.

- **A fração de atrasos é exata.** Toda entrega sinalizada levou 120 minutos ou mais, então toda ela
  está atrasada pela regra dos 90 minutos. Contá-las dá 13,2%.
- **A média tem um piso.** Tratar cada entrega sinalizada como exatamente 120 dá 61,2 minutos, o
  mínimo que a média real pode ser, e o relatório diz "pelo menos 61,2".

Contra o arquivo de verdade:

```
ana@lab:~/clean$ python -c "import pandas as pd; t = pd.read_csv('/var/lib/clean-data/truth/orders.csv'); m = t.loc[t['what'] == 'minutes', 'value']; print(f'real: mean {m.mean():.1f}, late {(m >= 90).mean() * 100:.1f}%')"
real: mean 61.9, late 13.2%
```

A fração de atrasos está exatamente certa, 13,2%, onde todo preenchimento anterior desta aula disse
10,2% ou 10,5%. A média é 61,9, dentro do limite. **O movimento mais humilde deu a melhor resposta**,
porque carregou a única coisa que se sabia sobre os vazios em vez de trocá-la por algo que não se
sabia.

Uma marca também serve à próxima pessoa. Uma coluna preenchida com medianas parece completa e não dá
pista de que 456 dos seus valores são palpites; uma marca diz em que linhas confiar para que
pergunta, e deixa alguém com um método melhor usá-lo sem desfazer nada.
