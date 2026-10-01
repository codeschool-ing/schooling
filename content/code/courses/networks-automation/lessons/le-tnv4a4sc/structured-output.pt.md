---
title: Pedir dados em vez de uma tela
version: 1
---

A solução para o screen-scraping não é uma expressão regular melhor. **É pedir ao equipamento uma
saída estruturada**, que a maioria das plataformas hoje consegue dar para a maioria dos comandos
`show`. O FRR responde em JSON quando o comando termina em `json`:

```
ana@ctl:~$ ssh netops@core1 "show ip ospf neighbor json" | head -14
{
  "neighbors":{
    "203.0.113.252":[
      {
        "priority":1,
        "state":"Full\/-",
        "nbrPriority":1,
        "nbrState":"Full\/-",
        "converged":"Full",
        "role":"DROther",
        "upTimeInMsec":11922,
        "deadTimeMsecs":38346,
        "routerDeadIntervalTimerDueMsec":38346,
        "upTime":"11.922s",
```

Todo valor tem nome: `nbrState` é `Full/-`, `upTimeInMsec` é um número de milissegundos em vez de
uma string para interpretar. A mesma pergunta em todo roteador, pelo Netmiko, interpretada com
`json.loads`:

```schooling-example
{
  "language": "python",
  "file": "neighbours.py",
  "parts": [
    {
      "code": "import json\n\nfrom netmiko import ConnectHandler\n\nROUTERS = [\"core1\", \"edge1\", \"edge2\"]\n\nfor name in ROUTERS:\n    router = ConnectHandler(device_type=\"cisco_ios\", host=name, username=\"netops\",\n                            use_keys=True, key_file=\"/home/ana/.ssh/id_ed25519\")"
    },
    {
      "code": "    data = json.loads(router.send_command(\"show ip ospf neighbor json\"))\n    router.disconnect()\n    for neighbour, entries in data[\"neighbors\"].items():\n        for n in entries:\n            print(f\"{name:6} sees {neighbour:15} on {n['ifaceName']:18} state {n['nbrState']}\")",
      "note": "**Peça JSON ao roteador em vez de uma tela.** O FRR responde à maioria dos comandos `show` em JSON quando o comando termina em `json`, e aí a saída é dado com campos nomeados, não colunas para recortar."
    }
  ]
}
```

```
ana@ctl:~$ python neighbours.py
core1  sees 203.0.113.252   on eth1:198.51.100.1  state Full/-
core1  sees 203.0.113.253   on eth2:198.51.100.5  state Full/-
edge1  sees 203.0.113.251   on eth1:198.51.100.2  state Full/-
edge2  sees 203.0.113.251   on eth1:198.51.100.6  state Full/-
```

Quatro adjacências, duas no `core1` e uma em cada edge, todas `Full`. **Nenhum texto foi
recortado**, e nada aqui quebra se o FRR acrescentar um campo ao seu JSON.

Onde um equipamento não tem saída estruturada, a ferramenta usual é o **TextFSM** com os
**ntc-templates** da comunidade: um template por comando e plataforma que transforma a tela numa
lista de dicionários, e o Netmiko o executa com `use_textfsm=True`. É screen-scraping feito com
cuidado e compartilhado, e continua sendo screen-scraping: o template só está certo para a saída
contra a qual foi escrito. **Prefira o JSON ou o XML do próprio equipamento onde existir**, depois
uma API, e um template por último.
