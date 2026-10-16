---
title: Exclusões, e o que um resync esquece
version: 1
---

A aula 7 apagou um contato quando ele saiu do modelo e disse que a resposta certa depende de por que ele
saiu. Os produtos transformam isso numa configuração, e a do Hightouch é a mais detalhada, então ela é o
exemplo aqui. O **delete behavior** dele é escolhido por sincronização, separado do sync mode, e tem
três valores onde o destino os aceita:

| delete behavior | o que acontece com um registro cuja linha saiu do modelo | o caso da aula 7 |
|---|---|---|
| Do nothing | ele fica como estava, com os valores antigos | — |
| Clear fields | os campos sincronizados são esvaziados; o registro fica | um filtro mudou |
| Delete destination record | o registro é apagado | uma eliminação |

O Mirror do Census e a opção de registros *deleted* do Segment fazem o mesmo que a última linha. Quais
deles um destino oferece está na página desse destino na documentação de cada produto, e varia: nem toda
API permite apagar.

Duas propriedades de como eles detectam uma linha removida importam mais que a configuração.

**Uma linha removida é uma linha que estava na execução anterior e não está nesta.** É exatamente o
segundo laço da aula 7: `last_sent` contra o modelo. Daí segue que uma linha que saiu do modelo antes de
a sincronização existir nunca é vista saindo, e a documentação do Hightouch diz isso com todas as
letras: linhas removidas antes de a sincronização começar não podem ser limpas.

**Um full resync esquece a execução anterior.** A documentação do Hightouch é explícita: um full resync
não calcula diferença, então as configurações de limpar e apagar são ignoradas e as linhas removidas não
são tratadas. Um cliente eliminado no dia em que alguém apertou *resync* nunca é apagado do CRM.

Juntando: **o delete da sincronização não é o processo de eliminação da empresa.** É uma parte dele. Um
pedido de eliminação precisa do próprio registro de quais sistemas guardam a pessoa, e de uma checagem de
que cada um não guarda mais — o CRM incluído, independentemente do que a sincronização fez ou deixou de
fazer naquela noite.
