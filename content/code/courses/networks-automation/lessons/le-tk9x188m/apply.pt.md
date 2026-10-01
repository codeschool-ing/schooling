---
title: Do arquivo renderizado ao roteador
version: 1
---

Uma mudança agora começa nos dados. A LAN do edge2 ganha uma descrição melhor, e tudo é renderizado
de novo:

```
ana@ctl:~$ cd tpl && sed -i 's/description: branch LAN/description: branch 2 LAN, floor 1/' data/edge2.yaml && python render.py
data/core1.yaml -> configs/core1.conf, 34 lines
data/edge1.yaml -> configs/edge1.conf, 34 lines
data/edge2.yaml -> configs/edge2.conf, 34 lines
```

Enviar os arquivos é o NAPALM da aula 8, com uma diferença: o arquivo renderizado é a configuração
inteira, então ele entra com `load_replace_candidate` em vez de como um merge.

```schooling-example
{
  "language": "python",
  "file": "push.py",
  "parts": [
    {
      "code": "import sys\n\nfrom napalm import get_network_driver\n\ndriver = get_network_driver(\"frr\")\nfor host in (\"core1\", \"edge1\", \"edge2\"):\n    with driver(host, \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:"
    },
    {
      "code": "        dev.load_replace_candidate(filename=f\"configs/{host}.conf\")\n        diff = dev.compare_config()\n        if not diff:\n            print(f\"{host}: matches\")\n            dev.discard_config()\n            continue\n        print(f\"{host}:\\n{diff}\")\n        if \"--commit\" in sys.argv:\n            dev.commit_config()\n            print(f\"{host}: committed\")\n        else:\n            dev.discard_config()",
      "note": "**O arquivo renderizado é a configuração inteira**, então entra como substituição: o que o roteador tem e o arquivo não tem é removido."
    }
  ]
}
```

Uma execução sem `--commit` mostra o que cada roteador receberia:

```
ana@ctl:~$ cd tpl && python push.py
core1: matches
edge1: matches
edge2:
interface eth2
- description branch LAN
interface eth2
+ description branch 2 LAN, floor 1
```

**Três arquivos foram renderizados e um roteador tem algo a fazer.** O diff é a comparação do
NAPALM com o que o edge2 está rodando, então ele contém exatamente a linha que mudou nos dados. Com
`--commit`, e mais uma vez depois:

```
ana@ctl:~$ cd tpl && python push.py --commit
core1: matches
edge1: matches
edge2:
interface eth2
- description branch LAN
interface eth2
+ description branch 2 LAN, floor 1
edge2: committed
ana@ctl:~$ cd tpl && python push.py
core1: matches
edge1: matches
edge2: matches
```

A segunda execução é a verificação que importa: todo roteador bate com o seu arquivo.

Substituir tem uma consequência que o merge não tem. Alguém acrescenta uma rota estática no edge1 à
mão, e a execução seguinte percebe:

```
ana@ctl:~$ ssh netops@edge1

Hello, this is FRRouting (version 8.4.4).
Copyright 1996-2005 Kunihiro Ishiguro, et al.

edge1# configure terminal
edge1(config)# ip route 192.0.2.128/25 198.51.100.1
edge1(config)# end
edge1# exit
Connection to edge1 closed.
ana@ctl:~$ cd tpl && python push.py
core1: matches
edge1:
+no ip route 192.0.2.128/25 198.51.100.1
edge2: matches
```

**A rota não está nos dados, então o envio a remove.** Esse é o sentido de um template da
configuração inteira, e é também por isso que ele não deve ser ligado numa rede numa tarde
qualquer: toda linha feita à mão que ninguém escreveu nos dados é removida pelo primeiro
`--commit`. A ordem segura é a que esta aula seguiu. Primeiro renderize, compare e faça os dados
baterem com a rede, sem enviar nada; só então deixe os dados decidirem.
