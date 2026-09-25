---
title: Apagando, sem Lixeira
version: 1
---

```
ana@server:~/work$ rm invoices/*.tmp
ana@server:~/work$ ls invoices
april.pdf  clients-backup.csv  march.pdf  may.pdf
ana@server:~/work$ rmdir reports-copy
rmdir: failed to remove 'reports-copy': Directory not empty
ana@server:~/work$ rm -r reports-copy
ana@server:~/work$ rm -i notes.txt
rm: remove regular empty file 'notes.txt'? n
ana@server:~/work$ ls
backup.log  clients.csv  invoices  notes-todo.txt  notes.txt  reports
```

- O `rm` apaga arquivos. O `rm invoices/*.tmp` removeu os dois nomes que o `echo` tinha mostrado na
  seção 04, e nada mais.
- O `rmdir` apaga só uma pasta **vazia**, e recusou `reports-copy`. Essa recusa é uma rede de
  segurança: ele não consegue remover nada que você ainda não esvaziou.
- O `rm -r` apaga uma pasta e tudo o que há dentro, em qualquer profundidade.
- O `rm -i` pergunta sobre cada arquivo. Responder `n` manteve o `notes.txt`.

**Não há Lixeira na linha de comando.** Um arquivo removido pelo `rm` sumiu, para o sistema; recuperá-lo
quer dizer um backup. Então os hábitos, em ordem:

1. **Olhe antes.** Dê `ls` ou `echo` no padrão exato que vai apagar, e leia a lista.
2. **Esteja onde acha que está.** `pwd` antes do `rm -r`, porque um caminho relativo apaga coisas
   diferentes em cada pasta, o ponto da aula 8 com um gume mais afiado.
3. **Nunca dê `rm -r` num caminho montado a partir de uma variável que você não conferiu.** Uma
   variável vazia transforma `rm -r $DIR/*` em `rm -r /*`.
4. **Use `-i` quando a lista é curta** e você não tem certeza.

## Windows e macOS

Nos dois, apagar pela linha de comando também pula a Lixeira. O **`del`** e o `Remove-Item` no
Windows e o `rm` no Mac são tão definitivos quanto aqui.
