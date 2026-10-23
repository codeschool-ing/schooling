---
title: O que uma empresa de fato consegue controlar
version: 1
---

**Uma empresa não consegue configurar uma conta que não é dela.** Todo controle desta seção atua
sobre uma de três coisas que a clínica possui: os próprios tenants, a própria rede e os próprios
aparelhos, e os próprios buckets. O armazenamento paralelo é combatido a partir dessas três, e a
primeira é a que mais importa, porque uma regra contra contas pessoais sem um serviço da empresa tão
fácil de usar só muda o arquivo para um lugar que a regra não enxerga.

## 1. Um serviço da empresa, configurado de forma estreita

A bia usou o próprio Drive porque era o jeito mais rápido de mandar um arquivo grande. A resposta da
clínica é uma conta da empresa tão rápida quanto, com o compartilhamento configurado do jeito que a
clínica quer:

- **links abertos à organização por padrão**, para que quem compartilha tenha de escolher ir além;
- **compartilhamento externo limitado a convidados nomeados, ou a domínios parceiros listados**, como
  o do contador;
- **uma validade em qualquer link aberto**, onde o serviço permite, para que um link mandado em março
  esteja morto em abril;
- **um relatório do que está compartilhado para fora**, lido por alguém com regularidade.

As quatro são configurações do console de administração do tenant no Microsoft 365 e no Google
Workspace, como descreveu a tabela da seção anterior. **Nenhuma foi executada aqui**: elas vêm da
documentação de cada provedor.

## 2. Ver e conduzir pela rede

Um arquivo enviado a um Dropbox pessoal sai pela rede da empresa ou de um notebook da empresa, e é
ali que ele pode ser visto.

- **Um CASB**, um *cloud access security broker*, lê os logs do proxy e do firewall da empresa e lista
  todo serviço de nuvem que as pessoas usam, com quanto enviam a cada um. É assim que o armazenamento
  paralelo é encontrado: o inventário dos serviços que ninguém aprovou.
- **As restrições de tenant** deixam a rede da empresa permitir login no tenant Microsoft ou Google
  da própria empresa e recusar login em contas pessoais do mesmo serviço. O endereço é o mesmo,
  `onedrive.live.com` ou `drive.google.com`, então bloquear o serviço bloquearia a empresa também; o
  que se verifica é qual conta está entrando.

::: track security
- **DLP**, prevenção de perda de dados, é a aula 9 do curso `defense-hardening`: inspeção de conteúdo
  que reconhece um número de CPF ou um termo médico num envio e o barra. Aqui é o mesmo controle,
  apontado para o armazenamento em nuvem em vez de pendrives.
:::

::: track *
- **DLP**, prevenção de perda de dados, inspeciona o que está sendo enviado e reconhece, por exemplo,
  um número de CPF ou um termo médico, e então barra o envio ou pede uma justificativa. É o mesmo
  controle que vigia pendrives e e-mail, apontado para o armazenamento em nuvem.
:::

Nenhum desses enxerga um celular no próprio plano de dados. **Esse é o limite honesto**, e o motivo de
a primeira seção desta aula vir primeiro.

## 3. Os buckets da própria clínica

No S3, o controle fica na política do bucket, e a AWS dá duas chaves de condição feitas para URLs
pré-assinadas. **`s3:authType`** vale `REST-QUERY-STRING` quando uma requisição é assinada no
endereço, que é o que uma URL pré-assinada é. **`s3:signatureAge`** é a idade da assinatura, em
milissegundos. Então a clínica pode proibir links de vez no `clinic-records`, de onde nenhum arquivo
deveria sair por link. No `clinic-results`, pode permiti-los só enquanto tiverem até dez minutos:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "NoLinksToRecords",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::clinic-records/*",
      "Condition": { "StringEquals": { "s3:authType": "REST-QUERY-STRING" } }
    }
  ]
}
```

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ResultLinksLiveTenMinutes",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::clinic-results/*",
      "Condition": { "NumericGreaterThan": { "s3:signatureAge": "600000" } }
    }
  ]
}
```

**Um `Deny` com condição é como se escreve uma proteção**, porque nenhum link que alguém faça
consegue durar mais que ela: o `--expires-in` de quem assina é uma promessa, e isto é a do bucket.
Nenhuma das duas políticas foi executada aqui, já que o moto guarda condições e as ignora; as duas
chaves e o que significam vêm da documentação da AWS sobre as chaves de condição do S3.

## Quando alguém sai

No dia em que a dani saiu, em março, alguém deveria ter encerrado o acesso dela à conta AWS da
clínica, e a aula 6 encontra o que ficou para trás. **Para um arquivo que ela pôs no próprio Dropbox,
não há nada a encerrar.** O máximo que a clínica consegue é pedir, e registrar que pediu. Por isso
todo controle acima previne em vez de limpar: o armazenamento paralelo é a única exposição deste curso
cuja correção não pode ser provada perguntando de novo, porque a clínica não tem onde perguntar.
