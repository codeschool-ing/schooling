---
title: Escolhendo a versão, e conferindo o download
version: 1
---

A aula 6 trata direito das famílias de distribuições Linux. Para esta aula, a escolha está feita: o
*Ubuntu*, a distribuição mais comum tanto em computadores de escritório quanto em servidores
pequenos, e especificamente uma versão *LTS*.

**LTS** quer dizer *long-term support*, suporte de longo prazo. O Ubuntu publica uma versão nova a cada
seis meses, e a cada dois anos, em abril, uma delas é LTS: recebe atualizações de segurança por *cinco
anos* no padrão, e por mais tempo com o *Ubuntu Pro*, pago, da Canonical. O número da versão é o ano
e o mês: **24.04** é abril de 2024. Para uma máquina que tem de continuar funcionando sem ninguém
pensar nela, como o servidor do escritório, só uma LTS faz sentido.

Há dois downloads: *Desktop*, com a interface gráfica, e *Server*, sem ela. Os dois são arquivos ISO
de alguns gigabytes (aula 2).

## Confira o que você baixou

Um download pode chegar danificado, ou, bem mais raramente e bem pior, pode vir de um espelho que
alguém adulterou. Toda distribuição publica um **checksum** para cada arquivo: um número comprido
calculado a partir do conteúdo exato dele, num arquivo em geral chamado `SHA256SUMS`. Se um byte do
download for diferente, o número fica completamente diferente.

Aqui está a conferência num arquivo pequeno que faz o papel do download, com as somas publicadas ao
lado:

```
ana@server:~/downloads$ cat SHA256SUMS
5af7b95208fdcff454bab3f5eddf567a688a3796c703d4fef91072e38645c062  download.img
ana@server:~/downloads$ sha256sum -c SHA256SUMS
download.img: OK
ana@server:~/downloads$ sha256sum -c SHA256SUMS
download.img: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
```

`OK` quer dizer que o arquivo é, byte a byte, o que quem publicou fez. Depois um byte dele foi mudado,
e a mesma conferência diz `FAILED`. Um checksum que falha quer dizer **baixe de novo**, nunca "deve
estar tudo bem".

No Windows, o mesmo número vem do `Get-FileHash` no PowerShell, e no macOS do `shasum -a 256`. Para ter
certeza de que o próprio arquivo `SHA256SUMS` é legítimo, as distribuições também o assinam com uma
chave criptográfica, e conferir essa assinatura é a versão completa deste passo.
