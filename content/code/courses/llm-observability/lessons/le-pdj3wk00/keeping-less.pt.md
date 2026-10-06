---
title: Guardar o texto por menos tempo que os números
version: 1
---

A tabela do início desta aula deu ao texto e aos números vidas diferentes: dias para as palavras que
as pessoas digitaram, meses para os tokens, os tempos e os resultados. Manter isso exige um job que
rode num horário marcado e tire o texto dos spans que passaram da data, deixando todo o resto no lugar.

O `expire.py` faz isso no arquivo de spans do laboratório:

```python
"""expire.py: take what people typed out of spans older than --days, and keep everything else."""
import argparse
import json
import os
from datetime import datetime, timedelta

TEXT = ("app.question", "app.reply")
p = argparse.ArgumentParser()
p.add_argument("--now", required=True)
p.add_argument("--days", type=int, required=True)
p.add_argument("--spans", default="spans.jsonl")
a = p.parse_args()

since = datetime.fromisoformat(a.now) - timedelta(days=a.days)
cutoff = since.timestamp() * 1e9
spans, expired = [json.loads(line) for line in open(a.spans)], 0
for s in spans:
    if s["start"] < cutoff and any(k in s["attributes"] for k in TEXT):
        for k in TEXT:
            s["attributes"].pop(k, None)
        expired += 1
with open(a.spans + ".new", "w") as f:
    f.writelines(json.dumps(s, ensure_ascii=False) + "\n" for s in spans)
os.replace(a.spans + ".new", a.spans)
print(f"{len(spans)} spans; text removed from {expired}, every one that started before {since:%Y-%m-%d %H:%M}")
```

A aula 3 explica o `replay.py`, que reproduz o arquivo de tráfego através do assistente com cada
pedido carimbado no momento que o arquivo lhe dá. Aqui ele reproduz o fim de semana, para haver o que
expirar:

```
ana@lab:~/obs$ rm -f spans.jsonl feedback.jsonl; python replay.py --from 2026-10-03 --to 2026-10-05
replayed 238 requests from data/traffic.jsonl: 296 asked, 0 failed, 124 feedback events
ana@lab:~/obs$ grep -c "app.question" spans.jsonl
296
ana@lab:~/obs$ python expire.py --now 2026-10-05T00:00 --days 1
1533 spans; text removed from 153, every one that started before 2026-10-04 00:00
ana@lab:~/obs$ grep -c "app.question" spans.jsonl
143
```

Dois dias, 296 perguntas em spans raiz. Com um dia de vida para o texto, rodando à meia-noite da noite
de domingo, as 153 perguntas de sábado perdem as palavras e mantêm o seu lugar em toda contagem: o span
continua lá, com a funcionalidade, a versão, os tokens, a duração e o resultado. As 143 de domingo
guardam o texto até a próxima execução.

## Como é uma política de retenção para traces

| o quê | guardado por | por que tanto |
|---|---|---|
| spans sem texto: nomes, tempos, tokens, resultados, notas | 13 meses | um ano de tendência mais o mês para comparar |
| a pergunta e a resposta num span | 7 dias | o bastante para depurar uma reclamação e amostrar para avaliação |
| uma amostra escolhida para avaliação (aulas 9 e 13) | até o conjunto de avaliação ser substituído | ela vira dado de teste, com dono e revisão próprios |
| o prompt inteiro, fontes incluídas | não é guardado | as fontes estão no banco e os ids dos trechos no span as acham |

Os números dessa tabela são um ponto de partida, não uma regra que alguém publicou. O que a torna uma
política é que cada linha tem um propósito e um fim, e que o job que a aplica roda quer alguém se
lembre dele ou não.

Dois detalhes decidem se funciona. **Expirar reescreve, e alguns armazéns tornam isso difícil**: um
backend de rastreamento feito para acrescentar pode só conseguir apagar traces inteiros por idade, e
nesse caso o texto pertence a um armazém separado, com retenção própria e mais curta, ligado ao trace
pelo id. E **a eliminação tem de chegar ao texto antes da expiração**. Um cliente que pede à loja que
apague o que ela guarda sobre ele tem direito a isso hoje, não daqui a sete dias. O pseudônimo torna o
pedido encontrável: faça o hash do id de usuário com a chave, apague o texto de todo span com esse
valor, e os números ficam nas contagens sem nada que identifique. A aula 10 do `observability` tem o
mesmo problema com logs e chega à mesma resposta.
