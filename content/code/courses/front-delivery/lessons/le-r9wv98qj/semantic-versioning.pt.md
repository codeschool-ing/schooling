---
title: Versionamento semântico, para um design system
version: 1
---

**Um número de versão é uma promessa sobre o que mudou, e o versionamento semântico torna a promessa
precisa: `MAJOR.MINOR.PATCH`, em que cada parte diz que tipo de mudança a versão traz.** Quem consome o
planner vai ler `0.1.0` e `0.2.0` e decidir só pelos números se atualiza sem olhar, então os números
precisam estar certos.

| parte | sobe quando uma versão | quem consome pode |
|---|---|---|
| PATCH, `0.1.0` → `0.1.1` | conserta algo sem mudar o que é oferecido | aceitá-la sem ler nada |
| MINOR, `0.1.1` → `0.2.0` | acrescenta algo, e não remove nem muda nada | aceitá-la, e usar a novidade se quiser |
| MAJOR, `0.2.0` → `1.0.0` | remove ou muda algo de que quem consome podia depender | ler as notas e mudar o próprio código antes |

**Antes do `1.0.0` as regras descem uma casa.** A especificação diz que qualquer coisa pode mudar numa
versão `0.x`; na prática o npm trata o minor de um `0.x` como a parte que quebra, então `^0.1.0` aceita
`0.1.5` e recusa `0.2.0`. Uma biblioteca em `0.x` está dizendo a quem a consome que ainda não prometeu
estabilidade. O `1.0.0` é a versão que faz a promessa.

## O que conta como quebra, para um design system

Para uma biblioteca comum, quebrar quer dizer que código que compilava agora falha. Um design system quebra
desse jeito e de dois jeitos mais silenciosos:

- **a interface de código**: um export removido ou renomeado, um argumento acrescentado que é obrigatório,
  um tipo estreitado. O `tsc` pega isso em quem consome, que é o caso fácil.
- **os nomes dos tokens**: `--muted` renomeado para `--subtle`. Nada deixa de compilar; o CSS de quem
  consome perde uma cor em silêncio, como a aula 5 mostrou. **Renomear um token é uma mudança major**, mesmo
  sem nenhuma ferramenta reclamar.
- **a aparência**: um espaçamento padrão dobrado, um raio mudado. Se isso quebra é uma questão de
  julgamento, e as equipes discordam. Uma regra útil: se os testes de captura de quem consome falhariam e
  essa pessoa precisaria aprovar imagens de novo, diga isso na versão.

## O que quem consome escreve

A outra metade da promessa é o intervalo que quem consome aceita. O `npm install` grava `^0.1.0` por
padrão, o que aceita qualquer atualização compatível automaticamente. **Este curso fixa versões exatas**,
`0.1.0`, para uma atualização ser um commit que alguém faz e revisa, e o lockfile fixa tudo o que vem por
baixo. Para um design system isso vale o pequeno esforço: uma versão nova pode mover pixels em toda tela, e
essa é uma mudança que alguém deve olhar, pelos testes visuais da aula 6, de propósito.
