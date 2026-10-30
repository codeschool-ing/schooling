---
title: Escopos de acesso e papéis do IAM
version: 1
---

O bloco `service_account` tem uma segunda linha que parece decidir o que a máquina pode fazer:
`scopes`. **Sozinha, ela não decide. Duas verificações separadas ficam entre o token da máquina e
uma API do Google, e as duas precisam dizer sim.** Errar isso produz uma máquina que não consegue
fazer o seu trabalho ou um token que faz muito mais do que alguém pretendia.

## Duas verificações

Um **escopo de acesso** é uma propriedade do token. Quando o servidor de metadados gera um token
para a máquina, ele o limita aos escopos com que a instância foi criada: um token com escopo de
Cloud Storage só leitura não chama o Pub/Sub, seja lá o que a conta de serviço tenha permissão de
fazer. Escopos são mais antigos que o IAM, grosseiros, e definidos por instância.

Um **papel do IAM** é uma propriedade da identidade. A conta de serviço `shop-web` tem papéis em
recursos, `roles/storage.objectViewer` num bucket por exemplo, e a API confere os papéis da conta a
cada chamada.

Então uma chamada só dá certo quando **o escopo cobre a API e um papel cobre a ação naquele
recurso**. Cada verificação pode falhar sozinha, com um erro que só cita a própria metade, e é
assim que equipes perdem tardes com uma máquina que "tem o papel".

## Escopos no plan

A máquina da seção 02 pediu `cloud-platform`. Eis o mesmo bloco trocado por dois apelidos mais
estreitos, e o que o plan mostra:

```
ana@laptop:~/gcp/meta$ sed -i 's/"cloud-platform"\]/"storage-ro", "logging-write"]/' main.tf
ana@laptop:~/gcp/meta$ terraform plan -no-color | grep 'auth/'
              + "https://www.googleapis.com/auth/devstorage.read_only",
              + "https://www.googleapis.com/auth/logging.write",
```

**O provider expandiu cada apelido no escopo completo que ele representa**, então o plan mostra o
que o token vai de fato carregar: `storage-ro` é `devstorage.read_only`, e `logging-write` é
`logging.write`. A linha `cloud-platform` da seção anterior também era uma dessas expansões:
`https://www.googleapis.com/auth/cloud-platform`, o escopo que cobre toda API do Google Cloud.

## Qual usar

A recomendação atual do Google é curta: **dê à máquina o escopo `cloud-platform` e controle tudo
com papéis do IAM.** Escopos não sabem dizer "este bucket e não aquele"; papéis sabem, e mudam sem
mexer na máquina. Escopos estreitos ainda têm um uso, como segunda cerca numa máquina cuja conta
você não controla bem, mas uma cerca que precisa ser lembrada em cada instância não é onde a decisão
deve morar.

Seguem dois fatos de operação, ambos da documentação do Google e não executados aqui. **Trocar a
conta de serviço ou os escopos de uma instância exige pará-la**: o provider recusa a mudança numa
máquina ligada a menos que `allow_stopping_for_update = true` esteja definido, e aí ele para e
religa a máquina para aplicar. E **retirar um papel vale em minutos, enquanto um token já emitido
mantém os escopos até expirar**, em até uma hora. Quando uma máquina é comprometida, o jeito rápido
de cortá-la é desativar a conta de serviço, depois do que o Google recusa as credenciais dela.

| o que você quer restringir | onde isso mora |
|---|---|
| quais buckets, tópicos e tabelas a máquina pode tocar | papéis do IAM nesses recursos |
| quais ações neles | as permissões dos papéis |
| quais APIs um token desta máquina alcança | escopos de acesso, mantidos em `cloud-platform` |
| se esta máquina tem identidade | nenhum bloco `service_account`, ou um sem papéis |
