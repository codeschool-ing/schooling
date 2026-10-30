---
title: Políticas de retenção, Bucket Lock e retenções temporárias
version: 1
---

**Uma política de retenção torna impossível apagar ou substituir qualquer objeto de um bucket até ele
ter idade suficiente, para todo mundo, inclusive o dono do projeto.** O versionamento e a exclusão
reversível protegem contra acidentes, porque quem cometeu o erro pode desfazê-lo; não protegem nada
contra quem faz de propósito, porque quem pode apagar um objeto vivo também pode apagar as gerações
dele, e pode desligar a exclusão reversível. Uma política de retenção é para o segundo caso: ransomware
rodando com uma chave roubada, um funcionário encobrindo algo, uma lei que manda guardar notas fiscais
por cinco anos. O último é o motivo de a Quitanda ter um bucket de arquivo.

O Cloud Storage tem quatro ferramentas para isso, e elas funcionam em dois níveis:

| ferramenta | definida em | o que faz |
|---|---|---|
| política de retenção | o bucket | nenhum objeto pode ser apagado ou substituído até a idade dele chegar ao prazo |
| Bucket Lock | a política de retenção do bucket | torna a política permanente: pode ser estendida, nunca encurtada nem removida |
| retenção temporária (hold) | um objeto | uma chave, temporária ou por evento, que guarda o objeto até ser liberada |
| retenção de objeto | um objeto | uma data até a qual aquele objeto é guardado, destravada ou travada |

Nada do que vem a seguir foi imposto neste laboratório, e a última parte desta seção mostra isso
claramente. É ensinado a partir da documentação do Google: cloud.google.com/storage/docs/bucket-lock,
cloud.google.com/storage/docs/object-holds e cloud.google.com/storage/docs/object-lock.

## A política de retenção, e como travá-la

Uma política de retenção é um prazo, definido com `--retention-period` quando o bucket é criado ou
depois com `gcloud storage buckets update`. Um objeto naquele bucket só pode ser apagado ou substituído
quando a idade dele, contada a partir de quando foi escrito, chegar ao prazo. Até lá uma exclusão é
recusada, seja qual for o papel de quem pede. O prazo pode chegar a 100 anos.

**Uma política destravada é um padrão forte e nada mais**, porque quem pode mudar o bucket também pode
remover a política com `--clear-retention-period` e então apagar o que ela protegia.
`--lock-retention-period` é o passo que muda isso. Depois que uma política é travada:

- ela não pode ser removida, e o prazo não pode ser encurtado. Só pode ser estendido;
- o bucket não pode ser apagado enquanto tiver algum objeto mais novo que o prazo;
- o projeto não pode ser apagado enquanto tiver um bucket assim, já que a documentação diz que uma
  trava coloca uma restrição (lien) no projeto.

**Travar é irreversível, e todo o valor dela está nisso.** É também o comando mais caro deste curso para
errar: um prazo de cem anos travado por engano num bucket que recebe um terabyte por dia é uma conta que
ninguém consegue parar. As notas fiscais da Quitanda ganham cinco anos, o prazo que a lei pede e nem um
dia a mais, e a trava é aplicada depois que a política foi lida de volta e conferida por uma segunda
pessoa.

## Retenções temporárias (holds)

Um hold é uma chave num objeto, sem data. Enquanto está ligado, o objeto não pode ser apagado nem
substituído, diga a política de retenção o que disser. Há dois tipos:

- **uma retenção temporária (temporary hold)** guarda o objeto até alguém liberá-la, e não faz mais
  nada. É a ferramenta para "guarde tudo sobre este cliente até os advogados dizerem o contrário",
  quando ninguém sabe a data do fim;
- **uma retenção por evento (event-based hold)** faz o mesmo e também zera o relógio da política de
  retenção: o prazo de retenção do objeto conta a partir do momento em que a retenção é liberada, não de
  quando ele foi escrito. Um bucket pode pôr uma em todo objeto novo por padrão, com
  `--default-event-based-hold`. Isso serve para um contrato guardado "cinco anos depois do fim", em que
  o fim é um evento que ninguém consegue datar com antecedência.

Liberar um hold exige permissão para atualizar o objeto, então ele protege contra acidentes e contra
quem não tem essa permissão, não contra um administrador. Não é uma trava.

## Retenção de objeto, um objeto de cada vez

Um bucket criado com `--enable-per-object-retention` permite que cada objeto tenha uma data própria,
definida com `gcloud storage objects update --retain-until` e `--retention-mode`. O modo é `Unlocked`
ou `Locked`. Unlocked pode ser encurtado ou removido por alguém com a permissão certa e a opção
`--override-unlocked-retention`, que a ajuda da linha de comando cita; Locked só pode ser estendido, e o
objeto fica guardado até a data, peça quem pedir. É a versão por objeto do Bucket Lock, para um bucket
cujos objetos precisam de prazos diferentes.

## No emulador

Crie o bucket de arquivo com um ano de retenção, escreva uma nota fiscal e apague-a na hora:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-archive-prod --location=southamerica-east1 --retention-period=1y
Creating gs://quitanda-archive-prod/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-archive-prod --format='value(retention_policy)'

ana@laptop:~/gcp$ printf 'invoice,total_cents\nnf-2026-10-0001,4590\n' > nf.csv && gcloud storage cp nf.csv gs://quitanda-archive-prod/invoices/2026-10/nf.csv
Copying file://nf.csv to gs://quitanda-archive-prod/invoices/2026-10/nf.csv
  

ana@laptop:~/gcp$ gcloud storage rm gs://quitanda-archive-prod/invoices/2026-10/nf.csv
Removing objects:
  
Removing gs://quitanda-archive-prod/invoices/2026-10/nf.csv...
ERROR: 'NoneType' object has no attribute 'items'

ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-archive-prod/invoices/
ERROR: (gcloud.storage.ls) One or more URLs matched no objects.
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-archive-prod --retention-period=1y && gcloud storage buckets update gs://quitanda-archive-prod --lock-retention-period
  
Updating gs://quitanda-archive-prod/...

  
Updating gs://quitanda-archive-prod/...
failed.
ERROR: (gcloud.storage.buckets.update) Bucket "gs://quitanda-archive-prod/" does not have a retention policy.
```

**A nota fiscal foi apagada, um segundo depois de escrita, num bucket com um ano de retenção.** O
`describe` mostra por quê: nenhuma política de retenção voltou, porque o fake-gcs-server não guardou
nenhuma. O último comando é a prova mais clara de todas, e veio da linha de comando, não do emulador.
`--lock-retention-period` faz o `gcloud` ler a política do bucket antes de travá-la, e ele não encontrou
nenhuma: `does not have a retention policy`, um comando depois de definir um ano dela.

As retenções temporárias não se saem melhor:

```
ana@laptop:~/gcp$ gcloud storage cp nf.csv gs://quitanda-archive-prod/disputes/c-17/order.csv && gcloud storage objects update gs://quitanda-archive-prod/disputes/c-17/order.csv --temporary-hold
Copying file://nf.csv to gs://quitanda-archive-prod/disputes/c-17/order.csv
  

  
Patching gs://quitanda-archive-prod/disputes/c-17/order.csv...

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/disputes/c-17/order.csv --format='value(temporary_hold,event_based_hold)'
	
ana@laptop:~/gcp$ gcloud storage rm gs://quitanda-archive-prod/disputes/c-17/order.csv
Removing objects:
  
Removing gs://quitanda-archive-prod/disputes/c-17/order.csv...
ERROR: 'NoneType' object has no attribute 'items'

ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-archive-prod/disputes/
ERROR: (gcloud.storage.ls) One or more URLs matched no objects.
```

**O hold foi aceito e não foi guardado**: os dois campos de retenção voltaram vazios, e a exclusão que
ele deveria ter recusado funcionou. Neste laboratório toda ferramenta de retenção é uma requisição que
passa na análise e uma configuração que não faz nada, e um teste de qualquer uma delas prova só que o
comando foi escrito corretamente. Uma verificação real de uma política travada precisa de um projeto
real, e custa o armazenamento do que ela trava durante o prazo inteiro, já que nada pode removê-lo antes.
