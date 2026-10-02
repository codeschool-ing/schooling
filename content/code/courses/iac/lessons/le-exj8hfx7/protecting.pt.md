---
title: Protegendo o estado
version: 1
---

O estado agora é um objeto num bucket, como deve ser, e é também o arquivo mais valioso que esta
configuração produz. Três coisas podem dar errado com ele, e cada uma tem a sua defesa: alguém o lê
sem dever, alguém grava uma versão ruim dele, ou ele se perde.

## Quem pode ler

**Ler o estado é ler tudo o que o Terraform sabe sobre a conta**: cada id, cada ARN, cada atributo
que um provider devolveu, de cada recurso. Para a rede da loja, isso é um mapa da infraestrutura.
Para uma configuração que cria um banco de dados, é também a senha do banco, em texto puro, por mais
que `sensitive = true` a esconda na tela; a aula 12 a mostra lá e os jeitos de mantê-la fora.

Então as permissões do bucket são as permissões do estado. O bloqueio de acesso público de
"remote-backend" é o mínimo. Acima dele, as pessoas e os pipelines que rodam o Terraform nesta
configuração precisam ler e gravar aquela key, e mais ninguém precisa de nada; uma política que deixa
"todos os desenvolvedores" listarem o bucket é uma política que entrega a eles todos os segredos de
todos os estados que estão lá. O `encrypt = true` protege o objeto nos discos do S3, e não faz nada
contra alguém que o bucket deixa entrar. Quem faz o trabalho é a política de acesso.

## Uma gravação ruim, e a história que a desfaz

O versionamento foi ligado antes de o primeiro estado ser gravado, e toda gravação desde então ainda
está no bucket. A migração e dois applies gravaram este estado, e o S3 guardou as três:

```
ana@laptop:~/shop$ aws s3api list-object-versions --bucket shop-tfstate-123456789012 --prefix shop/terraform.tfstate --query "Versions[?Key=='shop/terraform.tfstate'].[LastModified,Size,IsLatest]" --output text
2026-10-02T03:52:52.000Z	5979	True
2026-10-02T03:52:26.000Z	5907	False
2026-10-02T03:51:41.000Z	5835	False
```

Qualquer uma delas pode ser buscada pelo version id. A Ana pega a mais antiga, a que o
`-migrate-state` gravou, e a compara com a atual:

```
ana@laptop:~/shop$ aws s3api get-object --bucket shop-tfstate-123456789012 --key shop/terraform.tfstate --version-id 9049e965-1e0c-4ffe-b897-74c3fb7f9ff8 old.tfstate > /dev/null
ana@laptop:~/shop$ jq "{serial, lineage}" old.tfstate
{
  "serial": 1,
  "lineage": "68edf607-1653-46e5-9a24-69e2860acf13"
}
ana@laptop:~/shop$ terraform state pull | jq "{serial, lineage}"
{
  "serial": 3,
  "lineage": "68edf607-1653-46e5-9a24-69e2860acf13"
}
```

**Mesmo lineage, serial diferente**: dois pontos de uma mesma história, o antigo duas gravações
atrás. É para isso que servem o "lineage" e o "serial" da primeira seção. Suponha que a Ana, ou um
script, tentasse pôr o antigo de volta como estado atual:

```
ana@laptop:~/shop$ terraform state push old.tfstate
Failed to write state: cannot import state with serial 1 over newer state with serial 3
```

O Terraform se recusa a trocar um estado mais novo por um mais velho. É essa recusa que impede uma
cópia velha no disco de alguém de desfazer em silêncio uma semana de applies, e um estado de outro
lineage é recusado do mesmo jeito. O `terraform state push -force` passa por cima das duas
verificações, e é a ferramenta certa em exatamente uma ocasião: o estado atual está danificado, uma
versão anterior é sabidamente boa, e nada mais está rodando. Aí você também roda um plan logo depois
e o lê, porque toda mudança feita desde aquela versão volta a ser desconhecida do estado.

## As regras, em resumo

Mantenha o estado num backend remoto com travamento, nunca no git e nunca só num laptop. Ligue o
versionamento antes da primeira gravação, para que haja uma história para onde voltar. Bloqueie o
acesso público, e dê ao bucket uma política que nomeie quem pode usá-lo, em vez de uma que nomeie
quem não pode. Nunca edite o JSON à mão; o `terraform state` faz as edições necessárias, e as aulas 4
e 6 fazem a maioria delas a partir da configuração. E trate o bucket que o guarda como parte da
infraestrutura: criado primeiro, destruído por último, e por ninguém com pressa.

Uma pergunta que esta aula deixou em aberto é de que tamanho deve ser um único estado. A loja tem um
para tudo, o que significa uma trava para tudo e um arquivo cuja perda custa tudo. A aula 8 o divide.
