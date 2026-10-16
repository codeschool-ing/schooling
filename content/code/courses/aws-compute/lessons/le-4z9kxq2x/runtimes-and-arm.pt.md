---
title: Runtimes, Arm, e a imagem no lugar do zip
version: 1
---

`--runtime python3.12` parece uma versão do Python, e é mais do que isso. **Um runtime gerenciado é
uma versão da linguagem sobre um Amazon Linux específico, corrigida pela AWS e aposentada pela AWS
segundo um calendário publicado.** Você escolhe; a AWS mantém atualizado; e um dia a AWS para de
manter, que é a parte da escolha que tem data.

## O que o nome de um runtime promete

Os nomes vêm em famílias: `python3.12`, `python3.13`, `nodejs22.x`, `java21`, `dotnet8`,
`ruby3.3`, e `provided.al2023` para uma função que traz o próprio runtime, que é como Go e Rust
rodam no Lambda. `python3.12` é Python 3.12 sobre Amazon Linux 2023, os mesmos arquivos que a imagem
base da seção 02 traz.

**A AWS corrige um runtime gerenciado por baixo da sua função**, sem implantação nova: correções de
segurança do sistema operacional e da linguagem chegam sozinhas. Esse é quase todo o motivo para
usar um. É também o motivo da linha `LAMBDA_WARNING` no log do emulador na seção 02, que diz a quem
lê uma exceção não tratada para conferir se a versão do runtime mudou logo antes de os erros
começarem. As configurações de gerenciamento de runtime do Lambda decidem quando uma função recebe
uma atualização, e o padrão é automaticamente.

## A descontinuação, e o que o moto não recusa

Um runtime é **descontinuado** quando a versão da linguagem que ele traz chega ao fim do suporte da
comunidade; para o Python isso é cinco anos depois do lançamento, então o Python 3.12, lançado em
outubro de 2023, chega lá em outubro de 2028. A documentação da AWS lista uma data para cada
runtime, e três passos vêm depois dela. A partir da data de descontinuação o runtime não recebe mais
correções de segurança. Um tempo depois não se cria mais função nova com ele, e mais tarde ainda as
existentes não podem mais ser atualizadas. Uma função num runtime descontinuado continua rodando; só
roda sem correções.

O moto não mantém nada disso:

```
ana@laptop:~/aws$ aws lambda create-function --function-name old --runtime python2.7 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://greet/function.zip --query Runtime
"python2.7"
ana@laptop:~/aws$ aws lambda create-function --function-name typo --runtime python3.99 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://greet/function.zip --query Runtime
"python3.99"
```

**As duas funções existem no moto, e nenhuma poderia ser criada na AWS.** `python2.7` foi
descontinuado há anos e passou há muito tempo da data em que a criação é bloqueada; `python3.99` é
um erro de digitação de um runtime que nunca existiu, e a AWS o recusa com
`InvalidParameterValueException` e a lista de nomes que aceita. Nenhuma das duas recusas foi
executada aqui. **O que isso significa na prática** é que o runtime de uma função é uma dependência
com data de validade, como qualquer outra, e alguém precisa ser dono da atualização antes que o
calendário da AWS a imponha.

## x86 ou Arm

Toda função roda numa de duas arquiteturas, `x86_64` ou `arm64`, a segunda nos processadores
Graviton da AWS. A escolha é uma opção:

```
ana@laptop:~/aws$ aws lambda create-function --function-name greet-arm --runtime python3.12 --architectures arm64 --handler app.handler --role arn:aws:iam::123456789012:role/greet-role --zip-file fileb://greet/function.zip --query "[FunctionName,Architectures[0]]"
[
    "greet-arm",
    "arm64"
]
```

O moto registra e não roda nada, então o que vem a seguir é o preço, que é o motivo para olhar. O
bloco do Lambda na tabela de preços, em 16 de outubro de 2026:

```
ana@laptop:~/aws$ python3 prices.py lambda
AWS public price list, sa-east-1, USD, excluding tax

Lambda
  requests                                           0.2  per million
  duration, x86                             0.0000166667  per GB-second
  duration, Arm                             0.0000133334  per GB-second
  provisioned concurrency, x86              0.0000066372  per GB-second
  duration on provisioned, x86              0.0000154867  per GB-second
```

**Um gigabyte-segundo em Arm custa 0,0000133334 USD contra 0,0000166667 no x86, um quinto a
menos**; os pedidos custam o mesmo nos dois. Ponha um mês nisso: três milhões de invocações de uma
função de 512 MB que roda 120 ms cada são 3.000.000 × 0,120 s × 0,5 GB = 180.000 gigabytes-segundo.

| | x86 | Arm |
| --- | --- | --- |
| duração, 180.000 GB-s | 3,00 USD | 2,40 USD |
| pedidos, 3 milhões a 0,2 por milhão | 0,60 USD | 0,60 USD |
| mês | 3,60 USD | 3,00 USD |

A AWS também dá a toda conta uma cota mensal gratuita de pedidos e de duração do Lambda. Ela não
está na tabela de preços, e a conta acima a deixa de fora.

A economia só vale se a função rodar tão rápido em Arm, o que Python puro e a maior parte do código
interpretado fazem. **O que quebra é uma dependência compilada**: um wheel construído para x86, como
uma biblioteca de imagens ou de criptografia, não carrega em `arm64`, e o pacote precisa ser
construído para a arquitetura onde vai rodar. O emulador também não resolve essa questão num laptop
x86, porque a imagem que ele baixou é `linux/amd64`, como a seção 02 imprimiu. Num Mac com Apple
silicon o mesmo `docker pull` traz a imagem `arm64`, e a questão se inverte.

## A imagem no lugar do zip

A imagem base da seção 02 não serve só para testar. **Uma função pode ser implantada como imagem de
contêiner**, `--package-type Image` com `--code ImageUri=` uma imagem no ECR, construída `FROM
public.ecr.aws/lambda/python:3.12` com o código copiado para `/var/task`. Três coisas mudam. O
limite é 10 GB em vez de 250 MB. O runtime é o que a imagem tiver, então ele só recebe as correções
da AWS quando você reconstrói a partir de uma imagem base mais nova. E a imagem que você rodou com
`docker run` no seu laptop é exatamente a imagem que o Lambda roda, emulador e tudo. A aula 10 é
onde uma imagem espera no ECR antes de rodar, e a aula 17 pesa o que uma imagem maior faz a uma
partida a frio. Nada nesta seção criou uma função de imagem, nem no moto nem em lugar nenhum.