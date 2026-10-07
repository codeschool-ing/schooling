---
title: Escolhendo um método
version: 1
---

Cinco métodos em três aulas bastam para qualquer equipe discutir qual usar. A discussão é quase
sempre desnecessária, porque **eles respondem a perguntas diferentes**, e a maioria dos modelos
reais usa dois ou três deles para partes diferentes do trabalho.

| método | responde | use quando | o principal limite |
|---|---|---|---|
| **STRIDE** | o que pode dar errado em cada parte? | sempre, como primeira passada sobre um DFD | sem ordenação; cego a cadeias |
| **PASTA** | o que mais importa para o negócio, e por quê? | quem decide não é técnico, ou o risco é sobretudo de negócio | caro; precisa do negócio na sala |
| **LINDDUN** | que dano o sistema causa à privacidade das pessoas, mesmo funcionando como projetado? | o sistema guarda dado pessoal, e sobretudo dado sensível | não cobre ataques ao sistema |
| **árvores de ataque** | qual o caminho mais barato até este objetivo, e que controle o corta? | escolher entre controles para um objetivo que importa | um objetivo por árvore; só conhece os caminhos desenhados |
| **DREAD** | quão ruim é esta ameaça, de zero a dez? | ler um modelo antigo que o usou | as notas não concordam entre avaliadores |

### O que a Vereda faz

Para uma mudança no portal, a rotina da Vereda tem três passos, e cada um vem de um método
diferente:

1. **STRIDE** nos fluxos que a mudança toca, por interação onde uma fronteira é cruzada.
2. **LINDDUN** em qualquer fluxo que leve dado pessoal para fora da Vereda, ou em qualquer
   repositório novo que o guarde.
3. **Uma árvore de ataque** só quando um objetivo do estágio 1 ganha um caminho novo, para conferir
   se os controles que já existem ainda o cortam.

A moldura do PASTA, como a aula 4 descreveu, decide a ordem em que os achados são tratados. O DREAD
não é usado. Quando é preciso ordenar, as aulas 9 a 11 dão uma ordenação com números que dá para
conferir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l05-routine\" aria-label=\"A rotina da Vereda para uma mudança, um método por passo. Primeiro o STRIDE, nos fluxos que a mudança toca, por interação onde uma fronteira é cruzada. Depois o LINDDUN, em qualquer fluxo que leve dado pessoal para fora da Vereda, ou qualquer repositório novo que o guarde. Depois uma árvore de ataque, só quando um objetivo do estágio 1 do PASTA ganha uma rota nova. A moldura do PASTA ordena os achados; o DREAD não é usado.\"><defs><marker id=\"l05-routine-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">STRIDE</text><text x=\"125.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">os fluxos que a mudança toca</text><path d=\"M230.0 75.0 L255.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-routine-tm-ah-paper-dim)\"></path><rect x=\"255.0\" y=\"40.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">LINDDUN</text><text x=\"360.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">dado pessoal saindo da Vereda</text><path d=\"M465.0 75.0 L490.0 75.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l05-routine-tm-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"40.0\" width=\"210.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">árvore de ataque</text><text x=\"595.0\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">um objetivo com rota nova</text><rect x=\"20.0\" y=\"135.0\" width=\"680.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"360.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a moldura do PASTA decide a ordem em que os achados são tratados</text><text x=\"360.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">o DREAD não é usado: as aulas 9 a 11 ordenam com números conferíveis</text></svg>", "caption": "Cada passo responde a uma pergunta diferente, então tirar um deixa a pergunta dele sem fazer, não respondida pelos outros.", "same": ["LINDDUN", "STRIDE"]}
```

### Combinar é normal

Nenhum método diz ser completo, e os que são honestos sobre isso o dizem na própria documentação. O
STRIDE achou a T08 perguntando sobre divulgação, e o LINDDUN achou mais três coisas sobre o mesmo
fluxo. A árvore de ataque descobriu que um controle era desperdício para um objetivo. O ponto cego de
cada método é o assunto de outro, e um modelo que usou um só herda o ponto cego desse método
inteiro.
