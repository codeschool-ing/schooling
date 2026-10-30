---
title: Decidir de propósito
version: 1
---

O aprisionamento chega de dois jeitos. **Por acidente**, uma chamada conveniente de cada vez, até
alguém perguntar o que seria preciso para sair e ninguém saber responder. **De propósito**, quando
uma equipe escolhe um serviço sabendo a que ele a prende, anota isso e ganha algo que vale o preço. A
diferença não está em quais serviços são usados. Está em a escolha ter sido anotada ou não.

## Uma linha por dependência

O registro é curto, e mora ao lado do código. Para cada serviço do Google de que a loja depende,
quatro coisas:

| o que usamos | por quê | o que sair exige | quando olhar de novo |
|---|---|---|---|
| Cloud Run para orders e web | escala até zero, nenhum cluster para operar | refazer em qualquer serviço de contêineres; as imagens vão como estão | uma necessidade que o Cloud Run não atenda, como um protocolo que não seja HTTP |
| Eventarc e eventos do Cloud Storage para as fotos | miniaturas sem fila para operar | um gatilho novo; o handler lê CloudEvents | o volume de fotos fazer da saída de dados a maior linha da conta |
| Pub/Sub, atrás do módulo `events` da loja | ordem e novas tentativas que não construímos | reescrever um módulo | precisarmos de um segundo provedor por qualquer motivo |
| Cloud Scheduler e um job do Cloud Run para a exportação | cron sem máquina | qualquer agendador que chame uma URL | nunca, provavelmente; é a dependência mais barata da lista |
| um compromisso de um ano no Cloud Run | um preço menor | os meses que faltam do prazo | o mês antes da renovação |

A última coluna é a que importa. Uma dependência sem condição de "olhar de novo" deixou de ser uma
decisão e virou um fato do sistema que ninguém lembra de ter escolhido.

## Regras práticas que se sustentam

- **Prefira a costura quando ela não custa nada.** Um contêiner em vez de um upload de código-fonte,
  CloudEvents em vez de um payload específico do provedor, uma função que o Functions Framework
  serve localmente. Isso é portabilidade de graça, e recusá-la é aprisionamento sem benefício.
- **Aceite o serviço proprietário quando ele poupa você de construir um**, e embrulhe-o num módulo
  seu. As garantias de entrega do Pub/Sub não valem ser reconstruídas só para continuar portável.
- **Comprometa-se só com o que você rodaria de qualquer forma.** Um desconto por compromisso na base
  que roda há um ano é dinheiro economizado; numa capacidade que você espera precisar é dinheiro
  prometido.
- **Mantenha os dados onde você consegue pagar para movê-los**, e dê preço a essa mudança uma vez
  por ano com o programa da seção anterior.

## O que este curso deixa com você

Vinte e três lições de computação se resumem a um hábito: **escolher por serviço, com números, e
escrever os motivos onde a próxima pessoa vai encontrá-los.** O `gcp-operations` pega a loja daqui:
observá-la rodando, pagar por ela e mantê-la de pé quando algo quebra. Tudo que você decidiu neste
curso é o que aquele curso vai observar.
