---
title: Mantendo-o verdadeiro
version: 1
---

Um runbook que nunca rodou é um palpite escrito no imperativo. Ele parece exatamente com um que
funciona, e a diferença aparece no pior momento: um comando que mudou de nome no último upgrade, um
caminho que pertence a outro servidor, um verify que espera a coisa errada. O runbook das seções
anteriores tinha um desses no primeiro ensaio, a expectativa de que o `pg_wal` encolhesse, e só
rodá-lo revelou isso.

## Ensaie, numa cópia

**Rode todo runbook antes de precisar dele**, do jeito que esta lição rodou o do disco: prepare o
problema num servidor que não importa para ninguém, siga a página como está escrita e conserte todo
passo em que você teve de pensar. A cópia pode ser uma segunda máquina virtual, ou um cluster criado
ao lado do de verdade, como a lição 20 faz para um upgrade. Um servidor montado a partir do
repositório da lição 23 é a cópia mais barata de todas, porque um script a monta. Um ensaio que
precisou de um passo que a página não tinha é um ensaio que se pagou.

## Uma data e um nome

O cabeçalho traz **`Last rehearsed`** (último ensaio) e **`Owner`** (dono), e os dois merecem o
lugar. A data diz ao leitor quanto confiar na página: ensaiada no mês passado nesta versão, ou dois
anos e uma versão maior atrás. O dono é quem atualiza o runbook quando o servidor muda, e um runbook
que é de todo mundo é atualizado por ninguém. Quando a data envelhece, o runbook pede um ensaio, que
é uma tarefa que cabe numa agenda.

## Depois de cada uso

**O registro da noite é a revisão do runbook.** Leia-o no dia seguinte ao lado da página e procure
três coisas: um passo que você pulou porque estava errado, um passo que você acrescentou porque
faltava, e um intervalo entre duas linhas que foi gasto descobrindo alguma coisa. Cada uma é uma
edição, commitada com a data do incidente na mensagem.

Depois leia a última linha. O runbook lidou com um slot que encheu um disco, e o acompanhamento no
registro dá o nome da mudança que evitaria o próximo: **`max_slot_wal_keep_size`**, um limite de
quanto WAL um slot pode reter. Passado esse limite, o servidor desiste do slot — o `wal_status`
vira `lost` e a réplica não consegue mais continuar a partir dele — em vez de encher o disco. Se
uma réplica perdida é melhor que um disco cheio é uma decisão para as pessoas donas das duas
coisas, e é exatamente por isso que isso é um acompanhamento, e não algo feito às três da manhã. O
segundo acompanhamento, uma checagem de slots inativos no monitoramento, é um passo do runbook
virando alerta: o check 3 rodado a cada minuto por uma máquina, em vez de uma vez por uma pessoa
depois do estrago.

## Onde ele mora

**Ao lado da configuração, e nunca só no servidor que ele descreve.** No repositório da lição 23
ele é revisado como código e versionado com os ajustes que menciona. Mas um runbook para um
servidor que caiu precisa ser legível enquanto esse servidor está fora do ar. A cópia que as
pessoas abrem é a do servidor Git, ou de onde a sua equipe guarda documentos, e nunca a do `/home`
no `db`.

O runbook é um de três tipos de documento que uma equipe de banco de dados mantém, e os outros dois
pertencem a outro lugar. Conduzir um incidente e revisá-lo depois é a lição 22 de db-reliability. A
documentação que permite a alguém reconstruir o servidor a partir dos backups é a lição 24 de
db-reliability.
