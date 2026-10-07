---
title: Todo uso, por escrito
version: 1
---

O OpenBao gravou toda requisição da seção anterior no arquivo de auditoria declarado na
configuração. A última linha é a tentativa recusada do suporte de ler a chave, e vale lê-la
inteira:

```
ana@lab:~/gov$ sudo tail -n 1 /var/log/bao/audit.log | python3 -m json.tool
{
    "time": "2026-10-07T03:31:32.469348851Z",
    "type": "response",
    "auth": {
        "client_token": "hmac-sha256:e686ccd2a03f9324bbca9c2f4e0b568e9297bdde29e4f80336de4890e00941ba",
        "accessor": "hmac-sha256:28e7353fa80788e9b4780f56296a6183e860c12f58a8ac0604f38794409a2d89",
        "display_name": "token",
        "policies": [
            "default",
            "support"
        ],
        "token_policies": [
            "default",
            "support"
        ],
        "policy_results": {
            "allowed": false
        },
        "token_type": "service",
        "token_ttl": 3600,
        "token_issue_time": "2026-10-07T03:31:31Z"
    },
    "request": {
        "id": "54d19358-f2c4-a195-ae26-f365696091c7",
        "client_id": "YKvI9vKtRWISW5quAhZfWfERA7LcP30yuME/HSu3/W8=",
        "operation": "read",
        "mount_point": "transit/",
        "mount_type": "transit",
        "mount_running_version": "v2.5.5+builtin.bao",
        "mount_class": "secret",
        "client_token": "hmac-sha256:e686ccd2a03f9324bbca9c2f4e0b568e9297bdde29e4f80336de4890e00941ba",
        "client_token_accessor": "hmac-sha256:28e7353fa80788e9b4780f56296a6183e860c12f58a8ac0604f38794409a2d89",
        "namespace": {
            "id": "root"
        },
        "path": "transit/keys/ipe-cpf",
        "remote_address": "127.0.0.1",
        "remote_port": 35222
    },
    "response": {
        "mount_point": "transit/",
        "mount_type": "transit",
        "mount_running_plugin_version": "v2.5.5+builtin.bao",
        "mount_class": "secret",
        "data": {
            "error": "hmac-sha256:5d7ef83fb6db661c7e616c7d331786868549249309a0a85352d82a1d5115e433"
        }
    },
    "error": "1 error occurred:\n\t* permission denied\n\n"
}
```

O que fica registrado, e o que fica de fora de propósito:

- **quem** — as políticas do token, `default` e `support`, o tipo dele e quando foi emitido. O
  próprio token e o accessor dele aparecem como **valores `hmac-sha256:`**, não em claro;
- **o quê** — a operação, `read`, no caminho `transit/keys/ipe-cpf`, vinda de `127.0.0.1`;
- **o resultado** — `policy_results` diz `allowed: false`, e o erro está na última linha;
- **não o dado.** Todo campo que poderia carregar um segredo é trocado por um HMAC: um hash com
  chave, uma chave que só este OpenBao tem.

Os HMACs são a parte engenhosa. O log nunca contém um token, um CPF em claro ou um texto cifrado,
então pode ser enviado a uma plataforma de logs e lido pelo time de segurança sem virar ele mesmo
um depósito de segredos. E mesmo assim ele ainda responde "este token foi usado?": um investigador
com um token suspeito pede ao OpenBao que o passe pelo hash com a mesma chave (o endpoint
`sys/audit-hash` faz isso) e procura o resultado no log. **O log confirma um valor que não consegue
revelar.**

## O que um time faz com ele

Uma leitura recusada da configuração de uma chave pelo token do suporte não é incidente — é a Ana
testando uma política. A mesma linha às três da manhã, vinda de um endereço que não é o do suporte,
é a primeira linha de um. As perguntas são as da aula 1, um nível acima:

- **decifrações fora do horário em que o trabalho acontece**, ou por um token que nunca decifrou
  antes;
- **um salto de volume** — o suporte decifra alguns CPFs por hora; dez mil num minuto é uma
  exportação que ninguém aprovou;
- **recusas**, que são uma configuração errada que alguém deve consertar ou uma sondagem que alguém
  deve notar.

**O OpenBao se recusa a atender uma requisição que não consegue gravar em dispositivo de auditoria
nenhum.** Se o disco do log enche, cifrar e decifrar param. É uma escolha a favor do registro e
contra a disponibilidade, e é a certa para um serviço de chaves: uma decifração que ninguém
consegue explicar é pior que um atraso.
