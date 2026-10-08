---
title: Cortando documentos em trechos
version: 2
---

A recuperação devolve trechos, não documentos, e o tamanho de um trecho é a primeira decisão.
Grande demais, e um trecho sobre devoluções traz três parágrafos sobre reembolso junto, enchendo o
prompt com texto que não responde à pergunta. Pequeno demais, e uma frase chega sem a frase anterior
que dizia o que era "isso". **Um trecho deve ser o menor pedaço que faz sentido sozinho.**

## Um parágrafo, com o título

O manual é escrito em parágrafos curtos, cada um sobre uma coisa, então um parágrafo é um trecho
natural. Cada um leva o título do documento, para um parágrafo que diz "depois de 30 dias" ainda
dizer do que trata quando chega sozinho. Cada um ganha um id feito do arquivo e da posição do
parágrafo, que é o que uma resposta vai citar:

```python
def chunks(folder="docs/handbook"):
    """One chunk per paragraph, carrying its document's title, with an id that says where it is."""
    out = []
    for path in sorted(Path(folder).glob("*.md")):
        title, *paragraphs = path.read_text().split("\n\n")
        for n, p in enumerate(paragraphs, 1):
            out.append({"id": f"{path.name}#{n}", "text": title.lstrip("# ") + ". " + " ".join(p.split())})
    return out
```

```
ana@dev:~/shop$ PYTHONPATH=scratch python -c 'import rag; cs = rag.chunks(); n = [len(rag.ENC.encode(c["text"])) for c in cs]; print(len(cs), "chunks, from", min(n), "to", max(n), "tokens"); [print(c["id"], "|", c["text"][:70]) for c in cs[:4]]'
26 chunks, from 23 to 56 tokens
account.md#1 | Accounts and passwords. A customer can check out without an account, b
account.md#2 | Accounts and passwords. To reset a password, the customer chooses "For
account.md#3 | Accounts and passwords. To close an account, the customer writes to su
contact.md#1 | Contacting support. Support answers by email and chat from 9:00 to 18:
```

Vinte e seis trechos, de 23 a 56 tokens cada. O `account.md#2` é o segundo parágrafo do
`account.md`, e começa com `Accounts and passwords.`, o título de onde foi cortado.

## Escolhas que mudam os resultados

- **Tamanho.** Parágrafos servem para este manual. Documentos longos com seções longas costumam ser
  cortados num número fixo de tokens, algumas centenas, com uma **sobreposição** entre vizinhos para
  uma frase na fronteira estar nos dois.
- **Estrutura primeiro.** Corte em títulos e parágrafos antes de cortar por contagem de tokens. Um
  corte no meio de uma tabela ou de uma lista produz dois trechos que não fazem sentido.
- **Contexto em todo trecho.** O título aqui; num documento mais longo, a cadeia de títulos acima do
  parágrafo. Custa alguns tokens por trecho e evita um trecho que ninguém entende.
- **Ids que sobrevivem a edições.** Uma posição é um id fraco: insira um parágrafo e todo id depois
  dele se move, então uma citação guardada na semana passada aponta hoje para outro parágrafo.
  Sistemas reais dão ao trecho um id que não depende da posição, ou guardam o texto para o qual a
  citação apontava.

Os ids aqui são posições porque o manual não muda durante a aula. O último ponto é o primeiro a
corrigir quando ele mudar.
