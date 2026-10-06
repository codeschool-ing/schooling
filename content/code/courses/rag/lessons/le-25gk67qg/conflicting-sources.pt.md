---
title: Quando as fontes discordam
version: 1
---

Dois documentos podem ser relevantes e dizer coisas diferentes. Às vezes um substituiu o outro, como o
regulamento de devoluções de 2025 foi substituído. Às vezes os dois estão em vigor e valem para casos
diferentes: o regulamento de devoluções dá trinta dias e os termos de venda dão sete, porque um é a
promessa da loja e o outro é a lei. Um gerador que recebe os dois tem de decidir o que fazer, e a pior
decisão é a que o extract-1 toma.

## Com o regulamento substituído nas fontes

O filtro de status é o que manteve o regulamento de 2025 de fora. Aqui ele é afrouxado só para o público,
e o regulamento substituído volta a ser permitido:

```
ana@lab:~/rag$ python -c "from answer import answer; print(answer(\"How many days do I have to return a printed book?\", where=\"audience = %s\", params=(\"public\",))[0])"
You have 30 days from delivery to return a printed book in the condition you received it. [2] You may return a printed book within 14 days of delivery if it is unread and in the condition in which you received it. [1] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [3]
```

**Trinta dias por `[2]` e catorze por `[1]`, lado a lado, cada um citado.** O prompt mandava preferir a
fonte atualizada mais recentemente e dizer isso; os cabeçalhos levavam as datas, 2026-02-02 e
2025-03-01. O extract-1 não tem noção de data e citou as duas. Um modelo real em geral seguiria a
instrução aqui, com as datas na mão, e é exatamente por isso que as datas têm de estar no prompt: sem
elas a instrução é inútil.

## Com o filtro de volta

```
ana@lab:~/rag$ python answer.py "How many days do I have to return a printed book?"
You have 30 days from delivery to return a printed book in the condition you received it. [1] Our returns and refunds policy extends this period to 30 days for printed books. [3] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [2]
  [1] Returns and refunds policy > The return window, updated 2026-02-02
  [3] Terms of sale > 6. The right of withdrawal, updated 2026-01-05
  [2] Returns and refunds policy > Damaged, faulty and wrong items, updated 2026-02-02
```

**Trinta dias, do regulamento atual, e uma segunda fonte que concorda.** O `[3]` é a cláusula dos termos de
venda sobre arrependimento, *Our returns and refunds policy extends this period to 30 days*, que é outro
documento dizendo a mesma coisa. Esse é o tipo de desacordo que não é desacordo: os termos dizem o mínimo
legal de sete dias e remetem ao regulamento para os trinta.

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
