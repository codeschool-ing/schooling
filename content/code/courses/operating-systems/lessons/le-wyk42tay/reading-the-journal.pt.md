---
title: Lendo o journal
version: 1
---

Nas distribuições com systemd, a saída de todo serviço, as mensagens do kernel e os eventos do próprio
sistema vão para um lugar, **o journal**, e o `journalctl` o lê:

```
ana@server:~$ sudo journalctl --disk-usage
Archived and active journals take up 39.6M in the file system.
ana@server:~$ sudo journalctl -u cron -n 3 --no-pager
Sep 25 11:42:08 server (cron)[41]: cron.service: Referenced but unset environment variable evaluates to an empty string: EXTRA_OPTS
Sep 25 11:42:08 server cron[41]: (CRON) INFO (pidfile fd = 3)
Sep 25 11:42:08 server cron[41]: (CRON) INFO (Running @reboot jobs)
ana@server:~$ sudo journalctl -b -p err --no-pager -o cat | cut -c1-90 | tail -2
```

- **`--disk-usage`**: o journal guarda histórico, aqui 39.6 MB dele, e se apara conforme cresce.
- **`-u cron -n 3`**: as três últimas linhas de uma unidade. Cada linha tem **quando**, **qual máquina**,
  **qual programa e processo**, e **o quê**. O `-u` é o filtro que você mais vai usar, depois da aula 14.
  A primeira linha é um aviso sobre uma variável não definida, `EXTRA_OPTS`, de que o cron não precisa:
  **um aviso no log não é necessariamente o problema que você procura**, e decidir isso faz parte da
  habilidade.
- **`-b -p err`**: só esta inicialização (`-b`), só erros e piores (`-p err`); o `-o cat` tira as
  colunas de data e o `cut` mantém 90 caracteres. Não imprimiu **nada**: este servidor foi iniciado logo
  antes da gravação, e nada desde então foi registrado como erro. Uma resposta vazia ainda é uma
  resposta, e a seção 03 é uma falha que nunca chega a esta lista.

| filtro | mostra |
|---|---|
| `-u NOME` | uma unidade |
| `-b`, `-b -1` | esta inicialização, a anterior |
| `-p err` | esta prioridade e piores: `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, `debug` |
| `--since "1 hour ago"` | uma janela de tempo, também `--until` |
| `-f` | linhas novas conforme chegam, como o `tail -f` |
| `-x` | acrescenta explicações para mensagens conhecidas |

O `-b -1` merece uma nota. Depois de um reinício inesperado, as linhas interessantes estão na
inicialização **anterior**, as últimas que ela escreveu antes de parar.

Alguns programas ainda escrevem os próprios arquivos de log em **`/var/log`**, e o `tail` e o `grep` da
aula 12 os leem. Numa instalação completa do Ubuntu também existem o `/var/log/syslog` e o
`/var/log/auth.log`; este servidor mínimo guarda tudo no journal.
