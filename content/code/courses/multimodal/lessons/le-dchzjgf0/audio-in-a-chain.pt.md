---
title: Uma ligação gravada, numa só cadeia
version: 1
---

Uma cadeia vale a pena quando vários passos rodam em ordem e cada um precisa da saída do anterior. Transformar uma ligação gravada num chamado de suporte tem esse formato: transcrever, pedir os campos, conferi-los.

```schooling-example
{
  "language": "python",
  "file": "ticket.py",
  "parts": [
    {
      "code": "\"\"\"A recorded call to a support ticket: transcribe, then ask for fields, then check them.\"\"\"\nimport re\nimport sys\n\nfrom langchain_core.prompts import ChatPromptTemplate\nfrom langchain_core.runnables import RunnableLambda\nfrom langchain_openai import ChatOpenAI\nfrom openai import OpenAI\nfrom pydantic import BaseModel\n\n\n"
    },
    {
      "code": "class Ticket(BaseModel):\n    order: str\n    title: str\n    problem: str\n    refund_cents: int\n\n\n",
      "note": "**O formato do chamado, como um modelo Pydantic.** O `with_structured_output` o transforma num JSON schema para o pedido e converte a resposta de volta nele."
    },
    {
      "code": "def transcribe(path):\n    with open(path, \"rb\") as f:\n        return {\"transcript\": OpenAI(base_url=\"http://localhost:8700/v1\").audio.transcriptions.create(\n            model=\"whisper-base\", file=f, response_format=\"text\")}\n\n\n",
      "note": "**O passo do áudio é o SDK do próprio provedor**, o endpoint de transcrição da aula 10, embrulhado numa função comum. Ele devolve um dicionário para o próximo passo poder nomear o que precisa."
    },
    {
      "code": "prompt = ChatPromptTemplate.from_messages([\n    (\"system\", \"Turn this support call into a support ticket. Use only what the caller and agent say.\"),\n    (\"user\", \"{transcript}\")])\nllm = ChatOpenAI(model=\"qwen2.5vl:3b\").with_structured_output(Ticket, method=\"json_schema\")\nchain = RunnableLambda(transcribe) | {\"transcript\": lambda x: x[\"transcript\"],\n                                      \"ticket\": prompt | llm}\n\n",
      "note": "**A cadeia.** O `RunnableLambda` faz da função um passo, o `|` junta passos, e o dicionário roda dois ramos sobre a mesma entrada: um deixa a transcrição passar, o outro a transforma num chamado."
    },
    {
      "code": "out = chain.invoke(sys.argv[1])\nticket, heard = out[\"ticket\"], out[\"transcript\"]\nprint(ticket)\n\n",
      "note": "**Uma chamada roda tudo**, e manter a transcrição ao lado do chamado é o que torna a próxima parte possível."
    },
    {
      "code": "# The check the chain does not do: is every value the ticket states in what was heard?\ndef plain(s):\n    return re.sub(r\"[^0-9a-z]\", \"\", s.lower())\n\nprint(\"order  in transcript:\", plain(ticket.order) in plain(heard))\nprint(\"title  in transcript:\", plain(ticket.title) in plain(heard))",
      "note": "**A conferência que nenhum framework acrescenta por você**: todo valor que o chamado afirma deveria estar em algum lugar do que foi ouvido. Só letras e dígitos, para `M-1042` e `M1042` contarem como o mesmo pedido."
    }
  ]
}
```

```
ana@lab:~/mm$ python ticket.py media/call-1042.wav
order='M-1042' title='Dom Casmurro' problem='Cover torn and about ten pages folded at the corner' refund_cents=3480
order  in transcript: True
title  in transcript: False
ana@lab:~/mm$ tail -n 2 /var/log/labmm/requests.jsonl | python -c "import json, sys; [print(r[\"path\"], r.get(\"model\"), r.get(\"rule\", \"-\")) for r in map(json.loads, sys.stdin)]"
/v1/audio/transcriptions lab-whisper-base -
/v1/chat/completions lab-vision-1 l12-ticket
```

O log mostra os dois pedidos que a cadeia fez: uma transcrição pelo Whisper base, que é real, e um pedido de chat respondido por `l12-ticket`, **uma regra que o curso escreveu**. O chamado diz o que um modelo poderia dizer sobre esta ligação; nenhum modelo disse.

Depois a conferência, e ela achou algo. O pedido passa: `M-1042` e o `M1042` da transcrição são as mesmas letras e dígitos. **O título falha**, porque o Whisper base da aula 7 ouviu "Dom Kazmuro" e "Dom Casmorrow", nunca "Dom Casmurro". Aqui o chamado está certo e a transcrição errada, e a conferência não tem como saber disso. Ela só pode dizer que o chamado afirma algo que ninguém foi ouvido dizendo, e é exatamente aí que uma pessoa deve olhar.

Duas coisas que a cadeia não fez. Ela não **mandou áudio para um modelo de chat**: os blocos do LangChain podem carregar áudio, para os poucos modelos de chat que o aceitam, e esta cadeia transcreve antes, para o texto poder ser guardado, buscado e conferido. E ela não **conferiu nada**: a comparação no fim é Python comum, fora da cadeia, porque nenhum framework sabe que campos do seu chamado precisam vir da gravação.
