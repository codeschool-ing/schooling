---
title: "Versionar eventos: fatos antigos, código novo"
version: 1
---

**Eventos são gravados uma vez e lidos durante anos, por um código que não para de mudar, então a
forma deles precisa evoluir sem reescrever o que está guardado.** A ferramenta de costume é um
*upcaster*: uma função que transforma um evento de uma versão antiga na atual no momento em que ele é
lido. A linha guardada fica como foi gravada; todo leitor acima do upcaster vê uma forma só.

A correção tentadora, e errada, é uma migração que reescreve os eventos antigos na forma nova, do
jeito que uma tabela ganha uma coluna. Ela quebra a única promessa que o store faz. O trigger da
seção do store a recusaria, e com razão: um histórico que foi editado não pode ser confiado como
histórico, e um bug na migração destrói o único registro que havia.

```schooling-example
{"language": "python", "file": "upcast.py", "parts": [
 {"code": "# upcast.py\nfrom collections import Counter\nfrom store import EventStore\n\nTITLE_OF = {\"C1\": \"Dom Casmurro\", \"C2\": \"Dom Casmurro\", \"C3\": \"Vidas Secas\"}  # in 2025", "note": "As cópias que a biblioteca tinha quando os primeiros eventos foram gravados. O upcaster precisa disso para preencher o que os eventos antigos deixaram de fora."},
 {"code": "\n\ndef lent_v1_to_v2(event: dict) -> dict:\n    return {**event, \"v\": 2, \"title\": TITLE_OF[event[\"copy\"]], \"days\": 14}", "note": "Um passo: um `CopyLent` da versão 1, que só nomeava o exemplar, vira um da versão 2, que nomeia também o título e o prazo. Os empréstimos antigos eram todos de livros, então 14 dias é um fato de 2025, não um palpite."},
 {"code": "\n\nUPCASTERS = {(\"CopyLent\", 1): lent_v1_to_v2}", "note": "Passos indexados por tipo e versão. Um evento sem `v` é da versão 1, que é como os primeiros eventos foram gravados, antes de alguém pensar em versões."},
 {"code": "\n\ndef upcast(event: dict) -> dict:\n    while (step := UPCASTERS.get((event[\"type\"], event.get(\"v\", 1)))) is not None:\n        event = step(event)\n    return event", "note": "Aplicar passos até nenhum servir, para um evento da versão 1 passar pela 2 até a 3 no dia em que existir uma terceira versão. Só a leitura muda; a linha guardada nunca é tocada."},
 {"code": "\n\nif __name__ == \"__main__\":\n    store = EventStore(\":memory:\")\n    store.append(\"member-bia\", 0, [{\"type\": \"CopyLent\", \"copy\": \"C1\"},\n                                   {\"type\": \"CopyLent\", \"copy\": \"C3\"}])\n    store.append(\"member-caio\", 0, [{\"type\": \"CopyLent\", \"v\": 2, \"copy\": \"F1\",\n                                     \"title\": \"Central do Brasil\", \"days\": 7}])\n    for position, raw in store.read_all():\n        print(position, \"stored: \", raw)\n        print(position, \"read as:\", upcast(raw))\n    events = [upcast(raw) for _, raw in store.read_all()]\n    print(Counter(e[\"title\"] for e in events if e[\"type\"] == \"CopyLent\").most_common())", "note": "Dois empréstimos antigos gravados do jeito da versão 1 e um novo, depois cada um impresso como foi guardado e como é lido, e uma contagem de empréstimos por título que funciona sobre os dois."}
]}
```

```
ana@laptop:~/patterns/events$ python3 upcast.py
1 stored:  {'type': 'CopyLent', 'stream': 'member-bia', 'copy': 'C1'}
1 read as: {'type': 'CopyLent', 'stream': 'member-bia', 'copy': 'C1', 'v': 2, 'title': 'Dom Casmurro', 'days': 14}
2 stored:  {'type': 'CopyLent', 'stream': 'member-bia', 'copy': 'C3'}
2 read as: {'type': 'CopyLent', 'stream': 'member-bia', 'copy': 'C3', 'v': 2, 'title': 'Vidas Secas', 'days': 14}
3 stored:  {'type': 'CopyLent', 'stream': 'member-caio', 'v': 2, 'copy': 'F1', 'title': 'Central do Brasil', 'days': 7}
3 read as: {'type': 'CopyLent', 'stream': 'member-caio', 'v': 2, 'copy': 'F1', 'title': 'Central do Brasil', 'days': 7}
[('Dom Casmurro', 1), ('Vidas Secas', 1), ('Central do Brasil', 1)]
```

As posições 1 e 2 foram guardadas do jeito antigo, com um exemplar e mais nada, e saem de `upcast`
com uma versão, um título e um empréstimo de 14 dias. A posição 3 foi gravada como versão 2 e passa
sem mudança. A contagem no fim trata os três igualmente: um empréstimo de cada, *Dom Casmurro*,
*Vidas Secas* e *Central do Brasil*, o que teria lançado `KeyError` em `"title"` sem o upcaster.

## Que mudança pede o quê

Nem toda mudança precisa de upcaster, e algumas mudanças nem são mudanças num evento.

| mudança | o que fazer |
|---|---|
| um campo novo de que os eventos antigos podem prescindir | dar a ele um valor padrão na leitura; sem versão nova |
| um campo novo que os eventos antigos precisam ter | uma versão nova e um upcaster que o deriva, como `title` aqui |
| um campo renomeado | uma versão nova e um upcaster que renomeia; jamais reaproveitar o nome antigo com outro sentido |
| um fato inteiramente diferente | um tipo de evento novo, como `LoanExtended`; o tipo antigo mantém o seu sentido |
| um campo cujo sentido muda, como uma multa agora em reais | nunca no lugar; um campo novo ou um tipo novo, porque os eventos antigos queriam dizer centavos |

A última linha é a que estraga em silêncio. Se `fine` virasse reais nos eventos novos sem aviso, toda
projeção que soma multas somaria centavos com reais, e nada lançaria erro. **O sentido de um evento
fica fixado quando ele é gravado**; só a forma pode ser adaptada na saída.

## O que o upcaster pode saber

`lent_v1_to_v2` lê `TITLE_OF`, os exemplares como eram em 2025. Essa tabela faz parte do código do
upcaster, congelada, e precisa continuar assim: se ela lesse o catálogo de hoje, um exemplar
reatribuído a outro título em 2027 reescreveria o histórico de todos os empréstimos dele. Upcasters,
como `evolve` e as projeções, precisam ser **determinísticos no evento**, dando a mesma saída para a
mesma linha guardada para sempre.

Quando um evento antigo de fato não tem um fato e nada congelado consegue fornecê-lo, diga isso na
forma nova: um `title` igual a `None` que todo leitor trata é honesto; um título adivinhado é um
registro fabricado.

## Na sua linguagem

Toda pilha com event sourcing tem o mesmo gancho com outro nome. O Axon Framework, em Java, tem
*upcasters* com esse nome, encadeados por tipo e revisão. Os clientes do EventStoreDB e o Marten, no
.NET, transformam eventos na leitura. Em TypeScript e Go o upcaster costuma ser uma função simples na
etapa de desserialização, como aqui, muitas vezes decidindo por um campo `version` que os primeiros
eventos esqueceram, e é por isso que `event.get("v", 1)` trata uma versão ausente como 1. **Ponha a
versão no primeiro evento que você gravar**, mesmo que seja 1 e nada a leia ainda.
