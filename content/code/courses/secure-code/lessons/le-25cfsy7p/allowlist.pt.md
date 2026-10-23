---
title: Descreva o que é bom
version: 1
---

Uma **lista de permissão** (*allowlist*) inverte a pergunta. Em vez de listar o que é ruim, ela
descreve o que é um valor válido, e recusa todo o resto. A descrição costuma ser curta, porque
valores válidos têm forma: a Vereda tem quatro clínicas, um dia tem uma data real, uma sessão começa
na hora cheia entre 07:00 e 19:00, e um telefone tem 10 ou 11 dígitos. O que ninguém previu cai fora
dessa descrição e é recusado sem que alguém precise prever.

### O que uma descrição diz

Todo campo recebe as mesmas cinco perguntas, nesta ordem, e a primeira que falha decide a resposta:

| pergunta | no agendamento da Vereda | recusado, por exemplo |
|---|---|---|
| **está presente?** | os quatro campos são obrigatórios | um corpo sem `phone` |
| **é do tipo certo?** | texto, não número nem lista | `"phone": 11987654321` enviado como número |
| **tem o tamanho certo?** | um telefone tem 10 ou 11 caracteres | `1198765` |
| **está no intervalo?** | uma data que existe; uma hora em que as clínicas abrem | `2026-11-31`, `23:00` |
| **é um dos valores permitidos, ou do formato permitido?** | uma de quatro clínicas; só dígitos | `paulista`, um telefone com um espaço no meio |

A ordem importa para a mensagem de erro tanto quanto para o código. Dizer a um paciente que o
telefone está no formato errado quando ele o deixou em branco o manda procurar o erro errado.

### Conjuntos vencem padrões, e padrões precisam de âncora

**Quando os valores válidos cabem numa lista, liste.** Quatro clínicas são um conjunto, e pertencer a
um conjunto não tem caso de borda: `"moema" in CLINICS` é verdadeiro ou falso e não há o que errar. O
mesmo vale para os horários, treze ao todo, gerados por uma linha de código em vez de escritos à mão.

Quando os valores não cabem numa lista, uma **expressão regular** descreve o formato, e ela tem de
descrever o valor **inteiro**. O Python oferece três jeitos de aplicá-la, e só um está certo para
validação:

| chamada | o que verifica | para `11987654321 extra` |
|---|---|---|
| `re.search(r"[0-9]{10,11}", s)` | o padrão aparece em algum lugar de `s` | casa, errado |
| `re.match(r"[0-9]{10,11}", s)` | o padrão aparece no começo de `s` | casa, errado |
| `re.fullmatch(r"[0-9]{10,11}", s)` | o padrão é `s` inteiro | recusa |

`search` e `match` são o jeito mais comum de uma lista de permissão voltar, sem ninguém notar, a ser
"contém algo válido". `fullmatch` é o que descreve o valor. Escrever as âncoras à mão,
`^[0-9]{11}$`, chega perto e não é igual no Python: `$` também casa logo antes de uma quebra de linha
final, então `"11987654321\n"` passa nele e falha no `fullmatch`.

### Interprete em vez de casar, onde houver um interpretador

Uma data casada por `\d{4}-\d{2}-\d{2}` é uma string com a forma certa, e `2026-11-31` tem a forma
certa. **Um interpretador sabe o que a forma não sabe**: `date.fromisoformat("2026-11-31")` levanta
`ValueError`, porque sabe quantos dias tem novembro. Onde a biblioteca padrão consegue interpretar
um valor (uma data, um número, um endereço de e-mail por uma biblioteca própria, uma URL com
`urllib.parse`), interpretar é a validação, e o valor interpretado é o que o programa guarda.
