---
title: Mantendo o Redis para si
version: 1
---

O Redis foi desenhado para uma rede confiável, e **um Redis alcançável pela internet sem senha é um dos
jeitos mais comuns de servidores serem tomados**: qualquer um que consiga conectar lê toda chave, apaga
tudo, e usa os comandos de configuração dele para gravar arquivos no disco do servidor. Os padrões do
Ubuntu fecham essa porta, e vale conhecê-los para ninguém abri-la:

- `bind 127.0.0.1 -::1`: ele escuta só no loopback. Uma aplicação em outra máquina precisa de uma rede
  privada, ou de um túnel, não de um endereço público.
- `protected-mode yes`: se alguém o prender a todos os endereços e não definir senha, o Redis recusa
  conexões de qualquer lugar que não seja o loopback mesmo assim.

A terceira camada é **quem pode fazer o quê**, e o Redis 6 em diante responde isso com **ACLs**. De
fábrica há um usuário, `default`, sem senha e com toda permissão:

```
ana@web:~$ redis-cli ACL LIST
user default on nopass sanitize-payload ~* &* +@all
ana@web:~$ redis-cli ACL SETUSER shop on ">lab-shop-password" "~cache:*" +@read +@write -@dangerous
OK
```

O `shop` pode entrar com senha, mexer só em chaves que começam com `cache:` (`~cache:*`), rodar comandos
de leitura e escrita, e nenhum dos comandos que o Redis classifica como **perigosos**: `FLUSHALL`,
`CONFIG`, `KEYS`, `DEBUG` e os outros. Entrando como `shop`:

```
ana@web:~$ redis-cli --user shop --pass lab-shop-password --no-auth-warning SET cache:book:2 "{}" EX 60
OK
ana@web:~$ redis-cli --user shop --pass lab-shop-password --no-auth-warning GET bestsellers
NOPERM this user has no permissions to access one of the keys used as arguments

ana@web:~$ redis-cli --user shop --pass lab-shop-password --no-auth-warning FLUSHALL
NOPERM this user has no permissions to run the 'flushall' command

ana@web:~$ redis-cli --user shop --pass lab-shop-password --no-auth-warning CONFIG GET requirepass
NOPERM this user has no permissions to run the 'config|get' command
```

Ele consegue guardar um livro sob `cache:`, e é recusado em todo o resto: outra chave, esvaziar o banco,
ler a configuração. **Uma aplicação cujas credenciais do Redis só alcançam as próprias chaves de cache
transforma uma senha vazada de "tudo" em "o cache"**, o mesmo raciocínio do `ProtectSystem` da aula 4.

O último comando remove o usuário, porque o Redis do laboratório continua aberto ao `default` para as
aulas seguintes. Num servidor de verdade, o usuário `default` ganha uma senha ou é desligado (`ACL
SETUSER default off`), cada aplicação ganha o próprio usuário, e as ACLs ficam num arquivo que o Redis
carrega ao subir (`aclfile /etc/redis/users.acl`), para um reinício não as esquecer.
