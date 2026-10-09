---
title: A cópia de trabalho
version: 1
---

A aula 16 terminou com uma imagem em `evidence/` e um registro de custódia. Essa imagem nunca é aberta. A análise
começa fazendo uma **cópia de trabalho** e provando que ela é igual:

```
root@soc:~/case# cp evidence/files-data.dd work.dd
root@soc:~/case# sha256sum evidence/files-data.dd work.dd
4b5b35a873e1fcd4ac5199ee979949dbe57696b42da1ee379ae64cb17a85d6de  evidence/files-data.dd
4b5b35a873e1fcd4ac5199ee979949dbe57696b42da1ee379ae64cb17a85d6de  work.dd
```

Duas linhas, um hash. Daqui em diante tudo lê `work.dd`, e se algo der errado, uma ferramenta que escreve onde
não devia ou um comando digitado no arquivo errado, o custo é mais um `cp`. O hash é diferente do da aula 16
porque o disco do laboratório foi criado de novo; o que conta é as duas linhas baterem.

O disco da aula 16 precisa existir para esta aula. Se você o removeu, rode os comandos daquela aula de novo, do
`python3 make_disk.py` até o `dd`.
