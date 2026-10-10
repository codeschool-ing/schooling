---
title: Uma lista de verificação para o próximo padrão que você for usar
version: 1
---

**A lição inteira cabe em algumas perguntas, feitas em ordem, antes de um padrão entrar e de novo
quando alguém propõe tirar um.** Uma lista de verificação não substitui o julgamento. É um jeito de
garantir que o julgamento seja aplicado às coisas certas, na ordem certa, no dia em que você está
cansado e o padrão parece óbvio.

A ordem importa. Cada pergunta é mais barata de responder que a seguinte, e um "não" logo no começo
poupa o resto.

## Antes de acrescentar um padrão

1. Qual é a força, numa frase? Algo muda e a mudança sai cara, ou uma parte sabe o que não devia.
   Se a frase não vem, ou sai como "ficaria mais limpo", pare aqui.
2. A força é real hoje? Aponte para ela: a terceira cópia do mesmo `if`, o histórico de mudanças
   que vive mexendo nos mesmos cinco arquivos, o teste que precisa de um servidor de e-mail. Uma
   força prevista para o ano que vem é motivo para manter o código fácil de mudar, não para
   construir a estrutura agora.
3. Qual é a menor resposta? Um dicionário, uma função passada como argumento, um objeto no nível do
   módulo, uma lista de chamáveis. Python, Go, TypeScript e o Java moderno tornam baratas as formas
   pequenas, que era o argumento da lição 6 sobre padrões embutidos na linguagem.
4. Quanto custa para quem lê? Conte os arquivos e os saltos para responder a pergunta mais comum
   sobre esse código, como o `hops.py` fez. Compare isso com a frequência da mudança que ele
   absorve.
5. O que acontece com concorrência? A pergunta da lição 18: quem mais pode estar aqui ao mesmo
   tempo? Um singleton construído sob demanda ou uma lista de observers que muda durante o
   percurso é um defeito novo, não um padrão.
6. O que reabriria a decisão? Anote, num ADR se a escolha foi discutida, ao lado do código se não
   foi.

## Antes de remover um

As mesmas perguntas, lidas do outro lado. Estrutura especulativa vale a pena remover, e estrutura
que responde a uma força que você não está vendo vale a pena deixar. Antes de apagar uma interface,
procure a segunda implementação nos testes. Antes de achatar uma camada, procure a regra ou a
tradução que ela faz. Antes de trocar um dicionário de funções por uma hierarquia, ou o contrário,
procure o registro que diz por que está como está. **Remover um padrão também é uma decisão de
projeto, e merece as mesmas evidências que acrescentar um.**

## O currículo do título

O título da lição nomeia uma pressão que vale admitir. Padrões são um vocabulário que entrevistas e
revisões recompensam, e usar um é um jeito de mostrar que você o conhece. Isso não é um mau motivo
numa lição, num kata ou num projeto pessoal, em que o objetivo é aprender o formato. É um mau motivo
num código que outras pessoas vão ler por anos, porque o custo da demonstração cai sobre elas.

A prova de que você entende um padrão não é tê-lo usado. É conseguir dizer a que força ele
responde, quanto custa e quando você o tiraria de novo. Cada lição deste curso tentou dar isso a
você para uma família de padrões, e o curso seguinte, `architecture-modeling`, desenha os mesmos
padrões como modelos, em que as forças e os custos precisam ser declarados antes de qualquer coisa
ser construída.
