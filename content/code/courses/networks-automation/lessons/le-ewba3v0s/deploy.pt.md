---
title: Merge, deploy, verificação
version: 1
---

Fazer o merge é um push para a `main`, e os dois hooks rodam:

```
ana@ctl:~$ cd net && git switch -q main && git merge -q --no-edit edge2-lan-description && git push -q origin main
remote: testing refs/heads/main at a51dbce        
remote: == yamllint        
remote: == validate        
remote: data/core1.yaml: ok        
remote: data/edge1.yaml: ok        
remote: data/edge2.yaml: ok        
remote: == offline tests        
remote: ........                                                                                     [100%]        
remote: 8 passed in 0.09s        
remote: deploying main at a51dbce        
remote: == render        
remote: data/core1.yaml -> configs/core1.conf, 34 lines        
remote: data/edge1.yaml -> configs/edge1.conf, 34 lines        
remote: data/edge2.yaml -> configs/edge2.conf, 34 lines        
remote: == apply        
remote: core1: matches        
remote: edge1: matches        
remote: edge2:        
remote: interface eth2        
remote: - description branch LAN        
remote: interface eth2        
remote: + description branch 2 LAN, floor 1        
remote: edge2: committed        
remote: == post-check        
remote: attempt 1: 6 passed in 1.28s        
```

O commit foi testado de novo, desta vez como `main`, renderizado, aplicado ao único roteador que ele
mudou, e verificado contra a rede. O resultado no roteador, e o histórico no servidor:

```
ana@ctl:~$ ssh netops@edge2 "show running-config" | grep "description branch"
 description branch 2 LAN, floor 1
ana@ctl:~$ git -C net.git log --oneline main
a51dbce edge2: say which floor the LAN is on
f8272ac the network as data, with its tests
```

**A `main` agora é o que a rede roda**, e o log dela é a lista de mudanças que a rede já teve, cada
uma testada antes de ser aceita. Os backups da aula 11 comparam a rede com esse histórico; uma
diferença entre os dois é uma mudança que não passou pelo pipeline.

Um pós-check que falha aqui é relatado, não desfeito. O `post-receive` não pode recusar nada, já que
o commit já está na `main`, e a resposta automática segura a uma falha é discutível: reverter o
último commit e implantar de novo é o certo quando a mudança quebrou a rede, e o errado quando a
rede quebrou sozinha enquanto a mudança entrava. Muitas equipes param e chamam uma pessoa; a linha
`DEPLOY FAILED` no `post-receive` é o gancho para isso, e num pipeline real ela acionaria alguém ou
abriria um ticket, como fez a aula 7.

Duas coisas neste laboratório são mais simples do que deveriam. Os hooks rodam como `ana`, com a
chave SSH dela; um pipeline real roda com uma conta própria, com uma chave que não faz mais nada,
guardada no cofre de secrets do sistema de CI. E o deploy envia para todos os roteadores numa só
execução; com mais do que um punhado, ele iria em etapas, primeiro um site, o pós-check dele, depois
o resto.
