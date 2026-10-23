---
title: O checklist, e para que ele serve
version: 1
---

**Um checklist de revisão é uma lista de perguntas que revisores experientes fazem sempre, escrita
para que sejam feitas mesmo quando o revisor está cansado, é novo ou está com pressa.** Ele não
substitui o julgamento; garante que o julgamento seja aplicado a tudo, e não ao que chamou a atenção
do revisor primeiro.

## O checklist da Carcará

O checklist de Tainá nasceu dos riscos achados em revisões, uma pergunta para cada tipo de risco que
já tinha chegado à produção uma vez. Ele tem seis grupos:

| grupo | perguntas |
| --- | --- |
| **requisitos** | Que cenários de qualidade esta mudança afeta? As medidas deles ainda são atendidas, e como sabemos? Algum requisito significativo ficou sem verificação? |
| **decisões** | Em que decisões isto se apoia, ou que decisões muda? Há um registro para cada escolha difícil de desfazer, com opções e consequências? |
| **falha** | Para cada chamada pela rede, o que acontece se ela for lenta, falhar ou responder duas vezes? Onde estão os timeouts, e eles se aninham do jeito certo? |
| **dados** | Quem é dono de cada dado? O que acontece com os dados existentes quando o formato muda? Os dados pessoais estão cobertos pelos caminhos de exclusão e de exportação? |
| **operação** | Quem é acionado quando quebra, e o que essa pessoa vê? Como é implantado, e como se volta atrás? Quanto custa por mês no pico? |
| **documentos** | Os diagramas afetados são atualizados na mesma mudança? Cada um tem um dono e uma data? As funções de aptidão cobrem as regras novas? |

Cada pergunta remonta a algo que este curso construiu: cenários à aula 6, registros à aula 5, falha à
leitura de sequência da aula 2, documentos à aula 11. **Um checklist é o curso comprimido em
perguntas**, e é esse o valor dele: um revisor que conhece os motivos por trás de cada pergunta
consegue julgar quando um *não* importa.

## Regras para um checklist que continua útil

- **Curto o bastante para ser usado.** *The Checklist Manifesto*, de Atul Gawande, defende listas que
  caibam numa página e cubram os passos que as pessoas de fato pulam. O da Carcará tem vinte
  perguntas.
- **Perguntas, não instruções.** *Os timeouts se aninham do jeito certo?* pode ser respondida com sim
  ou não e discutida. *Use timeouts corretos* não pode.
- **Cada pergunta conquistada.** Uma pergunta entra quando um risco do tipo dela chega à produção, e
  sai quando ninguém responde *não* a ela durante um ano.
- **Com dono e data**, como toda página da aula 11. Um checklist que ninguém mantém vira um ritual.

## O checklist não é a revisão

Um time que passa por vinte perguntas e marca todas fez um checklist, não uma revisão. **As perguntas
são onde a revisão começa**: cada *não* ou *não sei* é um fio a puxar, com os cenários na mão. O tema
de risco da internet das rodoviárias, desta aula, não veio de uma pergunta do checklist; veio de
seguir três respostas *não sei* diferentes até elas se encontrarem.
