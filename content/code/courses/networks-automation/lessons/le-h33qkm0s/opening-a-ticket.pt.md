---
title: Abrindo, e fechando, um chamado
version: 1
---

O que o receptor faz com um evento é trabalho comum de API, o mesmo da aula 2. A central de
atendimento tem uma API REST com token, e o `desk.py` reúne tudo o que o receptor precisa dela:

```schooling-example
{
  "language": "python",
  "file": "desk.py",
  "parts": [
    {
      "code": "from pathlib import Path\n\nimport requests\n\nDESK = \"https://tickets.example.net/api/tickets\"\nhttp = requests.Session()\nhttp.verify = \"lab-ca.pem\"\nhttp.headers[\"Authorization\"] = \"Token \" + Path(\"~/.desk-token\").expanduser().read_text().strip()\n\n\ndef request(method, url, **kwargs):\n    r = http.request(method, url, timeout=10, **kwargs)\n    r.raise_for_status()\n    return r.json()\n\n",
      "note": "**A API da central de chamados**, com o token de `~/.desk-token`. Um sistema de chamados é mais uma API REST, e os hábitos da aula 2 valem: uma sessão, um timeout, `raise_for_status`."
    },
    {
      "code": "def handle(event):\n    title = f\"{event['device']} {event['interface']} is down\"\n    found = request(\"GET\", DESK, params={\"status\": \"open\", \"q\": title})[\"results\"]\n    if event[\"event\"] == \"interface.down\":\n        if found:\n            t = request(\"POST\", f\"{DESK}/{found[0]['number']}/comments\",\n                        json={\"body\": f\"down again at {event['time']}\"})\n            return f\"{t['number']}: commented, down again\"\n        t = request(\"POST\", DESK, json={\"title\": title, \"priority\": \"high\", \"requester\": \"edge-monitor\",\n                                        \"body\": f\"{event['description'] or 'no description'}, down at {event['time']}\"})\n        return f\"{t['number']}: opened\"\n    if found:\n        number = found[0][\"number\"]\n        request(\"POST\", f\"{DESK}/{number}/comments\", json={\"body\": f\"up at {event['time']}\"})\n        t = request(\"PATCH\", f\"{DESK}/{number}\", json={\"status\": \"resolved\"})\n        return f\"{t['number']}: resolved\"\n    return \"up, and no open ticket to resolve\"",
      "note": "**Um chamado aberto por link, não um por evento.** Um link que oscila dez vezes numa hora é um incidente só, então o tratador procura um chamado aberto sobre o mesmo equipamento e interface antes de abrir outro."
    }
  ]
}
```

A regra que ele aplica é a que mais importa em automação orientada a eventos: **um incidente, um
chamado.** Um link que oscila dez vezes em uma hora não são dez problemas, e dez chamados são dez
notificações para uma pessoa que vai parar de lê-las na terceira. Então um evento `down` primeiro
procura um chamado aberto sobre o mesmo equipamento e interface, e acrescenta um comentário se
achar um; um evento `up` resolve o chamado que encontrar.

O link cai, com o receptor escutando:

```
ana@ctl:~$ python link.py edge1 eth2 down
edge1 eth2: down
```

```
ana@ctl:~$ python receiver.py 1
edge1-1790682864-3: interface.down edge1 eth2
   INC-1001: opened
```

E a central de chamados tem um chamado, aberto pela automação, com a descrição da interface
nele:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Token $(cat .desk-token)" "https://tickets.example.net/api/tickets?status=open"
{
  "count": 1,
  "results": [
    {
      "number": "INC-1001",
      "title": "edge1 eth2 is down",
      "body": "branch LAN, down at 2026-09-29T08:55:00-03:00",
      "priority": "high",
      "requester": "edge-monitor",
      "status": "open",
      "opened": "2026-09-29T08:55:00-03:00",
      "comments": []
    }
  ]
}
```

Quando o link voltou, na demonstração da seção anterior, o mesmo receptor comentou e o resolveu:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Token $(cat .desk-token)" https://tickets.example.net/api/tickets/INC-1001
{
  "number": "INC-1001",
  "title": "edge1 eth2 is down",
  "body": "branch LAN, down at 2026-09-29T08:55:00-03:00",
  "priority": "high",
  "requester": "edge-monitor",
  "status": "resolved",
  "opened": "2026-09-29T08:55:00-03:00",
  "comments": [
    {
      "time": "2026-09-29T08:55:02-03:00",
      "body": "up at 2026-09-29T08:55:02-03:00"
    }
  ]
}
```

**O chamado é o registro.** Ele guarda quando o link caiu, quando voltou, e quem o abriu,
`edge-monitor`, para que uma pessoa lendo depois consiga distinguir um chamado que a automação
abriu de um que um colega abriu. Esse também é o limite do que este receptor deve decidir sozinho.
Abrir um chamado e resolvê-lo quando a condição passa são coisas seguras de automatizar; **decidir
a causa, ou mudar a rede em resposta, é trabalho de uma pessoa** até a automação conquistar a
confiança para fazer isso, e os testes da aula 13 são parte disso.
