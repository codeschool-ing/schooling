---
title: Mapeamento de campos, e a lista de opções outra vez
version: 1
---

No `sync.sh`, o payload era a linha do modelo transformada em JSON pelo `row_to_json`: toda coluna ia,
com o próprio nome. Um produto põe uma tela entre os dois, o **mapeamento de campos**: à esquerda as
colunas do modelo, à direita os campos do destino, e uma linha de cada coluna até o campo que ela
preenche.

Essa tela faz três trabalhos que a aula 7 fez por acaso ou não fez:

- **Ela escolhe o que é enviado.** Uma coluna não mapeada não é enviada, então o modelo pode carregar uma
  coluna para as próprias checagens — uma contagem, a data em que foi calculado — sem que ela chegue ao
  CRM. A aula 7 mandou todas as colunas, o que só deu certo porque o modelo tinha seis.
- **Ela renomeia.** O campo do CRM pode se chamar `Lifetime_Value__c` e o do modelo `net_revenue`. O
  mapeamento os junta, e o modelo fica com o nome que faz sentido no warehouse.
- **Ela conhece os tipos do destino.** O produto pergunta à API do destino quais são os campos dele,
  então um mapeamento de uma coluna de texto para um campo numérico, ou para uma lista de opções, pode
  ser apontado antes de qualquer envio.

O terceiro trabalho é o que teria pegado cedo a falha da aula 7. O valor de saúde novo, *new*, foi
recusado 284 vezes porque a lista de opções do CRM não o tinha. Um produto que lê a lista pode mostrar a
divergência na tela de mapeamento, mas só se alguém a abrir: uma view alterada no warehouse não abre a
tela de mapeamento de ninguém. **A recusa continua chegando como uma linha falha numa execução**, e o
hábito que a encontra é o mesmo do `sync.sh` — alguém lê as falhas da execução, ou um alerta lê.

Os alertas do Hightouch, por exemplo, separam um **erro fatal**, em que a execução falhou, de **erros de
linha**, em que a execução funcionou e algumas linhas não, e mandam qualquer um deles por e-mail, Slack,
SMS ou PagerDuty. Configure um para cada sincronização no dia em que ela for criada. Uma sincronização
sem alerta é a sincronização da aula 7 sem a última linha.
