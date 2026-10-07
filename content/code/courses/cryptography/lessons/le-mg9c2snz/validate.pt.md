---
title: Conferir o servidor antes de dizer qualquer coisa
version: 1
---

**Tudo na seção anterior depende de duas linhas do perfil, `ca_cert` e `domain_suffix_match`.
Qualquer um consegue montar um ponto de acesso que anuncia `Vereda-Equipe` e um servidor RADIUS
atrás dele. A única coisa que diz a um notebook que ele chegou ao servidor da Vereda, e não àquele, é
o certificado, e só se o notebook o conferir.** Esta seção aponta o mesmo notebook para um impostor,
duas vezes.

## O certificado que o notebook espera

O certificado RADIUS da Vereda é um certificado de servidor comum, da aula 9, emitido pela AC da
própria clínica para um nome só:

```
ana@lab:~/lab$ openssl x509 -in pki/radius.pem -noout -subject -issuer -ext subjectAltName,extendedKeyUsage
subject=C = BR, O = Vereda Fisioterapia, CN = radius.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
X509v3 Extended Key Usage: 
    TLS Web Server Authentication
X509v3 Subject Alternative Name: 
    DNS:radius.vereda.example
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/radius.pem
pki/radius.pem: OK
```

## Um impostor com os mesmos nomes

O laboratório tem um segundo servidor RADIUS, em 127.0.0.2, fazendo o papel de um ponto de acesso
falso no estacionamento. O certificado dele afirma todos os nomes que o da Vereda afirma, inclusive um
emissor chamado `Vereda Root CA`. Ele foi feito pela raiz impostora da aula 9, que qualquer um cria com
um comando:

```
ana@lab:~/lab$ openssl x509 -in pki/radius-impostor.pem -noout -subject -issuer -ext subjectAltName
subject=C = BR, O = Vereda Fisioterapia, CN = radius.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
X509v3 Subject Alternative Name: 
    DNS:radius.vereda.example
```

Com o perfil da seção anterior, o notebook o recusa antes de mandar qualquer coisa:

```
ana@lab:~/lab$ eapol_test -c peap.conf -a 127.0.0.2 -s lab-only-radius-secret | vcrypt eap-log
outer identity, in clear:  anonymous@vereda.example
method:                    PEAP
TLS version:               TLSv1.2
server certificate:        depth 0  /C=BR/O=Vereda Fisioterapia/CN=radius.vereda.example
                           depth 0  name DNS:radius.vereda.example
certificate REFUSED:       depth 0, unable to get local issuer certificate
                           alert sent to the server: unknown CA
result:                    FAILURE
```

Os nomes bateram. A **assinatura**, não: nenhuma cadeia levava deste certificado à raiz em
`pki/root.pem`, então o handshake TLS terminou com um alerta `unknown CA`. A identidade interna e a
troca MSCHAPv2 nunca saíram do notebook. Esse é o resultado a buscar, e ele não custa nada na hora em
que acontece. A pessoa vê uma rede que não quis conectar.

Agora o mesmo notebook com um perfil descuidado, o que uma pessoa acaba tendo depois de ir clicando
numa tela de configuração. A única diferença são as duas linhas:

```
ana@lab:~/lab$ diff peap.conf peap-lax.conf
9,10d8
< 	ca_cert="pki/root.pem"
< 	domain_suffix_match="radius.vereda.example"
```

```
ana@lab:~/lab$ eapol_test -c peap-lax.conf -a 127.0.0.2 -s lab-only-radius-secret | vcrypt eap-log
outer identity, in clear:  anonymous@vereda.example
method:                    PEAP
TLS version:               TLSv1.2
server certificate:        depth 0  /C=BR/O=Vereda Fisioterapia/CN=radius.vereda.example
                           depth 0  name DNS:radius.vereda.example
inside the tunnel:         inner identity sent
                           MSCHAPv2 challenge answered
result:                    FAILURE
```

**O notebook aceitou o certificado do impostor, abriu o túnel até ele e respondeu ao desafio
MSCHAPv2.** O resultado diz `FAILURE` só porque este impostor não conhecia a senha da ana e não
conseguiu completar a troca. Ele não precisava. Agora ele tem um desafio e uma resposta calculados a
partir daquela senha, que a seção anterior disse que dá para testar contra palpites offline, e a dona
do notebook não viu nada pior que uma rede que não conectou.

## Por que as duas linhas

- **Só o `ca_cert`** aceita qualquer certificado que encadeie até aquela raiz. Com a raiz privada da
  Vereda, isso basta na prática. Com a lista de ACs públicas do sistema no lugar dela, aceitaria
  qualquer certificado que qualquer uma daquelas centenas de autoridades tivesse emitido para
  qualquer nome.
- **Só o `domain_suffix_match`** confere um nome sem cadeia nenhuma por trás, e o impostor tinha o
  nome certo. Um nome não prova nada até uma assinatura confiável responder por ele, que era todo o
  argumento da aula 9.
- **Juntas** elas dizem: um certificado para este nome, emitido por esta AC. Usar uma AC privada que
  não emite nada além do certificado RADIUS estreita ainda mais.

## Fazer o perfil chegar a todo aparelho

O ponto fraco nunca é o servidor. É o perfil em cada aparelho, e as telas de configuração dos
principais sistemas operacionais facilitam errar. O Windows pergunta se deve "conectar" quando
encontra um certificado de servidor desconhecido, o Android já ofereceu "não validar" como opção, e a
resposta a "você confia nisto?" é sempre sim. A defesa é **tirar a pergunta**:

- Notebooks e celulares gerenciados recebem o perfil de Wi-Fi do sistema de gestão de aparelhos, com
  a AC e o nome do servidor já preenchidos e a pergunta desligada. No Windows isso significa **Verify
  the server's identity by validating the certificate**, o nome do servidor em **Connect to these
  servers**, a raiz da Vereda marcada em **Trusted Root Certification Authorities** e **Don't prompt
  user to authorize new servers**.
- Aparelhos que não podem ser gerenciados entram numa rede separada, nunca na da equipe.
- Onde todo aparelho é gerenciado, o **EAP-TLS** tira a senha da história: um cliente que conversa
  com um impostor entrega a ele um certificado, que é público de qualquer jeito, e nada para chutar.

Do lado da rede, um monitoramento sem fio que alerta para qualquer ponto de acesso anunciando
`Vereda-Equipe` a partir de um endereço de hardware desconhecido encontra o impostor que os perfis
derrotam.
