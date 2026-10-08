---
title: Julgando com um modelo
version: 2
---

Quando as respostas são parafraseadas, nada tão simples quanto uma busca de trecho consegue dizer se
elas estão certas. A resposta comum é perguntar a outro modelo: dar a ele a pergunta, a resposta esperada
e a resposta dada, e perguntar se a resposta está correta. Isso se chama **LLM-as-judge**, e é como a
maioria das equipes mede a qualidade das respostas em escala.

O `judge.py` roda um sobre o dev, ao lado do teste de fato, para que os dois possam ser comparados:

```schooling-example
{
  "language": "python",
  "file": "judge.py",
  "parts": [
    {
      "code": "import json\nimport re\n\nfrom openai import OpenAI\n\nfrom answer import REFUSAL, answer\nfrom verify import norm\n\nclient = OpenAI()\nJUDGE = \"\"\"You are checking an answer from a customer support assistant.\n\nQuestion: {question}\nExpected answer, from the documents: {expected}\nAssistant's answer: {reply}\n\nDoes the assistant's answer state the same fact as the expected answer,\nwithout adding anything that contradicts it? Ignore wording and length.\nReply with one word: CORRECT, INCORRECT or REFUSED.\"\"\"",
      "note": "O prompt do juiz é curto, faz uma pergunta só, e restringe a resposta a uma palavra que um programa consegue ler. A resposta esperada vem do conjunto de teste, e é por isso que toda pergunta ali deveria levar o que o trecho diz, e não só onde ele está."
    },
    {
      "code": "def judge(question, expected, reply):\n    out = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, max_tokens=8, messages=[\n        {\"role\": \"user\", \"content\": JUDGE.format(question=question, expected=expected, reply=reply)}])\n    word = re.search(r\"INCORRECT|CORRECT|REFUSED\", out.choices[0].message.content.upper())\n    return word.group() if word else \"?\"",
      "note": "O juiz é o mesmo modelo que escreveu as respostas, que é a preferência por si mesmo de que a próxima seção avisa, escolhido aqui porque é o modelo que todo leitor tem. O `INCORRECT` é procurado antes do `CORRECT`, porque o contém."
    },
    {
      "code": "questions = [q for q in map(json.loads, open(\"data/eval.jsonl\")) if int(q[\"id\"][1:]) % 3 != 0]\nagree = 0\nfor q in questions:\n    reply, _ = answer(q[\"question\"], where=\"status = %s\", params=(\"current\",))\n    expected = \"; \".join(q[\"facts\"]) or \"The documents do not answer this question.\"\n    if reply == REFUSAL:\n        fact = \"REFUSED\" if q[\"facts\"] else \"CORRECT\"\n    else:\n        fact = \"CORRECT\" if any(f in norm(reply) for f in q[\"facts\"]) else \"INCORRECT\"\n    verdict = judge(q[\"question\"], expected, reply)\n    agree += verdict == fact\n    print(f\"{q['id']}  fact {fact:9}  judge {verdict:9}  {q['question'][:52]}\")\nprint(f\"the judge and the fact test agree on {agree} of {len(questions)}\")",
      "note": "O dev, cada pergunta respondida pelo pipeline e depois marcada duas vezes: pelo teste de fato do `evaluate.py`, e pelo juiz, que recebe os fatos como resposta esperada. Uma recusa é `CORRECT` quando a pergunta não tem resposta, e `REFUSED` quando tem."
    }
  ]
}
```

```
ana@vm:~/rag$ python judge.py
e01  fact CORRECT    judge CORRECT    How many days do I have to return a printed book?
e02  fact INCORRECT  judge INCORRECT  Who pays for the return postage?
e04  fact CORRECT    judge INCORRECT  Can I return a signed copy?
e05  fact INCORRECT  judge INCORRECT  My e-book was downloaded yesterday, can I still get 
e07  fact CORRECT    judge CORRECT    Above what order value is standard delivery free?
e08  fact CORRECT    judge CORRECT    When is a standard parcel considered lost?
e10  fact INCORRECT  judge CORRECT    How long does a pickup point keep my parcel?
e11  fact CORRECT    judge CORRECT    On how many devices can I read my e-books?
e13  fact CORRECT    judge INCORRECT  When can an audiobook be refunded?
e14  fact REFUSED    judge INCORRECT  Can I pay in instalments?
e16  fact REFUSED    judge INCORRECT  Can I get an invoice in my company's name after the 
e17  fact CORRECT    judge CORRECT    When is the contract of sale formed?
e19  fact CORRECT    judge INCORRECT  What commission does Marginalia take from a marketpl
e20  fact CORRECT    judge CORRECT    How often are sellers paid?
e22  fact CORRECT    judge INCORRECT  What commission do affiliates earn on e-books?
e23  fact CORRECT    judge CORRECT    How long do you keep my order history?
e25  fact CORRECT    judge CORRECT    What is the most a support agent can refund without 
e26  fact CORRECT    judge CORRECT    What must I check before changing a customer's order
e28  fact CORRECT    judge CORRECT    Can I place an order by phone?
e29  fact CORRECT    judge CORRECT    Which carrier do you use in Portugal?
the judge and the fact test agree on 13 of 20
```

**O juiz e o teste de fato concordam em 13 de 20**, e vale ler as discordâncias uma a uma, porque cada
uma é um erro de um dos dois, e nem sempre do juiz.

- **e10, o ponto de retirada.** A resposta diz *10 days*, o fato é *waits there for ten days*. O teste
  de fato reprovou uma resposta certa e o juiz a aprovou, que é o caso para o qual um juiz existe.
- **e04, e13, e19 e e22.** O teste de fato aprovou, e o juiz disse INCORRECT. Cada resposta contém as
  palavras esperadas, *signed by the author*, *less than 10%*, *12% of the item price*, *3% of the
  price of e-books*. O juiz errou quatro vezes.
- **e14 e e16.** As duas respostas foram a recusa, a perguntas que os documentos respondem. O teste de
  fato chama isso de REFUSED e o juiz de INCORRECT; os dois querem dizer que a resposta falhou, e a
  discordância está só no rótulo, que um programa comparando rótulos conta mesmo assim.

E na e02 os dois concordam, e os dois erram: a resposta diz que a etiqueta é paga e o cliente não paga
nada, que é *Returns are free* com outras palavras. Então, nestas vinte, o juiz pegou o teste de fato uma
vez e errou cinco. É o llama3.2:3b julgando as próprias respostas, a partir de uma resposta esperada que
é um pedaço de frase, em oito tokens. Um modelo maior, uma resposta esperada completa e uma rubrica
fariam todos melhor, e o único jeito de saber quanto melhor é a calibração abaixo.

## O que os juízes erram

Estudos de modelos juízes, e as medições do `prompt-reliability`, encontram sempre os mesmos vieses:

- **Posição**: pedido para comparar duas respostas, um juiz tende a preferir a primeira mostrada. Troque
  a ordem e pergunte de novo; só conte uma preferência que sobreviva à troca.
- **Tamanho**: respostas mais longas são julgadas melhores mais vezes do que merecem. Uma rubrica que
  diz *ignore o tamanho* ajuda e não cura.
- **Autopreferência**: um juiz avalia com mais boa vontade as respostas da família do próprio modelo.
- **Concordar com a confiança**: uma resposta errada e confiante é marcada como correta mais vezes que
  uma certa e hesitante.

Nada disso torna um juiz inútil. Torna-o um instrumento que precisa de calibração.

## Calibrando o juiz

**Rotule uma amostra à mão.** Cinquenta respostas marcadas como corretas ou não por uma pessoa que
conhece os documentos. **Rode o juiz nas mesmas cinquenta** e conte a concordância. Se o juiz concorda
com a pessoa na maioria delas, e as discordâncias não pendem para um lado, use-o; se pendem, conserte o
prompt e meça de novo. **Repita quando algo mudar**: um modelo juiz novo, um prompt novo, um tipo novo de
pergunta. Um juiz calibrado há um ano contra outro pipeline não mede nada em particular agora.

E mantenha as verificações baratas rodando ao lado. Um teste de fato que diz *errada* e um juiz que diz
*correta* são um desacordo que vale dois minutos de uma pessoa.
