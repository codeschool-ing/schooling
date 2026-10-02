---
title: O que é um incidente, e quão grave
version: 1
---

**Um incidente é um evento não planejado que prejudica os usuários do serviço, ou vai prejudicar logo, e
pede uma resposta coordenada.** As três últimas palavras são a parte que trabalha na definição. Um disco
falhando numa réplica que o próximo deploy vai substituir é um ticket; checkouts falhando para todo
cliente é um incidente, porque várias pessoas vão precisar agir juntas, rápido, e alguém tem de fazer
isso acontecer.

**Declare cedo.** Declarar custa uma mensagem num canal e alguns minutos da atenção de alguém; não
declarar custa a hora em que três pessoas investigam a mesma coisa sem saber, e ninguém diz ao suporte o
que falar. Um incidente declarado que se revela pequeno é encerrado com uma frase. O hábito que machuca é
esperar ter certeza.

A severidade diz quão grave, e é definida pelo **impacto nos usuários**, nunca pela causa ou por quão
difícil a correção parece. Os níveis da loja:

| severidade | impacto | resposta |
|---|---|---|
| SEV-1 | a maioria dos clientes não consegue comprar, ou dados estão sendo perdidos ou expostos | todos os necessários, agora, a qualquer hora; a liderança é informada |
| SEV-2 | uma parte grande dos clientes afetada, ou um caminho importante quebrado | o plantão e quem ele precisar, agora; página de status atualizada |
| SEV-3 | uma funcionalidade menor quebrada, ou uma parte pequena afetada, com alternativa | o plantão, no horário de trabalho |

Três regras mantêm os níveis úteis. **A severidade pode mudar**, para cima ou para baixo, conforme o
quadro fica claro, e mudá-la não é confissão de nada. **Na dúvida, escolha a mais alta**: um incidente
com gente demais custa uma hora de algumas pessoas; um com gente de menos custa clientes. E as definições
estão **escritas de antemão**, para que a pessoa que decide às três da manhã leia uma tabela, e não
invente uma.

O orçamento de erros da aula 15 se liga direto: uma taxa de queima que esvaziaria o mês em dois dias é
SEV-2 no mínimo, seja qual for a causa que se descubra.
