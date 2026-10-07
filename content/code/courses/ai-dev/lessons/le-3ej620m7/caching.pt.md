---
title: Pagando menos pela parte que nunca muda
version: 2
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

Na API da Anthropic você marca o fim da parte a guardar com `cache_control`. Tudo até aquele bloco,
inclusive, vira o prefixo em cache. O `~/shop/scratch/cache.py` põe o projeto inteiro, cada arquivo
do git, no prompt de sistema, marca-o, e faz duas perguntas seguidas. Ele imprime o que o `usage`
diz de cada requisição, quanto ela demorou, e quanto a entrada dela teria custado nos preços do
Sonnet com e sem o cache:

```python
import subprocess
import time
from decimal import Decimal

import anthropic

# Claude Sonnet 5.5, dollars per million tokens, read on 2026-10-02.
BASE, READ = Decimal("2"), Decimal("0.20")
client = anthropic.Anthropic()
project = subprocess.run("git ls-files | xargs tail -n +1", shell=True,
                         capture_output=True, text=True).stdout
system = [{"type": "text", "text": "You review changes to this project.\n\n" + project,
           "cache_control": {"type": "ephemeral"}}]
for question in ["Explain the shop's shipping rule.", "Explain the shipping rule again, shorter."]:
    start = time.monotonic()
    r = client.messages.create(model="llama3.2:3b", max_tokens=300, system=system,
                               messages=[{"role": "user", "content": question}])
    u = r.usage
    read = u.cache_read_input_tokens or 0
    print(f"input {u.input_tokens:4}  cache read {read:4}  output {u.output_tokens:3}  "
          f"{time.monotonic() - start:4.1f} s")
    paid = (u.input_tokens * BASE + read * READ) / 1_000_000
    plain = (u.input_tokens + read) * BASE / 1_000_000
    print(f"    at Sonnet's prices: input ${paid:.6f}, against ${plain:.6f} with no cache")
```

```
ana@dev:~/shop$ ollama stop llama3.2:3b
ana@dev:~/shop$ python scratch/cache.py
input 1417  cache read    0  output 107  47.9 s
    at Sonnet's prices: input $0.002834, against $0.002834 with no cache
input   11  cache read 1407  output  59   8.9 s
    at Sonnet's prices: input $0.000303, against $0.002836 with no cache
```

O `ollama stop` descarrega o modelo antes, o que esvazia o cache do Ollama, então a execução começa
como começaria na sua máquina da primeira vez. A primeira requisição leu os 1.417 tokens da requisição
e levou 47,9 segundos, com a carga do modelo incluída. A segunda **leu 1.407 deles do cache**, leu
só os seus 11 tokens novos, e levou 8,9, a maior parte escrevendo os 59 tokens da resposta. Nada foi
cobrado, já que o modelo roda na sua máquina, então a economia que se vê é a espera. A linha de
preço mostra o que o mesmo `usage` teria custado na Anthropic: os tokens em cache a um décimo.

**O cache do Ollama não é o da Anthropic, e vale saber as diferenças.** O Ollama ignora o
`cache_control`: ele guarda o prefixo da última requisição na memória, marcado ou não, e reaproveita
a parte da próxima requisição que começa igual. Ele informa essa parte como
`cache_read_input_tokens`, e é por isso que todo programa desde a aula 1 a soma a `input_tokens`
para chegar ao tamanho de uma requisição. E ele nunca cobra pela escrita, então
`cache_creation_input_tokens` volta vazio. A Anthropic cobra o adicional de escrita na primeira
requisição: 1.417 tokens a `$2.50` em vez de `$2`, cerca de um quarto a mais que não usar cache, o
que só compensa se o mesmo prefixo for lido de novo antes de expirar. Os mínimos reais também
dependem do modelo: a Anthropic não guarda um prefixo abaixo de um tamanho mínimo, 1.024 tokens em
muitos dos modelos dela, e a documentação do provedor para o modelo que você usa é a fonte. A
OpenAI e o Google também dão desconto num prefixo repetido, e os modelos recentes deles fazem isso
sem ninguém pedir; a coluna `cache read` da tabela de preços é esse desconto.

## Fazendo o cache acertar

- **Ponha primeiro o que nunca muda e por último o que sempre muda.** O cache casa a partir do
  começo da requisição. Um horário ou o nome de um usuário no topo do prompt de sistema faz de
  cada requisição um prefixo novo, e de cada requisição uma escrita no cache.
- **Ordene as partes estáveis pelo quanto são estáveis**: instruções, depois definições de
  ferramentas, depois documentos, depois a conversa, depois a pergunta nova.
- **Confira o `cache_read_input_tokens` no `usage` que você registra.** Um cache que nunca lê está
  custando o acréscimo da escrita em toda requisição, e só esse campo vai lhe dizer.
