---
title: Backups que não são inteiramente seus
version: 1
---

Os backups do provedor são as lições 5 e 6, executadas para você: um base backup toda noite, o log
arquivado continuamente e recuperação para um ponto no tempo em qualquer momento dentro de uma
**janela de retenção** que você escolhe, em geral de uma semana a um mês. Três coisas sobre eles
decorrem do resto deste curso:

1. **Uma restauração cria um banco novo.** A recuperação para um ponto no tempo cria uma instância
   nova a partir dos backups, com o próprio endereço; a antiga continua rodando com o erro dentro. O
   seu runbook (lição 24) precisa dos passos para apontar a aplicação para a nova, e o tempo que isso
   leva, medido, é o seu RTO.
2. **Eles ficam na mesma conta.** Os backups, o arquivo e o banco estão todos ao alcance de quem tem
   as credenciais administrativas da conta, e apagar a instância muitas vezes apaga junto os backups
   automáticos dela. É o cenário de ransomware da lição 10 com outra porta: a cópia que precisa
   sobreviver tem de estar num lugar que essas credenciais não alcançam. Um dump lógico (lição 2),
   feito na sua própria agenda e guardado em outro lugar, é a resposta de costume, e é o único backup
   num serviço gerenciado que é completamente seu.
3. **Ninguém restaura esses backups por você para conferir.** O ensaio da lição 7 é tão necessário
   aqui quanto em qualquer lugar: uma restauração numa instância nova, uma conferência das linhas, um
   cronômetro. A única diferença é que o servidor custa dinheiro por hora enquanto existe, então apague
   ele depois.

## As perguntas a fazer antes de assinar

- Que disponibilidade o contrato promete, e o que conta como "indisponível"?
- O standby é síncrono? Quanto tempo leva um failover, medido por você?
- Qual é o tamanho da janela de retenção, e o que acontece com os backups quando uma instância é apagada?
- Os backups podem ser copiados para outra região, ou outra conta?
- O que você não pode fazer: quais extensões, quais configurações, superusuário?
- Como você tira os seus dados, todos eles, se for embora?
