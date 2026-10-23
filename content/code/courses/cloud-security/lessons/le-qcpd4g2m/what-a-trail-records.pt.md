---
title: O que uma trilha registra, e o que ela deixa de fora
version: 1
---

**O CloudTrail grava um registro para cada chamada feita à API da AWS: quem fez, de onde, quando, o
que pediu e se foi permitido.** Desde a aula 1, toda mudança na conta da clínica foi uma chamada
dessas. Então a trilha é a memória da conta sobre quem mudou o quê, e a única que existe: a aula 1
disse que você não toca no fio, e um servidor apagado não pode ser examinado depois.

A crença errada é a de que "o CloudTrail está ligado" quer dizer que tudo é registrado. Três coisas
limitam o que uma trilha guarda, e uma investigação descobre as três no pior momento.

## Eventos de gerenciamento e eventos de dados

| | o que cobre | exemplo | registrado por padrão |
|---|---|---|---|
| **evento de gerenciamento** | uma mudança, ou uma leitura, na configuração de um recurso | `CreateBucket`, `PutBucketPolicy`, `AttachUserPolicy`, `StopLogging` | **sim** |
| **evento de dados** | uma operação sobre os dados dentro de um recurso | `GetObject` e `PutObject` no S3, `Invoke` no Lambda | **não**: você os escolhe, recurso por recurso, e paga por evento |

**A pergunta depois de uma exposição é quase sempre uma pergunta de evento de dados.** Quem tornou o
bucket público é um evento de gerenciamento, e está lá. Quem baixou o arquivo enquanto ele estava
público é um evento de dados, e só está lá se alguém escolheu, antes, registrar as leituras daquele
bucket. Uma trilha ligada depois não registra nada sobre os dias anteriores.

## Sem trilha, noventa dias de um tipo

Toda conta tem o *histórico de eventos* sem configuração nenhuma: os últimos 90 dias de eventos de
gerenciamento, uma região por vez, pesquisáveis no console ou com `aws cloudtrail lookup-events`. Ele
não tem eventos de dados, não pode ser guardado por mais tempo e mora na mesma conta das pessoas que
registra. Uma **trilha** é a configuração que grava os registros como arquivos num bucket do S3 que
você escolhe, pelo tempo que você os guardar, incluindo os eventos de dados que você selecionou.

## Os campos de um registro

Um registro é um objeto JSON. Estes são os campos que esta aula lê, da descrição que a AWS faz do
formato:

| campo | o que guarda |
|---|---|
| `eventTime` | quando a chamada foi feita, **sempre em UTC** |
| `eventSource`, `eventName` | o serviço e a operação: `s3.amazonaws.com`, `PutBucketPolicy` |
| `userIdentity` | quem a fez: o tipo (um usuário do IAM, um papel assumido, um serviço da AWS, um chamador anônimo), o ARN, a chave de acesso usada |
| `sourceIPAddress` | o endereço de onde a chamada veio, ou o nome do serviço da AWS que a fez |
| `userAgent` | o programa que fez a chamada: a AWS CLI, um SDK, o console |
| `requestParameters` | o que foi pedido: o bucket, a chave do objeto, a política |
| `errorCode`, `errorMessage` | presentes só quando a chamada falhou, como `AccessDenied` |
| `eventCategory` | `Management` ou `Data` |

**Uma chamada recusada também é registrada**, com o seu `errorCode`. Isso passa fácil despercebido e
costuma ser o primeiro sinal de problema: alguém com uma chave, tentando coisas que ela não permite.

## O que nenhuma trilha registra

Uma trilha registra chamadas à API da AWS, e nada que aconteça sem uma. **Comandos rodados dentro de
uma instância, consultas mandadas a um banco de dados, requisições ao próprio sistema de agendamento
da clínica: nada disso é uma chamada à API da AWS**, e cada um precisa dos próprios logs, do sistema
operacional, do banco ou da aplicação. Tráfego de rede são os VPC flow logs, que a aula 8 apresentou.
E o conteúdo de uma requisição também não é registrado: um registro de `PutObject` nomeia o objeto,
nunca o que havia dentro dele.
