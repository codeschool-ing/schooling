---
title: O que o moto responde, e o que ele só finge
version: 1
---

**O moto responde como a AWS e impõe muito menos.** Ele foi escrito para que programas que chamam a
AWS possam ser testados sem conta, e para esse trabalho ele precisa aceitar uma requisição, guardar
o que ela disse e devolver a resposta que a AWS daria. Ele não precisa fazer o trabalho por trás da
resposta e, na maior parte do que este curso trata, não faz. Um curso de operação é quase todo sobre
esse trabalho: um alarme que dispara, um deploy que é revertido, uma política que recusa. Então o
curso usa o moto naquilo que ele faz bem e diz com todas as letras, toda vez, onde ele para.

## Onde fica a linha, serviço por serviço

| o que o curso faz | o que o moto faz | o que o moto não faz |
|---|---|---|
| esteiras, builds, deploys | guarda a esteira, o projeto de build, o deploy | rodar um build, levar um deploy além de `Created`, iniciar uma esteira |
| CloudFormation | cria e exclui uma stack a partir de um template | calcular um change set de uma stack existente, detectar drift |
| métricas | guarda pontos de dados, devolve somas, médias, mínimos e máximos | percentis, matemática de métricas |
| alarmes | guarda o alarme e deixa você definir o estado à mão | avaliá-lo, mudar o estado sozinho, avisar alguém, alarmes compostos |
| logs | guarda eventos e os devolve | aplicar um padrão de filtro, rodar uma consulta do Logs Insights, transformar um filtro de métrica em métrica |
| identidade | com uma chave, confere as políticas de quem chama, por ação | conferir o `Resource` de uma declaração, ler uma política de chave ou de bucket |
| KMS e Parameter Store | cifra e decifra, guarda um `SecureString` | recusar uma chave agendada para exclusão; ele guarda o valor "cifrado" com o texto puro dentro |
| achados de segurança | responde a uma varredura de imagem | achar qualquer coisa: o único achado que devolve é de mentira |
| preços | nada | preços: cada número deste curso vem da lista pública de preços da AWS, com a data |

Cada uma dessas linhas volta na lição a que pertence, com a transcrição que a mostra. Onde o moto
não consegue mostrar o comportamento real, a lição o ensina pela documentação da AWS e diz, com essas
palavras, que aquela parte não foi executada. **Leia essas frases com a mesma seriedade das
transcrições.** Uma chamada que funcionou no moto prova que a requisição estava bem formada, e nada
sobre se a AWS a teria permitido.

## A única chave

Por padrão o moto deixa qualquer um fazer tudo. Iniciado com `INITIAL_NO_AUTH_ACTION_COUNT`
definida, ele deixa passar esse número de requisições sem conferir, o bastante para criar um usuário
e dar uma política a ele, e dali em diante recusa qualquer ação que as políticas de quem chama não
permitam. A lição 17 usa isso, porque uma lição sobre quem pode ler um segredo é uma lição sobre uma
recusa. Ele confere a **ação** e não o recurso, então uma política limitada a um segredo se comporta,
no moto, como uma política que não nomeia segredo nenhum. Aquela lição mostra isso.

## Uma conta de verdade, se você quiser

Nada neste curso precisa de uma conta AWS de verdade, e nada nele fica mais fácil com uma. **Se você
abrir uma mesmo assim**, a lição 1 de `aws-foundations` tem a seção sobre fazer isso com segurança, e
a ordem é a parte para lembrar: proteja o usuário root com um segundo fator, depois crie um
orçamento com alerta, antes de qualquer outra coisa. O free tier é uma possibilidade para uma
conta pequena, nunca uma promessa: o que ele cobre muda, e um recurso esquecido é cobrado quer você
quisesse mantê-lo ou não. Esses passos não podem ser gravados sem uma conta, então não foram
executados para este curso e nenhuma transcrição deles aparece aqui.

Duas regras valem de qualquer jeito. **Nunca ponha uma chave de acesso real num arquivo que este
curso manda você criar**, e nunca cole uma numa pergunta ou num fórum. E os comandos destas lições
foram escritos para o moto: apontados para uma conta real, vários deles criam coisas que custam
dinheiro por hora.
