---
title: Onde o analista para e o arquiteto começa
version: 1
---

**O analista de negócio é dono da pergunta *o que é preciso e por quê*; o arquiteto é dono de *como o
sistema vai entregar isso, e quanto custa*.** Os dois se encontram no meio, nos requisitos de solução
e nas opções de design, e a maior parte do atrito entre eles acontece onde ninguém decidiu quem é
dono desse meio.

## A sobreposição, na prática

| | o analista | o arquiteto |
| --- | --- | --- |
| necessidades e objetivos de negócio | conduz | escuta; pergunta quanto vale o objetivo |
| stakeholders | identifica, mapeia, engaja | acrescenta os técnicos: Plataforma, Pagamentos, as ferramentas dos auditores |
| requisitos funcionais | elicita e escreve | confere se cada um pode ser construído e testado |
| atributos de qualidade | elicita os números do negócio | transforma-os em cenários, avalia a dificuldade |
| opções de design | descreve o impacto de cada uma no negócio | propõe as opções e registra a decisão |
| requisitos de transição | elicita | desenha a migração e a execução em paralelo |

## Três falhas na fronteira

- **O analista desenha a solução.** Um requisito que diz *o job lê o arquivo de liquidação de uma
  pasta SFTP toda noite às 03:00* decidiu a arquitetura dentro de um documento de requisitos. A
  pergunta de volta do arquiteto é *qual é a necessidade?*, que é o *o quê, não o como* da aula 6.
- **O arquiteto ignora o negócio.** Uma conciliação tecnicamente excelente, que cruza tudo o que o
  gateway manda e nada do que acontece no balcão, atende a todos os requisitos de solução e falha no
  de negócio.
- **Ninguém é dono dos números de qualidade.** O analista supõe que o arquiteto vai defini-los; o
  arquiteto espera pelo negócio. *Termina até as 07:00 num dia de São João* só foi escrito porque
  Tainá perguntou a Joana a que horas ela começa a trabalhar.

## Quando não há analista

No Carcará, como na maioria das empresas do seu tamanho, há uma analista, Joana, e ela trabalha
quase só para o financeiro. Nos outros times **o arquiteto ou um tech lead faz análise de negócio sem
o cargo**. Fazer isso de propósito é tomar emprestado o mínimo desta aula: os seis conceitos centrais
numa página, uma lista de stakeholders que inclua as pessoas que ninguém convidou, pelo menos uma
observação em vez de só entrevistas, as quatro classes para que os requisitos de transição não sejam
esquecidos, e o MoSCoW com o *won't* escrito.

**Desenhe você mesmo.** Escolha uma mudança que você conheça, no trabalho ou num projeto de curso.
Preencha os seis conceitos centrais numa página, liste os stakeholders e posicione-os num mapa de
influência e interesse, e escreva um requisito de cada uma das quatro classes. A classe que você
achar mais difícil de preencher costuma ser a que falta no seu projeto.
