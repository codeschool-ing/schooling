---
title: Um arquivo de instruções para o projeto
version: 1
---

Toda requisição começa do nada (aula 1 seção 06), então um assistente não conhece as regras do seu
projeto a menos que algo as ponha no contexto toda vez. **Um arquivo de instruções é um arquivo no
repositório que o assistente lê em toda requisição**, e é o jeito mais barato de parar de corrigir
o mesmo erro duas vezes.

As ferramentas não concordam com o nome. Em 2026 os comuns são o `AGENTS.md`, lido por vários
assistentes de fornecedores diferentes, o `CLAUDE.md` para o Claude Code, o
`.github/copilot-instructions.md` para o GitHub Copilot, e um diretório `rules` para o Cursor. São
todos Markdown, e todos funcionam do mesmo jeito. O `assist` lê o `AGENTS.md`.

## Um curto

O projeto da ana já tem o `CONVENTIONS.md`, escrito para pessoas. Ela não o copia para o arquivo
de instruções; aponta para ele e repete só as regras que um assistente mais quebra:

```
# Notes for coding assistants

Read CONVENTIONS.md before changing anything. The rules that matter most:

- Money is integer cents. Never introduce a float, not even in a test.
- Run `python -m pytest` after every change, and say if it fails.
- Never edit a test to make it pass. If a test looks wrong, say so instead.
- Standard library only. Ask before adding a dependency.
```

A mesma requisição de completar de antes agora o leva, em primeiro lugar:

```
ana@dev:~/shop$ assist complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py 2>&1 >/dev/null
context sent (765 of 3000 tokens):
     87  AGENTS.md
    411  shop/cart.py (cursor at line 34)
     91  shop/coupons.py
    176  tests/test_cart.py
---
```

**87 tokens, em toda requisição**, que é o preço do arquivo e o motivo de mantê-lo curto. A aula 2
seção 03 contou o `CONVENTIONS.md` em 374 tokens como prompt de sistema; mandá-lo inteiro em cada
completação disparada por uma tecla seria a maior parte da requisição. Um ponteiro e quatro regras
é a troca.

## O que cabe nele

- **O que um recém-chegado erraria no primeiro dia**: o dinheiro é em centavos, os testes rodam com
  este comando, o formatador é este. Não o que qualquer dev competente faria de qualquer jeito.
- **Os comandos**: como rodar os testes, o linter, o build. Assistentes que rodam comandos (aula 3
  seção 08) os usam diretamente.
- **Os limites**: "nunca edite um teste para ele passar", "pergunte antes de acrescentar uma
  dependência". Uma regra que é uma recusa é o tipo que um modelo mais segue quando está dita com
  clareza.
- **Nada de segredos, e nada que mude todo dia.** O arquivo vai para o commit, é lido pelas
  ferramentas de todo mundo, e uma instrução velha é pior que nenhuma.

## O que ele não faz

**Um arquivo de instruções é um pedido, não uma garantia.** O modelo o lê como parte do prompt, e
um prompt é algo de onde o modelo continua, não uma regra que o prende. Ele melhora as chances e
não impõe nada. O que impõe "dinheiro em centavos" neste projeto é um teste, e o que impõe "os
testes passam" é a CI. Escreva a regra no arquivo para as sugestões acertarem mais vezes, e
mantenha a checagem que pega as vezes em que não acertam.
