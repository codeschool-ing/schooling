---
title: Valores ausentes e não usados
version: 2
---

O harness faz barulho sobre um valor em duas situações, e as duas merecem. A primeira você já viu:
um buraco sem valor interrompe a renderização. A segunda é o oposto, um valor sem buraco:

```
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English --var tone=warm > /dev/null
pl: warning: {{tone}} is not in the template
```

O `> /dev/null` joga fora o prompt renderizado para sobrar só o aviso. Alguém passou `tone=warm`, e
o modelo de texto não tem `{{tone}}`. O prompt foi renderizado corretamente, e esse é exatamente o
problema.

## Um valor ausente

**Muitos motores de template não recusam um valor ausente.** Eles preenchem o buraco com alguma
coisa e seguem em frente, e o que usam para preencher depende do motor. O Jinja2, por padrão,
renderiza uma variável indefinida como texto vazio. O Mustache também renderiza uma chave ausente
como texto vazio. O `string.Template` do Python, com `safe_substitute`, deixa o marcador no texto
exatamente como foi escrito.

Então o prompt de resposta sem idioma vira *"Write in ."* ou a mesma frase com o marcador ainda
dentro, e o modelo recebe uma frase quebrada de um jeito que ele precisa contornar no palpite.
Nenhuma das duas aparece como erro. A resposta volta em algum idioma, talvez o certo, e o defeito
continua ali até um cliente de outro país receber inglês. **Um valor ausente precisa interromper a
execução**, porque nada depois da renderização consegue distinguir um buraco vazio de uma frase
curta.

## Um valor não usado

Um valor não usado parece inofensivo, já que o prompt está certo sem ele. O que ele mostra é uma
pessoa que acredita estar configurando algo que não está. Alguém queria respostas mais calorosas,
passou `tone=warm`, leu algumas respostas, achou que soavam um pouco mais calorosas e seguiu em
frente. **O valor nunca chegou ao modelo**, e as respostas que soavam mais calorosas são as que a
pessoa leu torcendo para que soassem.

Também acontece ao contrário: um modelo de texto é editado, `{{tone}}` vira `{{register}}`, e todo
script que ainda passa `tone` agora não passa nada. Um aviso de valor não usado é o único sintoma que
essa troca de nome vai produzir.

## Quando o harness avisa

A `render()` do `pl.py` avisa toda vez que preenche um modelo de texto, e o `pl run` o preenche uma
vez por caso, então uma execução repete o aviso para cada mensagem:

```
ana@lab:~/triage$ pl run prompts/reply.txt cases/three.jsonl --out runs/reply-warm.jsonl --var shop=Folio --var language=English --var tone=warm
pl: warning: {{tone}} is not in the template
pl: warning: {{tone}} is not in the template
pl: warning: {{tone}} is not in the template
3 calls, prompt 13304d8d, llama3.2:3b, written to runs/reply-warm.jsonl
```

Três avisos para três mensagens, e depois a execução segue, porque um aviso não é uma recusa. Numa
execução de quarenta eles passam num bloco, que é fácil de parar de ler. **Renderize um caso antes
de rodar um modelo de texto que você acabou de mudar**, e leia o que sai; não custa chamada nenhuma
e mostra o aviso uma vez, sozinho.
