---
title: Por que uma chave baixada é o último recurso
version: 1
---

**Uma chave de conta de serviço é um arquivo que prova que você é a conta, para qualquer um que o tenha,
enquanto ele existir.** É um arquivo JSON com uma chave privada, criado na página da conta ou com
`gcloud iam service-accounts keys create`, e por padrão nunca expira. Tudo que esta lição elogiou nas
contas anexadas e na personificação, a vida curta, o nome de quem pegou, o segundo fator da pessoa por
trás, a chave não tem.

| | conta anexada | personificação | chave baixada |
|---|---|---|---|
| onde mora a credencial | em lugar nenhum: o servidor de metadados emite uma | no Google, por uma hora | num arquivo, onde quer que tenha sido copiado |
| quanto tempo funciona | cerca de uma hora, renovada | uma hora, ou até doze | até alguém apagar a chave |
| quem a usou | a máquina a que está anexada | registrado com o nome de quem pegou | quem tinha o arquivo |
| segundo fator | não se aplica | o de quem pegou | nenhum |

A coluna da direita é o motivo de as contas de serviço serem roubadas pelas chaves. **Uma chave acaba
num repositório, numa imagem de contêiner, numa variável de CI, na pasta Downloads de um notebook**, e
toda cópia funciona. O próprio conselho do Google, e a política segura por padrão da lição 4, é não criar
nenhuma: uma organização criada de 2024 em diante recusa o `iam.serviceAccountKeys.create` até alguém
levantar a restrição.

## Os casos que parecem precisar de uma

Quase todo motivo para alguém pegar uma chave tem resposta melhor neste curso:

- **uma pessoa rodando um script como a conta**: personificação, seção anterior;
- **código rodando no Google Cloud**: uma conta anexada, primeira seção;
- **código rodando fora do Google Cloud com identidade própria**, GitHub Actions, outra nuvem, um
  datacenter com Active Directory: **Workload Identity Federation**, lição 9, que troca o token da
  identidade de fora por um do Google sem chave nenhuma.

O que sobra é raro de verdade: um appliance antigo ou um produto de terceiros que só aceita arquivo de
chave.

## Quando não há outro jeito

Então a chave é tratada como o segredo que é, e os controles ficam na conta em vez de nas boas intenções
das pessoas:

- **uma chave, numa conta que faz uma coisa**, com os papéis mais estreitos que funcionem;
- **uma validade**: a política da organização `iam.serviceAccountKeyExpiryHours` faz as chaves pararem de
  funcionar depois de um tempo, e a rotação deixa de ser opcional;
- **a rotação como rotina**: criar a chave nova, implantá-la, confirmar que a antiga não é mais usada,
  apagá-la. O Google registra o último uso de cada chave, e é assim que o terceiro passo é conferido em
  vez de suposto;
- **um gerenciador de segredos**, nunca um arquivo num repositório. O Secret Manager a guarda, e as
  concessões para lê-la são IAM como qualquer outra.

**Se uma chave vazar, apague-a primeiro e investigue depois.** Apagar a chave encerra toda cópia de uma
vez, e os logs de auditoria do que ela fez continuam lá depois. O Google também procura chaves de conta
de serviço em repositórios públicos e avisa os contatos do projeto quando acha uma; essa mensagem não é
um teste.

Nada nesta seção rodou: criar uma chave exige uma conta real, e este curso não cria nenhuma. Não há
arquivo de chave, real ou imitado, em lugar nenhum destas lições.
