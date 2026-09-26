---
title: O que o computador anota
version: 1
---

Toda sessão remota deixa um registro no computador que alcançou, alguém o leia ou não:

```
ana@pc1:~$ sudo journalctl -u ssh --no-pager -o cat | grep -m1 Accepted
Accepted publickey for ana from 10.30.0.1 port 37262 ssh2: ED25519 SHA256:VYM/Ij7b9RJCG7ekEnrLId6cMoZyz7Qd0m8WhFKhdgU
ana@pc1:~$ sudo journalctl _COMM=sudo --no-pager -o cat | grep "COMMAND=/usr/bin/tmux" | head -2
     ana : PWD=/home/ana ; USER=elisa ; COMMAND=/usr/bin/tmux -S /tmp/help new -d -s help
     ana : PWD=/home/ana ; USER=elisa ; COMMAND=/usr/bin/tmux -S /tmp/help server-access -a ana
```

- O servidor ssh registrou **quem entrou, de onde, e com qual chave**: `ana`, de `10.30.0.1`, o computador
  da técnica, com uma chave cuja impressão digital a identifica com exatidão.
- O `sudo` registrou **cada comando rodado com ele**, com quem rodou e como quem.

Leia a segunda parte com atenção, porque ela registra algo que a história acima deixou de fora. **Foi a
`ana` quem rodou os comandos da Elisa**, com `sudo -u elisa`, inclusive o que deu acesso à `ana`. No
laboratório a técnica fez o papel da Elisa, e o registro diz isso com clareza. Num computador de verdade,
essa mesma linha seria o alarme: uma técnica que dá a si mesma o consentimento do usuário não o recebeu.

É para isso que servem os logs no suporte remoto: **eles protegem os dois lados**. O usuário consegue ver
quem esteve no computador dele e o que foi feito; o técnico consegue mostrar exatamente o que fez e o que
não fez. Registre a sessão no chamado também, aula 5: quando começou, com o que o usuário concordou, e
quando terminou.
