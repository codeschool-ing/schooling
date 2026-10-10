---
title: Com que frequência, e quanto custa o dado fresco
version: 1
---

**Quão fresco o dado precisa ser é uma pergunta para quem o lê, e a resposta honesta quase sempre é
menos fresco que a primeira resposta.** "Tempo real" é o que as pessoas pedem quando ninguém perguntou
o que elas fariam de diferente com um dado de um minuto atrás em vez de uma hora atrás.

**Frescor** é a idade do dado mais novo que um leitor consegue ver. É outra coisa que
**granularidade**, o nível de detalhe com que o dado registra o que aconteceu, e as duas são confundidas
o tempo todo. Caio pediu leituras *a cada minuto*. Quando perguntam o que o modelo faz com elas, ele
diz que o modelo retreina no domingo à noite. Ele precisa de leituras minuto a minuto, entregues uma
vez por semana; nada na pergunta dele exige que elas cheguem dentro do minuto.

## Três leitores, três respostas

| quem lê | para quê | quão fresco precisa ser |
|---|---|---|
| Marta | o relatório da manhã sobre o dia anterior | o dia anterior completo até as 07:00 |
| o aplicativo | o mapa de bicicletas livres que um cliente abre | um ou dois minutos, ou o cliente anda até uma estação vazia |
| Caio | retreinar o modelo de demanda | a última semana completa, até domingo à noite |

Só um dos três precisa do dado dentro do minuto, e é o aplicativo, que lê os sensores diretamente e
nunca pede nada ao time de dados. Os outros dois são atendidos por uma cópia feita uma vez por dia.

## Puxar e empurrar

O dado chega até você de um de dois jeitos. **Pull** (puxar): o seu programa pergunta à origem, num
horário marcado, se há algo novo — ele faz *polling*, consulta a origem. **Push** (empurrar): a origem
envia cada registro novo a você no momento em que ele acontece, chamando um endereço que você deu a ela
ou escrevendo numa fila que você lê.

O polling é o que sempre dá para construir, porque só exige que a origem responda perguntas. O preço é
que ele pergunta tenha acontecido alguma coisa ou não. Este programa pega um dia de viagens terminando,
a maioria entre seis da manhã e onze da noite, e as consulta de quatro jeitos: a cada minuto, a cada
quarto de hora, a cada hora e uma vez por dia. Para cada um, conta as chamadas, as chamadas que não
encontraram nada novo, e quanto tempo uma viagem esperou entre terminar e ser coletada. Salve como
`collect/poll.py`:

```python
# collect/poll.py
import random

random.seed(3)
# one day of rides ending, in seconds after midnight: most between 06:00 and 23:00
ends = sorted(random.randint(6 * 3600, 23 * 3600) for _ in range(1000))
ends += sorted(random.randint(0, 6 * 3600) for _ in range(20))   # a few at night

print("every   calls  empty  mean wait  worst wait")
for minutes in (1, 15, 60, 1440):
    step = minutes * 60
    polls = 24 * 60 // minutes
    waits, busy = [], set()
    for t in ends:
        poll = (t // step + 1) * step          # the first poll after the ride ended
        waits.append(poll - t)
        busy.add(poll)
    empty = polls - len(busy)
    print(f"{minutes:5}m  {polls:5}  {empty:5}  {sum(waits) / len(waits) / 60:6.1f} min"
          f"  {max(waits) / 60:7.1f} min")
```

```
ana@lab:~/roda/collect$ python poll.py
every   calls  empty  mean wait  worst wait
    1m   1440    779     0.5 min      1.0 min
   15m     96     15     7.7 min     15.0 min
   60m     24      2    29.6 min     60.0 min
 1440m      1      0   573.7 min   1419.8 min
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo das 08:00 às 09:00 com sete viagens terminando. Consultando a cada quinze minutos, são quatro chamadas: três encontram viagens e uma volta vazia, e a viagem que terminou às 08:03 espera doze minutos. Consultando a cada minuto, são sessenta chamadas: sete encontram uma viagem e cinquenta e três voltam vazias.\" data-fig=\"polling\"><defs><marker id=\"polling-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"100\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00</text><text x=\"250\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:15</text><text x=\"400\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:30</text><text x=\"550\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:45</text><text x=\"700\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:00</text><text x=\"88\" y=\"100\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a cada 15 min</text><line x1=\"100\" y1=\"100\" x2=\"700\" y2=\"100\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"250\" y1=\"86\" x2=\"250\" y2=\"114\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"250\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 novas</text><line x1=\"400\" y1=\"86\" x2=\"400\" y2=\"114\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"400\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">vazia</text><line x1=\"550\" y1=\"86\" x2=\"550\" y2=\"114\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"550\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3 novas</text><line x1=\"700\" y1=\"86\" x2=\"700\" y2=\"114\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"700\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1 nova</text><circle cx=\"130\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"170\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"210\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"440\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"510\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"540\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"620\" cy=\"100\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><line x1=\"130\" y1=\"70\" x2=\"250\" y2=\"70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"130\" y1=\"65\" x2=\"130\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><line x1=\"250\" y1=\"65\" x2=\"250\" y2=\"75\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></line><text x=\"190\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">espera 12 min</text><text x=\"400\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4 chamadas: 1 volta vazia, e uma viagem espera até 15 minutos</text><text x=\"88\" y=\"195\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">a cada minuto</text><line x1=\"100\" y1=\"195\" x2=\"700\" y2=\"195\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></line><line x1=\"110\" y1=\"187\" x2=\"110\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"120\" y1=\"187\" x2=\"120\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"130\" y1=\"187\" x2=\"130\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"140\" y1=\"187\" x2=\"140\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"150\" y1=\"187\" x2=\"150\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"160\" y1=\"187\" x2=\"160\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"170\" y1=\"187\" x2=\"170\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"180\" y1=\"187\" x2=\"180\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"190\" y1=\"187\" x2=\"190\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"200\" y1=\"187\" x2=\"200\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"210\" y1=\"187\" x2=\"210\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"220\" y1=\"187\" x2=\"220\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"230\" y1=\"187\" x2=\"230\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"240\" y1=\"187\" x2=\"240\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"250\" y1=\"187\" x2=\"250\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"260\" y1=\"187\" x2=\"260\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"270\" y1=\"187\" x2=\"270\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"280\" y1=\"187\" x2=\"280\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"290\" y1=\"187\" x2=\"290\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"300\" y1=\"187\" x2=\"300\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"310\" y1=\"187\" x2=\"310\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"320\" y1=\"187\" x2=\"320\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"330\" y1=\"187\" x2=\"330\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"340\" y1=\"187\" x2=\"340\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"350\" y1=\"187\" x2=\"350\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"360\" y1=\"187\" x2=\"360\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"370\" y1=\"187\" x2=\"370\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"380\" y1=\"187\" x2=\"380\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"390\" y1=\"187\" x2=\"390\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"400\" y1=\"187\" x2=\"400\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"410\" y1=\"187\" x2=\"410\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"420\" y1=\"187\" x2=\"420\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"430\" y1=\"187\" x2=\"430\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"440\" y1=\"187\" x2=\"440\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"450\" y1=\"187\" x2=\"450\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"460\" y1=\"187\" x2=\"460\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"470\" y1=\"187\" x2=\"470\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"480\" y1=\"187\" x2=\"480\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"490\" y1=\"187\" x2=\"490\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"500\" y1=\"187\" x2=\"500\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"510\" y1=\"187\" x2=\"510\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"520\" y1=\"187\" x2=\"520\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"530\" y1=\"187\" x2=\"530\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"540\" y1=\"187\" x2=\"540\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"550\" y1=\"187\" x2=\"550\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"560\" y1=\"187\" x2=\"560\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"570\" y1=\"187\" x2=\"570\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"580\" y1=\"187\" x2=\"580\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"590\" y1=\"187\" x2=\"590\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"600\" y1=\"187\" x2=\"600\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"610\" y1=\"187\" x2=\"610\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"620\" y1=\"187\" x2=\"620\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"630\" y1=\"187\" x2=\"630\" y2=\"203\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><line x1=\"640\" y1=\"187\" x2=\"640\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"650\" y1=\"187\" x2=\"650\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"660\" y1=\"187\" x2=\"660\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"670\" y1=\"187\" x2=\"670\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"680\" y1=\"187\" x2=\"680\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"690\" y1=\"187\" x2=\"690\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"700\" y1=\"187\" x2=\"700\" y2=\"203\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><circle cx=\"130\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"170\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"210\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"440\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"510\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"540\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><circle cx=\"620\" cy=\"195\" r=\"4\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></circle><text x=\"400\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">60 chamadas: 7 encontram uma viagem, 53 voltam vazias</text></svg>", "caption": "As mesmas sete viagens, consultadas a cada quinze minutos e a cada minuto. Dado mais fresco custa chamadas, e a maioria das chamadas extras não encontra nada."}
```

**Cada passo rumo a um dado mais fresco é pago em chamadas, e a maioria das chamadas extras não
encontra nada.** Consultar a cada minuto faz 1.440 chamadas por dia, e 779 delas voltam vazias, entre
elas quase todos os minutos da madrugada. Uma vez por dia faz uma chamada, e uma viagem espera em média
573,7 minutos para ser coletada, mais de nove horas. Quinze minutos fica no meio: 96 chamadas, uma
espera média de 7,7 minutos, e ninguém na tabela acima precisa de mais que isso.

O push elimina tanto as chamadas vazias quanto a espera, e tem um preço próprio. A origem precisa
oferecê-lo, e muitas não oferecem. O seu lado precisa estar escutando sempre que a origem envia: um
receptor que ficou fora do ar por uma hora perdeu uma hora, a não ser que a origem guarde o que enviou e
tente de novo. O que uma origem promete sobre tentar de novo é assunto da aula 8.

## O que o frescor custa além das chamadas

Uma cópia feita a cada minuto são 1.440 execuções por dia, e a seção 02 contou o que isso significa:
1.440 chances de falhar, cada uma pedindo alguém que perceba. Cada execução precisa poder ser repetida
sem dano, porque uma execução repetida é o caso normal nesse ritmo. E ela não pode copiar tudo a cada
vez: precisa copiar só o que mudou, que é a próxima seção. **Mais fresco não é melhor; é mais caro**, e
o único motivo para pagar é um leitor cuja decisão muda com isso. Se o dado é processado em lotes ou à
medida que chega é a mesma pergunta, feita ao processamento em vez da cópia, e a aula 8 a faz.
