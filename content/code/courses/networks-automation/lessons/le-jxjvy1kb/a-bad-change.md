---
title: A change that passes every check before it
version: 2
---

Everything written so far goes into Git first, so that this section has a last good state to
compare with and to go back to. The rendered configurations and Python's caches are left out:

```
ana@ctl:~$ cd net && printf "configs/\n__pycache__/\n.pytest_cache/\n" > .gitignore && git init -q && git add . && git commit -qm "lesson 10 project, with tests"
```

edge2's uplink is changed from point-to-point to passive, a mistake that reads like a reasonable
edit in a review:

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

**The model accepted it and all seven offline tests passed**, because nothing in the data is
malformed: `passive` is one of the two words allowed, and edge2's address and network line are
still there. NAPALM pushed one line to one router. Forty-five seconds later, past the forty seconds
OSPF waits before it declares a silent neighbour dead, the post-check:

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

core1 has one neighbour where the data says two, and the branch LANs have disappeared from each
other's routing tables. **Look at what passed**: edge2's own neighbour test. The data now says edge2
has no point-to-point interfaces, so the test expected no neighbours and found none. A test that
reads its expectations from the data is only as right as the data, which is the reason core1's
test is the one that failed.

The way back is the last data that passed, which Git has:

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

And twelve seconds later, the post-check again:

```
ana@ctl:~$ cd net && pytest -q test_network.py | tail -4
FAILED test_network.py::test_every_branch_lan_is_routed[core1] - AssertionError: assert ['203.0.1...
FAILED test_network.py::test_every_branch_lan_is_routed[edge1] - AssertionError: assert ['203.0.1...
FAILED test_network.py::test_every_branch_lan_is_routed[edge2] - AssertionError: assert ['203.0.1...
3 failed, 3 passed in 1.29s
```

**Three failures, with the adjacency already back**: OSPF had re-formed with edge2, and the routes
had not yet been installed. Ten seconds after that:

```
ana@ctl:~$ cd net && pytest -q test_network.py
......                                                                                       [100%]
6 passed in 1.31s
```

A post-check run too early fails on a network that is still converging, and one run too late lets
users find the problem first. In a pipeline, the post-check is retried for a bounded time, long
enough for the protocol to converge and short enough that a real failure is still reported quickly.
