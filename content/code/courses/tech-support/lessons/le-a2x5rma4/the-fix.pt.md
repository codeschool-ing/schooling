---
title: O conserto, e o conserto que falhou antes
version: 1
---

O plano era guardar as últimas mil linhas do log, que é o que qualquer pessoa investigando o problema do
banco ia querer, e descartar o resto:

```
ana@pc1:~$ sudo tail -n 1000 /srv/shared/logs/export.log | sudo tee /srv/shared/logs/export.log.keep >/dev/null && sudo mv /srv/shared/logs/export.log.keep /srv/shared/logs/export.log && df -h /srv/shared
tee: /srv/shared/logs/export.log.keep: No space left on device
ana@pc1:~$ sudo tail -n 1000 /srv/shared/logs/export.log > /tmp/export.log.keep && sudo cp /tmp/export.log.keep /srv/shared/logs/export.log && df -h /srv/shared
Filesystem      Size  Used Avail Use% Mounted on
/dev/loop0       56M   92K   52M   1% /srv/shared
ana@pc1:~$ sudo -u daniel cp /home/daniel/september.csv /srv/shared/reports/ && ls -l /srv/shared/reports/
total 4
-rw-r--r-- 1 daniel daniel 34 Sep 26 00:38 september.csv
-rw-rw-r-- 1 daniel daniel  0 Sep 26 00:38 test.txt
```

**A primeira tentativa falhou pelo motivo que a tornava necessária.** Guardar as linhas significava
escrever um arquivo novo no mesmo disco, e o disco estava cheio. A segunda tentativa grava as linhas
guardadas em `/tmp`, em outro sistema de arquivos, e as copia de volta por cima do log; substituir o
conteúdo do arquivo libera o espaço na hora. O `df` agora diz **1%**, e o relatório do Daniel
salva.

Três coisas sobram, e elas vão no chamado:

- **O `test.txt` está vazio.** Foi criado pela checagem da seção 04 antes de a escrita falhar. Uma escrita
  que falha pode deixar um arquivo vazio para trás, e um relatório vazio numa pasta compartilhada é pior
  que nenhum.
- **O programa continua sendo a causa.** O que quer que escreva o `export.log` tenta de novo para sempre e
  registra cada tentativa. No laboratório nada está mais rodando; num escritório, o disco enche de novo
  amanhã, a menos que o dono daquele programa seja avisado, aula 7.
- **Apagar dados de outras pessoas** é uma decisão. Este log foi guardado em parte e nada mais foi mexido;
  quando falta espaço, dá vontade de remover o que parece sem importância, e a aula 14 é sobre quando isso
  não cabe a você decidir.
