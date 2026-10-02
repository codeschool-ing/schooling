---
title: Pagando menos pela parte que nunca muda
version: 1
---

A maioria das requisições a um modelo começa do mesmo jeito: o mesmo prompt de sistema, as mesmas
instruções, os mesmos documentos, e só as últimas linhas mudam. Um provedor precisa ler esse
prefixo toda vez. O **cache de prompt** deixa que ele guarde o trabalho de ler esse prefixo por
alguns minutos, e cobra menos de uma requisição que o reaproveita.

O jeito como isso é cobrado é a parte a entender. Na tabela da aula 2 seção 04, o Claude Sonnet 5.5
custa `$2` por milhão de tokens de entrada, `$2.50` para **escrever** um prefixo no cache e `$0.20`
para **lê-lo** de volta. Escrever custa mais que não usar cache nenhum; ler custa um décimo. Então
um cache só compensa quando o mesmo prefixo é lido de novo antes de expirar, o que na API da
Anthropic é cinco minutos por padrão, renovados a cada leitura.

## Marcando o prefixo

Na API da Anthropic você marca o fim da parte a guardar com `cache_control`. Tudo até esse bloco,
inclusive, vira o prefixo em cache. O `lab/cache.py` põe o projeto inteiro, todo arquivo do git, no
prompt de sistema, e faz duas perguntas seguidas:

```python
import subprocess
from decimal import Decimal

import anthropic

# Claude Sonnet 5.5, dollars per million tokens, read on 2026-10-02 (prices.py).
BASE, WRITE, READ = Decimal("2"), Decimal("2.50"), Decimal("0.20")
client = anthropic.Anthropic()
project = subprocess.run("git ls-files | xargs tail -n +1", shell=True,
                         capture_output=True, text=True).stdout
system = [{"type": "text", "text": "You review changes to this project.\n\n" + project,
           "cache_control": {"type": "ephemeral"}}]
for question in ["Explain the shop's shipping rule.", "Explain the shipping rule again, shorter."]:
    r = client.messages.create(model="scripted-1", max_tokens=300, system=system,
                               messages=[{"role": "user", "content": question}])
    u = r.usage
    print(f"input {u.input_tokens:4}  cache write {u.cache_creation_input_tokens:4}  "
          f"cache read {u.cache_read_input_tokens:4}  output {u.output_tokens}")
    paid = (u.input_tokens * BASE + u.cache_creation_input_tokens * WRITE
            + u.cache_read_input_tokens * READ) / 1_000_000
    plain = (u.input_tokens + u.cache_creation_input_tokens + u.cache_read_input_tokens) * BASE / 1_000_000
    print(f"    input cost ${paid:.6f}, against ${plain:.6f} with no cache")
```

```
ana@dev:~/shop$ python lab/cache.py
input    8  cache write 1398  cache read    0  output 147
    input cost $0.003511, against $0.002812 with no cache
input    9  cache write    0  cache read 1398  output 147
    input cost $0.000298, against $0.002814 with no cache
```

A primeira requisição **escreveu** 1.398 tokens no cache e pagou mais por eles do que teria pago sem
cache: US$ 0,003511 contra US$ 0,002812. A segunda **leu** os mesmos 1.398 tokens de volta e pagou
US$ 0,000298 pela entrada em vez de US$ 0,002814, cerca de um décimo. O `input_tokens` agora é só a
parte depois do prefixo em cache, a própria pergunta.

**As regras do labllm aqui são dele**, escritas para se comportar como as da Anthropic: um prefixo
com menos de 1.024 tokens não vai para o cache, e uma entrada vive cinco minutos desde o último uso.
Os mínimos reais dependem do modelo, e a documentação do provedor para o modelo que você usa é a
fonte. OpenAI e Google também dão desconto num prefixo repetido, e os modelos recentes deles fazem
isso sem que se peça; a coluna `cache read` da tabela de preços é esse desconto.

## Fazendo o cache acertar

- **Ponha primeiro o que nunca muda e por último o que sempre muda.** O cache casa a partir do
  começo da requisição. Um horário ou o nome de um usuário no topo do prompt de sistema faz de
  cada requisição um prefixo novo, e de cada requisição uma escrita no cache.
- **Ordene as partes estáveis pelo quanto são estáveis**: instruções, depois definições de
  ferramentas, depois documentos, depois a conversa, depois a pergunta nova.
- **Confira o `cache_read_input_tokens` no `usage` que você registra.** Um cache que nunca lê está
  custando o acréscimo da escrita em toda requisição, e só esse campo vai lhe dizer.
