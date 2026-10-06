---
title: Risco residual e apetite
version: 1
---

Nenhum tratamento, fora evitar, leva um risco a zero. Depois que os controles entram, sobra algum
risco, e o vocabulário tem uma palavra para cada ponta:

- **risco inerente** é o risco antes de qualquer controle, como se nada tivesse sido feito;
- **risco residual** é o que sobra depois que os controles escolhidos estão no lugar.

O R2 tinha uma ALE de R$ 4.000 por ano antes do backup offline e de R$ 400 depois. Os R$ 400 são o
risco residual, e alguém tem de aceitá-lo, exatamente como aceitaria um risco não tratado. **Todo
tratamento termina com a aceitação do que sobrou.** Mitigar não encerra a conversa; muda o que está
sendo aceito.

### Quanto é aceitável

**Apetite a risco** é quanto risco uma organização está disposta a correr em busca dos objetivos
dela, dito de antemão pela liderança. Uma startup vendendo algo novo tem um apetite grande; um
banco, pequeno. Os sócios da loja escreveram o deles numa frase: *"Aceitamos riscos com nota até 6
na matriz sem outra aprovação; acima de 6, é preciso um plano de tratamento ou a nossa assinatura."*

**Tolerância a risco** é o desvio aceitável para um objetivo específico, em geral como número: o
site pode ficar fora no máximo quatro horas por mês; não mais que um notebook por ano pode sumir sem
uma revisão. O apetite é a política; a tolerância é onde a política encontra uma medida.

Com um apetite escrito, a maioria das decisões deixa de ser discussão:

| risco | nota inerente | depois do tratamento | dentro do apetite (≤ 6)? |
|---|---|---|---|
| R1 senha padrão do portal | 16 | 2 × 4 = 8 | não: precisa da assinatura dos sócios |
| R2 ransomware | 10 | 2 × 2 = 4 | sim |
| R3 notebook perdido | 9 | 3 × 1 = 3 | sim |
| R4 atualização que falhou | 6 | 6 | sim, aceito como está |
| R5 enchente | 4 | 4 | sim, aceito como está |

O R1 é a linha interessante. Depois da troca de senha e do MFA, a nota residual é 8, ainda acima do
apetite de 6. A tabela deixa o próximo passo claro: ou mais um controle (tirar o portal da internet
baixa a probabilidade para 1 e a nota para 4), ou os sócios assinam o 8. Quem decide é quem é dono
do risco, nunca a TI em nome próprio.

### De quem é um risco

Todo risco tem um **dono do risco**: a pessoa que responde por decidir o tratamento e por aceitar o
que sobra. Em geral é o dono do ativo em jogo. A folha de pagamento é do financeiro, então o dono do
R1 é o bruno, que cuida do financeiro. A ana, da TI, propõe os controles e faz o trabalho; o bruno
decide se o risco residual é aceitável. Essa divisão impede a TI de aceitar riscos calada em nome
do negócio, e impede o negócio de fingir que um risco é problema de outro.
