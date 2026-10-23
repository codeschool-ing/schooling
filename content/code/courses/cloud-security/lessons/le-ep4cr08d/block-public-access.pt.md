---
title: Block Public Access: quatro chaves acima de toda concessão
version: 1
---

**O Block Public Access é uma camada acima das políticas e das ACLs: quando está ligado, uma
concessão pública é recusada quando alguém tenta escrevê-la, e ignorada se já estava lá.** Ele não
decide quem pode ler um bucket. Decide que ninguém pode torná-lo público, seja quem for e escreva o
que escrever, até a chave ser desligada.

Essa é a diferença entre uma proteção e uma regra. Uma regra é algo que as pessoas devem seguir; o
conserto rápido da aula 1 quebrou uma sem perceber. Uma proteção faz o conserto rápido falhar.

## As quatro chaves

| chave | o que faz, pela documentação da AWS |
|---|---|
| `BlockPublicAcls` | recusa qualquer requisição que acrescentaria uma ACL pública, ao bucket ou a um objeto |
| `IgnorePublicAcls` | ignora as ACLs públicas já existentes: continuam escritas e não concedem nada |
| `BlockPublicPolicy` | recusa uma política de bucket que conceda acesso público |
| `RestrictPublicBuckets` | limita um bucket com política pública aos serviços da AWS e à própria conta do dono |

Duas tratam de concessões **novas** e duas das **existentes**, e é por isso que são quatro. Um bucket
só com `BlockPublicAcls` continua respondendo a todos pela concessão que já tinha; o
`IgnorePublicAcls` é o que fecha isso. **Ligue as quatro**, que é o que a AWS faz em todo bucket novo
desde abril de 2023.

Elas existem em dois níveis. Num bucket, protegem aquele bucket. Na **conta**, pela API do S3
Control, protegem todo bucket dela, inclusive os criados no ano que vem por alguém que nunca ouviu
falar desta aula, e a configuração de um bucket não afrouxa a da conta. O nível da conta é o que vale
a pena ter; o do bucket é para a conta que ainda não pode tê-lo.

## No laboratório, e onde o moto para

Ligue as quatro no bucket de encaminhamentos e leia-as de volta:

```
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-referrals --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ aws s3api get-public-access-block --bucket clinic-referrals
{
    "PublicAccessBlockConfiguration": {
        "BlockPublicAcls": true,
        "IgnorePublicAcls": true,
        "BlockPublicPolicy": true,
        "RestrictPublicBuckets": true
    }
}
```

Agora peça, como o estranho, a carta cuja ACL ainda diz `AllUsers`, e depois tente escrever essa
concessão de novo:

```
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-referrals/referral-0412.txt
200
ana@laptop:~/aws$ aws s3api put-object-acl --bucket clinic-referrals --key referral-0412.txt --acl public-read
ana@laptop:~/aws$ aws s3api get-object-acl --bucket clinic-referrals --key referral-0412.txt --query "Grants[].[Grantee.URI,Permission]" --output text
None	FULL_CONTROL
http://acs.amazonaws.com/groups/global/AllUsers	READ
```

**O moto serviu a carta e aceitou a concessão nova. A AWS não teria feito nenhuma das duas coisas.**
Pela documentação dela, o `IgnorePublicAcls` faz a concessão existente não valer nada, então a
requisição anônima é recusada, e o `BlockPublicAcls` recusa o `put-object-acl` com `AccessDenied`. O
moto guarda o Block Public Access e não aplica nada dele, como diz a tabela da aula 1, e essas duas
respostas são documentação da AWS, não uma execução.

Isso vale ser visto por si só: **uma proteção que você só leu de volta não é uma proteção que você
testou.** Numa conta real, a requisição anônima acima é o teste, e é o mesmo comando.

## Mais duas configurações que fecham a mesma porta

**O Object Ownership em `BucketOwnerEnforced` desativa as ACLs por completo.** O dono do bucket é dono
de todo objeto, e nenhuma ACL, pública ou não, é consultada; o acesso vem só das políticas. Isso
remove três dos quatro caminhos da seção anterior numa configuração só, e é o padrão para buckets
novos desde abril de 2023 também. O moto guarda esta também e continua aplicando as ACLs.

As chaves no nível da conta se definem com `aws s3control put-public-access-block --account-id …`.
**Esse comando não foi executado aqui**: a linha de comando da AWS manda as requisições do S3 Control
para um endereço que começa com o id da conta, que um laboratório em `localhost` não responde. Numa
conta real é a primeira configuração a conferir.
