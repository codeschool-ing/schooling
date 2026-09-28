---
title: Vigiar em que um host escuta
version: 1
---

A mudança de configuração da seção anterior apontava para um programa na porta 8081. A verificação de
arquivos viu a configuração; uma verificação de **em que o host está escutando** vê o próprio programa.
É uma das verificações de host mais baratas que existem, e a lógica é a mesma do AIDE: registrar uma
linha de base (*baseline*), comparar.

Os sockets em escuta do `www`, salvos como linha de base:

```
root@www:~# ss -Hltn | awk "{print \$4}" | sort > listening.baseline; cat listening.baseline
192.0.2.80:443
192.0.2.80:80
```

A loja na 80 e na 443 e mais nada. Mais tarde, a mesma lista comparada com ela:

```
root@www:~# ss -Hltn | awk "{print \$4}" | sort | diff listening.baseline -; ss -Hltnp "sport = :8081" | awk "{print \$4, \$6}"
0a1
> 0.0.0.0:8081
0.0.0.0:8081 users:(("socat",pid=23908,fd=5))
```

**Um novo listener, em todos os endereços, porta 8081**, e o processo que o segura: `socat`, que não
tem o que fazer num proxy de produção. Em `0.0.0.0` ele responde em toda interface que a máquina tem,
então o firewall da aula 4 é agora tudo o que fica entre ele e a DMZ. O sensor de rede não viu nada,
porque ninguém se conectou a ele ainda; a verificação de host o viu no momento em que abriu.

Verificações de host úteis têm esse mesmo formato, e um agente de HIDS roda muitas delas com agenda:

| verificação | linha de base | um achado se parece com |
|---|---|---|
| portas em escuta | os serviços que o host deve rodar | uma porta que ninguém documentou |
| arquivos | hashes da configuração e dos binários | um arquivo alterado sem pedido de mudança |
| usuários e chaves | contas e entradas de `authorized_keys` | uma conta nova, ou uma chave que ninguém emitiu |
| processos | o que roda normalmente | um shell iniciado pelo servidor web |
| log de autenticação | os logins de sempre | um login às 3 da manhã vindo de um endereço novo |

Cada uma é pequena; juntas, descrevem uma máquina de perto o bastante para que a maioria das intrusões
tenha de aparecer em pelo menos uma. E como um intruso com root pode editar o que o host reporta,
**todo achado é mandado para fora do host na hora em que acontece**, para um lugar que o host não
consegue alcançar de volta. A aula 23 trata desse lugar.
