---
title: O laboratório em que este curso roda
version: 1
---

Toda transcrição deste curso foi gravada numa máquina Linux montada pelo `lab.sh`, que fica ao lado do `course.json`. É o mesmo tipo de laboratório que o `embeddings-vectors` usa, e ele reaproveita a central de ajuda, os livros e o modelo de embeddings daquele curso em vez de montar uma segunda cópia. Monte-o uma vez:

```sh
sudo bash lab.sh up
```

Ele cria o usuário `ana`, um ambiente virtual Python em `/opt/agents` com todas as bibliotecas que as aulas importam (fixadas no script), o diretório de trabalho `~/agents` e o labllm, o fornecedor de modelo com que os programas conversam. O `captures.sh` de cada aula começa com `lab.sh reset`, que refaz o `~/agents` do zero, então toda transcrição parte do mesmo estado.

```
ana@lab:~/agents$ curl -s http://127.0.0.1:8600/; echo
{"labllm": "a stand-in provider; see lab/labllm.py", "models": ["scripted-1", "scripted-mini"]}
ana@lab:~/agents$ ls data
books.jsonl
help.jsonl
shop.db
ana@lab:~/agents$ du -sh /opt/agents/share /opt/agents/lib
113M	/opt/agents/share
634M	/opt/agents/lib
ana@lab:~/agents$ du -sh /opt/agents/lib/python3.11/site-packages/claude_agent_sdk
232M	/opt/agents/lib/python3.11/site-packages/claude_agent_sdk
ana@lab:~/agents$ python -c "import shop; print(shop.get_order(\"M-1042\"))"
{'id': 'M-1042', 'customer_id': 'c-101', 'placed_on': '2026-09-20', 'status': 'delivered', 'delivered_on': '2026-09-24', 'shipping': 490, 'tracking': 'BR5512340002', 'lines': [{'book_id': 'b39', 'quantity': 1, 'cents': 2990}], 'total': 3480, 'refunded': 0}
```

O `~/agents/data` guarda a central de ajuda e o catálogo da Marginalia, copiados do `embeddings-vectors`, e o `shop.db`, os pedidos. O `shop.py` transforma esses arquivos em funções simples (`get_order`, `get_customer`, `get_book`, `search_help`, `refund`), que cada aula embrulha como ferramentas. O calendário do laboratório para em 6 de outubro de 2026, então a idade de um pedido sai igual em toda execução.

## O modelo é um substituto, e o curso diz isso toda vez

**Nenhuma API de fornecedor de modelo estava acessível da máquina em que este curso foi gravado**, e uma chave de API é uma conta que um curso não pode distribuir. Então quem responde é o labllm. Ele fala os formatos de três APIs reais (a Messages da Anthropic, a Chat Completions da OpenAI e a Gemini do Google), chamadas de ferramenta incluídas, de perto o bastante para que os SDKs dos fornecedores e os três SDKs de agente das aulas 8 a 10 conversem com ele sem modificação.

**O que ele não tem é um modelo.** As respostas dele são escolhidas a partir de regras que o curso escreveu, em `lab/scripted/`: uma regra identifica uma conversa por uma frase na mensagem do usuário e pelo passo em que ela está, e dá a resposta, que pode ser texto, uma chamada de ferramenta ou as duas coisas. **Então, sempre que uma transcrição mostra qual ferramenta um agente escolheu, ou o que ele disse no fim, essas são palavras do curso.** Toda aula diz isso onde acontece. Real é todo o resto: os SDKs, os laços, as ferramentas e seus resultados, os esquemas e a validação deles, os servidores MCP, os erros e os limites. É dessa parte que este curso trata, e é a parte que continuaria igual com um modelo real por trás.

## Três jeitos de ter a máquina

| caminho | o que exige | |
|---|---|---|
| **uma máquina Linux em que você tem root**, Ubuntu 24.04 | Python 3.11, Node.js 22, `iproute2` e `openssl`; cerca de 750 MB em `/opt/agents` | **recomendado**, e aquele em que toda transcrição foi gravada |
| uma máquina virtual com Ubuntu 24.04 | o mesmo, mais a memória e o disco da própria VM: dê a ela 4 GB de memória e 15 GB de disco | para Windows e macOS |
| um ambiente de desenvolvimento na nuvem que dê root | os mesmos pacotes | não testado por este curso |

Os 750 MB são as linhas do `du` na transcrição acima: 113 MB de arquivos compartilhados e 634 MB de bibliotecas. O último `du` é uma dessas bibliotecas sozinha, 232 MB delas: o Claude Agent SDK, que traz junto o programa de linha de comando do Claude Code que a aula 9 dirige. A montagem precisa da rede uma vez, para buscar as bibliotecas no PyPI e no npm e o modelo de embeddings no bucket do Chroma; depois disso o laboratório não alcança nada fora da máquina.
