---
title: O primeiro push, e um recusado
version: 1
---

O primeiro push leva o projeto inteiro para a `main`. A saída dos hooks volta para quem fez o push,
cada linha marcada com `remote:`:

```
ana@ctl:~$ cd net && git add . && git commit -qm "the network as data, with its tests" && git push -q origin main
remote: testing refs/heads/main at f8272ac        
remote: == yamllint        
remote: == validate        
remote: data/core1.yaml: ok        
remote: data/edge1.yaml: ok        
remote: data/edge2.yaml: ok        
remote: == offline tests        
remote: ........                                                                                     [100%]        
remote: 8 passed in 0.10s        
remote: deploying main at f8272ac        
remote: == render        
remote: data/core1.yaml -> configs/core1.conf, 34 lines        
remote: data/edge1.yaml -> configs/edge1.conf, 34 lines        
remote: data/edge2.yaml -> configs/edge2.conf, 34 lines        
remote: == apply        
remote: core1: matches        
remote: edge1: matches        
remote: edge2: matches        
remote: == post-check        
remote: attempt 1: 6 passed in 1.32s        
```

**Testado, depois implantado, depois verificado.** Todos os roteadores bateram, porque os dados
descrevem o laboratório como ele é, e o pós-check passou na primeira tentativa.

Depois, a mudança ruim da aula 13, numa branch própria, o uplink do edge2 tornado passivo:

```
ana@ctl:~$ cd net && git switch -qc edge2-uplink-passive main && sed -i 's/ospf: point-to-point/ospf: passive/' data/edge2.yaml && git commit -qam 'edge2: uplink passive' && git push -q origin edge2-uplink-passive
remote: testing refs/heads/edge2-uplink-passive at 4a0af3f        
remote: == yamllint        
remote: == validate        
remote: data/core1.yaml: ok        
remote: data/edge1.yaml: ok        
remote: data/edge2.yaml: ok        
remote: == offline tests        
remote: .......F                                                                                     [100%]        
```

```
remote: ===================================== short test summary info ======================================        
remote: FAILED test_links.py::test_both_ends_of_a_link_agree - AssertionError: 198.51.100.4/30: ['core1 e...        
remote: 1 failed, 7 passed in 0.11s        
remote: REFUSED: refs/heads/edge2-uplink-passive fails its tests        
To /home/ana/net.git
 ! [remote rejected] edge2-uplink-passive -> edge2-uplink-passive (pre-receive hook declined)
error: failed to push some refs to '/home/ana/net.git'
ana@ctl:~$ cd net && git ls-remote --heads origin
a51dbcea83dedecf940e4cfadbd7cb3f2c791c2c	refs/heads/edge2-lan-description
f8272acab6a5a56e90568dd82aca292aec38bca8	refs/heads/main
```

**O servidor recusou a branch.** Ela não existe no `origin`, como mostra a lista de branches.
Ninguém pode fazer merge dela, construir em cima dela ou implantá-la por engano, e a falha que a
recusou está no terminal de quem fez o push, com o enlace e os dois valores nomeados. O pipeline fez
num décimo de segundo o que custou à aula 13 uma adjacência quebrada e um revert.

O meio dessa saída, cortado aqui, é o mesmo relatório do pytest que a aula 13 mostrou inteiro.
