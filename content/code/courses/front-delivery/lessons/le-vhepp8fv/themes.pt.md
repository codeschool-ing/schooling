---
title: Temas são os mesmos nomes com outros valores
version: 1
---

**Um tema é um segundo conjunto de valores para os mesmos tokens semânticos, e não uma segunda folha de
estilo.** O CSS do planner diz `background: var(--surface)` uma vez; o que `--surface` guarda depende do
tema que vale. Acrescentar um tema é acrescentar uma coluna ao `tokens.json`, e nenhuma regra da folha de
estilo do app muda.

O arquivo gerado guarda a camada semântica três vezes:

```
ana@dev:~/planner$ sed -n '/^:root,/,$p' src/tokens.css
:root,
[data-theme="light"] {
  --surface: var(--color-grey-0);
  --raised: var(--color-grey-50);
  --text: var(--color-grey-900);
  --muted: var(--color-grey-600);
  --accent: var(--color-green-600);
  --on-accent: var(--color-grey-0);
}

@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --surface: var(--color-grey-900);
    --raised: var(--color-grey-800);
    --text: var(--color-grey-50);
    --muted: var(--color-grey-300);
    --accent: var(--color-green-300);
    --on-accent: var(--color-grey-900);
  }
}

[data-theme="dark"] {
  --surface: var(--color-grey-900);
  --raised: var(--color-grey-800);
  --text: var(--color-grey-50);
  --muted: var(--color-grey-300);
  --accent: var(--color-green-300);
  --on-accent: var(--color-grey-900);
}
```

## Três blocos, três situações

1. **`:root, [data-theme="light"]`** é o padrão, e também o que qualquer elemento com
   `data-theme="light"` recebe.
2. **`@media (prefers-color-scheme: dark)`** vale quando o sistema operacional de quem lê está no escuro.
   Dentro dele, `:root:not([data-theme="light"])` dá ao elemento raiz os valores escuros a menos que a
   página o tenha fixado no claro, que é o que um seletor de tema na interface faz.
3. **`[data-theme="dark"]`** força o escuro em qualquer elemento que pedir, diga o sistema o que disser.

O padrão atende tanto a preferência de quem lê quanto uma escolha explícita. Um seletor de tema é então
uma linha de JavaScript, definindo `document.documentElement.dataset.theme`, e lembrá-lo entre visitas é o
`localStorage`. O planner não tem seletor; ele segue o sistema, e a aula 6 usa o atributo para mostrar todo
componente nos dois temas lado a lado.

## O que mais um tema precisa mudar

As cores são a parte óbvia. Duas menos óbvias:

- **`color-scheme`.** Campos de formulário, barras de rolagem e os controles do próprio navegador são
  desenhados pelo navegador, e não pelo seu CSS, e ficam claros numa página escura a menos que a página
  declare `color-scheme: light dark`. A folha de estilo do planner declara, na próxima seção.
- **a conferência, por tema.** O tema escuro é um conjunto de pares novos com o próprio contraste, como o
  `grey-400` da seção anterior mostrou. Um tema que ninguém mediu é um tema que ninguém consegue ler sob
  alguma luz.

## Temas como marcas

O mesmo mecanismo serve um produto vendido sob duas marcas, ou um app white-label que cada cliente pinta
do seu jeito: cada marca é mais uma coluna de valores semânticos, talvez com os próprios primitivos. Os
componentes nunca ficam sabendo em qual marca estão. É o mesmo motivo de este curso repetir "a camada
semântica": todo tema, marca e modo é uma resposta diferente às mesmas perguntas com nome.
