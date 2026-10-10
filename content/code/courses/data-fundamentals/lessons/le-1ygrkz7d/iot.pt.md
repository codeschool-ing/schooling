---
title: IoT, ou sensores com relógio próprio
version: 1
---

**Um sensor é um computador pequeno com um relógio barato numa rede pouco confiável, e as leituras dele
chegam atrasadas, duas vezes, fora de ordem ou não chegam.** Cada doca da Roda Livre tem um. Uma vez por
minuto ele informa se está com uma bicicleta, e as leituras viajam pela rede celular até um servidor que
o fornecedor mantém. IoT, a internet das coisas, é o nome para fontes assim: muitos aparelhos pequenos,
cada um enviando pouco, com frequência, de lugares onde ninguém chega com pressa.

A imagem comum é uma tabela arrumada, uma linha por sensor por minuto. O que chega é essa tabela depois
de uma viagem ruim. Uma leitura pode se perder no caminho. Pode ficar presa na rede e ser ultrapassada
pela seguinte. Pode ser enviada duas vezes, porque o sensor não ouviu que a primeira chegou, que é a
mesma entrega pelo menos uma vez dos eventos do app. E ela leva o horário que o relógio do próprio
sensor marcava, que deriva se nada o corrigir.

Duas coisas em cada leitura tornam tudo isso contável. Um **número de sequência**, que o sensor aumenta
em um a cada leitura, transforma uma lacuna num número faltando e uma duplicata num número visto duas
vezes. E **dois horários**, o que o sensor carimbou e o de quando o servidor a recebeu, transformam um
relógio errado numa diferença que dá para medir.

## Uma hora de três docas

Este programa gera uma hora de leituras de três docas, a partir de uma semente fixa, do jeito que o
servidor do fornecedor as receberia, e depois conta o que deu errado:

```schooling-example
{"language": "python", "file": "sources/docks.py", "parts": [
{"code": "# sources/docks.py\nimport random\nfrom datetime import datetime, timedelta\n\n"},
{"code": "rng = random.Random(7)\nSTART = datetime(2025, 9, 15, 8, 0)\nCLOCK = {\"ST02-D01\": 0, \"ST02-D02\": 47, \"ST05-D01\": 0}   # seconds fast; one clock drifted\narrived = []\n", "note": "Uma semente fixa, para toda execução gerar a mesma hora. Três docas; o relógio da `ST02-D02` está 47 segundos adiantado."},
{"code": "for sensor, fast in CLOCK.items():\n    for seq in range(60):                                 # one reading a minute, for an hour\n        if rng.random() < 0.04:\n            continue                                      # lost before it was sent\n        taken = START + timedelta(minutes=seq)\n        stamped = taken + timedelta(seconds=fast)         # what the sensor writes on it\n        delay = 130 if rng.random() < 0.05 else rng.choice([1, 2, 3])   # a network hiccup\n        received = taken + timedelta(seconds=delay)\n        arrived.append((sensor, seq, stamped, received))\n        if rng.random() < 0.05:                           # no acknowledgement, so sent again\n            arrived.append((sensor, seq, stamped, received + timedelta(seconds=10)))\n", "note": "Sessenta leituras por doca. Algumas se perdem; cada uma recebe o horário que o sensor carimba nela e o horário em que o servidor a recebe, em geral de um a três segundos depois e às vezes 130. Algumas são enviadas duas vezes."},
{"code": "arrived.sort(key=lambda r: r[3])                          # the order the server saw them in\n\n", "note": "O servidor as vê na ordem em que chegaram, não na ordem em que foram feitas."},
{"code": "seen, highest, dupes, late, ahead = set(), {}, 0, 0, 0\nfor sensor, seq, stamped, received in arrived:\n    if (sensor, seq) in seen:\n        dupes += 1\n        continue\n    seen.add((sensor, seq))\n    if seq < highest.get(sensor, -1):\n        late += 1\n    highest[sensor] = max(seq, highest.get(sensor, -1))\n    if stamped > received:\n        ahead += 1\n\n", "note": "Uma passada, como um carregador faria: uma chave já vista é duplicata; um número de sequência abaixo do maior já visto daquele sensor chegou atrasado; um carimbo depois da chegada é um relógio adiantado."},
{"code": "print(len(arrived), \"readings arrived;\", len(CLOCK) * 60, \"were due\")\nprint(len(CLOCK) * 60 - len(seen), \"never arrived\")\nprint(dupes, \"arrived twice\")\nprint(late, \"arrived after a later reading from the same sensor\")\nprint(ahead, \"are stamped later than the moment they arrived\")\n", "note": "Tudo o que nunca chegou é a diferença entre o que era devido e as chaves distintas vistas."}
]}
```

```
ana@lab:~/roda/sources$ python docks.py
185 readings arrived; 180 were due
6 never arrived
11 arrived twice
6 arrived after a later reading from the same sensor
57 are stamped later than the moment they arrived
```

**Chegaram mais leituras do que eram devidas, e ainda faltam seis.** Essa linha sozinha é o motivo de
contar linhas não ser conferir uma fonte: 185 contra 180 parece tudo e mais um pouco. Tire as 11 que
vieram duas vezes e sobram 174, seis a menos que 180, e só os números de sequência dizem quais seis.

Seis chegaram depois de uma leitura que o mesmo sensor fez mais tarde, então um programa que guardasse
"a leitura mais recente" de cada doca às vezes guardaria uma mais antiga. E 57 leituras levam um horário
posterior ao momento em que chegaram ao servidor, o que nenhuma leitura honesta faz. Todas vêm da
`ST02-D02`, cujo relógio está 47 segundos adiantado. Num mapa isso é invisível. Numa pergunta sobre
quanto tempo a Rua XV ficou sem bicicleta, isso desloca cada período vazio de uma doca em quase um
minuto.

## O que o dono pode corrigir e o que fica com você

Parte disso cabe ao fornecedor corrigir, e vale pedir. Os aparelhos podem manter o relógio certo com
NTP, o protocolo que os computadores usam para acertar a hora por um servidor. Podem numerar as
leituras. Podem guardar as leituras que não conseguiram enviar e mandá-las depois, em vez de
descartá-las. Um protocolo comum para sensores, o MQTT, deixa um aparelho pedir entrega pelo menos uma
vez, que troca leituras perdidas por duplicatas.

O resto é permanente e fica com o lado dos dados. **Duplicatas são removidas pela chave**, aqui o sensor
e o número de sequência. **Lacunas são contadas, não preenchidas** inventando uma leitura. E **os dois
horários são guardados**, porque qual deles uma pergunta deve usar, e quanto esperar por uma leitura
atrasada antes de dar um minuto por encerrado, é o assunto da aula 8.
