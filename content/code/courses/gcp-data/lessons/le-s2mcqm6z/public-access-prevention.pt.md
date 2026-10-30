---
title: Prevenção de acesso público
version: 1
---

**A prevenção de acesso público é uma configuração que faz `allUsers` e `allAuthenticatedUsers`
pararem de funcionar num bucket**, diga o IAM ou uma ACL o que disser. Uma política pode estar errada
numa linha e uma ACL pode ser definida num objeto por qualquer um com permissão de escrevê-lo; a
prevenção de acesso público fica acima das duas, para que um erro em qualquer uma não chegue à
internet. A crença comum é que um bucket é privado porque ninguém o tornou público. Um bucket é privado
porque algo se recusa a deixá-lo ser tornado público, e é isto.

A documentação do Google, cloud.google.com/storage/docs/public-access-prevention, dá dois valores à
configuração:

| valor | o que significa |
|---|---|
| `enforced` | nenhuma permissão a `allUsers` ou `allAuthenticatedUsers` pode ser acrescentada, por IAM ou ACL, e qualquer uma que já exista para de funcionar |
| `inherited` | o bucket segue a política da organização acima dele, se houver uma, e fora isso fica sem proteção |

**A segunda metade de `enforced` é a parte que importa no dia em que ela é ligada.** Ela não só recusa
permissões públicas novas: uma permissão a `allUsers` que já existe continua escrita na política e não
concede nada, então ligar a prevenção fecha um vazamento na hora, sem que alguém precise antes achar
cada permissão que o causou. A documentação acrescenta que uma URL assinada não é acesso público: é uma
requisição feita com a autoridade de quem assinou, e continua funcionando num bucket com a prevenção
imposta.

## Neste laboratório

```
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-logs-prod --public-access-prevention=enforced 2>&1 | head -1
ERROR: (gcloud.storage.buckets.update) argument --public-access-prevention/--pap: ignored explicit argument 'enforced'
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-logs-prod --public-access-prevention
  
Updating gs://quitanda-logs-prod/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-logs-prod --format='value(public_access_prevention,uniform_bucket_level_access)'
	
ana@laptop:~/gcp$ gcloud storage cp access.log gs://quitanda-logs-prod/web/public.log --predefined-acl=publicRead
Copying file://access.log to gs://quitanda-logs-prod/web/public.log
  

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-logs-prod/web/public.log --format='json(acl)'
{
  "acl": [
    {
      "entity": "allUsers",
      "projectTeam": {},
      "role": "READER"
    }
  ]
}
```

**O primeiro comando mostra como esta versão da linha de comando a escreve.** No Google Cloud CLI
591.0.0, `--public-access-prevention` é uma chave: escrita sozinha define `enforced`, e
`--no-public-access-prevention` define `inherited`. A forma com `=enforced` que exemplos mais antigos
usam é recusada antes de qualquer envio. O segundo comando foi aceito, e o `describe` depois dele não
imprimiu nada nem para a prevenção de acesso público nem para o acesso uniforme no nível do bucket: o
emulador não guardou nenhum dos dois. Depois um objeto foi escrito com `--predefined-acl=publicRead`,
um atalho para "conceder `READER` a `allUsers`", e o emulador registrou exatamente essa permissão.

No Cloud Storage esse upload teria sido recusado duas vezes: pelo acesso uniforme no nível do bucket,
que recusa qualquer ACL, e pela prevenção de acesso público, que recusa uma pública. A Quitanda quer os
dois, em todo bucket, e não quer depender de quem criar o próximo bucket lembrar de duas opções. É
para isso que servem as políticas da organização da próxima seção.

## O bucket que deve ser público

A Quitanda tem um: as fotos dos produtos que o site mostra, que o navegador de todo visitante baixa sem
credenciais. A prevenção de acesso público nele quebraria a loja. **A resposta é tornar a exceção
visível, não enfraquecer a regra**:

- as fotos ficam num bucket só delas, `quitanda-web-public-prod`, que não guarda mais nada, para que
  uma permissão pública nele não alcance um pedido, um log ou um cliente;
- esse bucket fica num projeto só dele, e a política da organização que impõe a prevenção em todo o
  resto é sobrescrita para aquele projeto, com o motivo escrito no histórico da política;
- nada é escrito nele por um pipeline que também escreve dados privados, porque o vazamento mais comum
  de todos é o arquivo certo enviado para o bucket errado.

Quem revisa passa a ter uma pergunta só a fazer sobre a organização inteira, "que projetos sobrescrevem
a prevenção, e por quê", em vez de uma por bucket. A seção sobre o bucket que vazou mostra como fazê-la.

## Lendo a configuração de volta

No Cloud Storage, a verificação depois de qualquer mudança é ler as duas configurações do bucket de
volta, juntas, porque cada uma é metade da resposta:

```sh
gcloud storage buckets describe gs://quitanda-curated-prod \
  --format='value(public_access_prevention,uniform_bucket_level_access)'
```

A transcrição acima executou o mesmo comando contra o bucket de logs, e ele imprimiu dois campos
vazios. No Cloud Storage ele imprime `enforced` para a prevenção, ou `inherited` quando o bucket segue a
organização, e a configuração do acesso uniforme com o horário da trava. **`inherited` não é promessa
de segurança**: só é seguro se uma política da organização acima do bucket impuser a prevenção, e o
bucket sozinho não consegue dizer se há uma.
