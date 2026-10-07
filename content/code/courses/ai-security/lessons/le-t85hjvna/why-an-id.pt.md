---
title: Uma chave, milhares de pessoas
version: 1
---

O assistente da Tarefa chama o fornecedor do modelo com uma chave de API, a chave da empresa. Do lado
do fornecedor, toda requisição vem da Tarefa: o cliente perguntando sobre um reembolso, a freelancer
rascunhando uma proposta e a única pessoa tentando fazer o assistente escrever o que não deve. **Uma
chave identifica o cliente do fornecedor, e não diz nada sobre a pessoa por trás de cada requisição.**

Isso custa caro em dois lugares.

**No fornecedor.** Fornecedores vigiam o abuso das políticas de uso deles, e só conseguem agir sobre o
que veem. Se um usuário da Tarefa passa a tarde tentando arrancar instruções para algo proibido, o
fornecedor vê uma série de requisições ruins vindas da chave da Tarefa. As respostas possíveis são um
aviso à Tarefa, uma restrição na chave ou a suspensão da chave, e cada uma delas cai sobre todos os
usuários da Tarefa. Sem mais nada em que se apoiar, o fornecedor não distingue um usuário ruim de um
cliente ruim.

**Na Tarefa.** Quando o aviso do fornecedor chega, ou quando o monitoramento da própria Tarefa vê algo
estranho, a primeira pergunta é *quem*. Os logs da aula 11 respondem se cada chamada registrou a
conta. O mesmo identificador permite à Tarefa limitar, cobrar e investigar por usuário, que é o
assunto das próximas duas seções.

## O campo que o carrega

Vários fornecedores aceitam, em cada requisição, um identificador do usuário final separado do prompt.
Como as APIs estavam em 2026, a Messages API da Anthropic o recebe em `metadata.user_id`, e a da
OpenAI em `safety_identifier`, campo que substituiu o antigo `user`. As duas documentações o descrevem
como uma forma de ajudar a detectar abuso. A da Anthropic pede um identificador opaco, sem nome, e-mail
nem telefone; a da OpenAI sugere fazer o hash do nome de usuário ou do e-mail. A próxima seção mostra
por que um hash simples de e-mail protege menos do que parece.

Nomes de campo mudam entre versões de API, então o hábito a guardar independe deles: **toda chamada
ao modelo leva a identidade da pessoa a quem ela serve, num campo feito para isso, e numa forma que não
identifica ninguém para o fornecedor.** Eis o formato de uma requisição com ele, escrito como o corpo
JSON que uma aplicação enviaria; esta aula não envia nada a lugar nenhum:

```json
{
  "model": "a-model-name",
  "max_tokens": 400,
  "metadata": {"user_id": "eu-fe47aa8e7cd5e1b6f8bc"},
  "messages": [{"role": "user", "content": "How do I change the e-mail on my account?"}]
}
```

`eu-fe47aa8e7cd5e1b6f8bc` é o identificador que o laboratório produz para a conta `ac-7Q2M`, o cliente
cujo e-mail você viu na aula 11. A próxima seção é como ele é feito.

## O que o fornecedor faz com ele

Um identificador permite ao fornecedor dizer à Tarefa *qual* usuário disparou a detecção de abuso,
para que a Tarefa trate de uma conta em vez de ter a chave restrita. O que cada fornecedor faz de fato
com o campo, quanto tempo o guarda e se age sobre ele automaticamente está nos termos e na
documentação, e varia entre fornecedores. Leia-os para o fornecedor que você usa, do mesmo jeito que a
aula 12 leu o contrato. O campo custa poucos bytes por requisição, e o dia em que ele importa é o dia
em que um relatório de abuso cita a sua chave.
