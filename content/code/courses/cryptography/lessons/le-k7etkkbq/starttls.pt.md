---
title: SSL, TLS, e os dois jeitos de passar um protocolo para a cifragem
version: 1
---

**SSL é o nome antigo do TLS.** A Netscape projetou o SSL 2.0 e o 3.0 em meados dos anos 1990; o
IETF assumiu o protocolo e o rebatizou de TLS 1.0 em 1999. Toda versão do SSL está quebrada e
proibida, e nada em uso hoje a fala. O nome sobrevive em menus de produtos, no próprio nome do
OpenSSL e na expressão "certificado SSL", que significa um certificado TLS: os certificados das
aulas 8 e 9 são os mesmos, seja qual for o nome impresso na nota fiscal.

O que importa mais que o nome é **como** um protocolo entra no TLS, porque há dois jeitos e um deles
pode ser desfeito por um atacante.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas linhas do tempo de uma conexão. TLS implícito, como o LDAPS na porta 636: conectar, handshake TLS, depois o protocolo, cifrado desde o primeiro byte. STARTTLS, como o LDAP na porta 389: conectar, o protocolo começa em texto claro, o cliente pede a atualização, vem o handshake TLS, depois o protocolo continua cifrado. O trecho em texto claro antes da atualização é onde um atacante pode remover a oferta.\"><defs><marker id=\"tw-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">TLS implícito (LDAPS, 636)</text><rect x=\"20\" y=\"40\" width=\"90\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conectar</text><rect x=\"110\" y=\"40\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"195\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">handshake TLS</text><rect x=\"280\" y=\"40\" width=\"420\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"490\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">bind e consultas LDAP, cifrados</text><text x=\"20\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">STARTTLS (LDAP, 389)</text><rect x=\"20\" y=\"130\" width=\"90\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"65\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">conectar</text><rect x=\"110\" y=\"130\" width=\"170\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"195\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">texto claro: StartTLS?</text><rect x=\"280\" y=\"130\" width=\"140\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">handshake TLS</text><rect x=\"420\" y=\"130\" width=\"280\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">bind e consultas, cifrados</text><polyline points=\"195,200 195,168\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#tw-ah-amber)\"></polyline><text x=\"195\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">um atacante no caminho pode remover a oferta aqui</text><text x=\"195\" y=\"234\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a menos que o cliente exija TLS (-ZZ, --ssl-reqd)</text></svg>", "caption": "O TLS implícito não deixa trecho em claro; o STARTTLS tem um, antes da atualização.", "same": ["STARTTLS (LDAP, 389)"]}
```

## TLS implícito: uma porta separada

O cliente se conecta e começa um handshake TLS na hora, antes de o protocolo da aplicação dizer uma
palavra. HTTPS na 443, LDAPS na 636, IMAPS na 993 e envio SMTP na 465 funcionam assim. Não há nenhum
momento em que a conexão esteja sem cifragem, então não há nada a remover.

## STARTTLS: uma atualização na mesma porta

O cliente se conecta à porta comum, o protocolo começa em texto claro, e o cliente manda um comando,
`STARTTLS` no SMTP e no IMAP, a *operação estendida StartTLS* no LDAP, `AUTH TLS` no FTP, pedindo
para mudar. O handshake acontece e o protocolo continua cifrado. O OpenSSL consegue fazer a versão
LDAP sozinho:

```
ana@lab:~/lab$ echo | openssl s_client -connect ldap.vereda.example:3389 -starttls ldap -CAfile pki/root.pem -verify_hostname ldap.vereda.example 2>&1 | grep -E '^(New|Verif)'
Verification: OK
Verified peername: ldap.vereda.example
New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
Verify return code: 0 (ok)
```

O resultado é a mesma conexão TLS 1.3 da aula 10, verificada contra a raiz da Vereda e o nome do
diretório.

## A fraqueza de uma atualização opcional

Antes da atualização, a conversa está em texto claro e nada a protege. Um atacante no caminho pode
remover a oferta de STARTTLS do servidor, ou responder ao pedido do cliente com um erro, e um cliente
que trata a cifragem como opcional segue sem cifragem, achando que o servidor simplesmente não a
oferece. Isso é um ataque de **remoção de STARTTLS** (*STARTTLS stripping*), e ele já foi visto
contra e-mail em redes reais. As defesas são todas variações de uma regra, **tornar a atualização
obrigatória**:

- clientes configurados para recusar se o TLS não for estabelecido: `--ssl-reqd` no curl (seção 02),
  `-ZZ` nas ferramentas do OpenLDAP (próxima seção), `smtp_tls_security_level = encrypt` no Postfix;
- servidores que se recusam a autenticar antes do TLS, como o diretório da Vereda faz a seguir;
- para e-mail entre organizações, o **MTA-STS** e o **DANE**, que publicam o fato de que um domínio
  exige TLS, para que uma oferta removida seja percebida;
- onde houver escolha, o **TLS implícito**, que a RFC 8314 recomenda para clientes de e-mail
  justamente porque não há nada a remover.
