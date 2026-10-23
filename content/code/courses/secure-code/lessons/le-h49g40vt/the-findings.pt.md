---
title: O que um revisor encontrou
version: 1
---

Aqui está o mesmo diff, marcado do jeito que um revisor percorrendo as cinco perguntas o marca. Seis
achados, e cada um tem uma aula deste curso por trás:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-marked\" aria-label=\"O diff do branch messages, reduzido às seis linhas que importam, cada uma com um marcador numerado. Marcador 1, a rota nova que lê uma mensagem pelo número: nada verifica de quem é a mensagem. Marcador 2, a mensagem montada com todos os campos do formulário: quem envia escolhe em nome de quem ela fica. Marcador 3, o template que acrescenta o filtro safe: o escape é desligado para o texto dos pacientes. Marcador 4, a chave secreta escrita como string no código. Marcador 5, a versão do Flask afrouxada para um intervalo. Marcador 6, uma funcionalidade nova sem teste novo.\"><rect x=\"20\" y=\"14\" width=\"420\" height=\"276\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+@app.get(\"/messages/&lt;int:number&gt;\")</text><rect x=\"456\" y=\"26\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1</text><text x=\"496\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nada verifica de quem é</text><text x=\"36\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+    message = dict(request.form)</text><rect x=\"456\" y=\"70\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"84.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">2</text><text x=\"496\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">quem envia escolhe o nome</text><text x=\"36\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+ … m.text|replace('\\n', '&lt;br&gt;')|safe …</text><rect x=\"456\" y=\"114\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3</text><text x=\"496\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">escape desligado</text><text x=\"36\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+app.secret_key = \"vereda-dev\"</text><rect x=\"456\" y=\"158\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4</text><text x=\"496\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um segredo no repositório</text><text x=\"36\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">+flask&gt;=3.0</text><rect x=\"456\" y=\"202\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"216.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5</text><text x=\"496\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a versão virou intervalo</text><text x=\"36\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">(nenhum teste mudou)</text><rect x=\"456\" y=\"246\" width=\"28\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"470.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">6</text><text x=\"496\" y=\"260\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nenhum teste veio junto</text></svg>", "caption": "O mesmo diff, como um revisor o marca. Cada marcador é uma pergunta, e cada um tem uma aula por trás."}
```

### 1 · Qualquer paciente lê qualquer mensagem

`read_message` chama `patient()`, que recusa quem não está autenticado, e depois devolve
`MESSAGES[number]` seja de qual paciente for. As mensagens são numeradas 1, 2, 3, então toda mensagem
do portal está a um palpite de todo paciente autenticado. É a falha da aula 1 de novo, numa rota
nova, e vem primeiro na lista porque expõe dados de outras pessoas. A correção é a mesma: uma
mensagem que não é de quem chama é respondida como uma que não existe.

### 2 · Quem envia escolhe de quem é a mensagem

`dict(request.form)` guarda todo campo que chegou, e `message.get("patient", patient())` usa um campo
`patient` do formulário quando há um. Uma requisição consegue, portanto, registrar uma mensagem em
nome de outro paciente, e a clínica responderia à pessoa errada. A aula 3 chamou isso de atribuição
em massa. A correção é montar o registro só com os campos conhecidos, com `patient` vindo da sessão e
nunca da requisição.

### 3 · Escape desligado para o texto dos pacientes

Para manter as quebras de linha, o template troca `\n` por `<br>` e marca o resultado como `safe`.
Isso desliga, para o texto que um paciente digitou, o escape em que a aula 4 confiou. As quebras de
linha são uma necessidade real com uma resposta segura: manter o texto escapado e deixar o CSS mostrar
as quebras, com `white-space: pre-line` no parágrafo. Nenhum HTML precisa receber confiança por causa
de uma quebra de linha.

### 4 · Um segredo no repositório

`app.secret_key = "vereda-dev"` troca uma chave aleatória por uma fixa escrita no código. O Flask
assina o cookie de sessão com essa chave, então qualquer pessoa que leu o repositório consegue
produzir um cookie de sessão que o servidor aceita como legítimo. A descrição chama isso de
simplificação. A aula 16 diz onde uma chave deve ficar.

### 5 · A versão fixada virou intervalo

`flask>=3.0` instala o Flask que for mais novo no dia de cada deploy. A aula 17 explicou por que uma
aplicação fixa versões; nada na mudança precisava do intervalo.

### 6 · Nenhum teste veio junto

A mudança acrescenta duas rotas e mexe no template, e nenhum teste mudou. Cada achado acima é o tipo
de coisa que um único teste teria fixado: *um paciente não lê a mensagem 2*, *o remetente do
formulário é ignorado*, *o texto de uma mensagem é escapado*. **Um comentário de revisão que pede o teste
muitas vezes vale mais do que um que descreve a correção**, porque o teste fica depois que o revisor
foi embora.

### O que o revisor não marcou

`max(MESSAGES) + 1` pode dar o mesmo número a duas mensagens se elas chegarem ao mesmo tempo, e um
número de mensagem que não existe levanta um erro que vira 500. Os dois são reais e valem um
comentário. Nenhum expõe dados de ninguém, então ficam abaixo dos seis, marcados como não
bloqueantes.
