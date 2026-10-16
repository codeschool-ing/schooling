---
title: O ensaio como script
version: 1
---

O ensaio tem cinco passos, e cada um deles já apareceu numa lição anterior: nomear um momento, ler
o relatório nele, restaurar até ele no segundo servidor, ler o relatório de novo, comparar. O que é
novo é que eles rodam sem ninguém olhando, sempre do mesmo jeito, e deixam um registro. Salve isto
como `restore-drill.sh` ao lado do `report.sql`:

```schooling-example
{"language": "bash", "file": "restore-drill.sh", "parts": [{"code": "#!/usr/bin/env bash\n# restore-drill.sh: restore the newest backup elsewhere, prove it, throw it away\nset -euo pipefail\nstanza=main\ntarget=/var/lib/postgresql/16/restore\nport=5433\ndbs=\"shop bigshop\"\nlog=\"$HOME/drills.csv\"\nms() { echo $(( $(date +%s%N) / 1000000 )); }\nt0=$(ms)\n", "note": "Pare na primeira falha. As configurações dizem a stanza, para onde vai a cópia e quais bancos comparar."}, {"code": "label=\"drill-$(date +%Y%m%d-%H%M%S)\"\npsql -X -q -d shop -c \"SELECT pg_create_restore_point('$label')\" > /dev/null\nfor db in $dbs; do\n  psql -X -A -t -d \"$db\" -f report.sql > \"live-$db.txt\"\ndone", "note": "Nomeie o momento até o qual o ensaio restaura, e depois fotografe cada banco com o relatório. Isso supõe que nada escreve nos poucos segundos entre os dois; a seção sobre alvos em movimento trata de quando isso não é verdade."}, {"code": "sudo -u postgres pgbackrest --stanza=\"$stanza\" check\nbackup=$(sudo -u postgres pgbackrest --stanza=\"$stanza\" info | awk '/ backup: /{b=$3} END{print b}')\n", "note": "O check troca o log e espera até ele ser arquivado, então o ponto de restauração está no arquivo antes de qualquer coisa ser restaurada."}, {"code": "t1=$(ms)\nsudo pg_ctlcluster 16 restore stop 2>/dev/null || true\nsudo rm -rf \"$target\"\nsudo -u postgres pgbackrest --stanza=\"$stanza\" --pg1-path=\"$target\" \\\n  --archive-mode=off --type=name --target=\"$label\" --target-action=promote restore", "note": "Fase um, a restauração: os arquivos voltam do repositório para um diretório vazio, com o arquivamento desligado."}, {"code": "t2=$(ms)\nsudo pg_ctlcluster 16 restore start\nuntil psql -X -A -t -p \"$port\" -d shop -c \"SELECT NOT pg_is_in_recovery()\" 2>/dev/null | grep -q t; do\n  sleep 0.2\ndone", "note": "Fase dois, a recuperação: suba a cópia e espere até ela reaplicar até o ponto de restauração e ser promovida."}, {"code": "t3=$(ms)\nresult=ok\nfor db in $dbs; do\n  psql -X -A -t -p \"$port\" -d \"$db\" -f report.sql > \"restored-$db.txt\"\n  if ! diff \"live-$db.txt\" \"restored-$db.txt\"; then result=DIFFERENT; fi\ndone\nt4=$(ms)\n", "note": "Fase três, a prova: o mesmo relatório na cópia, comparado linha a linha com o de produção."}, {"code": "sudo pg_ctlcluster 16 restore stop\nsudo rm -rf \"$target\"\nsecs() { printf '%d.%d' $(( $1 / 1000 )) $(( $1 % 1000 / 100 )); }\n[ -f \"$log\" ] || echo \"when,backup,restore_s,recovery_s,verify_s,total_s,result\" > \"$log\"\necho \"$(date '+%F %T'),$backup,$(secs $((t2-t1))),$(secs $((t3-t2))),$(secs $((t4-t3))),$(secs $((t4-t0))),$result\" >> \"$log\"\ntail -n 1 \"$log\"\n[ \"$result\" = ok ]", "note": "Jogue a cópia fora, seja qual for o resultado, e escreva uma linha de histórico: quando, a partir de qual backup, quanto tempo levou cada fase, e o que encontrou."}]}
```

Ele roda como você, com `sudo` nos comandos que precisam, porque mexe em arquivos que pertencem ao
`postgres` e roda o `psql` como você. A restauração tem como alvo o **ponto de restauração** que ele
criou, pelo nome, que a lição 6 chamou de o seguro mais barato que existe. Torne-o executável e
rode:

```
ana@vm:~$ chmod +x restore-drill.sh
ana@vm:~$ ./restore-drill.sh
2026-10-10 16:50:15,20261010-164946F,2.2,2.5,6.0,16.7,ok
ana@vm:~$ echo $?
0
```

**Uma linha, e status de saída 0.** Leia a linha como o resultado inteiro do ensaio: ele rodou às
16:50:15, restaurou o backup full `20261010-164946F` mais o arquivo até o ponto de restauração,
gastou **2,2 segundos** pondo arquivos de volta, **2,5** reaplicando e promovendo, **6,0**
comprovando, e **16,7** no total. A prova é a fase mais lenta, porque tirar a impressão digital de
três milhões de linhas significa lê-las nos dois servidores; o total é maior que as três fases
porque inclui a leitura dos relatórios em produção e o `check` do arquivo.

Cada execução acrescenta uma linha ao `drills.csv`. A última seção desta lição lê esse arquivo, e
ele é a coisa mais útil que o ensaio produz.
