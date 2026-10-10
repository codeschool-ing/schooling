---
title: Janelas tumbling
version: 1
---

**Uma janela tumbling corta o tempo em fatias iguais que se encostam e nunca se sobrepõem, então todo
evento cai em exatamente uma.** É a janela que as pessoas querem dizer com "a cada cinco minutos" ou
"por hora", e é o que o `per_minute.py` da lição 9 construiu: uma venda às 10:37 foi para a hora das
10:00 e para nenhuma outra.

A regra é uma linha de aritmética. Com os horários em segundos e um tamanho de cinco minutos, 300
segundos, a janela começa no horário do evento arredondado **para baixo** até um múltiplo do tamanho:

```python
start = t // size * size
end = start + size
```

09:03:55 são 32.635 segundos depois da meia-noite; divididos por 300 dão 108,78, arredondado para
baixo 108 (o `//` do Python divide e arredonda para baixo num passo só), vezes 300 dá 32.400
segundos, que são 09:00:00. A janela vai das 09:00:00 às 09:05:00. Toda janela tumbling de qualquer
motor é essa fórmula, a menos de um deslocamento para fusos horários.

O programa que a lição inteira roda implementa quatro tipos de janela sobre as dez vendas da seção
anterior. Salve como `~/work/windows.py`:

```schooling-example
{
  "language": "python",
  "file": "windows.py",
  "parts": [
    {
      "code": "\"\"\"windows.py: the same ten sales, cut into windows four different ways.\n\n    python windows.py tumbling SIZE [--by-shop] [--updates]\n    python windows.py hopping SIZE ADVANCE [--by-shop] [--updates]\n    python windows.py sliding SIZE [--by-shop]\n    python windows.py session GAP [--by-shop]\n\nSIZE, ADVANCE and GAP are in minutes. The sales are listed in the order they\nARRIVED; the eighth happened at 09:08:50 and arrived after the seventh.\n\"\"\"\nimport sys\n\nSALES = [  # (when it happened, shop, cents), in the order they arrived\n    (\"09:00:40\", \"recife\", 3990), (\"09:02:10\", \"natal\", 5490),\n    (\"09:03:55\", \"olinda\", 2990), (\"09:05:00\", \"recife\", 7900),\n    (\"09:06:20\", \"natal\", 4490), (\"09:12:30\", \"caruaru\", 6200),\n    (\"09:13:05\", \"recife\", 3500), (\"09:08:50\", \"natal\", 8990),\n    (\"09:14:10\", \"olinda\", 2990), (\"09:21:00\", \"recife\", 5490),\n]\n\n",
      "note": "O uso e **as dez vendas, na ordem em que chegaram**. Os horários são de quando cada venda aconteceu; o dinheiro está em centavos."
    },
    {
      "code": "def secs(when):\n    h, m, s = map(int, when.split(\":\"))\n    return h * 3600 + m * 60 + s\n\n\ndef clock(t):\n    return f\"{t // 3600:02d}:{t % 3600 // 60:02d}:{t % 60:02d}\"\n\n",
      "note": "Dois auxiliares: um horário do dia para segundos desde a meia-noite, e de volta. Tudo no meio é aritmética sobre segundos."
    },
    {
      "code": "def tumbling(t, size):\n    start = t // size * size\n    return [(start, start + size)]\n\n",
      "note": "**Uma janela tumbling começa no horário do evento arredondado para baixo até um múltiplo do tamanho**, e termina um tamanho depois. Um evento, uma janela."
    },
    {
      "code": "def hopping(t, size, advance):\n    last = t // advance * advance\n    return [(s, s + size) for s in range(last, t - size, -advance)][::-1]\n\n",
      "note": "Uma janela hopping começa a cada ADVANCE. As janelas que contêm `t` são as que começaram nele ou antes e ainda não terminaram, contadas para trás a partir do início mais recente."
    },
    {
      "code": "def sliding(sales, size):\n    for t, _, _ in sorted(sales):\n        yield (t - size, t), [x for x in sales if t - size <= x[0] <= t]\n\n",
      "note": "O tipo do Kafka Streams: para cada venda, a janela que TERMINA nela, com toda venda até SIZE antes dela, as duas bordas incluídas."
    },
    {
      "code": "def session(sales, gap):\n    found = []  # [first, last, sales] for each session so far\n    for sale in sales:\n        t = sale[0]\n        near = [s for s in found if s[0] - gap < t < s[1] + gap]\n        if len(near) > 1:\n            print(f\"({clock(t)} arrives and joins {len(near)} sessions into one)\")\n        for s in near:\n            found.remove(s)\n        found.append([min([t] + [s[0] for s in near]), max([t] + [s[1] for s in near]),\n                      [sale] + [x for s in near for x in s[2]]])\n    for first, last, inside in sorted(found):\n        yield (first, last), inside\n\n",
      "note": "As sessões são encontradas na ordem de chegada. Uma venda perto de uma sessão existente entra nela, e **uma venda perto de duas sessões as junta numa só**, o que o programa diz em voz alta."
    },
    {
      "code": "def show(window, inside, prefix=\"\"):\n    cents = sum(c for _, _, c in inside)\n    print(f\"{prefix}{clock(window[0])}-{clock(window[1])}  {len(inside):5d}  {cents:6d}\")\n\n\nkind, minutes = sys.argv[1], [int(a) * 60 for a in sys.argv[2:] if a.isdigit()]\nby_shop, updates = \"--by-shop\" in sys.argv, \"--updates\" in sys.argv\nsales = [(secs(w), shop, cents) for w, shop, cents in SALES]\nprint((\"arrived   \" if updates else \"\") + \"window               sales   cents\")\nfor shop in sorted({s[1] for s in sales}) if by_shop else [None]:\n    mine = [s for s in sales if shop in (None, s[1])]\n    if shop:\n        print(shop)\n    if kind == \"sliding\":\n        for window, inside in sliding(mine, *minutes):\n            show(window, inside)\n    elif kind == \"session\":\n        for window, inside in session(mine, *minutes):\n            show(window, inside)\n    else:\n        windows = {}\n        for sale in mine:\n            cut = tumbling if kind == \"tumbling\" else hopping\n            for window in cut(sale[0], *minutes):\n                windows.setdefault(window, []).append(sale)\n                if updates:\n                    show(window, windows[window], prefix=clock(sale[0]) + \"  \")\n        if not updates:\n            for window, inside in sorted(windows.items()):\n                show(window, inside)",
      "note": "O resto imprime: uma linha por janela, opcionalmente por loja, ou, com `--updates`, uma linha cada vez que uma venda muda uma janela."
    }
  ]
}
```

As vendas estão escritas dentro do programa em vez de lidas do Kafka, de propósito: toda pergunta
desta lição é sobre a qual janela um evento pertence, e isso é aritmética sobre horários. As lições
12 e 13 rodam as mesmas janelas no Spark e no Flink sobre um tópico.

Janelas tumbling de cinco minutos:

```
ubuntu@stream:~/work$ python windows.py tumbling 5
```

Quatro janelas, e as dez vendas fecham a conta: 3, 3, 3 e 1. Não há linha para 09:15 às 09:20,
porque nenhuma venda aconteceu nesse intervalo. **Um motor só cria uma janela quando um evento cai
nela**, então cinco minutos sem movimento são uma linha ausente e não um zero, e um relatório que
precise do zero tem de preenchê-lo por conta própria.

## Para onde vai uma borda

A venda 4 aconteceu exatamente às 09:05:00. Ela está na segunda janela, 09:05 às 09:10, e não na
primeira. **Uma janela inclui o início e exclui o fim**, escrito `[09:00, 09:05)`: o colchete diz
que a borda está dentro, o parêntese que não está. A escolha é arbitrária e a consistência não é. Se
as duas bordas estivessem dentro, a venda 4 seria contada duas vezes; se nenhuma estivesse, ela
sumiria. Intervalos semiabertos são o único jeito de ladrilhar o tempo sem buracos e sem
sobreposições, e Flink, Spark e Kafka Streams usam todos eles para janelas tumbling.

O rótulo da própria janela também é uma convenção. Este programa imprime as duas bordas. Um motor
costuma identificar um resultado pelo início da janela, que se lê naturalmente ("a janela das
09:05"), e alguns painéis rotulam pelo fim, que é quando o resultado fica disponível. Confira qual
antes de juntar as saídas de dois sistemas, ou todo número vai ficar uma janela fora.

## Escolhendo o tamanho

O tamanho é uma pergunta sobre o negócio, não sobre o motor. Cinco minutos respondem "a loja está
cheia agora"; uma hora responde "como foi a manhã". Janelas menores significam mais janelas, cada
uma com menos eventos, então uma contagem fica mais ruidosa e o estado guardado por janela se
multiplica. A janela tumbling tem uma limitação que a próxima seção remove: um surto que cruza uma
borda é cortado em dois, e nenhuma das metades parece um surto.
