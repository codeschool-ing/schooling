---
title: Quem faz o quê
version: 1
---

A LGPD distribui deveres entre alguns papéis, e a mesma organização pode ter papéis diferentes em
tratamentos diferentes.

| papel | quem é | na livraria |
|---|---|---|
| **titular** | a pessoa natural a quem os dados se referem | cada cliente; cada pessoa da equipe, na folha de pagamento |
| **controlador** | quem toma as decisões sobre o tratamento | a loja, para a lista de clientes e a folha |
| **operador** | quem trata dados em nome do controlador | a empresa de hospedagem, o serviço de e-mail, o contador da folha |
| **encarregado** | a pessoa que é o canal entre o controlador, os titulares e a ANPD; muitas vezes chamada de DPO | na loja, um dos sócios |
| **ANPD** | a autoridade nacional: regulamenta, fiscaliza, sanciona | |

### Controlador e operador

A distinção é sobre **quem decide**. A loja decide por que os dados dos clientes são coletados e o que se
faz com eles, então ela é a controladora. A empresa que hospeda o site guarda esses dados só para prestar a
hospedagem que a loja comprou, seguindo as instruções da loja, então ela é operadora. Operadores têm
deveres próprios, inclusive de segurança, e respondem junto com o controlador quando descumprem a lei ou as
instruções lícitas do controlador.

Essa é a transferência da aula 3, vista pela lei: a loja pode contratar um operador para guardar os dados
dela, e **não pode contratar a saída do papel de controladora**. O contrato com cada operador deveria dizer
o que o operador pode fazer com os dados, exigir medidas de segurança e exigir que ele comunique
incidentes à loja depressa, já que os três dias úteis da loja começam quando a loja fica sabendo.

### O encarregado

O artigo 41 exige que o controlador indique um **encarregado**, cuja identidade e contato precisam ser
divulgados com clareza, em geral no site. O encarregado aceita reclamações e pedidos dos titulares, recebe
comunicações da ANPD e orienta a equipe sobre as práticas de proteção de dados.

### Pequenos negócios

A **Resolução CD/ANPD nº 2 de 2022** da ANPD criou um **regime simplificado para agentes de tratamento de
pequeno porte**: microempresas, empresas de pequeno porte, startups e outros, **a não ser que façam
tratamento de alto risco**. Entre as simplificações: o agente de pequeno porte não precisa indicar um
encarregado, mas precisa oferecer um canal de comunicação com os titulares; pode manter um registro
simplificado das operações de tratamento; e alguns prazos são maiores. Os deveres do artigo 46, de manter
os dados seguros, e do artigo 48, de comunicar incidentes graves, continuam.

A loja se enquadra, e mesmo assim escolheu nomear um dos sócios como encarregado. Uma pessoa nomeada é mais
fácil de os clientes acharem e mais fácil de cobrar pelo princípio da responsabilização.

### O que tudo isso soma

As exigências da lei, postas ao lado deste curso, são quase todas coisas que o curso já construiu por
outros motivos. Um registro de riscos, menor privilégio, logs com nomes, backups testados, um inventário,
evidência guardada: cada um se justificou pelos riscos próprios da loja, e cada um acaba sendo o que a
LGPD pede. É o padrão da aula 13 mais uma vez. **Segurança feita por motivos reais produz quase tudo o que a
conformidade precisa**, e o que sobra, o encarregado, o registro das operações de tratamento, o
procedimento de incidentes, é uma lista curta por cima.
