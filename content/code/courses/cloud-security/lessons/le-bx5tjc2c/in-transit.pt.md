---
title: Criptografia em trânsito, e como recusar as requisições sem ela
version: 1
---

**Criptografia em trânsito é TLS entre quem manda uma requisição e quem a responde. Na nuvem há dois
trechos diferentes a proteger: o que vai até a API do provedor e os que ligam as suas próprias
máquinas.** O primeiro cabe ao provedor oferecer e a você exigir. O segundo é inteiramente seu.

A ideia errada é a de que o tráfego dentro da nuvem é privado porque ninguém de fora o alcança. A
aula 6 do curso `cloud` montou redes cujas sub-redes privadas ninguém na internet alcança, e isso é
verdade. Isso não torna cifrado o tráfego entre duas máquinas suas; torna-o inalcançável numa
direção, o que é outra propriedade. Uma conexão de peering mal roteada, uma máquina comprometida na
mesma rede ou um engenheiro do próprio provedor estão todos do lado de dentro.

## O trecho até a API

Todo endpoint de API da AWS responde por HTTPS, e a documentação da AWS fixa o TLS 1.2 como o mínimo
que os endpoints aceitam. A linha de comando da AWS, os SDKs e o console usam isso, então as
requisições que você manda a uma conta real são cifradas sem você pedir. A aula 10 do curso
`cryptography` percorreu o que esse handshake faz e como ele falha.

**O seu laboratório é a exceção, e de propósito.** O `env.sh` aponta a linha de comando para
`http://localhost:4567`: HTTP puro, para um programa no mesmo computador, pela interface de loopback,
que nunca sai da máquina. Nada nele atravessa uma rede, então nada nele precisa de TLS; a mesma URL
apontada para outra máquina mandaria as suas requisições, chaves e assinaturas incluídas, às claras.

## Exigindo, bucket a bucket

O S3 é alcançável por HTTP puro além de HTTPS, por causa de clientes antigos. Um bucket pode recusar
toda requisição que não chegou por TLS, com uma chave de condição que a AWS define em toda
requisição, `aws:SecureTransport`, que vale `false` quando a requisição veio sem ele:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "TLSOnly",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::clinic-records",
        "arn:aws:s3:::clinic-records/*"
      ],
      "Condition": { "Bool": { "aws:SecureTransport": "false" } }
    }
  ]
}
```

Dois detalhes a fazem funcionar. **É um `Deny` com `"Principal": "*"`**, então ela vale para todo
chamador, administradores incluídos, e nenhum `Allow` em lugar nenhum a desfaz. E **ela nomeia o
bucket e os objetos dele como dois recursos**, porque `s3:*` cobre ações sobre os dois e um ARN sem
`/*` só casa com o bucket. Requisições por objetos sob uma chave do KMS já precisam de TLS, assim
como a seção das duas trancas disse que precisam de assinatura; esta política faz a mesma regra valer
para todo objeto do bucket. O moto guarda esta política e ignora a condição dela, então **o efeito
dela não foi executado aqui**; ele vem da documentação do S3 sobre essa chave.

## Os trechos entre as suas máquinas

Dentro de uma VPC, a criptografia é o que você configura:

- **um balanceador de carga** termina o TLS vindo da internet e depois ou encaminha HTTP puro às
  máquinas por trás dele, ou abre uma segunda conexão TLS até elas. A segunda custa um certificado em
  cada máquina e fecha a lacuna entre o balanceador e a aplicação;
- **uma conexão com banco de dados** só é cifrada se o cliente pedir e o servidor exigir. Bancos
  gerenciados oferecem uma configuração que recusa conexões sem criptografia, e em alguns motores ela
  começa desligada;
- **o tráfego entre serviços** dentro de uma rede é puro, a menos que algo o envolva. Uma malha de
  serviços, ou TLS na própria aplicação, são os dois caminhos.

Cada um desses é mais uma configuração, e o fio deste curso vale aqui também: **na nuvem, a
criptografia existe; se uma conexão a usa é uma configuração que alguém escolheu.**
