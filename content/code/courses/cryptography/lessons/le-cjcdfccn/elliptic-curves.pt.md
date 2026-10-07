---
title: Curvas elípticas, a mesma ideia com chaves menores
version: 1
---

**A criptografia de curvas elípticas troca o problema da fatoração do RSA por outro problema de
mão única, e precisa de chaves com cerca de um décimo do tamanho para a mesma força.** Uma chave de
curva de 256 bits equivale a uma chave RSA de 3072 bits. É por isso que protocolos novos, celulares
e cartões inteligentes usam curvas, e por isso o certificado do servidor do laboratório, na aula 8,
traz uma.

## Um número e um ponto

Uma curva elíptica, na criptografia, é um conjunto de pontos definido por uma equação sobre um
corpo finito, e esses pontos podem ser "somados" uns aos outros por uma regra fixa. Um ponto da
curva, chamado **gerador** `G`, é fixado pelo padrão. Então:

- a **chave privada** é um número `k`, sorteado abaixo do número de pontos;
- a **chave pública** é o ponto `k × G`, que é `G` somado a si mesmo `k` vezes por um atalho que
  leva algumas centenas de passos mesmo quando `k` tem 77 dígitos.

Ir para a frente, de `k` para `k × G`, é rápido. Voltar, do ponto para `k`, é o **problema do
logaritmo discreto em curvas elípticas**, e para uma curva bem escolhida os melhores métodos
conhecidos levam cerca de 2¹²⁸ passos a 256 bits. A chave P-256 do laboratório mostra as duas
metades:

```
ana@lab:~/lab$ openssl pkey -in keys/p256.key -noout -text
Private-Key: (256 bit)
priv:
    cc:ed:82:e0:7b:de:b0:17:25:72:95:27:2b:a8:9e:
    aa:1d:a1:e0:a3:ec:e1:f7:86:c5:9a:66:fb:90:62:
    99:c8
pub:
    04:ec:ad:7f:5a:17:42:6d:02:3c:45:bc:46:05:a7:
    30:88:6d:9d:eb:05:20:40:71:a5:45:6d:d8:a2:16:
    b0:be:4f:e3:80:7c:1e:0e:d8:4e:bc:7a:53:a9:72:
    df:4e:7f:a9:9c:50:10:7b:e6:df:3b:51:47:d9:50:
    29:73:24:41:dd
ASN1 OID: prime256v1
NIST CURVE: P-256
```

`priv` é o número `k`: 32 bytes, 256 bits. `pub` é o ponto: o `04` inicial diz que ele está escrito
*sem compressão*, seguido das duas coordenadas, 32 bytes de x e 32 bytes de y, 65 bytes no total.
As duas últimas linhas nomeiam a curva, e essa é a decisão que um defensor de fato toma.

## Escolha uma curva nomeada, nunca uma própria

Ninguém que usa curvas escolhe a própria equação. Um pequeno conjunto de **curvas nomeadas** vem
sendo examinado há anos, e escolher uma delas é a decisão inteira:

| curva | onde é usada | observações |
|---|---|---|
| **P-256** (`prime256v1`, `secp256r1`) | certificados TLS, cartões inteligentes, a maioria dos sistemas corporativos | padrão do NIST; a mais implantada |
| **X25519** | troca de chaves no TLS 1.3, SSH, Signal, WireGuard | projetada para ser difícil de implementar errado |
| **Ed25519** | assinaturas em chaves SSH, assinatura de pacotes, as chaves `ed25519-*` do laboratório | assinaturas determinísticas, abaixo |
| **secp256k1** | Bitcoin e Ethereum | fora deles, raramente há motivo para escolhê-la |

X25519 e Ed25519 são a mesma curva de base, a Curve25519, usada para dois trabalhos diferentes: a
X25519 combina uma chave (aula 7), a Ed25519 assina (aulas 3 e 6). Elas não são intercambiáveis, e
uma biblioteca se recusa a usar uma chave no lugar da outra.

## A falha que é das curvas

A falha típica do RSA era a falta de preenchimento. O ECDSA, o algoritmo de assinatura usado com a
P-256, tem a sua, e ela já causou desastres reais: **toda assinatura ECDSA precisa de um número
aleatório secreto e novo, e um número repetido ou previsível revela a chave privada** a quem tiver
duas assinaturas. A chave de assinatura do PlayStation 3 da Sony foi recuperada em 2010 porque o
mesmo número era usado em todas as assinaturas, e carteiras Android perderam bitcoins em 2013
porque um gerador de números aleatórios com defeito produzia repetições.

A defesa é tirar a aleatoriedade das mãos de quem assina. **A Ed25519 deriva esse número de forma
determinística** da chave privada e da mensagem, então a mesma mensagem dá sempre a mesma
assinatura e nenhum gerador consegue traí-la. A RFC 6979 faz o mesmo para o ECDSA, e as
bibliotecas modernas a usam. Se você está escolhendo um algoritmo de assinatura para algo novo, a
Ed25519 é o padrão com menos jeitos de dar errado.

## O que as curvas não mudam

As curvas mudam o tamanho das chaves e a velocidade, não a forma do que este curso ensina. Continua
havendo uma metade pública e uma metade privada, a metade pública continua sem dizer quem é o dono,
e a metade privada continua sem poder sair das mãos do dono. As curvas também compartilham com o
RSA a fraqueza diante de um computador quântico grande, assunto da última seção da aula 7.
