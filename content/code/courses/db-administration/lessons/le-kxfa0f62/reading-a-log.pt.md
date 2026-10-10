---
title: Lendo um log
version: 1
---

Um log de servidor é lido em duas situações: **algo está errado agora**, e você quer as linhas dos
últimos minutos, ou **algo deu errado uma vez**, e você quer todas as linhas de um tipo. As duas
começam pela palavra depois do prefixo, a **severidade**.

| severidade | o que significa |
|---|---|
| `LOG` | informação para o administrador: um checkpoint, um comando lento, uma conexão |
| `WARNING` | algo provavelmente não intencional, que seguiu mesmo assim |
| `ERROR` | um comando falhou; a sessão continua |
| `FATAL` | uma sessão terminou: um login recusado, um backend encerrado |
| `PANIC` | o servidor inteiro parou, e toda sessão junto |
| `DETAIL`, `HINT`, `CONTEXT`, `STATEMENT` | mais sobre a linha de cima, do mesmo processo |

`ERROR`, `FATAL` e `PANIC` sobem no quanto derrubaram junto, e **o `FATAL` é o que se lê errado**:
soa como o fim do servidor e quase sempre quer dizer que uma conexão foi recusada. O
`log_min_messages`, `warning` por padrão, é a severidade mais baixa que o servidor escreve, e
baixá-lo para `info` ou `debug1` acrescenta muito mais ruído que respostas.

## Contar antes de ler

O log teve uma lição movimentada. Antes de abri-lo, conte o que há nele:

```
ana@db:~$ sudo grep -oE '(LOG|ERROR|FATAL|PANIC|WARNING|DETAIL|HINT|CONTEXT|STATEMENT): ' /var/log/postgresql/postgresql-16-main.log | sort | uniq -c | sort -rn
 140060 LOG: 
      9 STATEMENT: 
      2 ERROR: 
      2 CONTEXT: 
      1 DETAIL: 
ana@db:~$ sudo grep -E 'ERROR|FATAL|PANIC' /var/log/postgresql/postgresql-16-main.log
2026-10-10 16:44:27.696 -03 [211] ana@shop ERROR:  division by zero
2026-10-10 16:44:29.187 -03 [220] ana@shop psql ERROR:  division by zero
```

São 140.060 linhas `LOG`, quase todas das duas execuções da seção anterior, com 70.000 comandos cada,
e dois erros. Os dois erros são o `SELECT 1/0` da seção do prefixo, e o `grep` os achou num arquivo onde
estavam perdidos entre os comandos da seção anterior. **Num servidor sob pressão, comece por esse
`grep`**, depois pegue o id de processo do prefixo de uma linha que importa e faça `grep` por
`[esse pid]` para ver tudo o que aquela sessão escreveu.

O `tail -f` no arquivo o acompanha ao vivo, o que é certo enquanto você reproduz um problema e
inútil para o que já aconteceu. O `less +G` abre um arquivo grande pelo fim sem lê-lo inteiro na
memória antes.

## Rotação

Um log que só cresce enche o disco, e a lição 9 mostra o que o PostgreSQL faz quando isso acontece.
No Ubuntu o arquivo é cortado pelo **logrotate**, a mesma ferramenta que gira todos os outros logs
da máquina, seguindo este arquivo:

```
ana@db:~$ cat /etc/logrotate.d/postgresql-common
/var/log/postgresql/*.log {
       weekly
       rotate 10
       copytruncate
       delaycompress
       compress
       notifempty
       missingok
       su root root
}
```

Toda semana, dez arquivos antigos guardados, comprimidos a partir do segundo (`delaycompress`).
Forçar uma rotação agora mostra o resultado:

```
ana@db:~$ sudo logrotate -f /etc/logrotate.d/postgresql-common
ana@db:~$ ls -l /var/log/postgresql
total 18484
-rw-r----- 1 postgres adm        0 Oct 10 16:45 postgresql-16-main.log
-rw-r----- 1 postgres adm 18925723 Oct 10 16:45 postgresql-16-main.log.1
```

A linha a entender é **`copytruncate`**. O servidor mantém o arquivo aberto como a sua saída de erro
e não tem como ser avisado para reabri-lo, então o logrotate não pode simplesmente renomear o
arquivo: o servidor continuaria escrevendo no renomeado. Em vez disso, ele copia o conteúdo para o
`.1` e depois trunca o original para zero, e o servidor segue escrevendo no começo de um arquivo
vazio. O preço é uma pequena janela entre a cópia e o truncamento em que as linhas escritas não
ficam em arquivo nenhum.

**Semanal é uma decisão de tamanho tomada sem olhar o tamanho.** Com `log_statement = 'all'` a seção
anterior escreveu megabytes em segundos, e uma semana disso seria um disco. Se o log que você
escolher escreve muito, gire diariamente, ou por tamanho com o `size` ou o `maxsize` do logrotate, e
confira a partição onde fica o `/var/log`.
