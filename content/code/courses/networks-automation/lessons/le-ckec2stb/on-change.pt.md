---
title: Avisado quando muda
version: 1
---

A amostragem serve para um contador, que muda o tempo todo. Ela desperdiça mensagens com um valor
que muda duas vezes por ano, como se um link está no ar, e ainda pode perder uma mudança mais curta
que o seu intervalo. **Uma inscrição ON_CHANGE envia o valor atual uma vez e depois uma mensagem
por mudança**, quando quer que ela aconteça.

```schooling-example
{
  "language": "python",
  "file": "watch.py",
  "parts": [
    {
      "code": "from datetime import datetime\nfrom pathlib import Path\n\nfrom pygnmi.client import gNMIclient, telemetryParser\n"
    },
    {
      "code": "SUB = {\"mode\": \"stream\", \"encoding\": \"json\",\n       \"subscription\": [{\"path\": \"/interfaces/interface[name=eth2]/state/oper-status\",\n                         \"mode\": \"on_change\"}]}\npassword = Path(\"~/.netops-password\").expanduser().read_text().strip()\n\nwith gNMIclient(target=(\"edge2.example.net\", 9339), username=\"netops\",\n                password=password, path_root=\"lab-ca.pem\") as gc:\n    stream = gc.subscribe(subscribe=SUB)\n    seen = 0\n    for response in stream:\n        msg = telemetryParser(response)\n        if \"update\" not in msg:\n            continue",
      "note": "**ON_CHANGE em vez de SAMPLE.** O equipamento manda o valor atual uma vez e depois uma mensagem só quando o valor muda, seja qual for o tempo entre as mudanças."
    },
    {
      "code": "        for u in msg[\"update\"][\"update\"]:\n            when = datetime.fromtimestamp(msg[\"update\"][\"timestamp\"] / 1e9).strftime(\"%H:%M:%S.%f\")[:-3]\n            print(f\"{when}  edge2 eth2 is {u['val']}\")\n        seen += 1\n        if seen == 3:\n            stream.cancel()\n            break",
      "note": "**A hora impressa é a do equipamento**, convertida de nanossegundos desde 1970."
    }
  ]
}
```

O script roda num terminal, observando a `eth2` do `edge2`, o link para a LAN da filial 2. Em
outro, o link é desabilitado e habilitado de novo com `gnmic set`, com três segundos de intervalo:

```
ana@ctl:~$ gnmic -a edge2.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/enabled" --update-value false
{
  "source": "edge2.example.net:9339",
  "timestamp": 1790681209746217523,
  "time": "2026-09-29T08:26:49.746217523-03:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "interfaces/interface[name=eth2]/config/enabled"
    }
  ]
}
ana@ctl:~$ gnmic -a edge2.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/enabled" --update-value true
{
  "source": "edge2.example.net:9339",
  "timestamp": 1790681212858854839,
  "time": "2026-09-29T08:26:52.858854839-03:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "interfaces/interface[name=eth2]/config/enabled"
    }
  ]
}
```

E o que o primeiro terminal imprimiu enquanto isso:

```
ana@ctl:~$ python watch.py
08:26:47.747  edge2 eth2 is UP
08:26:49.771  edge2 eth2 is DOWN
08:26:53.270  edge2 eth2 is UP
```

Três mensagens em cerca de cinco segundos. A primeira é o valor de quando a inscrição começou; a
segunda chegou quando `enabled=false` derrubou a interface, e a terceira quando ela voltou. Os
horários são os do `edge2`. **Nada foi enviado no meio**, e nada teria sido enviado por um ano se
nada tivesse mudado.

Esse é o formato de um sistema de alertas construído sobre telemetria: uma inscrição ON_CHANGE no
oper-status de toda interface que importa, e um programa que abre um incidente no `DOWN`. A aula 7
constrói a metade do incidente, com webhooks e um service desk.

O target do laboratório percebe uma mudança olhando a interface duas vezes por segundo, e é por
isso que as mensagens chegam uma fração depois de cada `set`. Um equipamento faz isso a partir do
próprio evento. De um jeito ou de outro, o assinante não consegue distinguir, e nem precisa.
