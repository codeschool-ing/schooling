---
title: Um pipeline de passos
version: 1
---

**Uma lista de funções pode ser dobrada numa função só**, começando por `Function.identity()` e
juntando cada passo com `andThen`. O resultado é um pipeline que você pode nomear, passar adiante e
testar, e acrescentar um passo a ele é acrescentar um elemento à lista.

Uma livraria recebe títulos digitados à mão, por fornecedores e por clientes, e quer uma forma limpa
de cada um antes de procurar no catálogo:

```schooling-example
{
  "language": "java",
  "file": "Pipeline.java",
  "parts": [
    {
      "code": "// Pipeline.java: cleaning steps folded into one function\nimport java.text.Normalizer;\nimport java.util.List;\nimport java.util.Locale;\nimport java.util.function.Function;\n\npublic class Pipeline {"
    },
    {
      "code": "    static final List<Function<String, String>> STEPS = List.of(\n            String::strip,\n            s -> s.replaceAll(\"\\\\s+\", \" \"),\n            s -> s.toLowerCase(Locale.ROOT),\n            s -> Normalizer.normalize(s, Normalizer.Form.NFD).replaceAll(\"\\\\p{M}\", \"\"));",
      "note": "Quatro passos, cada um pequeno o bastante para ler de relance: aparar as pontas, espremer sequências de espaços, baixar a caixa, tirar os acentos. O último separa cada letra acentuada na letra e na sua marca, depois apaga as marcas."
    },
    {
      "code": "\n    static Function<String, String> fold(List<Function<String, String>> steps) {\n        Function<String, String> all = Function.identity();\n        for (Function<String, String> step : steps) {\n            all = all.andThen(step);\n        }\n        return all;\n    }",
      "note": "A dobra. Começa pela função que não muda nada, e cada volta do laço faz uma função nova que faz tudo até ali e depois mais um passo. Nada é aplicado a título nenhum aqui."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        Function<String, String> clean = fold(STEPS);\n        for (String raw : List.of(\"  Cem Anos de   Solidão \", \"MIDDLEMARCH\", \"Ensaio sobre a cegueira\")) {\n            System.out.println(\"[\" + raw + \"] -> [\" + clean.apply(raw) + \"]\");\n        }\n        System.out.println(fold(List.of()).apply(\"no steps at all\"));\n    }\n}\n",
      "note": "Uma função, aplicada a três títulos. Com uma lista vazia a dobra devolve o próprio `identity()`, então um pipeline sem passos deixa a entrada passar em vez de falhar."
    }
  ],
  "output": "[  Cem Anos de   Solidão ] -> [cem anos de solidao]\n[MIDDLEMARCH] -> [middlemarch]\n[Ensaio sobre a cegueira] -> [ensaio sobre a cegueira]\nno steps at all"
}
```

Todo título saiu na mesma forma: sem espaços nas pontas, espaços simples por dentro, caixa baixa,
sem acentos, então `Solidão` e `solidao` agora combinam. O pipeline vazio imprimiu a entrada sem
mudança, e é por isso que a dobra começa por `identity()` e não pelo primeiro passo: **uma lista de
zero passos é um pipeline legítimo**, e o código não precisa de caso especial para ela.

## Por que dobrar em vez de chamar os passos num laço

Um laço que aplicasse cada passo a uma string daria as mesmas respostas para esses três títulos. A
dobra dá algo que o laço não dá: **o pipeline como valor**. `clean` pode ser montado uma vez na
inicialização a partir da configuração, guardado num campo, entregue a um método que só sabe que tem
uma `Function<String, String>`, e testado sozinho com uma lista de entradas e saídas esperadas.
Quando precisar de um quinto passo, tirar hífens por exemplo, é mais uma linha em `STEPS`, e o código
que usa `clean` não muda.

O `reduce` da aula 7 é esta mesma dobra escrita para qualquer stream: um valor inicial, e um jeito de
combinar o que você tem com o próximo elemento. Aqui os elementos são funções e combinar é `andThen`.
