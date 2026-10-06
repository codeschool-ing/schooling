---
title: Colocando o documento no prompt
version: 1
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
      "note": "O regulamento de devoluções inteiro, lido do disco como uma única string. O cliente encontra o labgen pela `OPENAI_BASE_URL`, que o laboratório define."
    },
    {
      "code": "reply = client.chat.completions.create(\n    model=\"extract-1\",\n    messages=[\n        {\"role\": \"system\", \"content\": \"Answer the question from the source below.\"},",
      "note": "A mensagem de sistema diz o que fazer com o texto que vem a seguir. Para um modelo real é uma instrução; o extract-1 não faz nada com ela, porque a regra 3 vale sempre que há fontes."
    },
    {
      "code": "        {\"role\": \"user\", \"content\": f\"[1] returns-policy\\n{policy}\\nQuestion: {sys.argv[1]}\"},\n    ],\n)",
      "note": "O documento entra na mensagem do usuário com um número na frente, `[1]`, e a pergunta depois dele. O número é o que uma resposta pode citar."
    },
    {
      "code": "print(reply.choices[0].message.content)\nprint(\"prompt tokens:\", reply.usage.prompt_tokens)",
      "note": "A resposta, e quantos tokens a requisição levou, contados pelo provedor."
    }
  ],
  "output": "ana@lab:~/rag$ python with_doc.py \"How many days do I have to return a printed book?\"\nYou have 30 days from delivery to return a printed book in the condition you received it. [1] A printed book with a fault from the printer, such as pages bound upside down or missing, can be returned for a refund or a replacement within 30 days, like any other return. [1]\nprompt tokens: 1144\nana@lab:~/rag$ python with_doc.py \"What is the phone number for customer service?\"\nThe sources do not say.\nprompt tokens: 1141"
}
```

**A mesma pergunta agora recebe a resposta em vigor hoje, trinta dias, com um número dizendo de onde
ela veio.** A segunda frase é sobre livros com defeito, que ninguém perguntou; está ali porque também
diz "printed book" e "30 days", e o extract-1 escolhe frases por similaridade, não pela relevância para
o que a pessoa precisa. Guarde essa frase: a aula 12 trata de manter texto como ela fora da janela
desde o começo.

A pergunta do telefone mostra a outra metade. Com o regulamento na frente, o extract-1 não achou
nenhuma frase parecida o bastante e disse isso, em vez de buscar um número de telefone. Dada uma fonte,
a resposta honesta a uma pergunta que a fonte não cobre é que ela não cobre. A aula 7 transforma isso
numa regra que você escreve no prompt, e não numa propriedade de um substituto.

## O que mudou, exatamente

Nada no modelo mudou entre o `ask.py` e o `with_doc.py`. Os pesos são os mesmos, o arquivo de memória
é o mesmo, e ele daria de novo a resposta dos catorze dias no instante em que o regulamento saísse do
prompt. **O conhecimento mora na requisição, pelo tempo que a requisição dura.** A próxima pergunta
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
de tokens numa requisição de 1.144. Esse número é o assunto da próxima seção.

## A janela tem tamanho

Todo modelo tem uma janela de contexto, um número máximo de tokens que ele consegue ler e escrever
numa requisição. A do extract-1 é de 8.192, um tamanho escolhido para este laboratório para que o
limite seja fácil de alcançar; os modelos comerciais atuais aceitam de uns cem mil tokens a mais de um
milhão. Uma janela maior empurra o limite. Ela não elimina os motivos, na próxima seção, para não
enchê-la.
