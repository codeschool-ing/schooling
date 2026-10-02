---
title: Valores faltando e valores sobrando
version: 1
---

A bancada faz barulho sobre um valor em duas situações, e as duas merecem. A primeira você já viu:
uma lacuna sem valor interrompe a renderização. A segunda é o contrário, um valor sem lacuna:

```
ana@lab:~/triage$ pl render prompts/reply.txt --cases cases/dev.jsonl --case t01 --var shop=Folio --var language=English --var tone=warm > /dev/null
pl: warning: not used by the template: tone
```

O `> /dev/null` joga fora o prompt renderizado para sobrar só o aviso. Alguém passou `tone=warm`, e o
template não tem `{{tone}}`. O prompt foi renderizado corretamente, e esse é justamente o problema.

## Um valor faltando

**Muitos motores de template não recusam um valor faltando.** Eles preenchem a lacuna com alguma
coisa e seguem em frente, e com o quê depende do motor. O Jinja2, por padrão, renderiza uma variável
indefinida como texto vazio. O Mustache também renderiza uma chave ausente como texto vazio. O
`string.Template` do Python, com `safe_substitute`, deixa o marcador no texto exatamente como foi
escrito.

Então o prompt de resposta sem idioma vira *"Write in ."* ou *"Write in {{language}}."*, e o modelo
recebe uma frase quebrada de um jeito que ele precisa contornar adivinhando. Nenhuma das duas aparece
como erro. A resposta volta em algum idioma, talvez o certo, e o defeito fica lá até um cliente de
outro país receber inglês. **Um valor faltando precisa interromper a execução**, porque nada depois
da renderização consegue distinguir uma lacuna vazia de uma frase curta.

## Um valor sobrando

Um valor sobrando parece inofensivo, já que o prompt está certo sem ele. O que ele revela é uma
pessoa que acredita estar configurando algo que não está. Alguém queria respostas mais calorosas,
passou `tone=warm`, leu algumas respostas, achou que soavam um pouco mais calorosas e seguiu em
frente. **O valor nunca chegou ao modelo**, e as respostas que soaram mais calorosas são as que a
pessoa leu torcendo para que soassem.

Também acontece ao contrário: um template é editado, `{{tone}}` vira `{{register}}`, e todo script
que ainda passa `tone` agora não passa nada. Um aviso sobre valor sobrando é o único sintoma que essa
renomeação vai produzir.

## Quando a bancada avisa

O `pl render` avisa em toda renderização. O `pl run` também para quando falta um valor, mas não
repete os avisos para cada um dos quarenta casos, então um valor sobrando numa execução passa em
silêncio. **Renderize um caso antes de rodar um template que você acabou de mudar**, e leia o que
sai; não custa chamada nenhuma e é o único momento em que o aviso com certeza aparece.
