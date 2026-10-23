---
title: Contra o que a criptografia em repouso protege, e contra o que não protege
version: 1
---

**A criptografia em repouso protege os dados de quem chega ao disco sem passar pelo serviço. Ela não
faz nada contra uma requisição que o serviço responde.** O S3 decifra um objeto para toda requisição
que permite, então um objeto criptografado atrás de uma política pública é servido a um estranho em
texto claro, decifrado na saída.

A ideia errada é a da caixinha marcada: *o bucket é criptografado, então os dados estão seguros*.
Auditorias perguntam por ela, painéis ficam verdes por causa dela, e desde janeiro de 2023 a AWS
criptografa todo objeto novo no S3, alguém pedindo ou não. Se a criptografia em repouso impedisse
exposições, a aula 9 não teria incidente nenhum. Ela impede outra coisa.

## Dois jeitos de chegar aos dados

| quem | como chega aos dados | a criptografia em repouso o impede? |
|---|---|---|
| alguém com um disco, uma fita de backup ou uma cópia do armazenamento do provedor | por fora do serviço, direto nos bytes | **sim**: o que ele tem é texto cifrado sem a chave |
| alguém a quem o serviço responde: um usuário com permissão, uma chave roubada, ou qualquer um por uma política pública | pela própria API do serviço | **não**: o serviço decifra para ele, porque foi mandado |

A primeira linha é real e é a metade do trabalho que cabe ao provedor, que a aula 2 pôs do lado dele
da linha: discos que saem de um data center, um backup extraviado, um engenheiro com acesso físico. A
segunda linha é onde aconteceu todo incidente da aula 9, e **ela é decidida por permissões, não por
criptografia**. Quem defende e confunde as duas acaba com painéis verdes e buckets públicos.

## Criptografado e público, no seu laboratório

Inicie o moto vazio no primeiro terminal e dê à clínica um bucket com um objeto gravado sob a
criptografia do próprio S3. Um arquivo faz o papel de um prontuário:

```sh
printf 'patient: Maria Souza\nallergy: penicillin\n' > record.txt
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-records
ana@laptop:~/aws$ aws s3api put-object --bucket clinic-records --key maria-souza.txt --body record.txt --server-side-encryption AES256 --query ServerSideEncryption
"AES256"
```

`"AES256"` é o S3 dizendo que guardou o objeto cifrado, sob uma chave que o próprio S3 possui e
administra. Agora o erro da aula 1, uma política de bucket que deixa todo mundo ler, e o pedido do
estranho:

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket clinic-records --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::clinic-records/*"}]}'
ana@laptop:~/aws$ curl -s -w "%{http_code}\n" http://localhost:4567/clinic-records/maria-souza.txt
patient: Maria Souza
allergy: penicillin
200
```

**Criptografado em repouso, e servido em texto claro a uma requisição sem identidade nenhuma.** Nada
deu errado com a criptografia; ela fez o seu trabalho no disco, e o S3 a desfez para uma requisição
que a política permitia. A AWS responderia do mesmo jeito para um objeto cifrado com a chave do
próprio S3: a transcrição é do moto, e o comportamento é o do S3.

Tire a política antes de seguir:

```
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket clinic-records
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-records/maria-souza.txt
403
```

## Então quanto vale uma chave?

Se o S3 decifra para qualquer um a quem serve, a pergunta útil é **quem mais precisa concordar antes
que ele decifre**. Com a chave do próprio S3, ninguém: permissão no bucket é permissão no texto claro.
Com uma chave que a clínica administra no KMS, usar a chave é uma segunda permissão, escrita num
segundo lugar, e uma requisição precisa ter as duas. A próxima seção traz os três tipos de chave, e a
seguinte mostra essa segunda permissão funcionando.
