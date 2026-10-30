---
title: Quem pode ler: IAM, ACLs e acesso uniforme no nível do bucket
version: 1
---

**O Cloud Storage tem dois sistemas de permissão, e um bucket fica mais seguro com um deles
desligado.** O IAM é o que as aulas 5 a 7 de `gcp-foundations` ensinaram: uma política no projeto ou no
bucket que concede um papel a um principal, herdada para baixo, com uma política de negação capaz de
sobrepô-la. As ACLs são o sistema mais antigo: uma lista de permissões no bucket e em cada objeto, com
três níveis, `READER`, `WRITER` e `OWNER`. Qualquer um dos dois pode tornar um objeto legível, e quem
confere só um deles conferiu metade.

**O acesso uniforme no nível do bucket desliga as ACLs.** Com ele ligado, o Cloud Storage ignora toda
ACL e recusa requisições que tentem definir uma, e o IAM no bucket e acima dele é o único lugar onde se
concede acesso. A documentação do Google, cloud.google.com/storage/docs/uniform-bucket-level-access, o
recomenda para todo bucket, e ele é necessário para duas coisas que esta aula usa: condições do IAM
num bucket, e a política da organização de duas seções adiante. Depois de 90 dias ligado ele não pode
mais ser desligado; antes disso, pode.

## Dois principais que significam "todo mundo"

O IAM e as ACLs têm dois principais especiais, e eles são todo o acesso público:

- **`allUsers` é qualquer pessoa na internet**, conectada ou não. Uma permissão a ele torna um objeto
  legível por um `curl` sem credenciais;
- **`allAuthenticatedUsers` é qualquer pessoa conectada a qualquer conta do Google**: não qualquer
  pessoa da Quitanda, qualquer pessoa com um endereço do Gmail. O nome fazia parecer o seguro, e ele
  nunca foi.

Conceder `roles/storage.objectViewer` a `allUsers` num bucket é um comando, e torna público todo objeto
dele, inclusive os escritos no ano que vem.

## O que o emulador faz com tudo isso

Crie o bucket de logs da Quitanda com acesso uniforme no nível do bucket, e peça ao bucket curated da
seção anterior a política de IAM dele:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-logs-prod --location=southamerica-east1 --uniform-bucket-level-access
Creating gs://quitanda-logs-prod/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-logs-prod --format=json
{
  "creation_time": "2026-10-30T15:53:38-0300",
  "default_storage_class": "STANDARD",
  "location": "southamerica-east1",
  "location_type": "region",
  "metageneration": 1,
  "name": "quitanda-logs-prod",
  "storage_url": "gs://quitanda-logs-prod/",
  "update_time": "2026-10-30T15:53:38-0300",
  "versioning_enabled": false
}
ana@laptop:~/gcp$ gcloud storage buckets get-iam-policy gs://quitanda-curated-prod
ERROR: (gcloud.storage.buckets.get-iam-policy) gs://quitanda-curated-prod not found: 404.
ana@laptop:~/gcp$ gcloud storage buckets add-iam-policy-binding gs://quitanda-curated-prod --member=allUsers --role=roles/storage.objectViewer
ERROR: (gcloud.storage.buckets.add-iam-policy-binding) gs://quitanda-curated-prod not found: 404.
```

**O emulador aceitou `--uniform-bucket-level-access` e não guardou nada**: o `describe` não tem esse
campo, onde o Cloud Storage mostraria a configuração ligada. E ele não tem IAM nenhum. Uma requisição
pela política de IAM de um bucket, ou para acrescentar uma permissão a ela, recebe `404`, como se o
bucket não existisse, embora o bucket esteja lá. Nada de IAM pode ser praticado contra o
fake-gcs-server, então a permissão abaixo é um comando para ler, não para executar:

```sh
gcloud storage buckets add-iam-policy-binding gs://quitanda-curated-prod \
  --member=serviceAccount:dashboard@planner-dev.iam.gserviceaccount.com \
  --role=roles/storage.objectViewer \
  --condition='expression=resource.name.startsWith("projects/_/buckets/quitanda-curated-prod/objects/reports/"),title=reports-only'
```

Ele não foi executado aqui, e a conta de serviço nele é tão inventada quanto a que assinou na seção
anterior. **Ele concede ao painel leitura em `reports/` e em nada mais do bucket**: a condição é
avaliada em toda requisição, contra o nome completo do recurso do objeto, e uma requisição por qualquer
outro objeto não encontra permissão. Condições num bucket exigem acesso uniforme no nível do bucket, o
que é mais um motivo para ligá-lo.

As ACLs, que o emulador guarda:

```
ana@laptop:~/gcp$ printf '203.0.113.7 GET /checkout 200\n' > access.log && gcloud storage cp access.log gs://quitanda-logs-prod/web/access.log
Copying file://access.log to gs://quitanda-logs-prod/web/access.log
  

ana@laptop:~/gcp$ gcloud storage objects update gs://quitanda-logs-prod/web/access.log --add-acl-grant=entity=allUsers,role=READER
  
Patching gs://quitanda-logs-prod/web/access.log...

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-logs-prod/web/access.log --format='json(acl)'
{
  "acl": [
    {
      "entity": "projectOwner-test-project",
      "projectTeam": {},
      "role": "OWNER"
    },
    {
      "entity": "allUsers",
      "projectTeam": {},
      "role": "READER"
    }
  ]
}
```

**Uma ACL concedendo `READER` a `allUsers` foi aceita num bucket criado com acesso uniforme no nível
do bucket**, e registrada ao lado da entrada de dono do próprio emulador, `projectOwner-test-project`.
No Cloud Storage a requisição teria sido recusada, porque com acesso uniforme ligado nenhuma ACL pode
ser definida. E a permissão não fez diferença aqui, de jeito nenhum: a próxima transcrição pede dois
objetos sem credencial nenhuma, um com a ACL pública e outro sem.

```
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' http://localhost:4443/storage/v1/b/quitanda-logs-prod/o/web%2Faccess.log?alt=media
203.0.113.7 GET /checkout 200
200
ana@laptop:~/gcp$ curl -s -w '%{http_code}\n' http://localhost:4443/storage/v1/b/quitanda-curated-prod/o/reports%2Fdaily.csv?alt=media
day,orders,total_cents
2026-10-29,412,5108840
200
```

**Os dois voltaram, o log público e o relatório privado.** O fake-gcs-server não confere credenciais
em requisição nenhuma, o que a aula 1 disse e o que mais importa aqui: neste laboratório todo objeto é
público para qualquer um que alcance a porta 4443, e só o fato de a porta escutar no seu próprio laptop
o mantém privado. As decisões de permissão desta aula são ensinadas a partir da documentação do Google,
e o laboratório só consegue mostrar como as requisições são.
