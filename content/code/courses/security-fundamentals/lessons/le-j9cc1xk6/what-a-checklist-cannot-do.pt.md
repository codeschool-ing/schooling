---
title: O que um checklist não faz
version: 1
---

Checklists são uma das ferramentas mais eficazes em segurança, e em muitas outras áreas: a aviação e a
cirurgia os adotaram porque especialistas sob pressão esquecem passos que conhecem perfeitamente. Um
checklist também é fácil de superestimar, e os limites dele valem ser ditos com a mesma precisão que as
forças.

### Ele só sabe o que lhe contaram

Um checklist pega problemas **conhecidos**: configurações que alguém já identificou como arriscadas,
escritas de antemão. Ele não diz nada sobre o problema que ninguém listou. As quatro linhas da loja não
dizem nada sobre quem tem uma chave SSH do `www`, se uma dessas chaves é de alguém que saiu em março, ou se
o servidor deveria sequer ser alcançável por SSH a partir da internet. Essas perguntas são das aulas 5 e
6, e um checklist que passa não as responde.

**Tudo PASS quer dizer "nenhuma configuração errada conhecida", e não "seguro".** É o conformidade não é
segurança da aula 13 em miniatura: todos os itens podem estar marcados enquanto o risco que importa está
em outro lugar.

### Ele é verdade no dia em que roda

Um servidor conferido em março e mudado em abril é outro servidor. Um administrador com pressa religa o
login por senha para resolver um problema urgente e esquece de desligar; uma atualização de pacote traz
um padrão novo; alguém copia uma configuração de uma máquina antiga. Isso é **desvio de configuração**
(*configuration drift*), e a defesa é aquela com que a seção anterior terminou: rodar as verificações de
forma automática e frequente, e tratar uma linha que vira `FAIL` como alerta. Um checklist rodado uma vez
por ano para o auditor acha o desvio onze meses atrasado.

### Ele precisa de exceções, por escrito

Às vezes um item do checklist está errado para um sistema. Um servidor que precisa aceitar login por
senha de um parceiro que não consegue usar chaves é um caso real. A resposta não é apagar a linha do
checklist, o que esconde a decisão, nem deixá-la falhar para sempre, o que ensina todo mundo a ignorar
falhas. É uma **exceção** documentada: o item, o sistema, o motivo, quem aceitou e até quando, no
registro de riscos da aula 3, com um controle compensatório da aula 4 quando houver. O checklist então
relata o item como exceção aceita, e não como falha.

### Ele precisa ser entendido, não só rodado

Um checklist aplicado sem ler a justificativa quebra coisas. Uma configuração de Nível 2 que desliga um
recurso de que alguém depende, aplicada às cegas, vira uma queda, e na próxima vez a equipe pula o
checklist inteiro. Cada linha existe por um motivo; quem a aplica deveria saber o motivo, e é por isso que
o checklist da loja tem uma coluna de "por quê" e os benchmarks têm uma justificativa para cada item.

### Onde ele se encaixa

Nada disso é argumento contra checklists. É argumento para usá-los como **uma camada**: a camada barata e
automatizável que pega a grande classe de erros conhecidos, para que a atenção das pessoas fique livre
para as perguntas que só pessoas respondem. Nos termos do CSF da aula 15, um checklist é uma ferramenta
forte para Proteger e fraca para todo o resto; na lista de IG1 da loja, é a primeira linha do controle 4
e nada mais.
