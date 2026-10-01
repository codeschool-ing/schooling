---
title: Testando as configurações sem um roteador
version: 1
---

Um modelo verifica cada arquivo isoladamente. Alguns erros só aparecem entre arquivos, ou só na
configuração renderizada, e esses precisam de testes. O `pytest` acha toda função chamada `test_*`
em arquivos chamados `test_*.py`, roda cada uma, e conta um teste como falho quando ele levanta uma
exceção:

```schooling-example
{
  "language": "python",
  "file": "test_configs.py",
  "parts": [
    {
      "code": "import ipaddress\nimport pathlib\nfrom collections import Counter\n\nimport pytest\nimport yaml\n\nfrom model import Router\nfrom render import template\n"
    },
    {
      "code": "ROUTERS = {p.stem: yaml.safe_load(p.read_text()) for p in sorted(pathlib.Path(\"data\").glob(\"*.yaml\"))}\n\n",
      "note": "**Os dados são carregados uma vez, e todo teste os lê.** Um teste é uma função cujo nome começa com `test_`; o pytest a acha, roda e informa cada uma."
    },
    {
      "code": "@pytest.mark.parametrize(\"name\", ROUTERS)\ndef test_data_matches_the_model(name):\n    Router.model_validate(ROUTERS[name])\n\n\ndef test_no_address_is_used_twice():\n    addresses = Counter(i[\"address\"].split(\"/\")[0] for r in ROUTERS.values() for i in r[\"interfaces\"])\n    addresses.update(r[\"loopback\"] for r in ROUTERS.values())\n    assert [a for a, n in addresses.items() if n > 1] == []\n\n\n@pytest.mark.parametrize(\"name\", ROUTERS)\ndef test_every_ospf_interface_gets_a_network_line(name):\n    config = template.render(ROUTERS[name])\n    for i in ROUTERS[name][\"interfaces\"]:\n        if i.get(\"ospf\"):\n            network = ipaddress.ip_interface(i[\"address\"]).network\n            assert f\" network {network} area 0\" in config.splitlines()",
      "note": "**Um teste por roteador**, a partir de uma função: `parametrize` a roda uma vez para cada nome, e uma falha diz qual roteador."
    }
  ]
}
```

O `render.py` é o da aula 10, com o laço movido para dentro de `if __name__ == "__main__":` para
que os testes possam importar o template sem renderizar todos os arquivos como efeito colateral.

```
ana@ctl:~$ cd net && pytest -v test_configs.py
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.6.0 -- /opt/netauto/bin/python3.12
cachedir: .pytest_cache
rootdir: /home/ana/net
collecting ... collected 7 items

test_configs.py::test_data_matches_the_model[core1] PASSED                                   [ 14%]
test_configs.py::test_data_matches_the_model[edge1] PASSED                                   [ 28%]
test_configs.py::test_data_matches_the_model[edge2] PASSED                                   [ 42%]
test_configs.py::test_no_address_is_used_twice PASSED                                        [ 57%]
test_configs.py::test_every_ospf_interface_gets_a_network_line[core1] PASSED                 [ 71%]
test_configs.py::test_every_ospf_interface_gets_a_network_line[edge1] PASSED                 [ 85%]
test_configs.py::test_every_ospf_interface_gets_a_network_line[edge2] PASSED                 [100%]

======================================== 7 passed in 0.10s =========================================
```

**Sete testes a partir de três funções**: o modelo em cada roteador, os endereços entre todos eles,
e a configuração renderizada de cada um. O `-v` imprime uma linha por teste, nomeada com seu
parâmetro, então uma falha diz não só o que falhou mas em qual roteador. A execução inteira levou
um décimo de segundo; nada foi pedido à rede.

O segundo teste é do tipo que nenhum modelo consegue expressar. Os dados de cada roteador são
válidos isoladamente e, ainda assim, dois deles poderiam reivindicar o mesmo endereço, e só um
teste que lê todos de uma vez enxerga isso. O terceiro testa o template e os dados juntos: uma
edição no template que removesse o laço `network` passaria no modelo e falharia aqui.
