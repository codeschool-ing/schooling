---
title: "Versionamento: recuperar o que foi apagado"
version: 1
---

Com o versionamento desligado, que é como um bucket novo começa, um `PUT` numa chave existente
substitui o objeto e um `DELETE` o remove, e os dois são definitivos, diga o número de durabilidade
o que disser. **Com o versionamento ligado, o bucket guarda cada versão de cada chave**, e nenhuma
das duas requisições destrói nada.

Duas regras descrevem tudo:

- Uma sobrescrita acrescenta uma versão nova, e a que ela substituiu vira **não corrente**. Um `GET`
  simples devolve a versão corrente; qualquer versão ainda pode ser lida pelo id de versão.
- Um `DELETE` que não nomeia versão não remove nada. Ele acrescenta um **marcador de exclusão**, uma
  versão vazia que vira a corrente e faz a chave parecer ausente. Remova o marcador e o objeto
  volta.

A sessão do moto de antes mostra as duas, com a mesma ressalva: é um programa imitando a interface
num notebook. O versionamento é ligado, um arquivo é gravado, alterado e gravado de novo sob a mesma
chave, e depois apagado:

```
ana@laptop:~/cloud$ aws s3api put-bucket-versioning --bucket ana-uploads --versioning-configuration Status=Enabled
ana@laptop:~/cloud$ aws s3 cp --no-progress report.txt s3://ana-uploads/notes.txt
upload: ./report.txt to s3://ana-uploads/notes.txt
ana@laptop:~/cloud$ echo 'hello, again' > report.txt
ana@laptop:~/cloud$ aws s3 cp --no-progress report.txt s3://ana-uploads/notes.txt
upload: ./report.txt to s3://ana-uploads/notes.txt
ana@laptop:~/cloud$ aws s3 rm s3://ana-uploads/notes.txt
delete: s3://ana-uploads/notes.txt
ana@laptop:~/cloud$ aws s3 ls s3://ana-uploads/notes.txt
```

O último `ls` não imprimiu nada. Até onde uma listagem sabe, `notes.txt` sumiu. O bucket ainda
guarda as duas versões, e o marcador na frente delas:

```
ana@laptop:~/cloud$ aws s3api list-object-versions --bucket ana-uploads --prefix notes.txt --query 'Versions[].[Key,Size,IsLatest]' --output text
notes.txt	13	False
notes.txt	6	False
ana@laptop:~/cloud$ aws s3api list-object-versions --bucket ana-uploads --prefix notes.txt --query 'DeleteMarkers[].[Key,VersionId,IsLatest]' --output text
notes.txt	c5b4844b-24d5-4283-93d7-a818373c7e91	True
```

As duas versões são a primeira gravação, de 6 bytes, e a segunda, de 13, e nenhuma é a mais
recente, porque o marcador é. **Apagar o marcador, pelo id de versão dele, traz a última versão de
volta:**

```
ana@laptop:~/cloud$ aws s3api delete-object --bucket ana-uploads --key notes.txt --version-id c5b4844b-24d5-4283-93d7-a818373c7e91
{
    "VersionId": "c5b4844b-24d5-4283-93d7-a818373c7e91"
}
ana@laptop:~/cloud$ aws s3 cp s3://ana-uploads/notes.txt -
hello, again
```

Os ids de versão são do moto. O S3 gera os próprios, e a resposta dele a essa remoção também diz que
a versão apagada era um marcador de exclusão, o que a resposta do moto deixa de fora. A sequência é
a mesma.

## Quanto custa guardar tudo

**Cada versão é guardada e cobrada como um objeto corrente.** Uma exportação de 1 GB sobrescrita uma
vez por dia deixa uns 30 GB no bucket depois de um mês com versionamento ligado, e continua somando
um gigabyte por dia enquanto ninguém remove as antigas. Apagar também não ajuda, porque um delete só
acrescenta um marcador. Por isso o versionamento quase sempre vem junto de uma regra de ciclo de
vida para as versões não correntes, que transforma "guardar tudo" em "guardar uma janela para
recuperar":

```json
{
  "Rules": [
    {
      "ID": "old-versions-go-after-30-days",
      "Filter": {},
      "Status": "Enabled",
      "NoncurrentVersionExpiration": { "NoncurrentDays": 30 },
      "Expiration": { "ExpiredObjectDeleteMarker": true }
    }
  ]
}
```

O `Filter` vazio aplica a regra ao bucket inteiro. Uma versão é apagada 30 dias depois de deixar de
ser corrente, então um erro tem um mês para ser notado. A última linha remove marcadores de exclusão
que ficaram sem nenhuma versão por trás, que de outro modo se acumulariam em toda listagem de
versões.

Dois limites valem saber antes de depender disso. **Depois que o versionamento foi ligado, o bucket
pode ser suspenso mas nunca volta a não versionado**; as versões já guardadas ficam até algo
apagá-las. E o versionamento protege contra erros, não contra alguém autorizado a apagar versões:
quem tem essa permissão pode remover cada versão, uma por uma. Quem pode fazer isso é uma pergunta
de política para a aula 7, e tornar versões impossíveis de apagar é o object lock que o
`cloud-security` cobre.
