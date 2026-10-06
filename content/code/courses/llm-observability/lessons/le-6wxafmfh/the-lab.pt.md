---
title: O laboratório, e o que nele é real
version: 1
---

Toda transcrição deste curso foi gravada numa máquina Linux, e o curso traz o script que a monta: o
`lab.sh`, ao lado do `course.json`. É a máquina que o `rag` montou, que é a máquina que o
`embeddings-vectors` montou, com um cômodo a mais a cada vez. `sudo bash lab.sh up` num Ubuntu 24.04
monta as duas primeiro e depois acrescenta o que é preciso para observar um modelo em produção.
`sudo bash lab.sh reset` devolve o diretório de trabalho ao estado de antes desta aula, e o
`captures.sh` de toda aula começa por ele.

Quem está no teclado continua sendo a ana, desenvolvedora da Marginalia, a livraria online que não
existe. No fim do `rag` ela tinha um pipeline que responde às perguntas dos clientes a partir dos treze
documentos da loja. Neste curso **ele está em produção**: os clientes digitam nele, a equipe de
atendimento o usa para resumir conversas, e ninguém sabe dizer como ele está se saindo. Essa última
parte é o assunto do curso.

## O que há no diretório de trabalho

```
ana@lab:~/obs$ ls
assistant.py
auto.py
data
one_call.py
prices.json
redact.py
releases.json
telemetry.py
tree.py
ana@lab:~/obs$ wc -l data/traffic.jsonl data/eval.jsonl
  1127 data/traffic.jsonl
    30 data/eval.jsonl
  1157 total
```

O `assistant.py` é o assistente de ajuda, e o resto desta aula o desmonta. `telemetry.py`,
`redact.py` e `tree.py` são os programinhas em que ele se apoia, e cada um aparece onde é usado pela
primeira vez. `data/docs` guarda os documentos do `rag`, sem mudança, e `data/eval.jsonl` as suas
trinta perguntas de teste, que voltam da aula 8 em diante.

`data/traffic.jsonl` é **uma semana de pedidos**, 1.127 deles, da segunda-feira 28 de setembro ao
domingo 4 de outubro de 2026: quem perguntou, em que sessão, por qual funcionalidade, e as palavras.
Foi gerado pelo `lab/traffic.py` a partir de formulações escritas pelo curso, então é um substituto
de uma fila de atendimento, não uma medição de uma. A aula 3 o reproduz através do assistente, e dali
em diante o curso tem uma semana de produção para examinar.

## O modelo, e por que ele não é um

```
ana@lab:~/obs$ curl -s http://127.0.0.1:8600/; echo
{"labobs": "ok", "models": ["extract-1", "extract-2", "judge-1"]}
```

**Nenhum modelo de linguagem estava ao alcance da máquina em que este curso foi gravado**, e uma
chave de API é uma conta que um curso não pode distribuir. Então o assistente conversa com o
`labobs`, na porta 8600, que fala a API Chat Completions da OpenAI de perto o bastante para que o SDK
`openai` de verdade converse com ele sem modificação. Ele serve três modelos, e nenhum deles é um
modelo de linguagem:

- **extract-1** é o modelo que o `rag` usou do começo ao fim: copia frases inteiras das fontes que
  recebe, aquelas cujos embeddings estão mais perto da pergunta, e as cita. As suas regras estão
  escritas no topo do `lab/labgen.py` do `rag`.
- **extract-2** é o mesmo com três números trocados, no papel de uma versão nova de um modelo. A aula
  14 é sobre trocar para ele.
- **judge-1** dá nota a uma resposta pela similaridade das suas frases com as fontes, a pergunta ou
  uma resposta esperada. As aulas 9 a 12 o usam.

O que o `labobs` acrescenta ao fornecedor do `rag` é **tempo**. Um fornecedor leva um momento antes
do primeiro token e depois um pouco mais para cada um que vem depois, e de vez em quando um pedido
espera bem mais que o normal. O `labobs` espera por regras escritas no topo do `lab/labobs.py`: 180 ms
mais um pouco por token de entrada antes do primeiro token, 25 ms para cada token depois dele, um
fator aleatório sorteado por pedido, e uma partida a frio rara de quatro segundos a mais. São números
do curso, não de nenhum fornecedor, e a aula 4 olha o que eles produzem.

Então toda resposta citada neste curso é do extract-1, todo veredito do judge-1, e todo tempo do
labobs. O que é real é tudo em volta deles: o SDK do OpenTelemetry, os spans, o banco de dados, as
ferramentas de rastreamento das aulas 6 e 7, os frameworks de avaliação da aula 12, e todo número que
eles calculam.

## Versões

```
ana@lab:~/obs$ cat releases.json
{
  "2026.09.4": {"from": "2026-09-01T00:00:00", "model": "extract-1", "k": 3, "floor": 0.5},
  "2026.10.1": {"from": "2026-10-02T10:00:00", "model": "extract-1", "k": 3, "floor": 0.62}
}
```

O assistente lê as suas configurações do `releases.json`: qual modelo, quantos trechos recuperar
(`k`) e a similaridade abaixo da qual um trecho não é mostrado ao modelo (`floor`, o piso que a aula
6 do `rag` escolheu). Cada versão diz a partir de quando vale. No dia 2 de outubro alguém subiu o piso
de 0,5 para 0,62, e essa ainda é a versão em vigor. Guarde isso; a aula 5 descobre o que ela fez.

## Uma pergunta

```
ana@lab:~/obs$ python assistant.py "How long is a gift card valid?"
A gift card is valid for two years from the day it was bought. [1] Gift cards are valid for two years from purchase and cannot be exchanged for cash. [2]
trace 8caa5cd5a78cdc79d1b3e420a1e2399f
```

Uma resposta, duas citações e um id de trace. A resposta está certa, e nada na tela diz quanto tempo
ela levou, quais documentos leu, ou quanto custou. As próximas seções põem isso em registro.
