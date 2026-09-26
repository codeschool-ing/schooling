---
title: O usuário e o aplicativo
version: 1
---

Duas checagens rápidas, uma por camada:

```
ana@pc1:~$ sudo -u daniel ls -l /home/daniel/september.csv; ls -ld /srv/shared/reports
-rw-r--r-- 1 daniel root 34 Sep 26 00:38 /home/daniel/september.csv
drwxr-xr-x 2 daniel root 4096 Sep 26 00:38 /srv/shared/reports
ana@pc1:~$ sudo -u daniel bash -c "echo test > /srv/shared/reports/test.txt"
bash: line 1: echo: write error: No space left on device
```

- **Usuário**: o arquivo existe, é do Daniel, e a pasta `reports` é dele para escrever. Ele digitou o
  caminho certo e tem o direito de usá-lo. Nada do que ele fez explica a recusa.
- **Aplicativo**: um programa diferente, o próprio `echo` do shell, falha na mesma pasta com as mesmas
  palavras. Então não é o `cp`, e também não teria sido o programa de planilhas dele.

As duas camadas foram riscadas. O que sobra começa no sistema.
