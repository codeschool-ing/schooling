---
title: Quando o Domain-Driven Design compensa
version: 1
---

**Domain-Driven Design é um jeito de construir software para um negócio complicado colocando o
modelo do próprio negócio, com as palavras dele, no centro do código.** Eric Evans o descreveu em
2003, num livro com o subtítulo *Tackling Complexity in the Heart of Software*, e o subtítulo é a
parte a lembrar. DDD é um conjunto de ferramentas para a complexidade que mora nas regras, e onde as
regras são simples ele vira cerimônia.

A imagem errada de DDD é uma estrutura de pastas: `entities/`, `value_objects/`, `repositories/` e
uma classe chamada `Aggregate` em algum lugar. Esses são os padrões *táticos*, e a lição 12 trata
deles. São a metade menor. A metade maior é *estratégica*: combinar as palavras com as pessoas que
tocam o negócio, decidir que parte do sistema merece mais cuidado e traçar as linhas onde um
significado de uma palavra termina e outro começa. Uma equipe pode usar todos os padrões táticos e
nada da estratégia, e terminar com o mesmo emaranhado em mais arquivos.

## O teste: onde mora a dificuldade?

Pergunte o que torna o software difícil. Se a resposta for "as telas", "o volume" ou "as
integrações", o DDD tem pouco a oferecer. Se a resposta for "as regras, e as discussões sobre as
regras", ele tem muito.

Pegue duas partes da biblioteca. A primeira é a página em que uma sócia edita o telefone e o
endereço. Ela lê uma linha, mostra um formulário, valida alguns campos e grava a linha de volta.
Cada regra cabe numa frase, e nenhuma depende de outra. Um módulo simples de criar, ler, atualizar e
apagar, escrito rápido, é o projeto certo.

A segunda é o empréstimo. Eis o que as bibliotecárias disseram quando perguntaram como funciona:

- um livro sai por 14 dias, um filme por 7, e um livro de referência não sai;
- devoluções atrasadas custam 50 centavos por dia, e um sócio que deve mais de 1000 centavos não
  pode pegar emprestado;
- um sócio pode ter no máximo 5 empréstimos ao mesmo tempo;
- um título com reservas não pode ser renovado;
- um exemplar devolvido que tem reserva vai para a estante de reservas, não de volta às estantes, e
  espera 7 dias.

**Cada regra é simples, e o problema é que elas se encontram.** Uma renovação mexe no empréstimo,
nas reservas e na multa. Uma devolução mexe no empréstimo, na multa, na estante de reservas e no
próximo sócio da fila. Mude uma regra, digamos filmes saindo por 10 dias, e a pergunta é quais das
outras ela perturba. É para esse tipo de dificuldade que o DDD foi escrito, e numa biblioteca é aqui
que as bibliotecárias gastam as discussões delas.

## O que custa

DDD não é de graça, e a conta vem em conversas, mais do que em código. Ele pede que os
desenvolvedores sentem com quem conhece o negócio, com frequência, e renomeiem coisas no código
quando o negócio os corrige. Pede disciplina com fronteiras que um modelo único deixaria você
ignorar por um tempo. Numa equipe pequena com um domínio simples, esse tempo não compra nada.

| sinal | provavelmente vale | provavelmente não |
|---|---|---|
| onde está a parte difícil | regras que interagem | telas, vazão, integrações |
| quem consegue explicar as regras | só gente de fora da equipe | qualquer um que leia o código |
| com que frequência as regras mudam | a cada poucos meses, por discussão | raramente, e de forma simples |
| quanto tempo o sistema vive | anos | uma campanha, um protótipo |

O resto desta lição constrói a metade estratégica sobre a biblioteca: primeiro as palavras, depois
as partes do negócio e quanto cada uma merece, depois as linhas entre modelos, como esses modelos se
relacionam, e como proteger um do outro. A última seção é uma oficina para descobrir tudo isso numa
sala.
