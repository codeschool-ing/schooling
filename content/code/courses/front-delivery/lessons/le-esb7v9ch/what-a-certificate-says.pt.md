---
title: O que um certificado diz, e como um host consegue um
version: 1
---

**Um certificado TLS é uma declaração assinada de que uma chave pública pertence a um nome, e o HTTPS só
vale o que valem os motivos do navegador para acreditar na assinatura.** Ele não diz que o site é seguro,
honesto ou digno da sua confiança; diz que quem responde por `example.com` tem a chave privada que
corresponde à do certificado, e que uma autoridade em que o navegador confia conferiu isso antes de
assinar.

A imagem comum é o cadeado como selo de aprovação. É uma promessa bem mais estreita: **a conexão é com o
nome da barra de endereço, e ninguém no meio consegue lê-la ou alterá-la.** Um site de phishing com um
certificado perfeitamente válido para o próprio nome parecido ganha o mesmo cadeado.

## O que há dentro de um

| campo | guarda |
|---|---|
| subject alternative names | os nomes para os quais o certificado vale: `example.com`, `www.example.com` |
| issuer | a autoridade que o assinou |
| validade | uma data de início e uma de fim; navegadores o recusam fora delas |
| chave pública | a metade do par de chaves cuja outra metade o servidor prova que tem |
| assinatura | a do emissor, sobre tudo o que está acima |

O navegador confere a assinatura contra uma autoridade da própria lista de confiança, através dos
certificados intermediários que o servidor mandar, e confere se o nome que ele pediu está entre os subject
alternative names. Um certificado para `www.example.com` não cobre `example.com`; cada nome em que o site
responde precisa estar listado.

## Como um host consegue um em segundos

Todo host deste curso obtém certificados automaticamente, de autoridades como a Let's Encrypt, por um
protocolo chamado **ACME**. A pergunta da autoridade é sempre a mesma, *você controla este nome?*, e há
dois jeitos de responder:

- **HTTP-01**: a autoridade pede um arquivo em
  `http://example.com/.well-known/acme-challenge/<token>`, e o host, para onde o nome já aponta, serve o
  conteúdo esperado. É por isso que os registros DNS vêm primeiro: até o nome apontar para o host, o host
  não consegue responder à pergunta.
- **DNS-01**: a autoridade pede um registro `TXT` em `_acme-challenge.example.com`. Um host que cuida do
  seu DNS consegue criá-lo; é o único jeito de obter um certificado para um nome curinga como
  `*.example.com`.

**Certificados expiram, e a vida deles fica cada vez mais curta.** A Let's Encrypt os emite por 90 dias,
e as regras conjuntas de navegadores e autoridades marcaram para o máximo de qualquer certificado encolher
ano a ano, até 47 dias em 2029. Vidas curtas só são suportáveis porque a renovação é automática, e esse é
o motivo mais forte para deixar o host cuidar dos certificados em vez de enviar um à mão.

## Para onde esta aula vai agora

Uma autoridade pública não assina nada para um nome que não está na internet, então o resto desta aula
faz o que organizações fazem para nomes internos: cria **uma autoridade própria**, assina com ela um
certificado para `planner.test` e diz ao `curl` para confiar nessa autoridade, e em mais nenhuma. Antes,
na próxima seção, o host aprende a falar HTTPS.
