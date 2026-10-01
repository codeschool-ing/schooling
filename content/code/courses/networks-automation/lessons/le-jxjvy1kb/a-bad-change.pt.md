---
title: Uma mudança que passa em todas as verificações anteriores
version: 1
---

O uplink do edge2 é mudado de ponto a ponto para passivo, um erro que parece uma edição razoável
numa revisão:

```
ana@ctl:~$ cd net && sed -i 's/ospf: point-to-point/ospf: passive/' data/edge2.yaml && diff <(git show HEAD:data/edge2.yaml) data/edge2.yaml
7c7
<     ospf: point-to-point
---
>     ospf: passive
ana@ctl:~$ cd net && python validate.py && pytest -q test_configs.py
data/core1.yaml: ok
data/edge1.yaml: ok
data/edge2.yaml: ok
.......                                                                                      [100%]
7 passed in 0.08s
ana@ctl:~$ cd net && python render.py > /dev/null && python push.py --commit
core1: matches
edge1: matches
edge2:
interface eth1
- ip ospf network point-to-point
interface eth1
+ ip ospf passive
edge2: committed
```

**O modelo o aceitou e os sete testes offline passaram**, porque nada nos dados está malformado:
`passive` é uma das duas palavras permitidas, e o endereço e a linha network do edge2 continuam lá.
O NAPALM enviou uma linha a um roteador. Quarenta e cinco segundos depois, passados os quarenta
segundos que o OSPF espera antes de declarar morto um vizinho silencioso, o pós-check:

```
ana@ctl:~$ cd net && pytest -q test_network.py
F..FFF                                                                                       [100%]
============================================= FAILURES =============================================
_______________________________ test_ospf_neighbours_are_full[core1] _______________________________

name = 'core1'

    @pytest.mark.parametrize("name", ROUTERS)
    def test_ospf_neighbours_are_full(name):
        expected = sum(i.get("ospf") == "point-to-point" for i in ROUTERS[name]["interfaces"])
        neighbours = [n for ns in show(name, "show ip ospf neighbor")["neighbors"].values() for n in ns]
>       assert [n["converged"] for n in neighbours] == ["Full"] * expected
E       AssertionError: assert ['Full'] == ['Full', 'Full']
E         
E         Right contains one more item: 'Full'
E         Use -v to get more diff

test_network.py:22: AssertionError
```

```
===================================== short test summary info ======================================
FAILED test_network.py::test_ospf_neighbours_are_full[core1] - AssertionError: assert ['Full'] ==...
FAILED test_network.py::test_every_branch_lan_is_routed[core1] - AssertionError: assert ['203.0.1...
FAILED test_network.py::test_every_branch_lan_is_routed[edge1] - AssertionError: assert ['203.0.1...
FAILED test_network.py::test_every_branch_lan_is_routed[edge2] - AssertionError: assert ['203.0.1...
4 failed, 2 passed in 1.26s
```

O core1 tem um vizinho onde os dados dizem dois, e as LANs das filiais sumiram das tabelas de
roteamento umas das outras. **Veja o que passou**: o teste de vizinhos do próprio edge2. Os dados
agora dizem que o edge2 não tem interfaces ponto a ponto, então o teste esperava nenhum vizinho e
não achou nenhum. Um teste que lê o que esperar dos dados só está tão certo quanto os dados, e é por
isso que foi o teste do core1 que falhou.

O caminho de volta são os últimos dados que passaram, e o Git os tem:

```
ana@ctl:~$ cd net && git checkout data/edge2.yaml && python render.py > /dev/null && python push.py --commit
Updated 1 path from the index
core1: matches
edge1: matches
edge2:
interface eth1
- ip ospf passive
interface eth1
+ ip ospf network point-to-point
edge2: committed
```

E doze segundos depois, o pós-check de novo:

```
ana@ctl:~$ cd net && pytest -q test_network.py | tail -4
FAILED test_network.py::test_every_branch_lan_is_routed[core1] - AssertionError: assert ['203.0.1...
FAILED test_network.py::test_every_branch_lan_is_routed[edge1] - AssertionError: assert ['203.0.1...
FAILED test_network.py::test_every_branch_lan_is_routed[edge2] - AssertionError: assert ['203.0.1...
3 failed, 3 passed in 1.29s
```

**Três falhas, com a adjacência já de volta**: o OSPF tinha se refeito com o edge2, e as rotas
ainda não tinham sido instaladas. Dez segundos depois disso:

```
ana@ctl:~$ cd net && pytest -q test_network.py
......                                                                                       [100%]
6 passed in 1.31s
```

Um pós-check rodado cedo demais falha numa rede que ainda está convergindo, e um rodado tarde
demais deixa os usuários acharem o problema primeiro. Num pipeline, o pós-check é repetido por um
tempo limitado, longo o bastante para o protocolo convergir e curto o bastante para que uma falha
real ainda seja relatada rápido.
