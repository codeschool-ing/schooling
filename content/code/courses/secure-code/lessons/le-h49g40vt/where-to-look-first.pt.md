---
title: Onde olhar primeiro
version: 1
---

Uma revisão de código tem um orçamento fixo de atenção, em geral menos de meia hora, e um diff de
algumas centenas de linhas. Leia de cima a baixo e a atenção vai para o que vem primeiro, que
costuma ser imports e nomes. **Uma revisão de segurança gasta o orçamento na ordem do que um erro
custaria**, e tem uma lista curta de lugares para olhar antes de qualquer outra coisa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l18-order\" aria-label=\"Onde uma revisão de segurança olha primeiro, como cinco perguntas em ordem de prioridade, cada uma com a aula deste curso que a ensina. Um: quem pode fazer isto, a autorização de cada rota nova, aulas 1, 12 e 13. Dois: o que entra, e se é validado na fronteira, aulas 2 e 3. Três: para onde sai, e se é codificado para aquele lugar, aula 4. Quatro: que segredos e configurações mudaram, aula 16. Cinco: que dependências mudaram, aula 17. Estilo e nomes vêm por último, e o diagrama os deixa de fora.\"><rect x=\"20\" y=\"20\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">1</text><rect x=\"80\" y=\"20\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">quem pode fazer isto?</text><text x=\"400\" y=\"33\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cada rota nova</text><text x=\"400\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">aulas 1, 12, 13</text><rect x=\"20\" y=\"74\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">2</text><rect x=\"80\" y=\"74\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"94.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o que entra?</text><text x=\"400\" y=\"87\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">validado na fronteira</text><text x=\"400\" y=\"103\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">aulas 2, 3</text><rect x=\"20\" y=\"128\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">3</text><rect x=\"80\" y=\"128\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"148.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">para onde sai?</text><text x=\"400\" y=\"141\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">codificado para o lugar</text><text x=\"400\" y=\"157\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">aula 4</text><rect x=\"20\" y=\"182\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">4</text><rect x=\"80\" y=\"182\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">que segredos e configurações mudaram?</text><text x=\"400\" y=\"195\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">nada secreto no diff</text><text x=\"400\" y=\"211\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">aula 16</text><rect x=\"20\" y=\"236\" width=\"40\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"40.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">5</text><rect x=\"80\" y=\"236\" width=\"300\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">que dependências mudaram?</text><text x=\"400\" y=\"249\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fixadas, auditadas</text><text x=\"400\" y=\"265\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">aula 17</text></svg>", "caption": "Cinco perguntas, nesta ordem. Um diff que vai mal na primeira não se salva indo bem nas outras."}
```

### As cinco perguntas

1. **Quem pode fazer isto?** Toda rota nova, toda ação nova numa rota existente. Há uma verificação
   de que quem chama está autenticado, e uma de que aquilo sobre o que ele age é dele? O botão de
   cancelar da aula 1 falhou na segunda metade, e as aulas 12 e 13 tratam só disso. Vem primeiro
   porque uma verificação que falta é invisível no código que está lá: o revisor tem de perguntar
   pela linha ausente.
2. **O que entra?** Todo valor de uma requisição, de um arquivo, de um cabeçalho ou de outro serviço.
   É validado uma vez, na fronteira, contra uma lista de permissão, e o registro é montado só com
   campos conhecidos? Aulas 2 e 3.
3. **Para onde sai?** Todo lugar onde um valor é escrito: HTML, um atributo, um script, uma URL, uma
   linha de log, uma consulta. É codificado para aquele lugar, pela ferramenta feita para ele? Aula 4.
4. **Que segredos e configurações mudaram?** Uma chave no código, um modo de depuração ligado, uma
   flag de cookie removida, um tempo limite aumentado. A aula 16 trata de segredos.
5. **Que dependências mudaram?** Um pacote novo, uma versão afrouxada, uma versão que voltou para trás.
   Aula 17.

Erros, logs e testes vêm logo depois, e nomes e estilo por último. Estilo importa, e um linter em
geral o pega sem precisar de uma pessoa.

### Leia a mudança, depois o contexto

Um diff mostra as linhas que mudaram e três linhas em volta de cada uma. A falha muitas vezes está em
como uma linha mudada encontra uma que não mudou: uma rota nova que chama uma função auxiliar escrita
no ano passado, que nunca verificou o que a rota nova supõe. **Quando uma linha nova depende de código
antigo, abra o código antigo.** O botão de expandir da ferramenta de revisão existe exatamente para
isso.

### E leia a descrição por último

A descrição diz o que o autor quis fazer. O diff diz o que ele fez. Ler a descrição primeiro facilita
ver a intenção no código em vez do próprio código, que é a única coisa que um revisor está ali para
evitar.
