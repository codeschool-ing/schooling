---
title: A explosão de classes
version: 1
---

**Quando mais de uma coisa varia, a herança precisa de uma classe para cada combinação, e
combinações se multiplicam.** A lição 1 mostrou isso com dois eixos e seis classes. Esta seção conta
o que acontece quando um projeto continua crescendo, porque o crescimento é o argumento: ninguém
projeta uma hierarquia de trinta e seis classes, ela vai chegando um eixo de cada vez.

A crença comum é que explosão de classes é coisa de projetista ruim, e que um projetista cuidadoso a
evita escolhendo bem a hierarquia. O problema é que uma hierarquia só pode ser escolhida ao longo de
**um** eixo. O que varia em segundo lugar tem de ser empurrado para dentro de cada ramo do primeiro,
e o que varia em terceiro, para dentro de cada ramo deste.

## Contando

Os empréstimos da biblioteca variam pelo item (livro ou filme), pelo membro (adulto ou estudante),
pelo canal de aviso (e-mail, SMS ou papel impresso) e pela regra de multa (por dia, por dia depois de
alguns dias de carência, ou anistia). Aqui está a conta, feita pela máquina para ninguém ter de
confiar nela:

```schooling-example
{"language": "python", "file": "explosion.py", "parts": [
 {"code": "# explosion.py\nfrom itertools import product\n\naxes = [\n    (\"item\", [\"Book\", \"Film\"]),\n    (\"member\", [\"Adult\", \"Student\"]),\n    (\"channel\", [\"Email\", \"Sms\", \"Slip\"]),\n    (\"fine\", [\"PerDay\", \"Grace\", \"Amnesty\"]),\n]", "note": "Quatro coisas que variam, cada uma com suas opções. São os eixos aos quais as próximas seções vão voltar."},
 {"code": "\nprint(f\"{'what varies':<32}{'subclasses':>10}{'parts':>7}\")\nfor n in range(1, len(axes) + 1):\n    used = axes[:n]\n    names = [\"\".join(combo) for combo in product(*(options for _, options in used))]\n    parts = sum(len(options) for _, options in used)", "note": "Os eixos entram um de cada vez, como acontece numa base de código. `product` dá um nome de classe por combinação; o projeto por composição precisa de uma classe pequena por opção, então a conta dele é uma soma."},
 {"code": "    label = \" x \".join(axis for axis, _ in used)\n    print(f\"{label:<32}{len(names):>10}{parts:>7}\")", "note": "Uma linha por estágio de crescimento."},
 {"code": "\nsms = [name for name in names if \"Sms\" in name]\nprint(len(sms), \"classes contain Sms, from\", sms[0], \"to\", sms[-1])", "note": "E uma pergunta que quem mantém o código faz: se o gateway de SMS mudar, quantas classes estão envolvidas?"}
]}
```

```
ana@laptop:~/patterns/composition$ python3 explosion.py
what varies                     subclasses  parts
item                                     2      2
item x member                            4      4
item x member x channel                 12      7
item x member x channel x fine          36     10
12 classes contain Sms, from BookAdultSmsPerDay to FilmStudentSmsAmnesty
```

Com dois eixos de duas opções os dois projetos custam o mesmo, e é por isso que a explosão não
aparece no começo. O terceiro eixo é onde eles se separam: doze classes contra sete partes. No
quarto, **trinta e seis classes contra dez partes**, e uma mudança no funcionamento do SMS mexe em
doze classes de um lado e em uma do outro.

## O custo não é só a contagem

Uma classe por combinação é também código por combinação. `BookStudentSmsGrace` e
`FilmStudentSmsGrace` precisam, as duas, da regra dos dias de carência. Ou ela é copiada em cada
uma, ou mora num pai compartilhado, e aí a hierarquia tem um segundo pai por classe e a árvore virou
uma rede. O Python permite isso, e a seção sobre mixins mostra quanto custa; Java e Go não permitem
de jeito nenhum.

Acrescentar uma opção também custa de forma desigual. Um quarto canal, uma mensagem de WhatsApp por
exemplo, custa doze classes novas no projeto por herança, uma para cada combinação de 2 itens, 2
tipos de membro e 3 regras de multa. No projeto por composição custa uma classe que sabe mandar a
mensagem.

## Qual eixo vira a árvore

Existe um custo mais discreto. Uma hierarquia diz que um eixo é o que o objeto *é*, e todo o resto é
detalhe. `Book` e `Film` no alto fazem sentido para um catálogo. O setor de multas poria a regra de
multa no alto; o time de avisos poria o canal. Cada time tem razão sobre o próprio trabalho, e a
árvore de classes só consegue concordar com um deles.

**A composição não precisa escolher.** Um empréstimo *tem* um item, *tem* uma regra de multa, e o
membro dele *tem* um canal. Cada eixo é um campo que guarda um objeto, e cada um pode ser trocado sem
consultar os outros. É isso que as duas próximas seções constroem: primeiro a delegação, o
mecanismo, depois a troca de um comportamento com o programa rodando, que nenhuma árvore de classes
consegue fazer.

Nada disso diz que a herança nunca está certa. Um eixo único que nunca cresce, em que os filhos são
de fato tipos do pai, é uma árvore e deve ser desenhado como uma. Classes de exceção são o exemplo
clássico, e a seção sobre quando a herança serve começa por elas.
