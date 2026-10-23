---
title: Honeytokens, isca que é dado
version: 1
---

**Um honeytoken é um dado que nada legítimo jamais lê.** Onde um honeypot pega alguém explorando a
rede, um honeytoken pega alguém mexendo em arquivos, que é o que qualquer um faz num servidor em que
acabou de entrar: procurar senhas, chaves e strings de conexão que abram a próxima porta.

No `web`, faça um arquivo que pareça exatamente o que essa pessoa esperaria achar: as credenciais de
banco de dados de um job de backup antigo, esquecidas num diretório. Todo valor nele é inventado. Não
existe `db.jatoba.example`, nem conta `svc_backup` em lugar nenhum do escritório, e a senha não abre
nada.

```
ana@web:~$ sudo mkdir -p /srv/portal/old-backup
ana@web:~$ printf "# old backup job, kept for reference\nDB_HOST=db.jatoba.example\nDB_USER=svc_backup\nDB_PASS=Ipe-Amarelo-2019\n" | sudo tee /srv/portal/old-backup/db-credentials.txt >/dev/null
ana@web:~$ sudo systemd-run -q --unit canary bash /home/ana/canary.sh
```

O último comando inicia o `canary.sh`, o vigia do arquivo, como serviço. Salve-o antes no seu home no
`web`; são poucas linhas de shell em volta do `inotifywait`, o mesmo aviso do kernel que o guarda da
aula 9 usou:

```schooling-example
{"language": "sh", "file": "canary.sh", "parts": [{"code": "#!/bin/bash\n# canary.sh: raise an alert whenever anybody opens the bait file.\nBAIT=/srv/portal/old-backup/db-credentials.txt\ninotifywait -m -q -e open --format '%e' \"$BAIT\" | while read -r event; do\n  logger -p auth.warning -t canary \"the bait file $BAIT was opened\"\ndone", "note": "O kernel avisa o `inotifywait` toda vez que o arquivo é aberto, por qualquer um, por qualquer motivo, e a cada vez um aviso vai para o log do sistema. Nada lê o arquivo no trabalho normal, então a primeira linha que isto grava já merece a atenção de uma pessoa."}]}
```

Agora abra o arquivo como faria alguém olhando o `/srv`, e veja o log:

```
ana@web:~$ sleep 1; sudo cat /srv/portal/old-backup/db-credentials.txt | head -1
# old backup job, kept for reference
ana@web:~$ sleep 1; sudo journalctl -t canary -o short-iso --no-pager
2026-10-23T10:13:49-03:00 web canary[131]: the bait file /srv/portal/old-backup/db-credentials.txt was opened
```

A leitura em si deu certo, e de propósito: um honeytoken que se recusasse a ser lido diria a quem lê
que é isca. **O alerta veio da abertura, não de nada que o leitor tenha feito com ele.** Aqui quem leu
foi você, com `sudo`; num caso de verdade a linha chegaria com o horário, e os outros logs do sistema
diriam que conta estava ativa então.

## Um token que continua funcionando depois de sair

O arquivo cita uma conta, `svc_backup`. **Nenhum sistema do escritório tem essa conta**, então nada
legítimo a tenta. Alguém que copiou o arquivo e depois tenta as credenciais, de qualquer máquina, deixa
uma linha dizendo isso:

```
ana@desk:~$ ssh -o BatchMode=yes svc_backup@web true
svc_backup@web: Permission denied (publickey,password).
ana@web:~$ sudo journalctl -u ssh -o short-iso --no-pager | grep svc_backup
2026-10-23T10:13:51-03:00 web sshd[140]: Invalid user svc_backup from 192.168.60.20 port 36808
2026-10-23T10:13:51-03:00 web sshd[140]: Connection closed by invalid user svc_backup 192.168.60.20 port 36808 [preauth]
```

`Invalid user svc_backup from 192.168.60.20`: o nome que só existe no arquivo-isca foi tentado, a
partir do `desk`. Essa linha pode ser achada por uma regra tão simples quanto um `grep`, e quer dizer
uma coisa só. **Esse é o tipo mais forte de honeytoken**, porque dispara onde quer que os dados
roubados sejam usados, e não só onde estavam guardados. A mesma ideia é uma linha falsa numa tabela de
clientes que, se um dia aparecer numa exportação ou na internet, prova qual cópia vazou, ou um endereço
de e-mail que só existe num arquivo e recebe mensagens no dia em que o arquivo é vendido.
