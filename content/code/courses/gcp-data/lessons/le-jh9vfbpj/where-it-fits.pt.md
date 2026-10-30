---
title: Entre o Cloud SQL e o Spanner, e o AlloyDB Omni
version: 1
---

**O Google vende três respostas para "preciso de um banco relacional", e elas diferem no que cresce
quando a carga cresce.** O Cloud SQL cresce indo para uma máquina maior, e copia os dados para cada
réplica. O AlloyDB cresce as leituras acrescentando nós que compartilham uma camada de armazenamento,
e as escritas levando a primária para uma máquina maior. O Spanner, da aula 9, cresce também as
escritas, espalhando os dados por mais máquinas. Cada passo para a direita compra um tipo de
crescimento que o anterior não pode ter, e cobra por ele.

**A ideia errada é que são três tamanhos de um produto**, de modo que um banco sai do Cloud SQL para o
AlloyDB e do AlloyDB para o Spanner. O primeiro passo é quase verdade: o AlloyDB é PostgreSQL, a
aplicação muda uma string de conexão, e o Google entrega um comando para a mudança, que a linha de
comando deste laptop conhece:

```
ana@laptop:~/gcp$ gcloud alloydb clusters migrate-cloud-sql --help | sed -n '/^DESCRIPTION/,/^EXAMPLES/p'
DESCRIPTION
    Migrate Cloud SQL instance to an AlloyDB cluster using an existing Cloud
    SQL backup.

EXAMPLES
```

**O segundo passo não é uma mudança, é um projeto novo.** O Spanner fala SQL, com um dialeto
PostgreSQL entre os dois que tem, mas não é PostgreSQL: as chaves primárias decidem onde as linhas
ficam guardadas, ele tem um jeito próprio de manter as linhas de um pai ao lado das dos filhos, e as
extensões e funções de um servidor PostgreSQL em geral não estão lá. A aula 9 trata exatamente dessas
diferenças. Um banco que pode precisar do Spanner um dia é projetado para o Spanner desde o começo, ou
reconstruído quando o dia chega.

## Lado a lado

| | Cloud SQL para PostgreSQL | AlloyDB para PostgreSQL | Spanner |
|---|---|---|---|
| o motor | PostgreSQL | PostgreSQL, com o armazenamento e o columnar engine do Google | o do próprio Spanner, GoogleSQL ou um dialeto PostgreSQL |
| as escritas vão para | uma primária | uma primária | todos os nós, por faixa de chave |
| as leituras crescem com | réplicas de leitura, cada uma com sua cópia | nós de read pool, sem cópia | mais nós |
| armazenamento | um disco que você dimensiona, por instância | GiB usados, uma vez por cluster | GiB usados, uma vez por instância |
| as regiões | uma, mais réplicas em outras regiões | uma, mais clusters secundários | uma, duas ou várias, como um banco só |
| o que muda para entrar | pouco | uma string de conexão | o schema e as consultas |

**A coluna do meio é o assunto desta aula**, e o lugar dela está na última linha tanto quanto em
qualquer outra. O AlloyDB é para o banco PostgreSQL que passou do que uma máquina do Cloud SQL e suas
réplicas fazem bem, em geral nas leituras, na carga analítica misturada ou no tempo que um failover ou
uma réplica nova levam, e que continua sendo um banco com um escritor. O banco de pedidos da Quitanda
tem esse formato: a loja grava algumas centenas de pedidos por minuto no pico da noite, que uma
máquina absorve com folga, e lê muitas vezes isso, pelo app, pelo catálogo e pelos analistas.

**Uma cópia em outra região existe nos três, e significa uma coisa diferente em cada um.** A do Cloud
SQL é uma réplica em outra região, a da aula 7. A do AlloyDB é um **cluster secundário**, criado com
`gcloud alloydb clusters create-secondary`, que recebe as mudanças do cluster primário de forma
assíncrona e pode ser promovido se a região primária for perdida. As configurações multirregionais
do Spanner são um banco só, cujas escritas são confirmadas em várias regiões ao mesmo tempo, o que é
outra promessa e, como a aula 9 mostra no preço, outra conta.

## O que não decide

**Não o SQL.** Os três respondem `SELECT … GROUP BY …`, e o relatório dos analistas roda em qualquer
um. A diferença é quanto cada um lê para responder, que a seção anterior mediu.

**Não o tamanho dos dados, sozinho.** Um disco do Cloud SQL vai a dezenas de terabytes, mais do que a
Quitanda vai guardar numa tabela de pedidos. A pergunta é o que a carga faz com uma máquina, não
quantos bytes estão atrás dela.

**E não o nome na tabela de preços.** A última seção desta aula põe preço no mesmo banco dos dois
jeitos, e o AlloyDB sai mais caro nos preços de tabela de São Paulo para o formato de que a Quitanda
precisa. Ele ainda pode ser a escolha certa; a conta diz quanto a escolha custa, não se ela está certa.

## AlloyDB Omni, o que dá para baixar

**O AlloyDB Omni é o motor do AlloyDB empacotado para rodar nas suas próprias máquinas**: uma imagem
de contêiner que o Google publica para Linux, Docker e Kubernetes, com o columnar engine dentro, para
um data center, um laptop ou outra nuvem. É um produto separado do serviço gerenciado, com edições e
termos de licença próprios, e a documentação do AlloyDB Omni do Google é onde eles estão descritos. A
página de preços do serviço gerenciado lida para esta aula não põe preço nele, então esta aula não dá
número para ele.

**Este laboratório não o roda**, e vale dizer o motivo: é o motor sem a parte de que esta aula trata. O
Omni guarda os dados nos discos da máquina onde roda, então a camada de armazenamento regional
compartilhada, os read pools que não precisam de cópia e o failover que não move nada não estão nele.
Para o que o Omni serve é exatamente o que esta aula fez com um PostgreSQL comum, e melhor: experimentar
o columnar engine nos seus dados, na sua máquina, antes de pagar por um cluster. Se você o rodar, o
quickstart do AlloyDB Omni do Google é o lugar para começar, e a versão dele não vai ser a que alguma
transcrição daqui mostra.
