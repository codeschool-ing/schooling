---
title: A linha
version: 1
---

As páginas da OpenAI não puderam ser alcançadas da máquina em que este curso foi gravado, então,
como com o Gemini, a família é lida na tabela do LiteLLM. Uma seleção das entradas de chat atuais:

```
ana@desk:~/desk$ sheet compare gpt-5.4-nano gpt-5.4-mini gpt-5.4 gpt-5.5 gpt-6-luna gpt-6-sol gpt-6-astra
# LiteLLM model sheet at 21881c57, 4472 entries
model                                            window  max out   in $/M  out $/M  VFSCRP
gpt-5.4-nano                                    272,000   128000      0.2     1.25  VFSCRP
gpt-5.4-mini                                    272,000   128000     0.75      4.5  VFSCRP
gpt-5.4                                       1,050,000   128000      2.5       15  VFSCRP
gpt-5.5                                       1,050,000   128000        5       30  VFSCRP
gpt-6-luna                                      922,000   128000      0.1      0.5  VFSCRP
gpt-6-sol                                       922,000   128000        2       10  VFSCRP
gpt-6-astra                                     922,000   128000       10       50  VFSCRP
```

Dois esquemas de nome convivem.

**GPT-5, por versão e tamanho.** Um número de versão (5.4, 5.5) e, abaixo do modelo completo, um
mini e um nano. Dentro da versão 5.4 os degraus são íngremes: o nano custa US$ 0,20 o milhão
de tokens de entrada, o mini US$ 0,75, o completo US$ 2,50, mais de doze vezes o nano. A janela também
sobe: 272.000 tokens no mini e no nano, cerca de um milhão nos completos. A 5.5 não tem mini nem nano
nesta seleção, o que é comum: os tamanhos pequenos de uma família muitas vezes ficam uma versão atrás
do grande, como o Pro do Gemini ficou, no sentido contrário.

**GPT-6, por nome.** `gpt-6-luna`, `gpt-6-sol` e `gpt-6-astra` são as entradas da tabela para uma
geração mais nova, com tamanhos por nome e não por sufixo: luna a mais barata, a US$ 0,10 e US$ 0,50,
sol no meio, astra a mais cara, a US$ 10 e US$ 50. Têm a mesma janela de 922.000 tokens em todo
tamanho. Este curso não conseguiu ler a descrição da própria OpenAI sobre eles, então diz só o que a
tabela registra: três tamanhos, os preços e a janela.

## Lendo para a ana

A aula 4 precificou o rascunho dela no `gpt-5.4-mini` em US$ 15,84 por mês com cache. Duas coisas que
esta tabela acrescenta:

- **Há duas linhas mais baratas**: o `gpt-5.4-nano`, a mais ou menos um quarto do preço do mini, e o
  `gpt-6-luna`, abaixo do nano. Os dois são candidatos para a tarefa fácil de classificação, e o
  único jeito de saber se são bons o bastante são os quarenta casos da aula 5.
- **As faixas não se comparam entre gerações pelo nome.** Um 6-luna não é "um nano melhor" até os
  casos dizerem isso, e uma geração nova é um conjunto novo de candidatos, não uma atualização.
