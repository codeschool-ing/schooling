---
title: Colocando o documento no prompt
version: 2
---

Se o modelo não conhece o regulamento de devoluções, o passo óbvio é dar o regulamento a ele. Um modelo
lê tudo o que está na sua **janela de contexto** antes de escrever uma palavra, a mensagem de sistema,
a conversa e qualquer texto que a requisição leve, e o que ele lê ali ele pode usar, tenha estado ou
não no treinamento. O conhecimento levado na requisição se chama **em contexto**, para separá-lo do
paramétrico da seção anterior.

O `with_doc.py` faz exatamente isso, com o regulamento inteiro:

```schooling-example
{
  "language": "python",
  "file": "with_doc.py",
  "parts": [
    {
      "code": "import sys\nfrom openai import OpenAI\n\nclient = OpenAI()\npolicy = open(\"data/docs/returns-policy.md\").read()",
      "note": "O regulamento de devoluções inteiro, lido do disco como uma única string. O cliente encontra o Ollama pela `OPENAI_BASE_URL`, que o `env.sh` define."
    },
    {
      "code": "reply = client.chat.completions.create(\n    model=\"llama3.2:3b\",\n    temperature=0,\n    messages=[\n        {\"role\": \"system\", \"content\": \"Answer the question from the source below.\"},",
      "note": "A mensagem de sistema diz o que fazer com o texto que vem a seguir. É uma instrução, e o modelo a pesa contra tudo o mais que lê."
    },
    {
      "code": "        {\"role\": \"user\", \"content\": f\"[1] returns-policy\\n{policy}\\nQuestion: {sys.argv[1]}\"},\n    ],\n)",
      "note": "O documento entra na mensagem do usuário com um número na frente, `[1]`, e a pergunta depois dele. O número é o que uma resposta pode citar."
    },
    {
      "code": "print(reply.choices[0].message.content)\nprint(\"prompt tokens:\", reply.usage.prompt_tokens)",
      "note": "A resposta, e quantos tokens a requisição levou, contados pelo próprio modelo."
    }
  ],
  "output": "ana@vm:~/rag$ python with_doc.py \"How many days do I have to return a printed book?\"\nYou have 30 days from delivery to return a printed book.\nprompt tokens: 1166\nana@vm:~/rag$ python with_doc.py \"What is the phone number for customer service?\"\nUnfortunately, the provided text does not include the phone number for customer service.\nprompt tokens: 1163"
}
```

**A mesma pergunta agora recebe a resposta que vale hoje, trinta dias.** O modelo que falava de
multas de biblioteca uma seção atrás leu o regulamento e citou a única frase que responde a pergunta.
Não disse de onde tirou a resposta, embora a fonte traga um número, `[1]`, porque nada pediu isso a
ele. A aula 7 pede, e confere.

A pergunta do telefone mostra a outra metade. Com o regulamento na frente, o modelo disse que o texto
não traz um número de telefone, em vez de partir para conselhos sobre como achar um. Com uma fonte, a
resposta honesta a uma pergunta que a fonte não cobre é que ela não cobre. Um modelo faz isso com
frequência e não sempre, então a aula 7 transforma isso numa regra que você escreve no prompt e testa,
em vez de um hábito em que você confia.

## O que mudou, exatamente

Nada no modelo mudou entre o `ask.py` e o `with_doc.py`. Os pesos são os mesmos, e ele voltaria a falar
de empréstimos de biblioteca no instante em que o regulamento saísse do prompt. **O conhecimento mora na requisição, pelo tempo que a requisição dura.** A próxima pergunta
começa do zero de novo, e o que ela precisar tem de ser mandado de novo.

Esse é o mecanismo inteiro sobre o qual este curso constrói, e ele tem três consequências que vale
dizer já.

**O documento é a autoridade, então o documento tem de estar certo.** O modelo só pode ser tão atual
quanto o texto que você dá a ele. Coloque o regulamento de 2025 no prompt e a resposta é a de 2025,
citada fielmente, com referência.

**Uma citação passa a ser possível.** Um modelo que responde de memória não consegue dizer de onde a
resposta veio, porque não sabe. Um modelo que responde a partir de texto numerado consegue apontar o
número, e uma pessoa consegue abrir a fonte e conferir. É essa rastreabilidade que a aula 3 põe na
balança contra o fine-tuning.

**A requisição fica maior, e cada token é pago.** O regulamento transformou uma pergunta de uma dúzia
de tokens numa requisição de 1.166, contados pelo tokenizador do próprio modelo. Esse número é o assunto da próxima seção.

## A janela tem tamanho

Todo modelo tem uma janela de contexto, um número máximo de tokens que ele consegue ler e escrever
numa requisição. O llama3.2:3b foi treinado com uma janela de 131.072 tokens, e o Ollama o serve com
4.096 a menos que alguém peça outra coisa, para manter pequena a memória de que ele precisa; a coluna
`CONTEXT` do `ollama ps` na instalação dizia isso. Os modelos comerciais atuais aceitam de uns cem
mil tokens a mais de um milhão. Uma janela maior empurra o limite. Ela não elimina os motivos, na
próxima seção, para não enchê-la.
