---
title: Um stream amostrado
version: 1
---

`Subscribe` com `--stream-mode sample` pede ao equipamento que envie um valor a cada intervalo,
**sem que peçam de novo**. O `timeout 5` para o `gnmic` depois de cinco segundos, porque um stream
não termina sozinho:

```
ana@ctl:~$ timeout 5 gnmic -a edge1.example.net:9339 subscribe --path "/interfaces/interface[name=eth1]/state/counters/in-octets" --stream-mode sample --sample-interval 2s
{
  "source": "edge1.example.net:9339",
  "subscription-name": "default-1790681185",
  "timestamp": 1790681185638940350,
  "time": "2026-09-29T08:26:25.63894035-03:00",
  "updates": [
    {
      "Path": "interfaces/interface[name=eth1]/state/counters/in-octets",
      "values": {
        "interfaces/interface/state/counters/in-octets": 1858
      }
    }
  ]
}
{
  "sync-response": true
}
{
  "source": "edge1.example.net:9339",
  "subscription-name": "default-1790681185",
  "timestamp": 1790681187663415268,
  "time": "2026-09-29T08:26:27.663415268-03:00",
  "updates": [
    {
      "Path": "interfaces/interface[name=eth1]/state/counters/in-octets",
      "values": {
        "interfaces/interface/state/counters/in-octets": 1858
      }
    }
  ]
}
{
  "source": "edge1.example.net:9339",
  "subscription-name": "default-1790681185",
  "timestamp": 1790681189664768514,
  "time": "2026-09-29T08:26:29.664768514-03:00",
  "updates": [
    {
      "Path": "interfaces/interface[name=eth1]/state/counters/in-octets",
      "values": {
        "interfaces/interface/state/counters/in-octets": 1858
      }
    }
  ]
}

received signal 'terminated'. terminating...
```

A primeira mensagem é o valor de quando a inscrição começou, e depois vem o **`sync-response`**.
Esse marcador quer dizer "agora você tem tudo o que existia quando se inscreveu; o que vem a seguir
é novo". Um coletor que carrega uma tabela do estado atual espera por ele antes de desenhar
qualquer coisa. Depois dele, uma mensagem a cada dois segundos, cada uma com o timestamp do
equipamento.

O contador não se mexeu nesses cinco segundos: nada estava atravessando a `eth1` além de um ou
outro pacote OSPF. **Um contador é o número de bytes desde que a interface subiu, não uma taxa.**
Para obter uma taxa, subtraia duas amostras e divida pelo tempo entre elas, usando os timestamps do
equipamento e não a hora em que a mensagem chegou, que inclui o atraso da rede.

```schooling-example
{
  "language": "python",
  "file": "rate.py",
  "parts": [
    {
      "code": "from pathlib import Path\n\nfrom pygnmi.client import gNMIclient, telemetryParser\n\nPATH = \"/interfaces/interface[name=eth1]/state/counters\"\nSUB = {\"mode\": \"stream\", \"encoding\": \"json\",\n       \"subscription\": [{\"path\": PATH, \"mode\": \"sample\", \"sample_interval\": 2_000_000_000}]}\npassword = Path(\"~/.netops-password\").expanduser().read_text().strip()\n\nwith gNMIclient(target=(\"edge1.example.net\", 9339), username=\"netops\",\n                password=password, path_root=\"lab-ca.pem\") as gc:\n    stream = gc.subscribe(subscribe=SUB)\n    last = None",
      "note": "**A mesma assinatura que o `gnmic` fez, a partir do Python.** `sample_interval` está em nanossegundos, como todo tempo no gNMI: dois segundos são 2.000.000.000."
    },
    {
      "code": "    for n, response in enumerate(stream):\n        msg = telemetryParser(response)\n        if \"update\" not in msg:\n            continue\n        values = {u[\"path\"].rsplit(\"/\", 1)[1]: u[\"val\"] for u in msg[\"update\"][\"update\"]}\n        now = (msg[\"update\"][\"timestamp\"], values[\"in-octets\"], values[\"out-octets\"])\n        if last:\n            seconds = (now[0] - last[0]) / 1e9\n            rx = (now[1] - last[1]) * 8 / seconds / 1000\n            tx = (now[2] - last[2]) * 8 / seconds / 1000\n            print(f\"{seconds:5.2f} s   in {rx:7.1f} kbit/s   out {tx:7.1f} kbit/s\")\n        last = now",
      "note": "**Cada amostra é um contador, e um contador só cresce.** O que uma pessoa quer é uma taxa: a diferença entre duas amostras dividida pelo tempo entre elas, tirado dos timestamps do próprio equipamento e não de quando a mensagem chegou."
    },
    {
      "code": "        if n == 6:\n            stream.cancel()\n            break",
      "note": "**Um stream não termina sozinho**, então o script o cancela depois de seis mensagens."
    }
  ]
}
```

Para dar ao contador algo para contar, o `pc1` faz ping no `pc2` num segundo terminal, 20 pacotes
por segundo de 1.228 bytes cada. Todo pacote atravessa a `eth1` do `edge1` na ida e a resposta
dele a atravessa na volta:

```
ana@ctl:~$ python rate.py
 2.02 s   in   176.8 kbit/s   out   176.8 kbit/s
 2.00 s   in   179.2 kbit/s   out   179.2 kbit/s
 2.00 s   in   174.0 kbit/s   out   174.0 kbit/s
 2.00 s   in   178.8 kbit/s   out   178.8 kbit/s
 2.00 s   in   173.9 kbit/s   out   173.9 kbit/s
```

```
ana@pc1:~$ ping -q -i 0.05 -s 1200 -c 300 203.0.113.74
PING 203.0.113.74 (203.0.113.74) 1200(1228) bytes of data.

--- 203.0.113.74 ping statistics ---
300 packets transmitted, 300 received, 0% packet loss, time 16892ms
rtt min/avg/max/mdev = 0.033/0.067/6.536/0.374 ms
```

Cerca de 175 kbit/s em cada sentido, e o mesmo nos dois sentidos porque todo echo tem a sua
resposta. Os intervalos são de dois segundos, com diferença de poucos centésimos, **medidos pelo
relógio do `edge1`**.

O número pode ser conferido. Vinte pacotes por segundo de 1.228 bytes, mais 14 bytes de cabeçalho
Ethernet que a interface também conta, dariam cerca de 199 kbit/s. O resumo do ping explica a
diferença: 300 pacotes levaram 16,9 segundos, não 15, porque o `ping` espera o seu intervalo depois
de cada pacote em vez de manter um relógio rigoroso. Na taxa em que ele realmente enviou, 17,8
pacotes por segundo, a mesma conta dá 177 kbit/s, **que é o que os contadores mediram**.
