---
title: A correção, e a prova de que ela se sustenta
version: 1
---

**Corrigir um bucket exposto são três coisas, em ordem: tirar a concessão, ligar a proteção para que
ela não volte, e perguntar de novo como o estranho.** A primeira é o que as pessoas fazem. A segunda
é o que segura a próxima pessoa. A terceira é a única que diz se as duas primeiras funcionaram.

A ideia errada é que a correção é apagar o bucket, ou o arquivo. Alguém precisava daquele arquivo
compartilhado, e foi assim que a concessão chegou lá; tire o compartilhamento sem dar um jeito melhor
e a concessão volta na semana que vem, num bucket de que você nem ouviu falar. Então cada correção
abaixo vem com o jeito como o trabalho deveria ter sido feito.

## Tirar as concessões

A carta e o relatório perdem cada um a sua concessão:

```
ana@laptop:~/aws$ aws s3api put-object-acl --bucket clinic-referrals --key referral-0412.txt --acl private
ana@laptop:~/aws$ aws s3api put-object-acl --bucket clinic-reports --key report-2026-09.csv --acl private
```

**O hospital ainda precisa da carta.** Um link que funciona para um destinatário, por alguns dias, é
uma URL pré-assinada, e a aula 10 faz uma. O relatório da bia vai para pessoas de dentro da clínica,
que têm credenciais próprias e não precisam de uma concessão a toda conta AWS do mundo.

## Ligar as proteções

O bucket de relatórios ganha as quatro chaves, e todo bucket ganha o `BucketOwnerEnforced`, para que
nenhuma ACL volte a ser consultada:

```
ana@laptop:~/aws$ aws s3api put-public-access-block --bucket clinic-reports --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
ana@laptop:~/aws$ for b in clinic-referrals clinic-reports clinic-records; do aws s3api put-bucket-ownership-controls --bucket "$b" --ownership-controls "Rules=[{ObjectOwnership=BucketOwnerEnforced}]"; done
```

Numa conta real a ordem importa: a AWS recusa o `BucketOwnerEnforced` num bucket cuja ACL de bucket
ainda concede acesso a alguém além do dono, pela documentação dela, então as concessões saem
primeiro, como aqui. Na AWS, as chaves no nível da conta da seção anterior também seriam ligadas.

## Perguntar de novo

```
ana@laptop:~/aws$ python3 public_buckets.py
clinic-referrals
    nothing found
clinic-reports
    nothing found
clinic-records
    nothing found
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-referrals/referral-0412.txt
403
```

**Nada encontrado, três vezes, e a carta recusada a uma requisição sem identidade.** Essa última
parte é a prova, e neste laboratório ela se apoia em a concessão ter saído: o moto ainda serviria a
carta se a ACL dela fosse pública, com proteção ou sem. Na AWS, a proteção seguraria mesmo que alguém
pusesse a concessão de volta, e o mesmo comando, rodado amanhã, é como você saberia.

## Um bucket que precisa ser público

Algum conteúdo é para todos: o site da clínica, o horário de atendimento, um folheto. O padrão
documentado pela AWS mantém até esse bucket privado. **Uma distribuição do CloudFront lê o bucket por
meio de um origin access control**, e a política do bucket permite essa distribuição e mais ninguém.
O público recebe os arquivos pelo CloudFront; ninguém consegue pedir direto ao bucket; e a proteção no
nível da conta fica ligada para todo bucket, sem exceção para lembrar. Esse padrão não foi executado
aqui, já que o moto não serve CloudFront.

Rode o verificador num cronograma, não uma vez. Um achado que aparece na terça foi uma mudança que
alguém fez na segunda, e a aula 15 trata de descobrir quem.
