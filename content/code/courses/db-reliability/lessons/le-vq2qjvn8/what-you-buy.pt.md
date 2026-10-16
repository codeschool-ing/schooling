---
title: O que um banco gerenciado tira das suas mãos
version: 1
---

Um **serviço gerenciado de PostgreSQL** opera o servidor por você: um provedor de nuvem, ou uma
empresa que só faz isso, cria a máquina, instala o PostgreSQL, faz os backups, mantém um standby em
outro data center da mesma região e faz o failover para ele quando o primário morre. Tudo o que as
lições 2 a 20 montaram à mão vira uma opção de configuração.

É uma troca de verdade, e muitas vezes boa. É também o lugar onde as perguntas deste curso deixam de
ser feitas com mais facilidade, porque a resposta parece ser "o provedor cuida disso". Esta lição é
sobre o que essa resposta cobre de fato, e é a única lição do curso que você poderia fazer num serviço
desses em vez de na sua máquina virtual: as transcrições dela são aritmética, feita no `psql` no
próprio servidor do lab.

O que muda, nos termos deste curso:

| | nos seus servidores | num serviço gerenciado |
|---|---|---|
| base backups e o arquivo (lições 3 a 5) | seus | do provedor, numa agenda que você escolhe num menu |
| recuperação para um ponto no tempo (lição 6) | num servidor que você indica | numa instância **nova**, com um endereço novo |
| o standby e o failover (lições 11 a 17) | seus, do Patroni | do provedor, em geral uma caixa de seleção |
| achar o novo primário (lição 19) | seu proxy ou sua connection string | o nome DNS do provedor, reapontado |
| superusuário, `pg_wal`, o diretório de dados | seus | **não** são seus |
| um `DELETE` errado, uma tabela apagada, uma senha vazada | seus | **continuam seus** |

A última linha é a que nenhum contrato muda. O provedor mantém o serviço no ar; se as linhas dentro
dele estão certas é problema do cliente em qualquer provedor, e os contratos deles dizem isso com
todas as letras.
