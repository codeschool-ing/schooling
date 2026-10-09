---
title: Auditando as chaves
version: 1
---

A primeira linha da lista, no laboratório. Toda chave SSH é identificada pela sua **impressão digital**, um hash
da chave pública que o `ssh-keygen -l` imprime. O inventário é um arquivo de texto com uma impressão digital
aprovada por linha, e começa com a única chave que o laboratório tem, a da ana, da aula 1:

```
root@soc:~# ssh-keygen -lf /home/ana/.ssh/id_ed25519.pub | awk '{print $2, "ana, work laptop"}' > inventory.txt
root@soc:~# cat inventory.txt
SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo ana, work laptop
root@soc:~# bash keyaudit.sh inventory.txt
/home/ana/.ssh/authorized_keys  SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo  approved
```

O `awk` guarda o segundo campo, a impressão digital, e acrescenta uma nota de quem é a chave. A auditoria é um
script curto; escreva-o como `keyaudit.sh` na pasta pessoal do root:

```schooling-example
{"language": "bash", "file": "keyaudit.sh", "parts": [{"code": "#!/usr/bin/env bash\n# keyaudit.sh INVENTORY: every key that can log in to this machine, checked against the inventory\ninv=${1:?usage: keyaudit.sh INVENTORY}", "note": "O inventário é um arquivo de texto simples: uma impressão digital aprovada por linha, com de quem é a chave e como isso foi confirmado."}, {"code": "for f in /root/.ssh/authorized_keys /home/*/.ssh/authorized_keys; do\n  [ -f \"$f\" ] || continue", "note": "Todo lugar onde uma chave pode ficar para um login: o arquivo do root e um por pasta pessoal. Um usuário sem arquivo é pulado."}, {"code": "  ssh-keygen -lf \"$f\" | while read -r bits fp comment; do\n    if grep -qF \"$fp\" \"$inv\"; then verdict=approved; else verdict=\"NOT IN INVENTORY\"; fi\n    printf '%s  %s  %s\\n' \"$f\" \"$fp\" \"$verdict\"\n  done", "note": "O ssh-keygen -l imprime uma linha por chave: tamanho, impressão digital, comentário. A impressão digital é procurada como texto fixo, sem confiar no comentário, que qualquer um que adiciona uma chave pode escrever."}, {"code": "done"}]}
```

Rodando contra o inventário, ele acha uma chave, e ela está aprovada. Agora o caso para o qual uma auditoria
existe. A ana cria uma segunda chave, para um notebook novo, e a adiciona ao mesmo arquivo sem avisar ninguém:

```
ana@soc:~$ ssh-keygen -q -t ed25519 -N '' -C ana@new-laptop -f ~/.ssh/new_laptop
ana@soc:~$ cat ~/.ssh/new_laptop.pub >> ~/.ssh/authorized_keys
root@soc:~# bash keyaudit.sh inventory.txt
/home/ana/.ssh/authorized_keys  SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo  approved
/home/ana/.ssh/authorized_keys  SHA256:ykVlgi+dtYAE67tXLUi1uRZaHEI9eZpkN+bDeY+MZO8  NOT IN INVENTORY
```

A segunda linha é a auditoria fazendo o seu trabalho: **uma chave que consegue fazer login, e que ninguém
anotou.** Repare no que a linha não diz. Ela não diz que a chave é de um invasor. Aqui é o notebook novo de uma
colega; na quinta, no arquivo do bruno, não era. **Uma chave desconhecida é uma pergunta para o dono da conta,
feita por outro canal**, pessoalmente ou por telefone, nunca por mensagem para a conta que pode estar
comprometida.

Quando o dono confirma, a chave entra no inventário, com o modo como foi confirmada, e a auditoria fica limpa
de novo:

```
root@soc:~# ssh-keygen -lf /home/ana/.ssh/new_laptop.pub | awk '{print $2, "ana, new laptop, confirmed in person"}' >> inventory.txt
root@soc:~# bash keyaudit.sh inventory.txt
/home/ana/.ssh/authorized_keys  SHA256:QJsKkPtqEBuAn+lfcyMGgnotN3pJ16nFW1AbcdPz8bo  approved
/home/ana/.ssh/authorized_keys  SHA256:ykVlgi+dtYAE67tXLUi1uRZaHEI9eZpkN+bDeY+MZO8  approved
```

As impressões digitais da sua execução são outras: cada par de chaves é novo. O que importa é o padrão. Rode a
auditoria com agendamento, não só durante um incidente, e **uma chave aparecendo entre duas execuções é um
alerta**, que é exatamente o que a chave da quinta teria sido, horas antes de alguém ler os alertas da aula 4.
