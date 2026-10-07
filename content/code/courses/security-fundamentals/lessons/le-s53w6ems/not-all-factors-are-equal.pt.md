---
title: Nem todo segundo fator é igual
version: 1
---

Qualquer segundo fator é muito melhor que nenhum. Eles não são igualmente bons, porém, e as diferenças
vêm de como cada um pode ser derrotado. Quatro de uso comum, do mais fraco ao mais forte:

| fator | como funciona | como é derrotado |
|---|---|---|
| **código por SMS** | um código mandado por mensagem para um número | **troca de chip** (*SIM swap*): o atacante convence a operadora a passar o número para o chip dele, e recebe as mensagens |
| **aprovação por push** | o app pergunta "é você?" e você toca em sim | **fadiga de MFA**: o atacante dispara pedido atrás de pedido até a vítima tocar em sim para fazer parar |
| **código TOTP** | os seis dígitos das seções anteriores | uma página de login falsa pede o código também e o usa dentro dos trinta segundos |
| **chave de segurança ou passkey** | um aparelho ou o celular prova que tem uma chave, para aquele site exato | a chave só responde ao endereço do site verdadeiro, então uma página falsa não recebe nada utilizável |

A terceira linha é a importante de entender. O TOTP para uma senha roubada **mês passado** num vazamento.
Ele não para uma página de phishing **agora**: a vítima digita a senha e depois o código na página falsa,
que repassa os dois ao site verdadeiro em segundos. O atacante nunca precisou do segredo, só de um código
fresco. Um código de uso único é "phishável" porque um humano o lê e o digita onde lhe pedirem.

### Autenticação resistente a phishing

A última linha funciona de outro jeito. Uma **chave de segurança** (hardware, como uma chave USB) ou uma
**passkey** (a mesma ideia guardada num celular ou notebook) usa os padrões **FIDO2** e **WebAuthn**. A
chave guarda uma chave privada por site e prova a posse assinando um desafio, e o navegador inclui o
endereço do site no que é assinado. Um site falso num endereço parecido recebe uma assinatura para o
endereço errado, que o site verdadeiro rejeita. Não há código para o humano digitar no lugar errado,
então não há nada para phishing. A aula 3 de `cryptography` explica as chaves pública e privada por
baixo.

Por isso esses se chamam **resistentes a phishing**, e são o que as recomendações de segurança hoje
indicam para administradores e para tudo o que for valioso.

### Melhorando push e códigos

Aprovações por push melhoram com **correspondência de número** (*number matching*): a página de login
mostra um número e o app pede à pessoa que o digite, o que derrota a fadiga, porque tocar em sim para o
barulho parar deixa de funcionar. Um limite de quantos pedidos podem ser mandados em pouco tempo também
ajuda.

### O que a loja escolhe

Para as nove pessoas da equipe, um app autenticador com TOTP em toda conta é o primeiro passo, porque é
de graça e derrota a senha reaproveitada, que é o atacante realista da loja segundo a aula 2. Para as
contas de administradora da ana e para o acesso dos sócios ao banco, chaves de segurança, porque essas
são as contas que um e-mail de phishing direcionado miraria. SMS só onde um serviço não oferece nada
melhor, porque um segundo fator fraco ainda é um segundo fator.
