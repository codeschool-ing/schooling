---
title: What-if: a mudança, antes de acontecer
version: 1
---

**O what-if pergunta ao Resource Manager o que um deploy mudaria, sem mudar nada.** É o equivalente no Azure ao
`terraform plan`, e precisa do grupo de recursos real para comparar, então **não foi executado** aqui:

```sh
az deployment group what-if -g rg-shop -f main.bicep -p main.prod.bicepparam
```

A resposta é uma lista de recursos, cada um com um **tipo de mudança**, e, para um modificado, as propriedades que
mudariam, com os valores antigo e novo. Os tipos de mudança documentados são seis:

| tipo de mudança | o que significa |
|---|---|
| **Create** | o recurso não existe e será criado |
| **Delete** | o recurso existe e seria apagado; só em modo *complete* ou com uma stack |
| **Modify** | o recurso existe e algumas propriedades vão mudar |
| **NoChange** | o recurso existe e bate com o template |
| **Ignore** | o recurso existe no escopo e o template não o menciona; fica como está |
| **Deploy** | o recurso existe, e o what-if não sabe dizer se propriedades vão mudar |

Dois deles merecem atenção toda vez. **Modify** numa propriedade em que você não mexeu é a linha interessante:
quer dizer que o recurso se afastou do que o arquivo diz, talvez porque alguém o mudou à mão no portal, e o deploy
está prestes a desfazer essa mudança. Leia antes de implantar, não depois. E **Ignore** é o lembrete do que é um
deploy incremental: um recurso que você apagou do arquivo não é apagado do Azure. Ele só deixou de ser
mencionado, e continua sendo cobrado.

O what-if tem uma fraqueza conhecida, e a Microsoft a documenta: **ruído**. Alguns provedores de recursos
informam propriedades como mudando quando não estão, porque o template e o recurso guardado expressam o mesmo
valor de jeitos diferentes. Uma equipe aprende quais linhas são ruído para os seus recursos, e o hábito a evitar é
o que nasce disso: aprovar um what-if sem ler porque ele é sempre longo.

Numa esteira, o what-if vai no estágio antes do deploy, com a saída anexada à aprovação da lição 3, para quem
aprova estar aprovando uma lista de mudanças, e não o hash de um commit.
