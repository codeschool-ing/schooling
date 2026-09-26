---
title: Os fatos do computador numa colada só
version: 1
---

Alguns desses campos são sobre o computador, e são as mesmas perguntas toda vez. Um script curto
responde todas numa colada só:

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# facts.sh: what a ticket needs to know about this computer, in one paste.", "note": "Rodado no computador do usuário, como o usuário, para o `id -un` nomear a pessoa e não você."}, {"code": "echo \"when:     $(date '+%Y-%m-%d %H:%M %Z')\"", "note": "**A hora, com o fuso.** As horas de um chamado são comparadas com logs, e logs de outro servidor podem estar em outro fuso."}, {"code": "echo \"computer: $(hostname)\"\necho \"user:     $(id -un)\"", "note": "Qual computador e qual conta: a armadilha da aula 2, testar como outra pessoa, se evita anotando os dois."}, {"code": ". /etc/os-release\necho \"system:   $PRETTY_NAME, kernel $(uname -r)\"", "note": "O `/etc/os-release` guarda o nome e a versão do sistema como variáveis de shell, então lê-lo com `.` define o `$PRETTY_NAME`."}, {"code": "echo \"up since: $(uptime -s)\"", "note": "Quando ligou pela última vez. \"Já reiniciou?\" fica respondido sem perguntar."}, {"code": "echo \"address:  $(hostname -I | awk '{print $1}')\"", "note": "O primeiro endereço, o que outro computador usaria para alcançá-lo."}, {"code": "df -h --output=pcent,avail / | awk 'NR == 2 {print \"disk /:   \" $1 \" used, \" $2 \" free\"}'", "note": "O quanto o disco do sistema está cheio, porque um disco cheio quebra muitas outras coisas, aula 3."}]}
```

Rodado no computador da Elisa, como a Elisa:

```
ana@pc1:~$ sudo -u elisa bash /tmp/facts.sh
when:     2026-09-26 00:51 -03
computer: pc1
user:     elisa
system:   Ubuntu 24.04.4 LTS, kernel 6.8.0-139-generic
up since: 2026-09-26 00:49:39
address:  10.30.0.76
disk /:   10% used, 6.1G free
```

Sete linhas, e cada uma seria de outro jeito uma pergunta a ela ou um palpite no chamado. Um script assim é
também onde uma equipe de suporte começa a dividir hábitos: os mesmos fatos, na mesma ordem, de todo
técnico.
