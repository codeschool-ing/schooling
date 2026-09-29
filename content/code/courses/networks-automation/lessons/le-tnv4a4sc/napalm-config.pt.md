---
title: Substituir, comparar, fazer commit, fazer rollback
version: 1
---

Os métodos de configuração do NAPALM levam o candidate da aula 3 a equipamentos que não têm um.
**A mudança é carregada, comparada, e então vai para commit ou é descartada**, e o driver faz o que
a plataforma precisar para que isso seja verdade.

Um **replace** recebe uma configuração inteira e faz o equipamento ficar igual a ela. O arquivo aqui
é a configuração em execução do `edge1` com duas edições: uma descrição mais longa na `eth2` e uma
nova rota estática.

```
ana@ctl:~$ ssh netops@edge1 "show running-config" > edge1.conf
ana@ctl:~$ sed -i 's/description branch LAN/description branch 1 LAN, floor 2/' edge1.conf
ana@ctl:~$ sed -i 's/^router ospf/ip route 192.0.2.128\/25 198.51.100.1\n!\nrouter ospf/' edge1.conf
```

```schooling-example
{
  "language": "python",
  "file": "candidate.py",
  "parts": [
    {
      "code": "import sys\n\nfrom napalm import get_network_driver\n\ndriver = get_network_driver(\"frr\")\nwith driver(\"edge1\", \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:"
    },
    {
      "code": "    dev.load_replace_candidate(filename=\"edge1.conf\")\n    diff = dev.compare_config()",
      "note": "**Substituir, não mesclar.** O arquivo é a configuração inteira que o edge1 deve ter; o NAPALM calcula o que remover e o que acrescentar para chegar lá."
    },
    {
      "code": "    if not diff:\n        print(\"edge1 already matches edge1.conf\")\n        dev.discard_config()\n        sys.exit()\n    print(diff)\n    if \"--commit\" in sys.argv:\n        dev.commit_config()\n        print(\"committed\")\n    else:\n        dev.discard_config()\n        print(\"discarded (run with --commit to apply)\")",
      "note": "**Olhe antes de fazer commit.** Um diff vazio quer dizer que o roteador já bate com o arquivo, e não há nada a fazer."
    }
  ]
}
```

Executado sem `--commit`, ele só mostra o que mudaria:

```
ana@ctl:~$ python candidate.py
interface eth2
- description branch LAN
interface eth2
+ description branch 1 LAN, floor 2
+ip route 192.0.2.128/25 198.51.100.1
discarded (run with --commit to apply)
```

O diff se lê como um diff do Git. Sob `interface eth2`, a descrição antiga sai e a nova entra, e a
rota estática é acrescentada no nível de cima. **Nada tocou o roteador**, e o script descartou o
candidate. Com `--commit`, e depois mais uma vez:

```
ana@ctl:~$ python candidate.py --commit
interface eth2
- description branch LAN
interface eth2
+ description branch 1 LAN, floor 2
+ip route 192.0.2.128/25 198.51.100.1
committed
ana@ctl:~$ python candidate.py
edge1 already matches edge1.conf
```

A segunda execução não encontrou nada para fazer, porque o roteador agora é igual ao arquivo. **É
isso que faz do replace a operação mais forte**: o arquivo é a verdade inteira, e qualquer coisa no
roteador que não esteja nele é removida. Esse também é o seu perigo, porque uma linha que falta no
arquivo por engano é uma linha removida do roteador, e é por isso que o diff vem primeiro.

Um **merge** acrescenta linhas ao que já existe, e `rollback` desfaz o último commit:

```schooling-example
{
  "language": "python",
  "file": "rollback.py",
  "parts": [
    {
      "code": "from napalm import get_network_driver\n\nROUTE = \"ip route 198.51.100.128/25 198.51.100.1\"\n\ndriver = get_network_driver(\"frr\")\nwith driver(\"edge1\", \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:\n    dev.load_merge_candidate(config=ROUTE + \"\\n\")\n    print(dev.compare_config())\n    dev.commit_config()\n    print(\"after commit:  \", ROUTE in dev.get_config()[\"running\"])"
    },
    {
      "code": "    dev.rollback()\n    print(\"after rollback:\", ROUTE in dev.get_config()[\"running\"])",
      "note": "**`rollback` devolve a configuração que o último commit substituiu.** O driver a guardou na hora do commit, então desfazer não depende de alguém ter feito um backup."
    }
  ]
}
```

```
ana@ctl:~$ python rollback.py
+ip route 198.51.100.128/25 198.51.100.1
after commit:   True
after rollback: False
```

A rota estava lá depois do commit e sumiu depois do rollback. O driver guardou a configuração que
substituiu, na hora do commit, e a colocou de volta. **O rollback só é tão bom quanto a memória do
equipamento ou do driver**: ele desfaz o último commit, não um qualquer da semana passada, e é para
isso que servem os backups da aula 11.
