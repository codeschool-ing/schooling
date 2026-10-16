---
title: Replicação: cópias, e cópias que estão atrasadas
version: 1
---

**Uma réplica é uma cópia dos dados em outra máquina, mantida em dia recebendo cada mudança. Ela
protege contra perder uma máquina, e não protege contra um engano.** A imagem errada é a de que uma
réplica é um backup. Não é: um `DELETE` rodado por engano numa segunda-feira às dez chega a todas as
réplicas em instantes, com a mesma fidelidade de uma escrita correta. Um backup é uma cópia de antes,
guardada à parte, e esse é o assunto de `db-reliability`.

## Um líder e os seus seguidores

O arranjo mais comum dá a uma réplica a tarefa de aceitar as escritas. Essa réplica é o **líder** (o
nome mais antigo é primário). Ele aplica cada escrita, registra a escrita num log de mudanças e manda
o log para as outras réplicas, os **seguidores**, que o reaplicam na mesma ordem. As leituras podem
ir para qualquer uma delas. A aula 4 manda as leituras pesadas para um seguidor exatamente por isso:
uma cópia que responde aos analistas sem deixar o aplicativo lento é um seguidor, com o nome de
*réplica de leitura*.

A decisão que molda todo o resto é quando o líder diz ao cliente que uma escrita terminou.

- **De forma síncrona**, depois que pelo menos um seguidor confirmou que também tem a escrita. Uma
  escrita confirmada sobrevive à perda do líder. O custo é que toda escrita espera o seguidor, e um
  seguidor que para de responder para as escritas.
- **De forma assíncrona**, na hora, com os seguidores alcançando depois. As escritas são rápidas e um
  seguidor pode falhar sem ninguém perceber. O custo é que um seguidor está sempre um pouco atrasado,
  e se o líder morre, as escritas que ele ainda não tinha mandado se perdem.

Muitos sistemas ficam no meio: um seguidor síncrono e os demais assíncronos, para que toda escrita
confirmada exista em duas máquinas enquanto as outras não conseguem atrasar nada.

## Ler o que ainda não chegou

Quanto um seguidor está atrasado é o **atraso de replicação**. Em geral ele é pequeno, e cresce quando
o líder está ocupado ou a rede está lenta, que é justamente quando as pessoas estão lendo. O programa
abaixo simula um líder, um seguidor e um atraso de 800 ms, que é um número escolhido para a
demonstração e não medido em lugar nenhum. ana devolve a bicicleta no fim da viagem R000123, e o
aplicativo lê a viagem de volta. Salve como `replica.py`:

```schooling-example
{"language": "python", "file": "spread/replica.py", "parts": [
{"code": "# spread/replica.py\nLAG_MS = 800                    # how far behind the follower runs, in this simulation\n\n", "note": "O seguidor roda 800 ms atrás do líder. Esse número é uma escolha deste programa, não uma medida: o atraso de um seguidor de verdade muda com a carga."},
{"code": "leader = {\"R000123\": \"riding\"}\nfollower = dict(leader)\nlog = []                        # every write the leader made: (time in ms, key, value)\napplied = 0                     # how much of the log the follower has applied\n\n\n", "note": "Duas cópias dos mesmos dados, e o log de mudanças do líder. As duas começam com a viagem R000123 em andamento."},
{"code": "def write(t, key, value):\n    leader[key] = value\n    log.append((t, key, value))\n    print(f\"t={t:4} ms  write {key} = {value} on the leader\")\n\n\n", "note": "Uma escrita muda o líder na hora e entra no log. Nada chega ainda ao seguidor."},
{"code": "def read(t, key, where):\n    global applied\n    while applied < len(log) and log[applied][0] + LAG_MS <= t:\n        _, k, v = log[applied]\n        follower[k] = v         # the follower replays the leader's log, late\n        applied += 1\n    value = (leader if where == \"leader\" else follower)[key]\n    print(f\"t={t:4} ms  read  {key} from the {where:8} -> {value}\")\n\n\n", "note": "Antes de uma leitura, o seguidor reaplica toda entrada do log que tenha pelo menos 800 ms. Depois a leitura responde a partir da cópia para a qual foi mandada."},
{"code": "write(0, \"R000123\", \"docked\")\nread(50, \"R000123\", \"follower\")\nread(50, \"R000123\", \"leader\")\nread(900, \"R000123\", \"follower\")\n", "note": "A viagem termina em 0 ms. O aplicativo a lê de volta em 50 ms, uma vez de cada cópia, e mais uma vez do seguidor em 900 ms."}
]}
```

```
ana@lab:~/roda/spread$ python replica.py
t=   0 ms  write R000123 = docked on the leader
t=  50 ms  read  R000123 from the follower -> riding
t=  50 ms  read  R000123 from the leader   -> docked
t= 900 ms  read  R000123 from the follower -> docked
```

Cinquenta milissegundos depois da escrita, o líder diz `docked` e o seguidor ainda diz `riding`. Em
900 ms o seguidor alcançou e os dois concordam. Se o aplicativo mandou a leitura de ana para o
seguidor, ela devolveu a bicicleta e ouviu que a viagem ainda estava em andamento.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"Três linhas do tempo: o líder, o aplicativo e o seguidor. Em 0 ms o aplicativo escreve docked no líder. Em 50 ms ele lê do seguidor e recebe riding, o valor antigo. A mudança chega ao seguidor em 800 ms. Em 900 ms o aplicativo lê do seguidor de novo e recebe docked.\" data-fig=\"replication-lag\"><defs><marker id=\"replication-lag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">líder</text><line x1=\"150\" y1=\"50\" x2=\"700\" y2=\"50\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">o aplicativo</text><line x1=\"150\" y1=\"128\" x2=\"700\" y2=\"128\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><text x=\"20\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">seguidor</text><line x1=\"150\" y1=\"206\" x2=\"700\" y2=\"206\" stroke=\"var(--wire)\" stroke-width=\"2\"></line><line x1=\"170.0\" y1=\"122\" x2=\"170.0\" y2=\"57\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#replication-lag-ah)\"></line><text x=\"164.0\" y=\"90\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escreve</text><text x=\"176.0\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">docked</text><circle cx=\"170.0\" cy=\"50\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><line x1=\"174.0\" y1=\"54\" x2=\"570.0\" y2=\"200\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\" marker-end=\"url(#replication-lag-ah)\"></line><text x=\"450.0\" y=\"100\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">a mudança chega 800 ms depois</text><circle cx=\"570.0\" cy=\"206\" r=\"4\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><line x1=\"195.0\" y1=\"134\" x2=\"195.0\" y2=\"199\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#replication-lag-ah)\"></line><text x=\"203.0\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">lê</text><text x=\"203.0\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--amber)\">riding</text><text x=\"255.0\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">(o valor antigo)</text><line x1=\"620.0\" y1=\"134\" x2=\"620.0\" y2=\"199\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#replication-lag-ah)\"></line><text x=\"628.0\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">lê</text><text x=\"628.0\" y=\"226\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">docked</text><text x=\"170.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">0</text><text x=\"195.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">50</text><text x=\"570.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">800</text><text x=\"620.0\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">900</text><text x=\"700\" y=\"254\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ms</text></svg>", "caption": "O aplicativo escreve no líder e lê de um seguidor. Uma leitura que chega ao seguidor antes da mudança recebe o valor antigo."}
```

O remédio de costume tem nome, **ler as próprias escritas** (*read-your-writes*): o que uma pessoa
acabou de mudar é lido de volta do líder, por um tempo depois da mudança ou até o seguidor ter
reaplicado além dela. As leituras de todos os outros continuam indo para os seguidores. Isso não
deixa os seguidores em dia; garante que a única pessoa que sabe qual deveria ser a resposta não veja
a antiga. A aula 10 põe essa promessa ao lado das outras que um sistema pode fazer sobre o que uma
leitura devolve.

## Quando o líder cai

Se o líder para, um seguidor é promovido para ocupar o lugar dele, o que se chama **failover**. Com
replicação assíncrona, o seguidor promovido pode não ter as últimas escritas que o líder antigo
confirmou, e elas se perdem. Pior: um líder antigo que só ficou isolado, sem ter morrido, pode voltar
ainda achando que é o líder, e por um tempo duas máquinas aceitam escritas para os mesmos dados. Isso
se chama **split brain**, e é um dos assuntos da aula 10.

Existem outros dois arranjos, e você deve reconhecê-los: **vários líderes**, cada um aceitando
escritas e mandando-as para os outros, comum entre data centers distantes; e **nenhum líder**, que é
a próxima seção.
