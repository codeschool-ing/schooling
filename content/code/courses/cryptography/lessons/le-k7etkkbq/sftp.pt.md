---
title: SFTP, transferência de arquivos dentro do SSH
version: 1
---

**O SFTP não é o FTP com cifragem acrescentada. É outro protocolo, que roda dentro de uma conexão
SSH e herda tudo o que o SSH faz: um canal cifrado, um servidor que prova a identidade com uma chave
de host, e clientes que podem entrar com uma chave em vez de uma senha.** O FTPS, por outro lado, é o
FTP antigo embrulhado em TLS, com certificados e duas conexões. Os dois são cifrados; o SFTP é mais
simples de passar por um firewall e é o que a maioria das equipes escolhe.

## Conferindo a chave do servidor, na primeira vez

O SSH não tem autoridade certificadora por padrão. Na primeira vez que um cliente encontra um
servidor, ele recebe a **chave de host** do servidor e precisa decidir se confia nela, que é o
momento contra o qual a aula 7 alertou. O administrador do servidor de arquivos da Vereda publica a
impressão digital da chave, calculada a partir da própria chave:

```
ana@lab:~/lab$ ssh-keygen -lf keys/sftp_host_ed25519
256 SHA256:ab2RcbxsJtmnwtnW6lBA5u897l40ZxOUi/ikAg3jjfk  (ED25519)
```

A Ana pede a chave ao servidor e calcula a mesma impressão digital a partir do que voltou:

```
ana@lab:~/lab$ ssh-keyscan -p 2222 files.vereda.example 2>/dev/null | ssh-keygen -lf -
256 SHA256:ab2RcbxsJtmnwtnW6lBA5u897l40ZxOUi/ikAg3jjfk [files.vereda.example]:2222 (ED25519)
```

Elas batem, então a chave que o servidor apresentou é a que o administrador publicou, e a Ana a
guarda. Daqui em diante o cliente dela recusa a conexão se o servidor algum dia apresentar outra
chave:

```
ana@lab:~/lab$ ssh-keyscan -p 2222 files.vereda.example 2>/dev/null > known_hosts
```

Essa comparação é o que o `ssh` pede quando imprime *"The authenticity of host … can't be
established"*. Responder `yes` sem comparar é confiar em quem respondeu. Equipes com muitos
servidores evitam a pergunta distribuindo as entradas de `known_hosts` pela gerência de
configuração, ou usando certificados SSH assinados por uma AC interna, para que os clientes confiem
na AC e não em cada chave.

## Entrando com uma chave

A sessão SFTP da Ana entra com a chave Ed25519 dela da aula 6. O servidor guarda só a chave pública
dela, no `authorized_keys`, e a conta nem tem senha:

```
ana@lab:~/lab$ echo 'ls /etc/hostname' | sftp -b - -i keys/ana_ssh -P 2222 -o UserKnownHostsFile=known_hosts -o StrictHostKeyChecking=yes ana@files.vereda.example
sftp> ls /etc/hostname
/etc/hostname   
```

## O que a conexão negociou

A saída detalhada da mesma conexão mostra as escolhas, o equivalente SSH do ServerHello da aula 10:

```
ana@lab:~/lab$ ssh -v -i keys/ana_ssh -p 2222 -o UserKnownHostsFile=known_hosts -o StrictHostKeyChecking=yes ana@files.vereda.example true 2>&1 | grep -E 'kex: algorithm|kex: client->server|Server host key|matches|Authenticated to'
debug1: kex: algorithm: sntrup761x25519-sha512@openssh.com
debug1: kex: client->server cipher: chacha20-poly1305@openssh.com MAC: <implicit> compression: none
debug1: Server host key: ssh-ed25519 SHA256:ab2RcbxsJtmnwtnW6lBA5u897l40ZxOUi/ikAg3jjfk
debug1: Host '[files.vereda.example]:2222' is known and matches the ED25519 host key.
Authenticated to files.vereda.example ([127.0.0.1]:2222) using "publickey".
```

- `sntrup761x25519-sha512` é a **troca de chaves**: X25519 combinada com o Streamlined NTRU Prime, um
  algoritmo pós-quântico. O OpenSSH usa esse **híbrido** por padrão desde a versão 9.0, de 2022,
  exatamente pelo motivo de "coletar agora, decifrar depois" da aula 7;
- `chacha20-poly1305` é a **cifra autenticada** da última seção da aula 1, na forma que não é AES;
- a impressão digital da **chave de host** é conferida contra o `known_hosts` e bate;
- `publickey` é como a Ana foi autenticada, sem nenhuma senha atravessar a conexão.
