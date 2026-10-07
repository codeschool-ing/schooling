---
title: Para guardar um segredo, use a chave pública do destinatário
version: 1
---

**Quem quer enviar um segredo o cifra com a chave pública do destinatário, e só a chave privada do
destinatário consegue decifrá-lo.** O remetente não precisa de nada secreto. Essa é a metade da
criptografia assimétrica que resolve o problema da aula 1: qualquer um pode mandar ao serviço de
prontuários da Vereda uma carta que só o serviço consegue ler, sem nunca ter compartilhado uma
chave com ele.

Nesta aula, o par `rsa-3072` do laboratório representa esse serviço. A chave pública dele é
publicada; a privada nunca sai do serviço.

## Cifrando para o serviço

A Ana cifra a carta de encaminhamento de 170 bytes com a chave pública do serviço, duas vezes,
usando RSA com preenchimento OAEP (o preenchimento que a aula 2 exigiu):

```
ana@lab:~/lab$ cat data/referral.txt | wc -c
170
ana@lab:~/lab$ openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in data/referral.txt -out ref1.rsa
ana@lab:~/lab$ openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in data/referral.txt -out ref2.rsa
ana@lab:~/lab$ wc -c ref1.rsa ref2.rsa; cmp -s ref1.rsa ref2.rsa || echo "the two ciphertexts differ"
384 ref1.rsa
384 ref2.rsa
768 total
the two ciphertexts differ
```

Duas coisas a notar. Cada texto cifrado tem **384 bytes**, o tamanho do módulo de 3072 bits,
qualquer que seja o tamanho da carta. E os dois textos cifrados são **diferentes**, embora a carta
e a chave sejam as mesmas: o OAEP mistura bytes aleatórios novos em cada cifragem, e é exatamente
isso que o torna seguro onde o RSA cru da aula 2 não era. Um observador não consegue perceber que a
mesma carta foi enviada duas vezes.

O serviço decifra com a chave privada:

```
ana@lab:~/lab$ openssl pkeyutl -decrypt -inkey keys/rsa-3072.key -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in ref1.rsa
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
```

A Ana não conseguiria fazer isso. Ela tem a carta, claro, mas não tem a chave privada, então depois
de cifrar ela não consegue ler de volta o próprio texto cifrado. Nem quem o interceptar.

## O RSA cifra pouco, e tudo bem

O arquivo de agendamentos tem 512 bytes. O RSA o recusa:

```
ana@lab:~/lab$ openssl pkeyutl -encrypt -pubin -inkey keys/rsa-3072.pub -pkeyopt rsa_padding_mode:oaep -pkeyopt rsa_oaep_md:sha256 -in data/slots.dat -out slots.rsa 2>&1 | grep -o "data too large for key size"
data too large for key size
```

Com uma chave de 3072 bits e OAEP sobre SHA-256, o máximo que o RSA consegue cifrar numa operação
são 318 bytes: os 384 bytes do módulo, menos o que o preenchimento ocupa. O RSA também é milhares
de vezes mais lento que o AES. Por isso ninguém cifra arquivos com RSA. **A cifragem assimétrica é
usada para proteger uma chave, e a chave protege os dados**, que é o esquema híbrido da seção 04
desta aula.

## Guardar um segredo não prova nada sobre o remetente

Como a chave pública é pública, **qualquer um** poderia ter produzido aquele texto cifrado. Quando o
serviço decifra a carta, ele descobre o que a carta diz e nada sobre quem a enviou: a Ana, um
paciente ou alguém se passando pela clínica da Ana. A cifragem com uma chave pública dá
confidencialidade e só confidencialidade. Saber quem escreveu algo é o outro trabalho, e ele usa
as chaves ao contrário.
