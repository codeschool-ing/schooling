---
title: Escolhendo, e o custo de mais um banco
version: 1
---

Cada família responde a um dos padrões de acesso da bilheteria melhor que o PostgreSQL, e a
conclusão óbvia é usar cinco bancos. **Essa conclusão costuma estar errada**, e os motivos são mais
de operação que de tecnologia.

## O imposto de todo banco

Um banco em produção é mais que os dados dentro dele. Cada um precisa de:

- **backups**, e uma restauração que alguém realmente ensaiou;
- **monitoramento**: as métricas próprias, os jeitos próprios de ficar lento, os alertas próprios;
- **atualizações**, no calendário dele, com as quebras de compatibilidade dele;
- **alguém que entenda como ele falha** às três da manhã;
- **um jeito de manter a cópia dele dos dados em dia** com todo outro banco que guarda uma cópia.

O último é o pior. O nome de um show no PostgreSQL, num documento do MongoDB e num nó do Neo4j são
três lugares para atualizar, sem transação entre eles, então por alguma janela eles discordam. Os
problemas de consistência da aula 3, entre réplicas de um banco, voltam entre bancos, sem protocolo
de replicação para resolvê-los.

## Um hábito para decidir

1. **Escreva os padrões de acesso**, como na seção 03, com frequência e pressa.
2. **Pergunte se o banco que você já roda atende cada um bem o bastante.** O PostgreSQL tem `jsonb`
   para documentos, partições para dados ordenados no tempo, consultas recursivas para caminhadas
   curtas num grafo. "Bem o bastante" é medido, como na aula 1, não suposto.
3. **Acrescente um banco para um padrão só quando a medida mandar**, e quando o padrão for central o
   bastante para pagar o imposto acima.
4. **Decida qual banco é a fonte da verdade** de cada fato, e trate toda outra cópia como derivada
   dela e reconstruível.

## Onde armazenamentos especializados costumam se pagar

| padrão | costuma valer um armazenamento separado quando | senão |
|---|---|---|
| chave-valor | latência em microssegundos, expiração, ou volume além do banco principal | uma tabela com coluna de expiração |
| documento | o esquema varia de verdade por registro, ou os dados são enormes e lidos inteiros | `jsonb` no PostgreSQL |
| coluna larga | escritas na casa das centenas de milhares por segundo em muitos servidores | tabelas particionadas |
| grafo | caminhadas profundas ou de profundidade variável são o produto | SQL recursivo para as rasas |
| série temporal | métricas e eventos em grande volume com retenção e redução de amostragem | tabelas particionadas, ou o sistema de monitoramento que você já roda |

O formato a que este curso chega para a bilheteria é o mais comum de todos: o PostgreSQL como
verdade para shows e ingressos, e o Redis ao lado para reservas e contadores, que a aula 9
acrescenta. **Um banco relacional e um armazenamento chave-valor.** A aula 5 roda os outros quatro
para que as trocas deles sejam algo que você viu, e não algo que você leu; ela não defende que você
precisa deles.
