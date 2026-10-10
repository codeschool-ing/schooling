---
title: O log, em vinte e cinco linhas de Python
version: 1
---

**Um log é uma sequência de registros que só cresce por uma ponta.** Cada registro recebe um
número, o seu **offset**, que é a sua posição contando a partir de zero, e fica com ele enquanto
existir. Ninguém insere no meio, ninguém edita, e ler um registro não o remove. Essa é a estrutura
de dados inteira, e é sobre ela que o Kafka é construído.

A palavra engana em duas direções. Para um programador, *log* é o texto que um servidor escreve
sobre si mesmo, o `server.log`, em que alguém dá grep quando algo dá errado. Para muita gente que já
usou brokers de mensagens, um stream é uma **fila**: a mensagem é entregue a um leitor e some. O log
desta lição não é nenhum dos dois. Ele é o próprio dado, guardado em ordem, e qualquer número de
leitores pode percorrê-lo, cada um no seu lugar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um log de oito registros, offsets 0 a 7, desenhado da esquerda para a direita. Registros novos são anexados na ponta direita. Três leitores apontam para lugares diferentes: o warehouse no offset 0, o programa de fidelidade no offset 3 e o sistema de estoque no offset 8, o próximo registro, que ainda não existe. Ler move só o ponteiro do próprio leitor.\" data-fig=\"l2-log-readers\"><defs><marker id=\"l2-log-readers-ah-83\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l2-log-readers-ah-726\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker></defs><rect x=\"60\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"88.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">0</text><rect x=\"122\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"150.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><rect x=\"184\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"212.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><rect x=\"246\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"274.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><rect x=\"308\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"336.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><rect x=\"370\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"398.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">5</text><rect x=\"432\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"460.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">6</text><rect x=\"494\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"522.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">7</text><rect x=\"556\" y=\"70\" width=\"56\" height=\"40\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"584.0\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\">8</text><text x=\"586.0\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o próximo append entra aqui</text><line x1=\"584\" y1=\"52\" x2=\"584\" y2=\"66\" stroke=\"var(--amber)\" stroke-width=\"1.2\" marker-end=\"url(#l2-log-readers-ah-83)\"></line><text x=\"30\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offset</text><text x=\"88\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mais antigo</text><text x=\"522\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mais novo</text><line x1=\"88\" y1=\"175\" x2=\"88\" y2=\"116\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l2-log-readers-ah-726)\"></line><text x=\"88\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">warehouse</text><text x=\"88\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">lê uma vez por noite</text><line x1=\"274\" y1=\"175\" x2=\"274\" y2=\"116\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l2-log-readers-ah-726)\"></line><text x=\"274\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">fidelidade</text><text x=\"274\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma hora atrás</text><line x1=\"584\" y1=\"175\" x2=\"584\" y2=\"116\" stroke=\"var(--paper)\" stroke-width=\"1.2\" marker-end=\"url(#l2-log-readers-ah-726)\"></line><text x=\"584\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">estoque</text><text x=\"584\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">já leu tudo</text></svg>", "caption": "Um log, três leitores, três lugares. O log não sabe onde nenhum deles está.", "same": ["offset", "warehouse"]}
```

## Um log que se lê de uma sentada

O log do Kafka é espalhado por máquinas e discos, com índices e réplicas, que as lições 3 e 5 abrem.
A ideia cabe num arquivo. Salve isto como `~/work/minilog.py`:

```schooling-example
{
  "language": "python",
  "file": "minilog.py",
  "parts": [
    {
      "code": "\"\"\"minilog.py: an append-only log in one file, and readers that keep their own place.\n\n    python minilog.py append LOG MESSAGE   add MESSAGE at the end and print its offset\n    python minilog.py read LOG READER      print what READER has not read yet\n\"\"\"\nimport os\nimport sys\n",
      "note": "O que ele faz. Um registro é uma linha de texto, e **o offset dele é o número da linha**, contando a partir de zero."
    },
    {
      "code": "\ndef append(log, message):\n    with open(log, \"a\", encoding=\"utf-8\") as f:\n        f.write(message + \"\\n\")\n    with open(log, encoding=\"utf-8\") as f:\n        return sum(1 for _ in f) - 1\n",
      "note": "Anexar abre o arquivo no modo `\"a\"`, que **só consegue escrever no fim**: o sistema operacional não deixa esta função inserir nem sobrescrever. Depois ela conta as linhas para saber o offset do registro novo."
    },
    {
      "code": "\ndef read(log, start):\n    with open(log, encoding=\"utf-8\") as f:\n        for offset, line in enumerate(f):\n            if offset >= start:\n                yield offset, line.rstrip(\"\\n\")\n",
      "note": "Ler começa num offset e vai até o fim. Não muda nada no arquivo, então dois leitores não conseguem atrapalhar um ao outro."
    },
    {
      "code": "\nif __name__ == \"__main__\":\n    command, log = sys.argv[1], sys.argv[2]\n    if command == \"append\":\n        print(append(log, sys.argv[3]))",
      "note": "A linha de comando. `append` acrescenta um registro."
    },
    {
      "code": "    elif command == \"read\":\n        place = f\"{log}.{sys.argv[3]}\"\n        start = int(open(place).read()) if os.path.exists(place) else 0\n        for offset, message in read(log, start):\n            print(offset, message)\n            start = offset + 1\n        with open(place, \"w\") as f:\n            f.write(f\"{start}\\n\")",
      "note": "`read` é onde entram os leitores. **O lugar de cada leitor é um arquivo próprio** ao lado do log, com o offset do próximo registro que ele ainda não viu. O log nunca fica sabendo quem leu o quê."
    }
  ]
}
```

Anexe três vendas. Cada `append` imprime o offset que o registro recebeu:

```
ubuntu@stream:~/work$ python minilog.py append demo.log '{"sale": "rec-000001", "qty": 1}'
0
ubuntu@stream:~/work$ python minilog.py append demo.log '{"sale": "oli-000002", "qty": 2}'
1
ubuntu@stream:~/work$ python minilog.py append demo.log '{"sale": "rec-000003", "qty": 1}'
2
```

Agora leia como o sistema de estoque, duas vezes:

```
ubuntu@stream:~/work$ python minilog.py read demo.log stock
0 {"sale": "rec-000001", "qty": 1}
1 {"sale": "oli-000002", "qty": 2}
2 {"sale": "rec-000003", "qty": 1}
ubuntu@stream:~/work$ python minilog.py read demo.log stock
```

A segunda leitura não imprime nada, porque o leitor do estoque já viu tudo o que existe. **Não é
porque os registros sumiram.** Acrescente uma quarta venda, e leia como o sistema de estoque e
depois como um programa de fidelidade que nunca leu nada:

```
ubuntu@stream:~/work$ python minilog.py append demo.log '{"sale": "nat-000004", "qty": 1}'
3
ubuntu@stream:~/work$ python minilog.py read demo.log stock
3 {"sale": "nat-000004", "qty": 1}
ubuntu@stream:~/work$ python minilog.py read demo.log loyalty
0 {"sale": "rec-000001", "qty": 1}
1 {"sale": "oli-000002", "qty": 2}
2 {"sale": "rec-000003", "qty": 1}
3 {"sale": "nat-000004", "qty": 1}
```

O leitor do estoque recebeu só o registro novo; o de fidelidade recebeu os quatro, desde o offset 0.
Os dois leram o mesmo arquivo, e nenhum sabia que o outro existia. Os lugares deles são dois
arquivinhos ao lado do log:

```
ubuntu@stream:~/work$ ls demo.log*
demo.log
demo.log.loyalty
demo.log.stock
ubuntu@stream:~/work$ head demo.log.*
==> demo.log.loyalty <==
4

==> demo.log.stock <==
4
```

Cada um guarda o offset do próximo registro que aquele leitor vai pedir. Os dois dizem 4, porque os
dois já leram até o fim, e o último registro do log é o offset 3.

## O que o Kafka acrescenta à mesma ideia

Tudo o que está acima existe no Kafka, com outros nomes: um log é uma **partição**, o lugar de um
leitor é um **offset commitado**, e o leitor é um **consumer group**. O que o `minilog.py` faz mal é
justamente o que o Kafka foi construído para fazer bem, e cada falha é uma lição mais adiante:

| o que o minilog.py faz | o que dá errado | onde o Kafka responde |
|---|---|---|
| conta todas as linhas para achar um offset | ler a partir do offset 1 000 000 lê um milhão de linhas antes | um índice ao lado de cada arquivo, lição 3 |
| guarda todo registro para sempre | o disco enche | retenção e compactação, lição 3 |
| um arquivo num disco | o disco morre e o log junto | réplicas em outras máquinas, lição 5 |
| grava o lugar do leitor depois de imprimir | uma queda no meio imprime alguns registros duas vezes | commit de offsets, lições 4 e 7 |

Vale olhar a última linha de novo antes que a lição 7 faça dela o assunto. Se o programa caísse
depois de imprimir o registro 3 e antes de gravar o arquivo de lugar, a próxima execução começaria
do lugar antigo e imprimiria o registro 3 de novo. **Onde um leitor anota o seu lugar, em relação a
quando faz o trabalho, decide o que uma queda custa**, e nenhum log pode decidir isso pelo leitor.
