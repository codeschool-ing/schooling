---
title: Um bucket no notebook
version: 1
---

A interface do S3 é HTTP, então dá para imitá-la. O **moto** é um programa em Python escrito para
testar código que conversa com a AWS: o `moto_server` escuta numa porta do notebook e responde às
requisições do S3 do jeito que o S3 responde, guardando os objetos na própria memória. Esta seção
aponta a AWS CLI de verdade para ele, o que mostra a forma da interface: as requisições, as
respostas, o que são uma chave e um prefixo. **Ele não diz nada sobre latência, durabilidade ou
preço do S3.** Nada do que ele guarda sai do notebook, e ele aceita credenciais que a AWS recusaria.
O `captures.sh` da aula diz como rodar a mesma sessão.

A CLI precisa saber para onde mandar as requisições e precisa de alguma credencial para assiná-las.
Quatro variáveis fazem as duas coisas: a palavra `test` como par de chaves, uma região, e o endereço
do moto no lugar do da AWS. O resto são comandos `aws s3` comuns:

```
ana@laptop:~/cloud$ export AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=test AWS_DEFAULT_REGION=sa-east-1 AWS_ENDPOINT_URL=http://127.0.0.1:5000
ana@laptop:~/cloud$ aws s3 mb s3://ana-uploads
make_bucket: ana-uploads
ana@laptop:~/cloud$ aws s3 cp --no-progress cat.jpg s3://ana-uploads/photos/2026/cat.jpg
upload: ./cat.jpg to s3://ana-uploads/photos/2026/cat.jpg
ana@laptop:~/cloud$ aws s3 cp --no-progress report.txt s3://ana-uploads/reports/q3.txt
upload: ./report.txt to s3://ana-uploads/reports/q3.txt
```

O `mb` criou um bucket. Cada upload virou um `PUT`, e a chave é a string inteira depois do nome do
bucket; nada precisou existir em `photos/` ou `photos/2026/` antes.

Agora a listagem, de três jeitos:

```
ana@laptop:~/cloud$ aws s3 ls s3://ana-uploads
                           PRE photos/
                           PRE reports/
ana@laptop:~/cloud$ aws s3 ls s3://ana-uploads --recursive
2026-09-28 15:15:51        100 photos/2026/cat.jpg
2026-09-28 15:15:53          6 reports/q3.txt
ana@laptop:~/cloud$ aws s3api list-objects-v2 --bucket ana-uploads --query 'Contents[].Key'
[
    "photos/2026/cat.jpg",
    "reports/q3.txt"
]
```

**A primeira listagem, sem `--recursive`, pediu ao repositório que cortasse as chaves em `/`.** Ela
devolveu duas linhas `PRE`, prefixos, e nenhum objeto, porque toda chave tem uma barra. A segunda
listou cada chave inteira. A terceira, pelo comando de nível mais baixo `s3api`, mostra o que o
bucket guarda: duas chaves, strings com barras dentro, e nada chamado `photos/`.

## Renomear é copiar e apagar

`aws s3 mv` parece o `mv`. O que ele manda está no log do próprio moto, que registra uma linha por
requisição HTTP, e o `grep` separa o método e o caminho de cada linha sobre `reports`:

```
ana@laptop:~/cloud$ aws s3 mv --no-progress s3://ana-uploads/reports/q3.txt s3://ana-uploads/reports/2026-q3.txt
move: s3://ana-uploads/reports/q3.txt to s3://ana-uploads/reports/2026-q3.txt
ana@laptop:~/cloud$ grep -o '[A-Z]* /ana-uploads/reports[^ ]*' moto.log
PUT /ana-uploads/reports/q3.txt
HEAD /ana-uploads/reports/q3.txt
PUT /ana-uploads/reports/2026-q3.txt
DELETE /ana-uploads/reports/q3.txt
```

Leia o log de cima para baixo. O primeiro `PUT` é o upload de antes. Depois vem a movimentação: um
`HEAD` para ler os metadados do objeto de origem, um `PUT` para a chave nova e um `DELETE` da
antiga. A requisição do meio é uma cópia: a CLI a manda como um `PUT` com um cabeçalho que nomeia o
objeto de origem, então os bytes são copiados dentro do repositório, sem download e upload.

**Três requisições para renomear uma vez**, e entre a cópia e a remoção as duas chaves existem. Um
programa que renomeia dez mil objetos manda trinta mil requisições, paga por cada uma e pode ser
interrompido no meio, deixando alguns objetos com os dois nomes. Por isso dados organizados para um
repositório de objetos escolhem as chaves uma vez só. Uma chave que carrega algo que tende a mudar,
como o nome de um cliente ou do time dono de um relatório, é uma chave que vai ser copiada e apagada
no dia em que isso mudar.
