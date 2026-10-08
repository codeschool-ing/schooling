---
title: Quando as fontes discordam
version: 2
---

Dois documentos podem ser relevantes e dizer coisas diferentes. Às vezes um substituiu o outro, como o
regulamento de devoluções de 2025 foi substituído. Às vezes os dois estão em vigor e valem para casos
diferentes: o regulamento de devoluções dá trinta dias e os termos de venda dão sete, porque um é a
promessa da loja e o outro é a lei. Um gerador que recebe os dois tem de decidir o que fazer, e a pior
decisão é citar os dois e deixar quem lê escolher.

## Com o regulamento substituído nas fontes

O filtro de status é o que manteve o regulamento de 2025 de fora. Aqui ele é afrouxado só para o público,
e o regulamento substituído volta a ser permitido:

```
ana@vm:~/rag$ python -c "from answer import answer; print(answer(\"How many days do I have to return a printed book?\", where=\"audience = %s\", params=(\"public\",))[0])"
According to [1], you have 14 days to return a printed book, but this is only if it is unread and in the condition in which you received it. However, [2] states that you have 30 days from delivery to return a printed book in the condition you received it. 

Since [2] is the more recent update, I prefer it. Therefore, you have 30 days from delivery to return a printed book.
```

**Catorze dias por `[1]`, trinta por `[2]`, e uma escolha, dita em voz alta.** O prompt mandava
preferir a fonte atualizada mais recentemente e dizer isso, e os cabeçalhos levavam as datas,
2025-03-01 e 2026-02-02. O modelo fez as duas coisas. Sem as datas no prompt ele não teria como: a
instrução é inútil quando nada na frente do modelo diz qual fonte é a mais nova. E é uma instrução,
então é seguida na maior parte das vezes, por este modelo, nesta pergunta.

## Com o filtro de volta

```
ana@vm:~/rag$ python answer.py "How many days do I have to return a printed book?"
According to [1], you have 30 days from delivery to return a printed book. This is the most recent and updated policy, as stated in the source date (2026-02-02).
  [1] Returns and refunds policy > The return window, updated 2026-02-02
```

**Trinta dias, do regulamento atual, sem conflito nenhum para resolver.** O filtro tirou o regulamento
de 2025 antes de o modelo vê-lo, então não havia entre o que escolher. O modelo ainda disse que o
regulamento era o mais recente, uma instrução aplicada onde não tinha o que fazer, o que aqui é
inofensivo e é o motivo de um prompt não carregar instrução para um caso que o código consegue
resolver.

## Resolva conflitos no código quando der

O padrão da seção anterior vale de novo. **Sempre que a regra de qual fonte vence puder ser escrita,
escreva-a no código, antes do prompt**, e deixe para o modelo só os conflitos que nenhuma regra cobre.

- **Um documento substituído**: filtrar pelo `status`, como acima. A decisão é tomada uma vez, por quem
  marca o documento como substituído, e toda resposta a segue.
- **Duas versões de um documento**: ficar com a mais nova pelo `doc_version` ou pelo `updated`, a não ser
  que a pergunta seja sobre uma data passada, como as perguntas jurídicas da aula 2.
- **Uma regra geral e uma exceção**: manter as duas, porque o modelo precisa das duas, e ordená-las para a
  mais específica vir primeiro; a aula 12 mede o que a ordem faz.
- **Dois documentos em vigor que discordam de verdade**: isso é um defeito nos documentos, não no
  pipeline. Mostre os dois com as datas, e registre, porque alguém dono de um deles precisa saber. A coluna
  `owner` da aula 5 diz quem.
