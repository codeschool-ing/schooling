---
title: Pondo uma configuração de volta
version: 1
---

Restaurar é tirar um arquivo do histórico e enviá-lo como uma configuração inteira. O arquivo vem
de `git show HEAD~1:edge1.conf`, como na seção 06, onde `HEAD~1` é o commit anterior ao último, a
noite antes da mudança:

```schooling-example
{
  "language": "python",
  "file": "restore.py",
  "parts": [
    {
      "code": "import sys\n\nfrom napalm import get_network_driver\n\nhost, filename = sys.argv[1], sys.argv[2]\ndriver = get_network_driver(\"frr\")\nwith driver(host, \"netops\", None, optional_args={\"key_file\": \"/home/ana/.ssh/id_ed25519\"}) as dev:"
    },
    {
      "code": "    dev.load_replace_candidate(filename=filename)\n    print(dev.compare_config() or \"nothing to restore\")\n    if \"--commit\" in sys.argv:\n        dev.commit_config()\n        print(\"restored\")\n    else:\n        dev.discard_config()",
      "note": "**Um backup é restaurado do jeito que um template é enviado**: como configuração inteira que substitui a que está rodando, depois de olhar o diff."
    }
  ]
}
```

```
ana@ctl:~$ cd net && git -C backups show HEAD~1:edge1.conf > edge1-before.conf && python restore.py edge1 edge1-before.conf
interface eth2
- description guest wifi
+no ip route 192.0.2.128/25 198.51.100.1
interface eth2
+ description branch LAN
```

O dry run mostra a restauração como o NAPALM vai fazê-la: a descrição de volta, a rota removida.
**Uma restauração é uma mudança como qualquer outra**, e ela é examinada antes do commit. Com
`--commit`, e depois um backup e a comparação:

```
ana@ctl:~$ cd net && python restore.py edge1 edge1-before.conf --commit
interface eth2
- description guest wifi
+no ip route 192.0.2.128/25 198.51.100.1
interface eth2
+ description branch LAN
restored
ana@ctl:~$ cd net && python backup.py && git -C backups log --oneline
committed: edge1.conf
dbe7812 backup: edge1
3c44ac7 backup: edge1
4ad37d6 backup: core1, edge1, edge2
ana@ctl:~$ cd net && python compare.py edge1
edge1, missing from the router:
(nothing)
edge1, on the router and not intended:
(nothing)
```

O histórico agora tem três commits para o edge1, e o último o põe de volta onde o primeiro o
deixou. **Nada foi reescrito**: a deriva continua no histórico, entre o commit que a achou e o
commit que a desfez, que é o que uma auditoria precisa.

Uma restauração só é tão boa quanto o backup que ela lê, e o backup só é provado restaurando-o.
Enviar um backup de volta a um roteador no laboratório, como aqui, é o teste; um backup que
ninguém nunca restaurou é um conjunto de arquivos que provavelmente funciona.
