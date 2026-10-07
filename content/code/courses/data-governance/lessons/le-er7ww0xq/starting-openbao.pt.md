---
title: Subindo o OpenBao
version: 1
---

O `lab.sh` instalou o OpenBao e escreveu a configuração dele; nada foi guardado nele ainda. A
configuração é curta:

```
ana@lab:~/gov$ cat /etc/bao/bao.hcl
# OpenBao for the lab: one node, its data in a directory, TLS on the
# listener with the lab CA's certificate for bao.ipe.example.
storage "file" {
  path = "/var/lib/bao/data"
}
listener "tcp" {
  address       = "127.0.0.1:8200"
  tls_cert_file = "/etc/bao/bao.crt"
  tls_key_file  = "/etc/bao/bao.key"
}
api_addr      = "https://bao.ipe.example:8200"
ui            = false

# Every request and every response, written to a file. OpenBao takes audit
# devices from this file and refuses to create them through its API.
audit "file" "to-file" {
  options {
    file_path = "/var/log/bao/audit.log"
  }
}
```

Há quatro decisões nela. **O armazenamento é um diretório**, `/var/lib/bao/data`, o que serve para
uma máquina e um laboratório; um cluster de produção usa o armazenamento integrado do OpenBao,
replicado entre vários nós. **O listener fala TLS** com um certificado da mesma CA de laboratório
do banco, para o nome `bao.ipe.example`, então todo cliente o confere como a aula 3 ensinou.
**`api_addr`** é o endereço que os clientes recebem para usar. E **toda requisição e resposta vai
para um arquivo de auditoria**, declarado aqui porque esta versão do OpenBao só aceita dispositivos
de auditoria vindos do arquivo de configuração: o que é auditado faz parte do arquivo que um
revisor lê, e não de uma configuração que alguém com um token consegue mudar.

O `lab.sh bao-start` subiu o servidor como o usuário `bao`; na máquina virtual uma unit do systemd
faria isso no boot. Ele responde, e diz que não está pronto:

```
ana@lab:~/gov$ bao status
Key                Value
---                -----
Seal Type          shamir
Initialized        false
Sealed             true
Total Shares       0
Threshold          0
Unseal Progress    0/0
Unseal Nonce       n/a
Version            2.5.5
Build Date         2026-06-17T11:18:48Z
Storage Type       file
HA Enabled         false
```

**`Initialized false`, `Sealed true`.** Ele ainda não tem chaves próprias, e não as usaria se
tivesse.

## Inicializando: a chave que protege as chaves

Tudo o que o OpenBao guarda — as chaves do transit, as políticas, os tokens — é cifrado em disco
com uma **chave raiz**. Inicializar cria essa chave raiz e a divide na mesma hora:

```
ana@lab:~/gov$ bao operator init -key-shares=3 -key-threshold=2 | tee init.txt
Unseal Key 1: 7lO0Motm4zDTjj322eJo8vo1TwTY2ZnueWQQ3qqPcTpX
Unseal Key 2: gaQ1dkP33nYAjVaZWflpEKhJXGFzADlO4jBOzQvqtuDT
Unseal Key 3: KeCYHX1gaNGzJ30xknQPi7ZxzBh7YobxpGHOXdKTvCib

Initial Root Token: s.c5LGosDv5B2HJo3zt3fSzP4o

Vault initialized with 3 key shares and a key threshold of 2. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 2 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 2 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum
of existing unseal keys shares. See "bao operator rotate-keys" for more
information.
```

A chave raiz foi cortada em **três partes, quaisquer duas das quais a reconstroem**. Isso é o
compartilhamento de segredo de Shamir, e o sentido dele está na linha abaixo das chaves: o OpenBao
não guarda a chave raiz. Ela só existe enquanto é reconstruída a partir das partes. As mensagens
ainda dizem "Vault", herança do projeto de que o OpenBao é fork.

**As três partes aparecem impressas aqui porque este laboratório é jogado fora quando reiniciado.**
Num ambiente real, cada parte vai para uma pessoa diferente, cada pessoa guarda a sua onde as
outras não alcançam, e ninguém — inclusive quem rodou este comando — fica com as três. Um limiar de
dois quer dizer que uma pessoa pode estar de férias e uma parte pode se perder sem trancar a
empresa do lado de fora, e que nenhuma pessoa sozinha abre o cofre.

O **token root inicial** é a outra coisa na tela, e a próxima seção trata de por que ele deve
existir pelo menor tempo possível.
