---
title: Chegou inteiro?
version: 1
---

O mesmo tamanho é um bom sinal, e não uma prova. Um **checksum** é: o `sha256sum` lê cada byte de um
arquivo e imprime uma impressão digital de 64 caracteres que muda por completo se um único bit mudar.
Rodado nas duas pontas:

```
ana@laptop:~$ sha256sum licences.tar.gz
77dba05f431399c924a90ae73166f79b8f3a9d684073ef34f10aaed8d2d37d84  licences.tar.gz
ana@laptop:~$ ssh office sha256sum licences.tar.gz
77dba05f431399c924a90ae73166f79b8f3a9d684073ef34f10aaed8d2d37d84  licences.tar.gz
```

`77dba05f4313…` nas duas, então o arquivo no servidor é, byte a byte, o do laptop. O segundo comando
rodou o `sha256sum` no servidor pelo `ssh`, sem abrir uma sessão lá.

Vale a pena para tudo que importa: um backup antes de se confiar nele, um arquivo grande depois de uma
conexão instável, um instalador baixado para vinte PCs. Fabricantes de software publicam o SHA-256 dos
downloads justamente para isto, e comparar leva poucos segundos.
