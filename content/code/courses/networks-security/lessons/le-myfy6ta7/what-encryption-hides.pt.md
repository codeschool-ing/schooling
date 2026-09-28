---
title: O que a criptografia esconde do inspetor
version: 1
---

O Suricata escreveu um registro para cada protocolo que conseguiu analisar. Compare o do HTTPS com o
do HTTP puro:

```
root@fw:~# jq -c "select(.event_type==\"tls\") | .tls | {sni, version, subject, issuerdn}" /var/log/suricata/eve.json
{"sni":"www.example.com","version":"TLS 1.3","subject":null,"issuerdn":null}
root@fw:~# jq -c "select(.event_type==\"http\") | .http | {hostname, url, http_user_agent, status}" /var/log/suricata/eve.json
{"hostname":"192.168.20.10","url":"/","http_user_agent":"curl/8.5.0","status":200}
```

**Do HTTP puro o inspetor leu tudo**: o host, o caminho, o programa que fez a requisição, a resposta
do servidor. Do TLS 1.3 ele leu uma coisa só, o **SNI**, o nome do servidor que o cliente põe na
primeira mensagem para o servidor saber qual certificado apresentar. O `subject` e o `issuer` do
certificado são `null`, porque o TLS 1.3 criptografa o certificado também. No TLS 1.2 o certificado
passava pela rede em claro, e produtos de inspeção mais antigos dependiam de lê-lo.

```
root@fw:~# jq -c "select(.event_type==\"ssh\") | .ssh | {client: .client.software_version, server: .server.software_version}" /var/log/suricata/eve.json
{"client":"OpenSSH_9.6p1","server":"OpenSSH_9.6p1"}
```

O SSH é parecido: as linhas de saudação são legíveis, e tudo depois da troca de chaves não é.

Então, diante de tráfego criptografado, a DPI fica limitada a **metadados**: qual protocolo, qual
nome de servidor, quanto, com que frequência. Ainda é muita coisa. "SSH para um desconhecido na 443"
e "TLS para um nome numa lista de bloqueio" são decidíveis a partir disso. O que ela não consegue ver
é o que foi dito.

## Descriptografar de propósito: inspeção de TLS

Algumas organizações fecham essa lacuna com **inspeção de TLS** (*TLS inspection*), também chamada
de *break-and-inspect*. O firewall age como proxy: completa a conexão TLS com o cliente usando um
certificado que ele gera na hora para o nome pedido, assinado pela autoridade da própria empresa, e
abre uma segunda conexão TLS com o servidor real. No meio, ele lê tudo.

Isso só funciona porque todo computador gerenciado foi instruído a confiar na autoridade da empresa,
e os custos são reais:

- **O firewall passa a guardar em claro o tráfego de todos os funcionários**, bancos e saúde
  incluídos, e vira a máquina mais valiosa de se comprometer. A maioria das políticas isenta essas
  categorias.
- **Programas que fixam os seus certificados quebram**, e também tudo o que confere um certificado
  de cliente, porque o firewall não consegue apresentar a chave do cliente.
- **O firewall passa a decidir se o certificado do servidor real é válido.** Se a conferência dele
  for mais fraca que a de um navegador, os usuários estão mais seguros sem ele. A aula 13 mostra
  quanto custa um certificado não conferido.

Descriptografar ou não é uma decisão de política com peso legal: no Brasil, a LGPD se aplica ao que
o firewall lê. A aula 23 volta ao que pode ser guardado.
