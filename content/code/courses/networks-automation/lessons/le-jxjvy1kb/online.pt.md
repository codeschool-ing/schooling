---
title: Perguntando à rede
version: 1
---

Os testes online leem o que esperar dos mesmos dados e comparam com o que os roteadores relatam:

```schooling-example
{
  "language": "python",
  "file": "test_network.py",
  "parts": [
    {
      "code": "import ipaddress\nimport json\nimport pathlib\nimport subprocess\n\nimport pytest\nimport yaml\n\nROUTERS = {p.stem: yaml.safe_load(p.read_text()) for p in sorted(pathlib.Path(\"data\").glob(\"*.yaml\"))}\n\n\ndef show(router, command):\n    out = subprocess.run([\"ssh\", f\"netops@{router}\", command + \" json\"], capture_output=True, text=True,\n                         check=True, timeout=15).stdout\n    return json.loads(out)\n\n"
    },
    {
      "code": "@pytest.mark.parametrize(\"name\", ROUTERS)\ndef test_ospf_neighbours_are_full(name):\n    expected = sum(i.get(\"ospf\") == \"point-to-point\" for i in ROUTERS[name][\"interfaces\"])\n    neighbours = [n for ns in show(name, \"show ip ospf neighbor\")[\"neighbors\"].values() for n in ns]\n    assert [n[\"converged\"] for n in neighbours] == [\"Full\"] * expected\n\n",
      "note": "**O que a rede deveria estar fazendo, lido dos dados**: um vizinho OSPF por interface ponto a ponto, e todo vizinho `Full`."
    },
    {
      "code": "LANS = [str(ipaddress.ip_interface(i[\"address\"]).network)\n        for r in ROUTERS.values() for i in r[\"interfaces\"] if i.get(\"ospf\") == \"passive\"]\n\n\n@pytest.mark.parametrize(\"name\", ROUTERS)\ndef test_every_branch_lan_is_routed(name):\n    routes = show(name, \"show ip route\")\n    assert [lan for lan in LANS if lan not in routes] == []",
      "note": "**Todo roteador alcança toda LAN de filial.** Os prefixos também vêm dos dados, então uma filial acrescentada amanhã é testada sem editar este arquivo."
    }
  ]
}
```

```
ana@ctl:~$ cd net && pytest -v test_network.py
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.6.0 -- /opt/netauto/bin/python3.12
cachedir: .pytest_cache
rootdir: /home/ana/net
collecting ... collected 6 items

test_network.py::test_ospf_neighbours_are_full[core1] PASSED                                 [ 16%]
test_network.py::test_ospf_neighbours_are_full[edge1] PASSED                                 [ 33%]
test_network.py::test_ospf_neighbours_are_full[edge2] PASSED                                 [ 50%]
test_network.py::test_every_branch_lan_is_routed[core1] PASSED                               [ 66%]
test_network.py::test_every_branch_lan_is_routed[edge1] PASSED                               [ 83%]
test_network.py::test_every_branch_lan_is_routed[edge2] PASSED                               [100%]

======================================== 6 passed in 1.31s =========================================
```

**O que a rede deveria estar fazendo é derivado dos dados**, não escrito no teste: o core1 tem
duas interfaces ponto a ponto, então deveria ter dois vizinhos `Full`, e toda interface passiva é
uma LAN para a qual todo roteador deveria ter uma rota. Uma filial acrescentada aos dados é testada
no dia em que é acrescentada, pelas mesmas três linhas.

Esses testes são mais lentos, mais de um segundo, porque cada um abre uma sessão SSH, e são os
únicos que conseguem achar o que arquivos não mostram: um cabo desconectado, um processo que não
subiu, um vizinho que discorda sobre um timer. Antes de uma mudança, eles são um **pré-check**: a
rede está saudável agora, então uma falha depois é culpa da mudança. Depois de uma mudança, eles são
o **pós-check**, e a próxima seção mostra como é quando um falha.
