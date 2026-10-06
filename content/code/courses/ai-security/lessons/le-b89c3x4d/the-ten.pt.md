---
title: As dez, ao lado dos controles deste curso
version: 1
---

O `data/owasp-llm-2025.json` traz as dez categorias. **Os nomes são da OWASP; os significados de uma
linha e o mapa para o laboratório são do curso**, escritos para ligar cada nome a algo que você rodou:

```
ana@lab:~/guard$ python3 -c "import json; [print(r['id'], '-', r['meaning']) for r in json.load(open('data/owasp-llm-2025.json'))]"
LLM01 - text the developer did not write steers the model
LLM02 - personal data or secrets reach a reply, a log or a provider
LLM03 - a model, dataset or package from somewhere else is not what it claims
LLM04 - the data a model learns or retrieves from was tampered with
LLM05 - a reply is used by other code without being checked
LLM06 - an agent can do more than its task needs
LLM07 - the instructions, or what is hidden in them, reach a client
LLM08 - the store a model retrieves from leaks or is tampered with
LLM09 - a confident answer is false and somebody acts on it
LLM10 - one user or one loop spends without limit
ana@lab:~/guard$ guard owasp
LLM01 Prompt Injection                   guard check-in, guard filter, guard gate
LLM02 Sensitive Information Disclosure   guard redact, guard minimise, guard filter
LLM03 Supply Chain                       guard deps
LLM04 Data and Model Poisoning           NOT COVERED IN THIS LAB
LLM05 Improper Output Handling           guard check-out, guard filter
LLM06 Excessive Agency                   guard gate
LLM07 System Prompt Leakage              canary in guard filter
LLM08 Vector and Embedding Weaknesses    NOT COVERED IN THIS LAB
LLM09 Misinformation                     guard ground
LLM10 Unbounded Consumption              guard ratelimit, guard retry, guard gate --budget
10 categories, 2 with no control in this lab
```

Leia o mapa em três grupos.

**As que tratam do que entra.** *Prompt injection* (LLM01) é a raiz que a aula 1 descreveu: um modelo lê
instruções e material num fluxo só. Nenhum controle sozinho a elimina, e é por isso que a linha dela
nomeia três: estreitar a entrada (aula 9), filtrar a saída (aula 5) e controlar as ferramentas (aula
20). *Supply chain* (LLM03) trata de tudo o que veio de outro lugar; o laboratório cobre só os nomes de
pacote da aula 2, e a procedência do próprio modelo fica fora dele.

**As que tratam do que sai.** *Sensitive information disclosure* (LLM02) são as aulas 11 e 12.
*Improper output handling* (LLM05) é o schema da aula 9 e a cadeia da aula 5. *System prompt leakage*
(LLM07) tem só o canário, que detecta um vazamento literal e mais nada; a defesa mais forte é o conselho
da aula 5 de não pôr num prompt de sistema nada que importe se for lido. *Misinformation* (LLM09) é a
aula 2.

**As que tratam do que o modelo pode fazer.** *Excessive agency* (LLM06) é o manifesto, o portão e a
confirmação da aula 10. *Unbounded consumption* (LLM10) é todo limite do curso: taxas por usuário na
aula 7, o teto de novas tentativas na aula 9, o orçamento de chamadas na aula 10.

Cada linha é um ponteiro, não uma prova. Uma linha com um comando diz que o laboratório tem *um*
controle; se esse controle basta para um dado recurso é a pergunta que a próxima seção faz.
