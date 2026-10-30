---
title: DNS: um nome, duas respostas
version: 1
---

**A aplicação continua usando o nome público, e o DNS decide que endereço ela recebe.** É assim que o Azure documenta para o
SQL, e não foi observado aqui porque nenhum nome foi resolvido:

```
sql-shop.database.windows.net             CNAME  sql-shop.privatelink.database.windows.net
sql-shop.privatelink.database.windows.net A      10.20.2.4   (asked from inside vnet-shop)
```

O primeiro registro é do Azure, e público: o nome do serviço sempre aponta para o nome `privatelink` dele. O segundo é
respondido por **qualquer que seja o DNS a que o cliente pergunta**. Dentro de `vnet-shop`, o resolvedor do Azure consulta a
zona privada ligada e devolve o endereço privado. Da internet, a mesma cadeia termina na resposta pública do Azure, e com o
acesso público desligado a conexão é recusada.

Três falhas cobrem a maioria dos chamados:

- **o nome resolve para um endereço público de dentro da rede**: a zona não está ligada àquela rede, ou a rede usa um servidor DNS
  próprio que não encaminha ao resolvedor do Azure em `168.63.129.16`;
- **funciona do Azure e não do escritório**: o DNS do escritório não sabe que a zona privada existe; a correção é um encaminhador
  de DNS ou o **DNS Private Resolver** do Azure, para consultas locais de domínios `privatelink` chegarem ao Azure;
- **alguém criou uma segunda zona `privatelink.database.windows.net`** em outro grupo de recursos e a ligou também. Uma rede só
  pode estar ligada a uma zona de um mesmo nome, então zonas DNS privadas pertencem a um lugar compartilhado, cujo dono é a
  equipe de plataforma.

O teste é o mesmo em todo caso: resolva o nome **de onde o cliente roda**, com `nslookup` ou `dig`, e compare a resposta com o
endereço do endpoint. Um erro de conexão a um private endpoint é uma pergunta de DNS até prova em contrário.
