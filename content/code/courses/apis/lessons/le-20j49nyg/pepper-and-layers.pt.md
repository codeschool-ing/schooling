---
title: Um pepper, e as regras para a própria senha
version: 1
---

Mais duas camadas ficam em volta do hash. Um **pepper** protege os hashes guardados quando o banco
vaza sozinho. E as **regras para a senha** decidem o tamanho que a lista de palpites precisa ter até
chegar nela, coisa contra a qual hash nenhum pode fazer nada.

## Um pepper é uma chave que o banco não tem

Um pepper é um valor secreto, o mesmo para todas as senhas, guardado **fora** do banco: num arquivo
que só o servidor lê, ou num gerenciador de segredos. Antes do hash, a senha passa por um HMAC com o
pepper como chave, e assim o que o Argon2id recebe é um valor que ninguém calcula sem a chave.

A ideia errada é que ele seria um segundo salt. Um salt é público, fica na linha e é diferente em cada
linha; um pepper é secreto, fica em outro lugar e é o mesmo para todas. Ele só se paga num caso,
aquele em que o banco vaza e os segredos do servidor não: um backup do `shelf.db`, uma consulta que
devolveu demais. Nesse caso cada palpite contra cada linha precisa da chave antes, e a tabela sozinha
não serve para nada.

Uma chave, guardada onde só o dono a lê, e o HMAC que ela produz:

```
ana@api:~$ openssl rand -base64 32 > pepper.key && chmod 600 pepper.key && ls -l pepper.key
-rw------- 1 ana ana 45 Oct 10 01:23 pepper.key
ana@api:~$ printf %s 'correct horse battery staple' | openssl dgst -sha256 -hmac "$(cat pepper.key)"
SHA2-256(stdin)= 4d9e379010370ed56865994f32938e97ab0b2e7a49cfebd5be0979e774b39431
```

A mesma senha com outra chave dá um valor sem relação nenhuma, e essa é toda a propriedade:

```
ana@api:~$ printf %s 'correct horse battery staple' | openssl dgst -sha256 -hmac 'a different key'
SHA2-256(stdin)= bc4c043da0c136b6bfc363de1b0b9ad1ca9ba6a7537834a76f7c7896d6f125c7
```

No `passwords.py` isso seria uma função, `hmac.digest(key, password.encode(), "sha256")`, chamada
antes do `HASHER.hash` e antes do `HASHER.verify`. Ela não está no arquivo nesta lição, porque traz
um custo de que o arquivo ainda não precisa: **um pepper não pode ser trocado**. Todo hash guardado
depende dele, então um pepper novo significa todo usuário definindo uma senha nova. A folha da OWASP
o chama de defesa em profundidade e diz com todas as letras que, sozinho, ele não acrescenta nada.

## Senhas que já vazaram

Uma senha longa não ajuda se estiver em toda lista. A SP 800-63B do NIST exige que uma senha nova seja
comparada com uma lista de senhas conhecidas por serem comuns ou já vazadas, e recusada se estiver
nela.

Uma lista conhecida de senhas vazadas pertence a um serviço público, o Have I Been Pwned, e é
consultada com **k-anonimato**: o servidor nunca fica sabendo a senha, nem o hash inteiro dela. Você
calcula o SHA-1 da senha:

```
ana@api:~$ printf %s sunshine | sha1sum
8d6e34f987851aa599257d3831a1af040886842f  -
```

e envia só os cinco primeiros caracteres, `8d6e3`, para `https://api.pwnedpasswords.com/range/8d6e3`
(não executado aqui: a máquina em que esta lição foi gravada não tem rede). A resposta é cada sufixo
de hash que começa com esses cinco caracteres, centenas deles, cada um com uma contagem, e o seu
servidor procura os 35 caracteres restantes nessa lista por conta própria. O serviço vê um prefixo
comum a centenas de senhas e não tem como saber sobre qual você perguntou.

## O que o NIST pede da própria senha

A SP 800-63B do NIST, na quarta revisão, traz regras que surpreendem quem se lembra das antigas:

| regra | o que diz |
|---|---|
| comprimento | pelo menos 15 caracteres quando a senha é o único fator; 8 quando é um de dois |
| máximo | permitir pelo menos 64 caracteres |
| composição | não exigir misturas de maiúsculas, dígitos e símbolos |
| expiração | não forçar trocas periódicas; forçar uma quando houver evidência de comprometimento |
| lista de bloqueio | recusar senhas comuns ou sabidamente vazadas |
| caracteres | aceitar todo caractere imprimível, espaços e Unicode |

**É o comprimento que deixa uma lista de palpites longa, e regras de composição mais ensinam todo
mundo os mesmos poucos padrões**, e por isso elas saíram. O `passwords.py` impõe a primeira regra e
mais nada; um cadastro de verdade também consultaria a lista de bloqueio. E a segunda regra bate de
frente com o limite do bcrypt: 64 caracteres com acentos podem passar de 72 bytes, mais um motivo para
a shelf usar o Argon2id.
