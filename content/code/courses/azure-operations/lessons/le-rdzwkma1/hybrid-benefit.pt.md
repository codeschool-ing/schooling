---
title: Azure Hybrid Benefit: licenças que você já tem
version: 1
---

**O Azure Hybrid Benefit deixa uma organização usar licenças que já tem em vez de pagar de novo por elas no preço do Azure.** A
taxa por hora de uma VM Windows Server inclui a licença do Windows; a de uma VM com SQL Server ou de um banco Azure SQL por vCore
inclui a do SQL Server. Uma organização com essas licenças no ambiente local, com um contrato que cubra levá-las (Software
Assurance ou uma assinatura equivalente), pode ligar o benefício e pagar só pela computação.

É uma propriedade, não uma compra: `licenseType: 'Windows_Server'` numa VM, ou `licenseType: 'BasePrice'` num banco Azure SQL por
vCore, no mesmo Bicep do recurso. Ele se combina com uma reserva: a reserva desconta a computação, e o benefício tira a licença.

Três coisas o fazem uma decisão, e não um interruptor:

- **você precisa ter as licenças**, e contá-las: o benefício é uma afirmação que a sua organização faz, e uma auditoria de licenças
  é onde uma afirmação sem licenças aparece;
- **ele vale para Windows e SQL Server**, e para Red Hat e SUSE Linux nos programas deles; o App Service em Linux da loja e os
  workers de código aberto não têm nada para ele tirar;
- **a economia é a parte da licença na taxa**, que é grande para o Windows e muito grande para o SQL Server Enterprise, e é
  publicada por tamanho.

Para a loja, hoje, o benefício vale para uma coisa: `vm-reports`, uma VM Windows de uma ferramenta de relatórios, que a lição 23
está prestes a encontrar fazendo muito pouco.
