---
title: Consentimento, um passo de cada vez
version: 1
---

Os computadores do laboratório não têm área de trabalho para compartilhar, então a tela compartilhada aqui
é de terminal, o **tmux**, que tem os mesmos estados de uma ferramenta de suporte remoto. A Elisa abre uma
sessão própria:

```
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help new -d -s help; ls -l /tmp/help
srw------- 1 elisa elisa 0 Sep 26 01:36 /tmp/help
ana@pc1:~$ tmux -S /tmp/help send-keys -t help "hostname" Enter
error connecting to /tmp/help (Permission denied)
```

O socket da sessão é só da Elisa, `srw-------`, e a técnica é recusada: **recusado é o padrão**, que é o
que qualquer pessoa ia querer no próprio computador. Deixar o arquivo acessível também não basta:

```
ana@pc1:~$ sudo -u elisa chmod 666 /tmp/help; tmux -S /tmp/help send-keys -t help "hostname" Enter
access not allowed
```

O tmux guarda a própria lista de quem pode conectar, e a `ana` não está nela. Só a Elisa pode colocá-la ali:

```
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help server-access -a ana
ana@pc1:~$ tmux -S /tmp/help send-keys -t help "hostname; whoami" Enter; sleep 1; sudo -u elisa tmux -S /tmp/help capture-pane -p -t help | grep -v "^$"
elisa@pc1:~$ hostname; whoami
pc1
elisa
elisa@pc1:~$
```

Agora a técnica pode digitar, e a captura da tela da Elisa mostra o que isso quer dizer: **os comandos
aparecem na sessão dela e rodam como ela**, o `whoami` responde `elisa`. Ela vê cada tecla que a técnica
aperta, e tudo o que é feito ali é feito com as permissões dela, não as da técnica.
