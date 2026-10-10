---
title: As partes que toda feature store tem
version: 1
---

Feature stores diferem em como são feitas, de um produto com console web a umas poucas tabelas e uma
biblioteca. **Elas concordam num vocabulário**, e aprendê-lo uma vez torna todas legíveis:

| parte | o que é | nesta lição |
| --- | --- | --- |
| **entidade** (*entity*) | a coisa que os atributos descrevem, com a sua chave | um membro, `member_id` |
| **visão de atributos** (*feature view*) | um conjunto de atributos calculados juntos, de uma fonte, por um código | as dez colunas que o `features.py` monta |
| **carimbo de tempo do evento** (*event timestamp*) | o momento em que um valor era verdade | `as_of`, o dia da fotografia |
| **armazenamento offline** | todo valor já calculado, com o seu carimbo | a tabela `offline` em `features.db` |
| **materialização** | calcular valores e gravá-los num armazenamento | `snapshot` e `backfill` |
| **armazenamento online** | o valor mais novo por entidade, indexado para ler uma linha | a tabela `online` |
| **junção no ponto do tempo** | para cada linha perguntada, o valor mais novo até o momento dela | `historical` |
| **tempo de vida** (*time to live*) | a idade máxima de um valor que ainda pode ser servido | `MAX_AGE`, sete dias |

Duas delas carregam a maior parte do peso. **O carimbo de tempo do evento é o que transforma uma
tabela em história**: sem ele, um armazenamento guarda valores mas não consegue dizer quando eram
verdade, que é exatamente a tabela de resumo da lição 3. **A junção no ponto do tempo é o que usa essa
história corretamente**: é a consulta que torna o vazamento do futuro impossível por construção, e
não por cuidado.

Rótulos não estão na lista. Um rótulo é o desfecho depois do momento, a única coisa que uma feature
store não pode guardar ao lado dos seus atributos, e o armazenamento abaixo o descarta antes de
gravar qualquer coisa.
