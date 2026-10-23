---
title: Uma conta com quatro falhas dentro
version: 1
---

**Antes de escrever um scanner, dê a ele algo para achar.** Esta seção monta no seu laboratório uma
cópia pequena da conta da clínica, com quatro falhas postas de propósito, cada uma uma aula deste
curso deixada por fazer. Inicie o moto no primeiro terminal, vazio, e leia o `env.sh` nos dois. A
verificação do moto fica desligada: nada aqui é sobre uma recusa.

Estes comandos a montam. Cole-os no segundo terminal como estão; nenhum imprime nada que você precise
ler:

```sh
aws iam create-user --user-name caio > /dev/null
aws iam create-user --user-name bia > /dev/null
aws iam enable-mfa-device --user-name caio --serial-number arn:aws:iam::123456789012:mfa/caio \
  --authentication-code1 123456 --authentication-code2 654321
for b in clinic-records clinic-web clinic-exports; do
  aws s3api create-bucket --bucket "$b" --create-bucket-configuration LocationConstraint=sa-east-1 > /dev/null
done
for b in clinic-records clinic-web; do
  aws s3api put-bucket-encryption --bucket "$b" --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
done
aws s3api put-bucket-policy --bucket clinic-web --policy \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::clinic-web/*"}]}'
sg=$(aws ec2 create-security-group --group-name booking-admin --description "booking admin" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null
```

O que isso deixou para trás, falha por falha:

| falha | onde | que aula diz por que importa |
|---|---|---|
| um bucket que todo mundo lê | `clinic-web`, pela política dele | 9 |
| um bucket sem criptografia padrão | `clinic-exports` | 11 |
| SSH aberto para a internet inteira | o security group `booking-admin` | 8 |
| o usuário de uma pessoa sem segundo fator | `bia`, que não tem dispositivo de MFA | 6 |

**Uma das quatro não é erro.** O `clinic-web` guarda o site público da clínica, as páginas e o
logotipo, e um site é feito para ser lido por estranhos. Um scanner não tem como saber disso, e a
seção depois da próxima decide o que fazer a respeito.

**O segundo fator do caio foi aceito com dois códigos inventados.** O `enable-mfa-device` pede dois
códigos seguidos do dispositivo que está sendo registrado, e a AWS os confere contra o segredo do
dispositivo antes de registrar qualquer coisa. O moto registra o dispositivo sem conferir, o que basta
para um laboratório cujo ponto é que o dispositivo existe. **Não executado contra a AWS**, onde esses
dois números seriam recusados.

Pergunte à conta o que ela tem agora, do jeito que uma pessoa faria antes de existir qualquer
ferramenta:

```
ana@laptop:~/aws$ aws s3api list-buckets --query "Buckets[].Name" --output text
clinic-records	clinic-web	clinic-exports
ana@laptop:~/aws$ aws iam list-users --query "Users[].UserName" --output text
caio	bia
ana@laptop:~/aws$ aws ec2 describe-security-groups --query "SecurityGroups[].[GroupId,GroupName]" --output text
sg-4201c37563e313c56	default
sg-d877b106d3b8c910b	booking-admin
```

Três listas, e nenhuma diz qual entrada está errada. **É essa a lacuna que um scanner preenche**: as
listas são completas e não dizem nada, e as regras estão na sua cabeça. O laço da aula 1 pelas 38
regiões mostrou o mesmo sobre tamanho. Aqui há três buckets, dois usuários e dois grupos, e lê-los a
olho já custa mais seis chamadas. A conta de verdade da clínica tem mais de tudo.
