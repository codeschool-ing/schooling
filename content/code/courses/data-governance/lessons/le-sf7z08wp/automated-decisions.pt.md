---
title: Decisões que nenhuma pessoa tomou
version: 1
---

Três leis agora têm algo a dizer quando uma máquina decide algo sobre uma pessoa.

**GDPR, artigo 22.** A pessoa tem o direito de **não ficar sujeita a uma decisão tomada
exclusivamente com base em tratamento automatizado**, incluindo perfilamento, que produza efeitos
jurídicos sobre ela ou que a afete significativamente de forma similar. Ela só é permitida quando
necessária a um contrato, autorizada por lei, ou baseada em consentimento explícito — e no primeiro e
no último caso o controlador deve garantir pelo menos o direito de obter **intervenção humana**, de
manifestar o seu ponto de vista e de contestar a decisão. Os artigos 13 a 15 acrescentam o direito a
**informações úteis sobre a lógica subjacente**.

**LGPD, artigo 20.** Aula 7: o direito de pedir a **revisão** de uma decisão tomada unicamente com
base em tratamento automatizado, e informações sobre os critérios dela. Desde a reforma de 2019 a lei
não diz que a revisão precisa ser humana.

**AI Act, artigo 86.** Uma pessoa afetada por uma decisão que o responsável pela implantação tomou com
base no resultado de um sistema de alto risco, com efeitos jurídicos ou igualmente significativos,
pode pedir **uma explicação clara e útil do papel do sistema** na decisão e dos seus principais
elementos. Ele está ligado aos sistemas de alto risco do Anexo III.

## Onde as três diferem

O GDPR parte de uma proibição com exceções; a LGPD parte de uma permissão com direito a revisão. As
exceções do GDPR exigem um humano que possa intervir; a LGPD, depois de 2019, não. E o direito do AI
Act vale para um conjunto mais estreito de sistemas, mas pede algo que os outros dois não pedem
exatamente: que papel *o sistema* teve, que é uma pergunta diferente de quais foram os critérios.

No `fraud-score` da Ipê, cancelar um pedido só com a palavra do modelo é uma decisão com efeito
significativo. Em Lisboa, o artigo 22 obriga a Ipê a oferecer uma pessoa que possa olhá-la de novo. Em
São Paulo, o artigo 20 obriga a Ipê a revisá-la a pedido e explicar os critérios. O desenho mais
simples que atende os dois é o do GDPR: **uma pessoa revisa todo cancelamento antes de ele ser
definitivo** — que também é o desenho em que um modelo errado é notado primeiro.

## O que isso pede do dado

Explicar uma decisão meses depois exige a decisão **registrada como foi tomada**: que versão do
modelo, que entradas, que score, que limiar, qual foi o resultado, e quem revisou. Isso é uma tabela
de decisões só de inserção, o mesmo formato dos eventos de consentimento da aula 7 e da trilha de
auditoria da aula 10. Um modelo que é retreinado toda semana e cujas versões antigas são apagadas não
consegue explicar nada do que fez no mês passado.
