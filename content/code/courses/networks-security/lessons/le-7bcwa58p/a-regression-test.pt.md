---
title: Um teste que percorre a matriz inteira
version: 1
---

Todos os erros desta aula têm uma coisa em comum: **o conjunto de regras carregou, e a rede ainda
parecia funcionar.** A quarentena sombreada, a máscara larga, a regra impossível, a inalcançável; cada
uma só foi encontrada porque alguém testou o tráfego específico. Esse é o teste da matriz da aula 4, e o
passo que o transforma de hábito em rede de segurança é escrevê-lo e rodá-lo depois de toda mudança.

O resultado esperado de cada célula fica em um arquivo de texto, uma linha por célula, a partir de onde
o tráfego começa:

```
$ cat matrix.expected
remote  www:443      open
remote  app:8080     blocked
remote  db:5432      blocked
laptop  app:8080     open
laptop  app:22       blocked
laptop  db:5432      blocked
admin   app:22       open
admin   app:8080     blocked
www     app:8080     open
www     db:5432      blocked
```

O teste é um script curto que tenta cada linha a partir da máquina que ela nomeia e imprime só as células
cujo resultado difere:

```schooling-example
{"language": "sh", "file": "matrix-test.sh", "parts": [{"code": "#!/bin/bash\n# Try every cell of matrix.expected from the machine it starts on,\n# and print each cell whose result differs from what was expected.\nfail=0", "note": "Silêncio quer dizer que a matriz se mantém. Um teste que imprime cada célula que passou enterra a que falhou."}, {"code": "while read -r from target want; do\n  got=$(sudo bash ~/nslab/nslab.sh exec \"$from\" \"$USER\" \"probe $target\" | awk '{print $2}')", "note": "No seu computador, o `nslab.sh exec` roda o `probe` na máquina da primeira coluna, como você, então a conexão começa de fato naquela zona. Em equipamento real, esta linha é um comando SSH para uma pequena máquina de teste em cada zona, ou um agente de monitoramento capaz de abrir conexões."}, {"code": "  if [ \"$got\" != \"$want\" ]; then\n    printf '%-7s %-12s expected %-8s got %s\\n' \"$from\" \"$target\" \"$want\" \"$got\"\n    fail=1\n  fi\ndone < matrix.expected\nexit $fail", "note": "Qualquer diferença é impressa e faz o código de saída ser 1, então o teste pode barrar uma mudança automatizada: se ele falha, a mudança é desfeita antes que alguém seja acionado."}]}
```

Ele roda no seu próprio computador, a única máquina que consegue iniciar uma conexão a partir de
todas as zonas, num diretório só dele com o `matrix.expected` ao lado; o `sudo` pode pedir a sua senha
uma vez. Contra o conjunto de regras que ainda carrega o erro do `/16` da seção 03:

```
$ bash matrix-test.sh; echo "exit $?"
laptop  app:22       expected blocked  got open
exit 1
```

**Uma linha: a célula que a máscara larga abriu**, e um código de saída 1. Depois de recarregar a
configuração de base:

```
$ bash matrix-test.sh; echo "exit $?"
exit 0
```

Silêncio, e 0. Dez células levam alguns segundos. Uma matriz real tem mais, e o teste cresce com ela; o
custo de rodá-lo é sempre menor que o custo da única célula que ninguém testou.
