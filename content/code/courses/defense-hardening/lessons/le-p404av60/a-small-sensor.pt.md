---
title: Um sensor em menos de quarenta linhas
version: 1
---

**Um sensor é um programa que vigia uma máquina e anota o que vê, num formato que uma máquina
consegue ler de volta.** Sensores comerciais são grandes porque vigiam tudo, resistem a tentativas
de pará-los e mandam os registros para um lugar seguro. O núcleo é pequeno o bastante para ser lido
de uma vez, e lê-lo é o caminho mais rápido para entender o que os grandes fazem e onde podem errar.

Este vigia processos. Salve-o no `web` como `/usr/local/sbin/sensor.py`; é preciso `sudo` para
gravar ali, e de propósito, porque um sensor que qualquer conta pode editar registra o que essa
conta quiser:

```sh
sudo nano /usr/local/sbin/sensor.py
```

```schooling-example
{"language": "python", "file": "sensor.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"sensor.py: every new process on this machine, as one line of JSON, with its parents.\"\"\"\nimport json, os, pwd, socket, time\n\nOUT = \"/var/log/sensor.jsonl\"\nHOST = socket.gethostname()", "note": "O sensor grava um objeto JSON por linha em `/var/log/sensor.jsonl`. Um objeto por linha é o que coletores de log e o `jq` leem sem interpretar o arquivo inteiro, e é o formato que a telemetria bruta de todo EDR tem a caminho de um console."}, {"code": "def info(pid):\n    try:\n        with open(f\"/proc/{pid}/stat\") as f:\n            ppid = int(f.read().rsplit(\")\", 1)[1].split()[1])\n        with open(f\"/proc/{pid}/cmdline\", \"rb\") as f:\n            cmd = f.read().replace(b\"\\0\", b\" \").decode(errors=\"replace\").strip()\n        uid = os.stat(f\"/proc/{pid}\").st_uid\n        exe = os.readlink(f\"/proc/{pid}/exe\")\n    except OSError:\n        return None  # it ended between two reads, or is a kernel thread with no program\n    return {\"pid\": pid, \"ppid\": ppid, \"user\": pwd.getpwuid(uid).pw_name, \"exe\": exe, \"cmd\": cmd}", "note": "Tudo o que o kernel sabe sobre um processo é um diretório em `/proc`. `stat` traz o id do pai depois do nome entre parênteses, `cmdline` os argumentos separados por bytes zero, e `exe` é um link para o próprio arquivo do programa. Um processo pode terminar entre duas dessas leituras, e aí a função desiste dele em vez de chutar."}, {"code": "def parents(pid):\n    chain = []\n    while pid > 1 and len(chain) < 6:\n        p = info(pid)\n        if p is None:\n            break\n        chain.append(os.path.basename(p[\"exe\"]))\n        pid = p[\"ppid\"]\n    return chain", "note": "A cadeia de pais é o campo que faz disto telemetria e não uma lista de processos. `bash` sozinho não quer dizer nada; `bash` cujo pai é a conta do servidor web é a primeira pergunta de um analista. Seis níveis bastam para chegar a um serviço ou a um login."}, {"code": "seen = {int(p) for p in os.listdir(\"/proc\") if p.isdigit()}\nwith open(OUT, \"a\", buffering=1) as log:\n    while True:\n        now = {int(p) for p in os.listdir(\"/proc\") if p.isdigit()}\n        for pid in sorted(now - seen):\n            p = info(pid)\n            if p is not None:\n                p[\"parents\"] = parents(p[\"ppid\"])\n                p[\"time\"] = time.strftime(\"%Y-%m-%dT%H:%M:%S%z\")\n                p[\"host\"] = HOST\n                log.write(json.dumps(p) + \"\\n\")\n        seen = now\n        time.sleep(0.2)", "note": "O laço compara a lista de ids de processo cinco vezes por segundo com a lista anterior. Cada id novo ganha uma linha. **Esse é o método inteiro do sensor, e a fraqueza dele**: um processo que começa e termina entre duas olhadas nunca é visto."}]}
```

Confira o que você colou e depois inicie-o como um serviço próprio. O `systemd-run` transforma um
comando numa unidade temporária, que lhe dá um nome, não reinicia nada e para quando você manda:

```
ana@web:~$ sha256sum /usr/local/sbin/sensor.py
95d23b1ebe37822ea1714107ad42d9712acd63ea89e6c8698fdd4bd039422653  /usr/local/sbin/sensor.py
ana@web:~$ sudo systemd-run --unit sensor /usr/bin/python3 /usr/local/sbin/sensor.py
Running as unit: sensor.service; invocation ID: 1615c2408e18470980b66f65808a4224
ana@web:~$ sleep 1; grep "\"sleep 1\"" /var/log/sensor.jsonl | jq .
{
  "pid": 154,
  "ppid": 152,
  "user": "ana",
  "exe": "/usr/bin/sleep",
  "cmd": "sleep 1",
  "parents": [
    "bash",
    "su"
  ],
  "time": "2026-10-23T02:02:03-0300",
  "host": "web"
}
```

O `sleep 1` digitado na mesma linha de comando foi pego, e o JSON diz tudo o que a seção anterior
pediu: o arquivo do programa, os argumentos, ana como conta e, acima dele, `bash` e `su`, o shell e o
login de onde veio. Todo processo iniciado no `web` a partir de agora ganha uma linha assim.

## O que ele deixa passar

Um sensor que olha cinco vezes por segundo deixa passar o que vive menos de um quinto de segundo.
Isso não é palpite; dá para medir:

```
ana@web:~$ for i in $(seq 20); do /bin/true; done; sleep 1; grep -c "\"/usr/bin/true\"" /var/log/sensor.jsonl
0
ana@web:~$ sleep 0.5; sleep 1; grep -c "\"sleep 0.5\"" /var/log/sensor.jsonl
1
```

Vinte execuções de `/bin/true`, cada uma terminada em um ou dois milissegundos, e **nenhuma**
chegou ao arquivo. Um `sleep` de meio segundo foi visto. Qualquer coisa que um invasor faça num único
comando rápido, um download que termina logo, um arquivo copiado, uma configuração mudada, passa
entre duas olhadas. Olhar mais rápido custa processador e só estreita a fresta, nunca a fecha.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" data-fig=\"l08-gap\" aria-label=\"Uma linha do tempo de um segundo com o sensor olhando a cada quinto de segundo, cinco olhadas desenhadas como marcas. Um processo que vive dois milissegundos começa e termina entre duas marcas e nunca é visto. Um processo que vive meio segundo cobre duas ou três marcas e é registrado na primeira.\"><path d=\"M60.0 150.0 L660.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60.0 140.0 L60.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"60.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.0 s</text><path d=\"M180.0 140.0 L180.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"180.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.2 s</text><path d=\"M300.0 140.0 L300.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"300.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.4 s</text><path d=\"M420.0 140.0 L420.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"420.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.6 s</text><path d=\"M540.0 140.0 L540.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"540.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.8 s</text><path d=\"M660.0 140.0 L660.0 160.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"660.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.0 s</text><text x=\"360.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">o sensor olha o /proc em cada marca</text><rect x=\"170.0\" y=\"92.0\" width=\"6.0\" height=\"20.0\" rx=\"1\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"173.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">/bin/true, 2 ms: nunca visto</text><rect x=\"330.0\" y=\"92.0\" width=\"300.0\" height=\"20.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"480.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sleep 0.5: visto em 0,6 s</text><text x=\"360.0\" y=\"28.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">olhando cinco vezes por segundo</text></svg>", "caption": "O que começa e termina entre duas olhadas não deixa rastro no arquivo."}
```

A mesma fraqueza esconde mais uma. Quando um processo termina, os filhos dele são adotados pelo
processo 1, então um sensor que lê os pais **depois do fato** encontra uma cadeia já quebrada. A
próxima seção dá de cara exatamente com isso.

Um produto fecha as duas frestas do mesmo jeito, sendo avisado em vez de olhar: o kernel chama o
sensor no instante em que um programa começa, antes de ele executar uma única instrução, com os pais
ainda no lugar. A última seção desta aula diz como.
