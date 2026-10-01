---
title: O teste que o teria pegado
version: 1
---

A mudança ruim chegou à rede porque nenhum teste offline olhava para **as duas pontas de um
link**. Os dados de cada roteador eram válidos; o erro estava no par. Esse teste pode ser escrito,
e não precisa de roteador:

```schooling-example
{
  "language": "python",
  "file": "test_links.py",
  "parts": [
    {
      "code": "import ipaddress\nimport pathlib\nfrom collections import defaultdict\n\nimport yaml\n\nROUTERS = {p.stem: yaml.safe_load(p.read_text()) for p in sorted(pathlib.Path(\"data\").glob(\"*.yaml\"))}\n\n"
    },
    {
      "code": "def test_both_ends_of_a_link_agree():\n    ends = defaultdict(list)\n    for name, router in ROUTERS.items():\n        for i in router[\"interfaces\"]:\n            net = ipaddress.ip_interface(i[\"address\"]).network\n            if net.prefixlen == 30:\n                ends[str(net)].append(f\"{name} {i['name']} ospf={i.get('ospf')}\")\n    for net, sides in ends.items():\n        assert len(sides) == 2, f\"{net} has {len(sides)} end(s): {sides}\"\n        assert sides[0].split(\"ospf=\")[1] == sides[1].split(\"ospf=\")[1], f\"{net}: {sides}\"",
      "note": "**O teste que teria pegado.** Um enlace ponto a ponto é um /30 com um roteador em cada ponta, e o OSPF só forma adjacência se as duas pontas o rodam do mesmo jeito. Os dados de nenhum roteador estão errados sozinhos; o erro está no par."
    }
  ]
}
```

Com a mesma mudança ruim feita de novo, e os testes offline rodados com o arquivo novo:

```
ana@ctl:~$ cd net && sed -i 's/ospf: point-to-point/ospf: passive/' data/edge2.yaml && pytest -q test_configs.py test_links.py
.......F                                                                                     [100%]
============================================= FAILURES =============================================
__________________________________ test_both_ends_of_a_link_agree __________________________________

    def test_both_ends_of_a_link_agree():
        ends = defaultdict(list)
        for name, router in ROUTERS.items():
            for i in router["interfaces"]:
                net = ipaddress.ip_interface(i["address"]).network
                if net.prefixlen == 30:
                    ends[str(net)].append(f"{name} {i['name']} ospf={i.get('ospf')}")
        for net, sides in ends.items():
            assert len(sides) == 2, f"{net} has {len(sides)} end(s): {sides}"
>           assert sides[0].split("ospf=")[1] == sides[1].split("ospf=")[1], f"{net}: {sides}"
E           AssertionError: 198.51.100.4/30: ['core1 eth2 ospf=point-to-point', 'edge2 eth1 ospf=passive']
E           assert 'point-to-point' == 'passive'
E             
E             - passive
E             + point-to-point

test_links.py:19: AssertionError
===================================== short test summary info ======================================
FAILED test_links.py::test_both_ends_of_a_link_agree - AssertionError: 198.51.100.4/30: ['core1 e...
1 failed, 7 passed in 0.11s
```

**Pego sem nada renderizado e nada enviado, com o link, as duas interfaces e os dois valores na mensagem.** Revertido:

```
ana@ctl:~$ cd net && git checkout data/edge2.yaml && pytest -q test_configs.py test_links.py
Updated 1 path from the index
........                                                                                     [100%]
8 passed in 0.09s
```

Esse é o hábito de que esta aula trata. Uma falha achada por um teste online é uma pergunta:
**um arquivo poderia ter mostrado isso?** Quando a resposta é sim, escreva o teste offline que a
teria pegado, e da próxima vez o mesmo erro custa um segundo de CI em vez de uma queda. Quando a
resposta é não, um cabo ou um processo que caiu, o teste online é o lugar certo, e ele cumpriu seu
papel.

Os testes também têm limites que vale nomear. Eles verificam o que alguém pensou em verificar; a
rede tem outras maneiras de falhar. Ferramentas que analisam configurações inteiras offline, como
o Batfish, que modela o plano de controle da rede a partir dos arquivos de configuração e responde
a perguntas como "esta LAN alcança aquela?", vão muito além de testes escritos à mão, ao custo de
rodar um serviço próprio.
