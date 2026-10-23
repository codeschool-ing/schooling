---
title: Por que os gates acabam desligados
version: 1
---

Um quality gate é uma checagem que decide se uma mudança pode seguir: o build quebra, e nada entra
até alguém agir. A crença comum é que um gate mais rígido é um gate mais seguro, então todo achado
deveria quebrar o build. **Um gate que quebra por coisas que ninguém consegue corrigir é desligado
em semanas**, e um gate desligado é menos seguro que um que alerta.

### Como um gate morre

A aula 1 abriu com o scanner que estava vermelho havia um mês. Ninguém decidiu ignorá-lo. Ele
quebrava o build por achados que quem fazia o push não conseguia corrigir, como um aviso sem versão
corrigida ou um alerta sobre código de três anos atrás, e o time aprendeu que vermelho não queria
dizer nada. O passo seguinte é sempre o mesmo, e é sempre uma linha:

| onde | a linha que transforma um gate em enfeite |
|---|---|
| GitLab CI | `allow_failure: true` no job |
| GitHub Actions | `continue-on-error: true` no step |
| o pipeline deste curso | o nome do estágio comentado em `ci/stages` |
| um laptop | `git commit --no-verify` |

E em qualquer estágio de shell, `|| true` no fim do comando.

Cada uma é revisada em um minuto e aprovada, porque quem revisa também passou um mês vendo o mesmo
build vermelho. Nenhuma é revertida quando o ruído acaba, porque ninguém está de olho nisso. As duas
palavras-chave hospedadas vêm da documentação do GitLab e do GitHub e não foram executadas aqui. Isso
é **fadiga de alertas**: um sinal que dispara por ruído ensina os leitores a parar de ler, e então o
achado verdadeiro chega num canal que ninguém abre.

### A régua que este curso usa

A aula inteira argumenta a partir de uma regra, já vista como hábito na aula 1:

**Uma checagem quebra o build só pelo que quem o quebrou consegue corrigir, agora, na mudança que
está fazendo.** Todo o resto é alerta, contado, mostrado e com dono, ou nada.

A regra tem duas metades, e cada uma exclui um tipo comum de ruído. *Consegue corrigir* exclui o
aviso sem versão corrigida: o desenvolvedor não tem como publicar uma versão da biblioteca de outra
pessoa. *Agora, na mudança* exclui achados antigos em código que a mudança não tocou: quebrar a
mudança de terça por causa da dívida de segunda pune a pessoa errada e ensina que o gate é injusto.

Dois tipos de achado ficam acima da regra. **Um segredo sempre quebra**, porque o dono sempre pode
agir na hora, revogando-o, e esperar custa mais a cada minuto. E **uma checagem que não rodou também
quebra**: um scanner que travou, estourou o tempo ou nem começou não disse nada, e tratar silêncio
como aprovação é como um pipeline fica verde sem checar nada. Isso se chama falhar fechado, e o gate
desta aula é construído em volta disso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l07-decide\" aria-label=\"A ordem em que um achado é julgado. Primeiro, a checagem rodou até o fim? Se não, quebra. Depois, é um segredo? Se for, quebra. Depois, há uma exceção em vigor para ele? Se houver, passa, com alerta na última semana da exceção. Por último, quem fez o push consegue corrigir nesta mudança? Se sim, quebra; se não, alerta, com um dono.\"><defs><marker id=\"sp-l07-decide-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l07-decide-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"sp-l07-decide-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l07-decide-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"15\" y=\"30\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"90\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a checagem rodou</text><text x=\"90\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">até o fim?</text><rect x=\"195\" y=\"30\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">é um</text><text x=\"270\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">segredo?</text><rect x=\"375\" y=\"30\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">há exceção</text><text x=\"450\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">em vigor?</text><rect x=\"555\" y=\"30\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"630\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">quem fez o push corrige</text><text x=\"630\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nesta mudança?</text><path d=\"M165 61 L193 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-paper-dim)\"></path><text x=\"179\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><path d=\"M345 61 L373 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-paper-dim)\"></path><text x=\"359\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><path d=\"M525 61 L553 61\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-paper-dim)\"></path><text x=\"539\" y=\"51\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><rect x=\"15\" y=\"160\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">quebra</text><path d=\"M90 92 L90 158\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-amber)\"></path><text x=\"96\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text><rect x=\"195\" y=\"160\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">quebra</text><path d=\"M270 92 L270 158\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-amber)\"></path><text x=\"276\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"375\" y=\"160\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">passa</text><text x=\"450.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">alerta na última semana</text><path d=\"M450 92 L450 158\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-phosphor)\"></path><text x=\"456\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"555\" y=\"160\" width=\"72\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"591.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">quebra</text><path d=\"M580 92 L580 158\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-amber)\"></path><text x=\"586\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">sim</text><rect x=\"633\" y=\"160\" width=\"72\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.2\"></rect><text x=\"669.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">alerta</text><text x=\"669.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">com dono</text><path d=\"M680 92 L680 158\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l07-decide-ah-paper)\"></path><text x=\"686\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não</text></svg>", "caption": "Quatro perguntas, nesta ordem. Só a última é um julgamento sobre o achado; as duas primeiras quebram o build seja ele o que for."}
```

### Três vereditos, e o que cada um promete

| veredito | o que promete a quem o lê |
|---|---|
| quebra | isto é seu, tem correção, e nada entra até ser corrigido ou ganhar exceção |
| alerta | isto é real, ninguém consegue corrigir nesta mudança, e alguém com nome é o dono |
| passa | toda checagem rodou até o fim e não achou nada que mandaram apontar |

A promessa do "passa" é a que mais se quebra, por um estágio que sai com 0 porque o scanner não
conseguiu rodar. A promessa do alerta é a que mais se esquece: um alerta sem dono é ruído, e o gate
que o produz está a caminho de ser desligado. A próxima seção transforma os três vereditos em códigos
de saída que o pipeline sabe tratar, e as quatro seguintes os aplicam a seis casos, uma decisão cada.
