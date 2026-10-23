---
title: Um honeypot de baixa interação
version: 1
---

**Um honeypot de baixa interação responde o suficiente para notar um visitante e mais nada.** Ele não
finge ser um servidor completo com logins e arquivos, o que dá trabalho de construir e dá a um
visitante algo para atacar. Ele escuta, anota quem veio e fecha a porta. No `trap`, uma máquina que
ninguém no escritório usa, salve isto como `bait.py` no seu home:

```schooling-example
{"language": "python", "file": "bait.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"bait.py: listen on ports nobody in the firm uses, and record whoever connects.\"\"\"\nimport json, socket, selectors, syslog, time\n\nPORTS = [23, 445, 1433, 3389]\nLOG = \"/var/log/bait.jsonl\"", "note": "Quatro portas que pedem para ser tentadas: telnet, compartilhamento de arquivos do Windows, um banco SQL Server e área de trabalho remota. A Jatobá não roda nenhuma delas em lugar nenhum, e esse é o ponto. Uma conexão a qualquer uma delas no `trap` não tem explicação inocente no trabalho normal deste escritório."}, {"code": "sel = selectors.DefaultSelector()\nfor port in PORTS:\n    s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)\n    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)\n    s.bind((\"0.0.0.0\", port))\n    s.listen()\n    sel.register(s, selectors.EVENT_READ, port)\nsyslog.openlog(\"bait\")", "note": "Um socket por porta, todos vigiados por um único laço. Nada por trás deles responde como um serviço de verdade: este é um honeypot de **baixa interação**, que registra um toque e não oferece nada com que trabalhar, e por isso não tem quase nada dentro que possa ele mesmo ser atacado."}, {"code": "with open(LOG, \"a\", buffering=1) as log:\n    while True:\n        for key, _ in sel.select():\n            conn, (addr, sport) = key.fileobj.accept()\n            event = {\"time\": time.strftime(\"%Y-%m-%dT%H:%M:%S%z\"), \"from\": addr, \"port\": key.data}\n            conn.close()\n            log.write(json.dumps(event) + \"\\n\")\n            syslog.syslog(syslog.LOG_WARNING, f\"touched: {addr} on port {key.data}\")", "note": "Cada conexão é aceita, fechada na hora e anotada duas vezes: uma linha JSON para quem estudar os toques depois, e um aviso no log do sistema, que é de onde um alerta seria gerado. O endereço que conectou é o achado."}]}
```

Inicie-o como um serviço. Portas abaixo de 1024 exigem root para escutar, o que o `systemd-run` com
`sudo` fornece:

```
ana@trap:~$ sudo systemd-run -q --unit bait python3 /home/ana/bait.py
ana@trap:~$ sleep 1; sudo ss -Htlnp | grep python3 | awk '{print $4}'
0.0.0.0:1433
0.0.0.0:23
0.0.0.0:445
0.0.0.0:3389
```

Quatro portas estão abertas no `trap` que a Jatobá nunca usa. Nada mais mudou: nenhuma regra de
firewall, nenhum produto, e o código do próprio honeypot é curto o bastante para ter sido lido inteiro
antes de rodar, que é o padrão certo para qualquer coisa rodando como root numa máquina feita para ser
tocada.

## A isca precisa parecer alguma coisa

As portas foram escolhidas porque são o que alguém explorando uma rede tenta primeiro: área de
trabalho remota, compartilhamento de arquivos, um banco de dados, um login remoto antigo. Um honeypot
escutando numa porta que ninguém tentaria não pega ninguém. **A melhor isca é o que o escritório
plausivelmente teria**, e num escritório de contadores um banco de dados e compartilhamentos do Windows
são exatamente isso.

O `trap` também tem um nome, e o nome importa tanto quanto as portas. No uso real ele se chamaria algo
que vale uma olhada, `fs-backup` ou `sql-legacy`, nunca `trap` ou `honeypot`. Este laboratório o chama
de `trap` para você sempre saber qual máquina é a isca.
