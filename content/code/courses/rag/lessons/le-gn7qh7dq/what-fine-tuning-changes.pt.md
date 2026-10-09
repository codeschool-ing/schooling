---
title: O que o fine-tuning muda
version: 2
---

Há dois jeitos de fazer um modelo responder sobre a Marginalia. O RAG deixa o modelo como está e põe o
texto certo em cada requisição. O **fine-tuning** (ajuste fino) muda o próprio modelo: continua o
treinamento com exemplos do comportamento desejado, e os pesos se movem até o modelo produzi-lo. Depois
de um fine-tuning existe um modelo novo, com nome próprio, que responde sem que lhe mostrem nada.

A crença com que a maioria das pessoas começa é que o fine-tuning é como um modelo *aprende os seus
documentos*: treine-o no manual e ele vai saber o manual. É o trabalho que ele faz pior, e esta aula
trata sobretudo do porquê.

## Como é um exemplo de fine-tuning

Um conjunto de dados de fine-tuning é um arquivo de conversas, cada uma mostrando uma requisição e a
resposta que o modelo deveria ter dado. Os provedores que o oferecem usam o mesmo formato das suas APIs
de chat, uma conversa por linha. O `dataset.py` monta um a partir do conjunto de teste deste curso: para
cada uma das 26 perguntas que têm resposta, pega a pergunta, põe a melhor seção na frente do
llama3.2:3b, e guarda a resposta como aquela que o modelo ajustado deveria aprender a dar sem seção
nenhuma.

Ele busca com o `sections.py`, o programa da aula 2 com duas pequenas mudanças, que toda execução desta
aula usa. Salve por cima do antigo:

```schooling-example
{
  "language": "python",
  "file": "sections.py",
  "parts": [
    {
      "code": "import glob\nimport os\nimport re\nimport sys\n\nfrom vectors import embed\nfrom openai import OpenAI\n\nskip = set(os.environ.get(\"WITHOUT\", \"\").split(\",\"))\nsections = []\nfor path in sorted(glob.glob(\"data/docs/*.md\")):\n    doc = path.split(\"/\")[-1][:-3]\n    if doc in skip:\n        continue\n    for part in re.split(r\"\\n(?=## )\", open(path).read())[1:]:\n        sections.append((f\"{doc} > {part.splitlines()[0][3:]}\", part))\nvectors = embed([text for _, text in sections])",
      "note": "A primeira de duas mudanças em relação à aula 2: a variável `WITHOUT` nomeia documentos a deixar de fora, separados por vírgula, que é como a última seção desta aula apaga um."
    },
    {
      "code": "def search(question, k=3):\n    scores = vectors @ embed(question)[0]\n    return [(sections[i][0], sections[i][1], float(scores[i])) for i in scores.argsort()[::-1][:k]]",
      "note": "O `search` não mudou."
    },
    {
      "code": "def answer(question, k=3):\n    found = search(question, k)\n    for rank, (name, _, score) in enumerate(found, 1):\n        print(f\"[{rank}] {score:.3f}  {name}\")\n    sources = \"\".join(f\"[{rank}] {name}\\n{text}\\n\" for rank, (name, text, _) in enumerate(found, 1))\n    reply = OpenAI().chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n        {\"role\": \"system\", \"content\": \"Answer from the sources and cite them by number.\"},\n        {\"role\": \"user\", \"content\": f\"{sources}Question: {question}\"}])\n    print(reply.choices[0].message.content)\n    return reply",
      "note": "A segunda mudança: o `answer` devolve a resposta além de imprimi-la, para que outro programa possa usá-la."
    },
    {
      "code": "if __name__ == \"__main__\":\n    answer(sys.argv[1])"
    }
  ]
}
```

E o próprio `dataset.py`:

```schooling-example
{
  "language": "python",
  "file": "dataset.py",
  "parts": [
    {
      "code": "import json\n\nimport tiktoken\nfrom sections import search\nfrom openai import OpenAI\n\nenc = tiktoken.get_encoding(\"cl100k_base\")\nclient = OpenAI()\ntotal = 0",
      "note": "A busca do `sections.py`, o modelo, e o tiktoken para contar o que um provedor cobraria pelo treinamento."
    },
    {
      "code": "with open(\"ft.jsonl\", \"w\") as out:\n    for line in open(\"data/eval.jsonl\"):\n        q = json.loads(line)\n        if not q[\"gold\"]:\n            continue\n        name, text, _ = search(q[\"question\"], 1)[0]\n        reply = client.chat.completions.create(model=\"llama3.2:3b\", temperature=0, messages=[\n            {\"role\": \"user\", \"content\": f\"[1] {name}\\n{text}\\nQuestion: {q['question']}\"}])\n        answer = reply.choices[0].message.content.replace(\" [1]\", \"\")",
      "note": "Para cada pergunta que tem resposta, a melhor seção vai na frente do modelo, e a resposta dele, sem a citação, vira a resposta que um modelo ajustado seria ensinado a dar sem seção nenhuma."
    },
    {
      "code": "        example = {\"messages\": [{\"role\": \"user\", \"content\": q[\"question\"]},\n                                {\"role\": \"assistant\", \"content\": answer}]}\n        out.write(json.dumps(example) + \"\\n\")\n        total += sum(len(enc.encode(m[\"content\"])) for m in example[\"messages\"])\nprint(\"examples:\", sum(1 for _ in open(\"ft.jsonl\")))\nprint(\"training tokens per epoch:\", total)",
      "note": "Uma conversa por linha, no formato que os serviços de fine-tuning dos provedores aceitam, e o total que um treinamento cobra por passada pelos dados."
    }
  ]
}
```

```
ana@vm:~/rag$ python dataset.py
examples: 26
training tokens per epoch: 1320
ana@vm:~/rag$ head -n 2 ft.jsonl
{"messages": [{"role": "user", "content": "How many days do I have to return a printed book?"}, {"role": "assistant", "content": "According to the policy, you have 30 days from the day the carrier records the parcel as delivered to return a printed book."}]}
{"messages": [{"role": "user", "content": "Who pays for the return postage?"}, {"role": "assistant", "content": "According to the text, the customer pays for the return postage."}]}
```

**Nenhum fine-tuning foi rodado para este curso**: ele precisa do serviço de treinamento de um provedor
ou de uma GPU, e a máquina em que ele foi gravado não tem nenhum dos dois. O que vem a seguir descreve
o que um treinamento desses faz, e os números são os do conjunto de dados.

**Olhe o segundo exemplo.** Ele ensina ao modelo que o cliente paga o frete de devolução, que era a
regra de 2025. O conjunto foi montado por um passo de recuperação, o passo de recuperação achou o
regulamento substituído, e o erro entrou nos dados de treinamento sem nada que o marcasse. Depois que
um modelo é treinado nessa linha, não há citação para seguir até o documento que o causou. O problema
que o RAG mostrou na aula 1 continua lá, só que agora dentro dos pesos.

Os dois exemplos também ensinam uma coisa que ninguém escolheu. Eles começam com *According to the
policy* e *According to the text*, porque o modelo que os escreveu tinha um texto na frente. Um modelo
treinado neles aprende a dizer isso sem texto nenhum, que é a cara de uma citação sem nada por trás. Um
conjunto de dados carrega todos os hábitos de quem o produziu, os desejados e os outros.

## Comportamento se aprende fácil; fatos, não

Um fine-tuning é bom em ensinar um **padrão que aparece em todos os exemplos**: responder em duas
frases, responder em português quando o cliente escreve em português, sempre produzir um JSON válido
com estes quatro campos, escrever como o nosso manual de atendimento. Todo exemplo repete o padrão,
então algumas centenas de exemplos movem os pesos bastante numa direção.

Um fato aparece em um ou dois exemplos. Para fazer o modelo dizer "trinta dias" de forma confiável a
qualquer jeito que um cliente pergunte, o conjunto precisa desse fato dito de muitos jeitos e perguntado
de muitos jeitos, e o mesmo para cada outro fato. Mesmo assim, um fato aprendido de poucos exemplos fica
preso de leve: o modelo o produz para perguntas próximas dos exemplos de treinamento e alguma coisa
plausível para perguntas mais distantes, que é a falha do livro fechado da aula 1 de novo, mais perto
dos seus dados. Os próprios guias de fine-tuning dos provedores apontam na mesma direção: apresentam-no
para formato, estilo e comportamento, e recomendam recuperação quando o que falta é conhecimento.

## O que custa fazer a mudança

Mudar o comportamento de um modelo ajustado quer dizer um conjunto novo, um treinamento novo e um modelo
novo para avaliar e implantar. Mudar o que um sistema de RAG sabe quer dizer mudar um documento e
reindexá-lo. As próximas quatro seções comparam os dois nas quatro coisas que mais diferem: quão atuais
são as respostas, se dá para rastreá-las, quanto custam e se alguma coisa pode ser removida.
