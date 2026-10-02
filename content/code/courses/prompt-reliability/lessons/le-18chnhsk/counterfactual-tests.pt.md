---
title: Testes contrafactuais
version: 1
---

Os três testes até aqui mudaram o prompt. O viés que mais importa para um cliente está no outro
lugar: **uma resposta que muda com algo sobre a pessoa** que não deveria importar, como um nome, o
jeito de escrever ou de onde ela parece ser. Esse viés não se lê no prompt, porque ele não está no
prompt.

O teste para ele tem nome e um formato simples. Pegue mensagens, faça uma cópia de cada uma que
difira **só** no atributo que não pode importar, rode as duas e compare as respostas. Se o atributo
não importa, nada muda.

```
ana@lab:~/triage$ head -n 1 cases/names-a.jsonl cases/names-b.jsonl
==> cases/names-a.jsonl <==
{"id": "n01", "message": "Maria Souza here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}

==> cases/names-b.jsonl <==
{"id": "n01", "message": "John Smith here. I was charged twice for order 5120.", "expect": {"category": "billing", "urgency": "high"}}
```

`names-a` e `names-b` são as mesmas oito mensagens, assinadas por Maria Souza num arquivo e por
John Smith no outro. Nada mais difere, e os rótulos que uma pessoa deu são os mesmos nos dois.

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/names-a.jsonl --out runs/names-a.jsonl
8 calls, prompt fbc4c9b1, written to runs/names-a.jsonl
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/names-b.jsonl --out runs/names-b.jsonl
8 calls, prompt fbc4c9b1, written to runs/names-b.jsonl
ana@lab:~/triage$ pl compare runs/names-a.jsonl runs/names-b.jsonl --answers
8 cases, same answer 8, different answer 0
ana@lab:~/triage$ pl compare runs/names-a.jsonl runs/names-b.jsonl
runs/names-a.jsonl       passes 4/8
runs/names-b.jsonl       passes 4/8
fixed 0, broken 0, still passing 4, still failing 4
sign test on the 0 that changed: p = 1.000
```

Nenhuma resposta mudou. A comparação de aprovações, que conta a urgência além da categoria,
concorda: nada corrigido, nada quebrado.

## O que isso prova

**Neste laboratório, nada.** O substituto classifica por palavras-chave, e nenhum nome é
palavra-chave, então ele não tem como tratar Maria de um jeito e John de outro. O teste saiu limpo
porque o substituto não consegue falhar nele, e um teste que não pode falhar não diz nada sobre o
que está sendo testado.

Num modelo real, os mesmos oito pares poderiam sair diferentes, e você só saberia rodando. É esse o
ponto da seção: **o teste é como você descobriria**, e são os mesmos três comandos, seja qual for o
modelo.

## Uma resposta mudou, sim

Olhe um par mais de perto:

```
ana@lab:~/triage$ pl show runs/names-a.jsonl n06
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "Maria Souza writing."
│ }
stop: end, tokens in 117, out 28
ana@lab:~/triage$ pl show runs/names-b.jsonl n06
│ Here is the JSON you asked for:
│
│ {
│   "category": "billing",
│   "urgency": "normal",
│   "summary": "John Smith writing."
│ }
stop: end, tokens in 117, out 36
```

Mesma categoria, mesma urgência, e a resposta de John tem uma frase antes do JSON. O substituto
sorteia os hábitos de formatação a partir do texto exato que recebe, então outro nome é outro
sorteio. Isso é ruído, e ele calha de depender do nome.

É por isso que um teste contrafactual precisa de um **piso de ruído**. Rode o mesmo arquivo duas
vezes e compare; o que difere entre essas duas execuções difere sem motivo nenhum, e uma diferença
entre Maria e John só conta acima disso. No substituto, com temperatura 0, o piso é zero. Num modelo
real, não há garantia de que seja.

## Montando um conjunto contrafactual

- **Mude uma coisa só.** Um `diff` dos dois arquivos deve mostrar o atributo e mais nada, como
  mostraria aqui.
- **Use mais de dois valores.** Maria e John são uma comparação; um viés contra um grupo só aparece
  quando o grupo está no conjunto.
- **Procure uma direção, não só uma contagem.** Duas respostas mudando em sentidos opostos é ruído.
  Seis urgências mais altas para um nome do que para o outro é um achado.
- **Use pares suficientes.** Oito é uma demonstração. Com poucos pares, o teste do sinal da aula 7
  diz quão pouco uma diferença pequena prova.

A resposta que um cliente recebe deve depender do que ele escreveu, nunca de quem ele é. **Um
conjunto contrafactual é o único destes testes que verifica isso diretamente**, e custa uma cópia
a mais de um arquivo que você já tem.
