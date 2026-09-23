---
title: Nomear, que é a única parte disto que é trabalho
version: 2
---

Tudo antes desta seção foi como o sistema de arquivos se comporta. Esta é o hábito que decide se
algo daquilo te ajuda, e ele é menor do que as pessoas esperam: **o nome de um arquivo deve dizer
o que ele é sem ninguém precisar abrir.**

## A regra da data, que se paga numa semana

Ponha a data na frente, e escreva **ano, mês, dia**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Duas listas dos mesmos cinco arquivos de fatura, cada uma ordenada do jeito que um computador ordena nomes. À esquerda as datas estão escritas com o ano na frente e a lista sai em ordem de data, de novembro de 2025 a novembro de 2026. À direita as mesmas datas estão escritas com o dia na frente e a lista sai ordenada por dia do mês, com o arquivo mais antigo no fim.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">Os mesmos cinco arquivos, ordenados pela mesma regra</text><rect x=\"24\" y=\"36\" width=\"326\" height=\"188\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><rect x=\"370\" y=\"36\" width=\"326\" height=\"188\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"44\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o ano escrito na frente</text><text x=\"390\" y=\"56\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a data escrita do jeito de sempre</text><text x=\"44\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2025-11-30-invoice.pdf</text><text x=\"390\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">02-03-2026-invoice.pdf</text><text x=\"44\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-01-08-invoice.pdf</text><text x=\"390\" y=\"108\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">05-11-2026-invoice.pdf</text><text x=\"44\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-02-14-invoice.pdf</text><text x=\"390\" y=\"132\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">08-01-2026-invoice.pdf</text><text x=\"44\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-03-02-invoice.pdf</text><text x=\"390\" y=\"156\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">14-02-2026-invoice.pdf</text><text x=\"44\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">2026-11-05-invoice.pdf</text><text x=\"390\" y=\"180\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">30-11-2025-invoice.pdf</text><text x=\"44\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">em ordem de data, de graça</text><text x=\"390\" y=\"246\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">em ordem nenhuma</text><text x=\"24\" y=\"278\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Um computador ordena nomes caractere por caractere. Pôr o ano na frente é o que faz os dois concordarem.</text></svg>", "caption": "Nada foi ordenado à mão dos dois lados. A lista da esquerda é o que o gerenciador de arquivos faz sem ajuda nenhuma."}
```

Um computador ordena nomes caractere por caractere. `2026-01-08` e `08-01-2026` descrevem o mesmo
dia, e só um deles põe os arquivos em ordem de data quando ordenados por nome — que é a ordem que
todo gerenciador de arquivos oferece por padrão e a ordem que você quer quase sempre.

É uma norma de verdade, a `ISO 8601`, e ela é inequívoca de quebra: `03-04-2026` é março num país
e abril em outro, e `2026-04-03` é abril em todo lugar.

## O que um nome bom contém

`2026-03-14-tavares-contrato-assinado.pdf`

- **a data**, na frente, em ISO;
- **de quem ou do que ele é**;
- **o que ele é**;
- **o estado dele**, onde isso importa — `rascunho`, `assinado`, `final`.

E o que ele não contém: `final`, `final2`, `FINAL-mesmo`, `v2-novo`. Se você precisa de versões,
numere com zeros à frente — `v01`, `v02` — para que dez venha depois de nove.

## Pastas: rasas, e nomeadas do jeito que você procura

Duas regras, e a segunda é a que é quebrada:

- **Três ou quatro níveis, não oito.** Cada nível a mais é uma decisão na hora de arquivar e um
  chute na hora de procurar.
- **Nomeie pastas do jeito que você vai buscar, não do jeito que a coisa é classificada.** Uma
  pasta chamada `clientes/tavares` é achável. Uma chamada
  `negocio/ativo/2026/t1/correspondencia` exige reconstruir a taxonomia de alguém de memória.

Quando um arquivo genuinamente pertence a dois lugares, é para isso que serve um atalho — e é um
dos poucos usos honestos de um.

## As quatro pastas que cobrem quase uma vida

```localised
documentos/
  2026/           ← coisas que pertencem a um ano
  referencia/     ← coisas que não mudam
  projetos/       ← coisas em andamento agora
  arquivo/        ← coisas terminadas
```

A interessante é `arquivo/`. **Mover um projeto terminado para fora de `projetos/` é o passo que
mantém a lista atual curta**, e uma lista atual curta é o benefício inteiro. Nada é apagado; para
de estar no caminho.

## Duas coisas para não fazer

**Não organize por tipo de arquivo.** Uma pasta de `pdfs` e uma de `planilhas` é uma classificação
pela qual ninguém busca — você procura *o contrato da Tavares*, não *um PDF*.

**Não dependa só de etiquetas.** Etiquetas são genuinamente boas e não são portáveis: elas vivem
no banco de dados de um sistema, raramente sobrevivem a uma cópia para outra máquina ou para um
serviço de nuvem, e são invisíveis para todo outro programa. Use por cima de uma estrutura de
pastas, nunca no lugar de uma.

## E a frase para guardar

**Nomeie um arquivo para a pessoa que vai procurá-lo daqui a dois anos, e essa pessoa é você.**
Toda regra acima é consequência disso, inclusive as que parecem frescura no dia.
