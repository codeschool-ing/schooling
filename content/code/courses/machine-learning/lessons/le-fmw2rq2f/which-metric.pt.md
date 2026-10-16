---
title: Que métrica, para que pergunta
version: 1
---

Cada métrica desta aula responde a uma pergunta, e os erros vêm de fazer a ela outra pergunta. A Ana
mantém esta tabela ao lado do enquadramento da aula 1:

| pergunta | métrica | precisa de corte? | na Feira em Casa |
|---|---|---|---|
| agir com o modelo dá dinheiro? | **valor líquido** | sim | R$ 21.672 no corte de equilíbrio |
| dos créditos enviados, quantos valiam a pena? | **precisão** | sim | 0,489 |
| de quem sai, quantos foram alcançados? | **revocação** | sim | 0,235 |
| um número só quando os dois erros custam o mesmo | **F1** | sim | 0,317 |
| o modelo põe quem sai acima de quem fica? | **ROC AUC** | não | 0,804 |
| quão boa é a ordem no topo, numa classe rara? | **precisão média** | não | 0,322 |
| o modelo acerta mais do que erra? | **acurácia** | sim | 0,938, e sem sentido aqui |

Três hábitos decorrem disso.

**Relate primeiro a métrica do negócio, e o resto como explicação.** A equipe de retenção perguntou
quanto dinheiro os créditos dão. Precisão e revocação explicam como esse número foi feito; AUC e
precisão média explicam quanto melhor ele poderia ser com outro corte. Nenhuma delas o substitui.

**Nunca cite uma métrica que depende de corte sem o corte.** "Revocação de 0,33" não quer dizer nada
até virar "revocação de 0,33 num corte de 0,2, com precisão de 0,42". Um número sem o seu corte pode
ficar tão grande quanto alguém quiser.

**Compare modelos nas mesmas linhas, com a mesma métrica, e com o bootstrap da aula 2.** Uma métrica é
uma medição com ruído dentro. Dois modelos cujas AUCs diferem na terceira casa decimal não foram
separados; o intervalo diz se foram.

Mais uma coisa que a tabela mostra: em 0,2 o modelo fez R$ 23.448, mais que no corte de equilíbrio que a
aula 2 tirou dos custos. Se as chances do modelo fossem probabilidades honestas, o corte de equilíbrio
seria o melhor por construção. Ele não ser quer dizer que as chances não são bem o que afirmam, e esse é
o primeiro assunto da aula 11.
