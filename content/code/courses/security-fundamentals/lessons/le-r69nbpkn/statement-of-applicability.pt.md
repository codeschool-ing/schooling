---
title: A declaração de aplicabilidade
version: 1
---

O Anexo A é uma lista de 93 controles, e nenhuma organização precisa de todos do mesmo jeito. Uma loja
sem desenvolvedores de software tem pouco uso para codificação segura; uma organização sem instalações
próprias tem pouco a dizer sobre áreas seguras. A 27001 não exige todos os controles. Ela exige algo mais
exigente: que a organização **decida sobre cada um e diga por quê.**

Essa decisão fica registrada na **declaração de aplicabilidade** (*statement of applicability*, SoA), um
dos documentos que a 27001 exige. Para cada um dos 93 controles ela diz:

| coluna | o que vai nela | linha de exemplo |
|---|---|---|
| controle | o número e o nome no Anexo A | 8.13 backup das informações |
| aplicável? | sim ou não | sim |
| justificativa | por que é incluído ou excluído, em geral apontando um risco | R2 ransomware, R5 enchente (aula 3) |
| situação | implementado, parcial, planejado | implementado: backup noturno, teste mensal de restauração |
| referência | onde estão o detalhe e a evidência | procedimento de backup; registro de restauração (aula 12) |

E um excluído:

| controle | aplicável? | justificativa |
|---|---|---|
| 8.28 codificação segura | não | a loja não desenvolve software; o site é uma plataforma hospedada, coberta pelos 5.19 a 5.22 de segurança com fornecedores |

### Por que ela importa tanto

A SoA é a **ponte entre a avaliação de riscos e os controles**. Todo "sim" deveria remeter a um risco no
registro, e todo "não" deveria ser defensável: um auditor lê as exclusões com cuidado especial, porque
uma exclusão é o lugar mais fácil de esconder um controle que ninguém quis implementar. "Não aplicável
porque nunca fizemos" não é justificativa; "não aplicável porque a atividade não existe no escopo" é.

Ela também é o documento que gente de fora pede. Um cliente avaliando a loja como fornecedora aprende
mais com a SoA do que com o certificado: quais controles se aplicam, quais estão completos e quais ainda
estão planejados. Muitas organizações a compartilham sob acordo de confidencialidade exatamente por isso.

### Controles além do Anexo A

O Anexo A não é um teto. Se a avaliação de riscos pede um controle que não está na lista, a organização o
acrescenta, e a 27001 espera isso. A SoA então o inclui com os outros. A lista é uma referência para
conferir, para que nada importante passe despercebido; os controles em si vêm dos riscos.
