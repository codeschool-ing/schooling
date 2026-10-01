---
title: Uma branch é uma proposta
version: 1
---

Uma mudança que alguém quer fazer vai para uma branch própria. A LAN do edge2 ganha o andar na
descrição:

```
ana@ctl:~$ cd net && git switch -qc edge2-lan-description && sed -i 's/description: branch LAN/description: branch 2 LAN, floor 1/' data/edge2.yaml && git commit -qam 'edge2: say which floor the LAN is on' && git push -q origin edge2-lan-description
remote: testing refs/heads/edge2-lan-description at a51dbce        
remote: == yamllint        
remote: == validate        
remote: data/core1.yaml: ok        
remote: data/edge1.yaml: ok        
remote: data/edge2.yaml: ok        
remote: == offline tests        
remote: ........                                                                                     [100%]        
remote: 8 passed in 0.10s        
```

**Testada e aceita, e não implantada.** O `post-receive` só implanta a `main`, então a branch fica no
servidor como uma proposta que passou nos testes. Num serviço hospedado, este é o momento em que se
abre um merge request ou pull request: outra pessoa lê o diff, que é uma linha de YAML em vez de uma
configuração de roteador, e o resultado dos testes está ao lado dele.

A revisão é a parte que um pipeline não consegue fazer. Os testes sabem que os dados estão bem
formados e que as duas pontas de um enlace concordam; não sabem se a LAN do edge2 fica mesmo no
primeiro andar, ou se esta era a semana de mudá-la. **Um pipeline barateia a revisão, tirando dela
as perguntas mecânicas**, e deixa as perguntas que só uma pessoa sabe responder.

Quando a branch é aprovada, ela recebe o merge na `main`.
