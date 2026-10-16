---
title: Decidindo, e o que a equipe faz no lugar
version: 1
---

Os dois modelos, na mesma noite, com os mesmos desfechos:

| 29 de março de 2026 | campeão, versão 1 | desafiante, versão 3 |
| --- | --- | --- |
| treinado em | 31 de agosto de 2025 | 28 de dezembro de 2025 |
| ROC AUC | 0,747 | 0,745 |
| precisão média | 0,496 | 0,500 |
| afastados entre os 300 primeiros | 193 | 196 |
| dito, contra 0,210 acontecido | 0,177 | 0,175 |

**Um empate.** Quatro meses mais novo, e nada melhor em março: os rótulos do desafiante fecharam em 28
de março, antes de o rival abrir, então ele aprendeu o mesmo mundo que o campeão. Nenhum dos dois
está calibrado, porque a mudança que quebrou a calibração não está nos rótulos de nenhum. A política
diz para promover só um desafiante que vence, então o apelido fica onde está, e o registro mostra:

```
ana@dev:~/ml$ python champion.py | head -n 3
version 1  aliases ['champion']  commit c87382e  average precision 0.522  said 0.177
version 2  aliases []  commit 71633df  average precision 0.519  said 0.426
version 3  aliases []  commit 5d9b036  average precision 0.5  said 0.175
```

**No dia em que um desafiante vencer, promover é um comando, e voltar atrás também.** O lote pega a
versão nova na próxima execução; o serviço no próximo reinício, porque a lição 8 fixou o modelo na
partida:

```sh
python champion.py 3      # promote: the alias moves, nothing is copied
python champion.py 1      # roll back: the same command, the old number
```

As duas versões ficam no registro com os seus commits e os seus dados, e é isso que torna a segunda
linha segura: voltar é apontar para algo que nunca saiu de lá.

**E em 30 de junho, sem nenhum modelo que se possa mostrar melhor, a equipe age mesmo assim:**

- **o boletim dividido vai para o marketing**, que pode responder aos membros jovens de Paulista e
  Pinheiros com algo que um modelo não consegue, uma oferta que concorra com uma assinatura;
- **o `segments.py` entra nas checagens noturnas**, para a diferença ser acompanhada conforme os
  desfechos de cada noite nova fecham, e a regra de "retreinar antes" dispara na noite em que um
  teste estrito conseguir vê-la;
- **o calendário fica escrito**: uma noite de treino depois de 1º de abril fecha em julho, e uma
  noite de teste 90 dias depois dela fecha em outubro. É a primeira noite em que a evidência pode
  existir.

**Esse é o fim honesto do ciclo de vida que este curso acompanhou.** Um modelo é construído a partir
do passado, conferido contra um passado mais recente e servido num presente que continua se movendo.
O monitoramento não impede o presente de se mover; o que ele faz é tornar cada mudança visível no
momento mais cedo que a evidência permite, e guardar cada versão, cada nota e cada desfecho, para que
a próxima decisão seja tomada com números e não com um palpite.
