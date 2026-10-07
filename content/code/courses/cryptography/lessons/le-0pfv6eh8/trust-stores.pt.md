---
title: O repositório de confiança, a lista que decide tudo
version: 1
---

**Um repositório de confiança (*trust store*) é a lista de certificados raiz que um sistema aceita
sem mais provas, e toda verificação de certificado termina numa delas.** Nada num certificado o torna
confiável por si só. Uma cadeia é confiável porque o topo dela está nesta lista, e a lista foi
escolhida por quem distribui o sistema operacional ou o navegador.

## De onde vem a lista

Nesta máquina Ubuntu a lista é a da Mozilla, distribuída pelo pacote `ca-certificates`:

```
ana@lab:~/lab$ ls /usr/share/ca-certificates/mozilla | wc -l
121
```

As raízes de cerca de cento e vinte organizações, entre elas a do Let's Encrypt (ISRG) e a da
DigiCert:

```
ana@lab:~/lab$ ls /usr/share/ca-certificates/mozilla | grep -i -E "isrg|digicert_global_root_g2"
DigiCert_Global_Root_G2.crt
ISRG_Root_X1.crt
ISRG_Root_X2.crt
```

Há quatro listas principais no mundo: a da **Mozilla** (usada pelo Firefox e pela maioria das
distribuições Linux), a da **Apple**, a da **Microsoft** e a **Chrome Root Store** do Google. Cada
uma funciona como um programa com requisitos escritos, auditorias e um processo público para admitir
e remover ACs. Um runtime Java, um ambiente Python com `certifi` ou uma imagem de contêiner podem ter
a própria cópia, e essa cópia é tão atual quanto a última vez em que foi atualizada.

## A raiz da Vereda não está nela

A raiz interna da Vereda, corretamente, não está na lista de ninguém. Verificada contra o
repositório do sistema, a cadeia do portal para na AC emissora, cujo emissor o repositório não
conhece:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -untrusted pki/issuing1.pem pki/portal.pem
C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
error 20 at 1 depth lookup: unable to get local issuer certificate
error pki/portal.pem: verification failed
```

Essa é a resposta esperada para uma AC interna numa máquina que nunca foi avisada dela. Clientes que
devem confiar nos serviços internos da Vereda recebem a raiz da Vereda instalada, por gerência de
configuração ou política de dispositivos. **Ninguém resolve isso desligando a verificação.**

## O intermediário que falta

Com a raiz certa, mas **sem** a AC emissora, a verificação também falha:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem pki/portal.pem
C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
error 20 at 0 depth lookup: unable to get local issuer certificate
error pki/portal.pem: verification failed
```

Esse é o erro da seção 03: o servidor mandou o próprio certificado e esqueceu o intermediário. Alguns
navegadores disfarçam isso buscando ou guardando intermediários, então um servidor mal configurado
funciona num notebook e falha no `curl`, num app de celular ou no cliente de API de outra empresa. A
correção é no servidor: servir a cadeia completa, como o `portal-chain.pem` do laboratório faz.

## Um nome não é uma chave

O laboratório também tem um impostor: um certificado raiz com **exatamente o mesmo nome** da raiz da
Vereda, gerado com outra chave. Os nomes batem e as impressões digitais não:

```
ana@lab:~/lab$ openssl x509 -in pki/root.pem -noout -subject -fingerprint -sha256; openssl x509 -in pki/impostor-root.pem -noout -subject -fingerprint -sha256
subject=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
sha256 Fingerprint=B9:6C:9C:AC:42:71:58:AE:0F:32:96:89:BA:90:D5:99:D0:15:56:BD:AA:AE:CE:10:57:86:0D:EB:EA:6F:D4:1F
subject=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
sha256 Fingerprint=23:4F:F0:80:71:ED:FE:74:09:B5:5A:B9:56:C5:9E:B2:81:35:B0:AB:BB:BD:33:50:BF:49:63:1A:3A:37:80:6A
```

Um certificado do portal assinado pelo impostor falha contra a raiz real, porque a verificação
confere a assinatura com a chave da raiz, não com o nome do emissor:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal-impostor.pem
C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
error 20 at 0 depth lookup: unable to get local issuer certificate
error pki/portal-impostor.pem: verification failed
```

Mas numa máquina em que alguém instalou a raiz impostora, o mesmo certificado forjado verifica:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/impostor-root.pem pki/portal-impostor.pem
pki/portal-impostor.pem: OK
```

**Quem consegue acrescentar uma raiz a um repositório de confiança consegue se passar por qualquer
site para aquela máquina.** É por isso que instalar uma raiz é um ato administrativo, por isso que
dispositivos corporativos que inspecionam tráfego TLS fazem isso de propósito e avisam, e por isso
que um malware que faz isso é grave. Auditar o repositório de confiança, nos servidores e nas
imagens que você monta, faz parte do endurecimento.
