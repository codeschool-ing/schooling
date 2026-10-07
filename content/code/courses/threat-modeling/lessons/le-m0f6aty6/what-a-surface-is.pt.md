---
title: O que é uma superfície de ataque
version: 1
---

Um modelo de ameaças pergunta o que pode dar errado. Uma superfície de ataque faz antes uma pergunta
mais estreita: **por onde qualquer coisa de fora consegue entrar, e por onde qualquer coisa nossa
sai?** Toda ameaça da aula 3 chegou por um desses lugares. Um mapa deles é a lista de onde olhar, e o
tamanho dele é uma das poucas propriedades de segurança de um projeto que dá para contar.

A ideia ganhou forma com Michael Howard, na Microsoft, no começo dos anos 2000, e depois com
Pratyusa Manadhata e Jeannette Wing, na Carnegie Mellon, que definiram a superfície de ataque de um
sistema como três conjuntos:

| | o que é | no portal |
|---|---|---|
| **pontos de entrada e de saída** | os métodos pelos quais dados entram no sistema ou saem dele | o formulário de login, o upload, o handler do webhook, as páginas, a chamada do lembrete |
| **canais** | os jeitos como alguém de fora se conecta a esses pontos | HTTPS a partir da internet, HTTPS a partir dos fornecedores, a rede da clínica |
| **itens de dado não confiável** | os dados que alguém de fora consegue ler ou escrever por eles | os PDFs enviados, os campos do agendamento, o corpo do webhook |

Num diagrama de fluxo de dados, os três já estão desenhados. **Um ponto de entrada é um fluxo que
cruza uma fronteira para dentro do que você roda; um ponto de saída é um fluxo que cruza para
fora.** É por isso que o mapa pode ser calculado a partir do modelo da aula 2, que é o que esta aula
faz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" data-fig=\"l06-three-sets\" aria-label=\"Os três conjuntos de Manadhata e Wing que formam uma superfície de ataque, com um exemplo de cada no portal. Pontos de entrada e saída: o tratador do webhook. Canais: HTTPS vindo dos fornecedores. Itens de dado não confiáveis: um PDF enviado.\"><rect x=\"20.0\" y=\"30.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pontos de entrada e saída</text><text x=\"125.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o tratador do webhook</text><rect x=\"255.0\" y=\"30.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">canais</text><text x=\"360.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">HTTPS dos fornecedores</text><rect x=\"490.0\" y=\"30.0\" width=\"210.0\" height=\"100.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"595.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">itens de dado não confiáveis</text><text x=\"595.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um PDF enviado</text><text x=\"360.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">os três já estão no DFD: fluxos que cruzam uma fronteira, o transporte, os dados</text></svg>", "caption": "A definição são três listas, e um diagrama de fluxo de dados já guarda todas."}
```

### Superfície não é risco

Uma superfície maior significa mais lugares para olhar, não mais risco em cada um. Uma página só de
leitura com o horário das clínicas faz parte da superfície e quase ninguém se importa com ela. O
webhook é um ponto de entrada e decide se um agendamento está pago. Então o mapa vem com duas
perguntas por entrada: **quem chega até ela sem credencial, e o que ela consegue mudar?** As
respostas ordenam as entradas, e a segunda parte desta aula encolhe as do topo.

### As partes que ninguém desenha

A superfície também é tudo o que roda com a confiança do seu sistema: as bibliotecas que o portal
importa, os serviços que ele chama, as ferramentas que o constroem e o publicam. Nenhuma aparece como
círculo no DFD, e cada uma é um jeito de o erro de outra pessoa virar problema da Vereda. A seção
sobre dependências as desenha.
