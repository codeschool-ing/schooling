---
title: A rotina noturna, e um verify que precisa ser lido
version: 1
---

A lição 1 terminou com três verificações que toda rotina de backup faz: todos os programas deram
certo, a saída é plausível, e a cópia foi restaurada em algum lugar. O pgBackRest cobre as duas
primeiras; a terceira é a lição 7. Coloque-as num script, e faça o script **se recusar a informar
sucesso** até a ferramenta ter dito isso do único jeito que esta versão dela diz de forma confiável.

Salve isto como `nightly-backup.sh`:

```schooling-example
{"language": "bash", "file": "nightly-backup.sh", "parts": [{"code": "#!/usr/bin/env bash\n# nightly-backup.sh: back up, then refuse to call it good until verify says so\nset -euo pipefail\nstanza=main\n", "note": "Parar na primeira falha, em qualquer variável não definida, e numa falha em qualquer ponto de um pipe: o pipeline silencioso da lição 1 não tem permissão para voltar."}, {"code": "pgbackrest --stanza=\"$stanza\" check", "note": "Primeiro o caminho do arquivamento. Se os segmentos não estão chegando ao repositório, um backup feito agora não poderia ser restaurado para nenhum momento depois dele."}, {"code": "pgbackrest --stanza=\"$stanza\" backup\n", "note": "Sem --type, o pgBackRest faz um backup incremental, ou um full se ainda não houver nenhum. A retenção roda no fim, como as seções anteriores mostraram."}, {"code": "report=$(pgbackrest --stanza=\"$stanza\" verify --verbose --output=text)\nif ! grep -q '^status: ok$' <<<\"$report\"; then\n  echo \"verify found a problem:\" >&2\n  echo \"$report\" >&2\n  exit 1\nfi\necho \"backup and verify ok\"", "note": "O verify, com o relatório completo pedido. O status de saída dele é 0 seja o que for que encontre, e sem --verbose um repositório saudável não imprime absolutamente nada, então o script lê o relatório e só a linha exata `status: ok` conta como aprovação. Silêncio não é aprovação."}]}
```

Ele roda como `postgres`, que não consegue ler o seu diretório home, então instale-o num lugar onde
qualquer usuário possa rodá-lo, e rode uma vez à mão:

```
ana@vm:~$ sudo install -m 755 nightly-backup.sh /usr/local/bin/nightly-backup.sh
ana@vm:~$ sudo -u postgres /usr/local/bin/nightly-backup.sh
backup and verify ok
ana@vm:~$ echo $?
0
```

**Status de saída 0, e uma linha de saída**, que é a cara que uma rotina funcionando deve ter. Agora
o mesmo dano da seção de verificação, no backup full mais novo, e a rotina de novo:

```
ana@vm:~$ sudo -u postgres /usr/local/bin/nightly-backup.sh
verify found a problem:
stanza: main
status: error
  archiveId: 16-1, total WAL checked: 11, total valid WAL: 11
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162742F, status: valid, total files checked: 1271, total valid files: 1271
    missing: 0, checksum invalid: 0, size invalid: 0, other: 0
  backup: 20261010-162752F, status: invalid, total files checked: 1271, total valid files: 1270
    missing: 0, checksum invalid: 1, size invalid: 0, other: 0
  backup: 20261010-162752F_20261010-162802I, status: invalid, total files checked: 1271, total valid files: 1270
    missing: 0, checksum invalid: 1, size invalid: 0, other: 0
  backup: 20261010-162752F_20261010-162806I, status: invalid, total files checked: 1272, total valid files: 1271
    missing: 0, checksum invalid: 1, size invalid: 0, other: 0
ana@vm:~$ echo $?
1
```

O backup em si deu certo, como antes do dano. O verify encontrou o arquivo inválido, o script
imprimiu o relatório e **saiu com 1**, e qualquer coisa que vigie o status de saída da rotina agora
vê o que aconteceu.

## Rodando toda noite

O agendamento é uma linha no crontab do usuário `postgres`, editado com `sudo crontab -u postgres -e`:

```
30 2 * * * /usr/local/bin/nightly-backup.sh
```

Isso roda o script às 02:30 todo dia. O agendamento não foi executado neste lab, que não tem `cron`
rodando; na sua máquina virtual ele já vem por padrão. O `cron` manda a saída de uma rotina por
e-mail para o usuário que a roda, e numa máquina sem e-mail configurado essa saída não vai para
lugar nenhum, então o agendamento é metade da rotina. **A outra metade é algo que perceba quando ela
falha, ou quando ela nem chega a rodar**: um sistema de monitoramento que espera uma execução
bem-sucedida toda noite e alerta tanto no silêncio quanto na falha. A lição 7 constrói o ensaio de
restauração em cima desta rotina, e a lição 22 é o que acontece quando o alerta dispara.
