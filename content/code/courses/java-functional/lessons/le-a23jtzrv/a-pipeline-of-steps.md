---
title: A pipeline of steps
version: 1
---

**A list of functions can be folded into one function**, starting from `Function.identity()` and
joining each step with `andThen`. The result is a pipeline you can name, pass and test, and adding
a step to it is adding an element to the list.

A bookshop receives titles typed by hand, by suppliers and by customers, and wants one clean form of
each before it searches its catalogue:

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
      "note": "Four steps, each small enough to read at a glance: trim the ends, squeeze runs of spaces, lower the case, remove accents. The last one splits each accented letter into the letter and its mark, then deletes the marks."
    },
    {
      "code": "\n    static Function<String, String> fold(List<Function<String, String>> steps) {\n        Function<String, String> all = Function.identity();\n        for (Function<String, String> step : steps) {\n            all = all.andThen(step);\n        }\n        return all;\n    }",
      "note": "The fold. It starts from the function that changes nothing, and each turn of the loop makes a new function that does everything so far and then one more step. Nothing is applied to any title here."
    },
    {
      "code": "\n    public static void main(String[] args) {\n        Function<String, String> clean = fold(STEPS);\n        for (String raw : List.of(\"  Cem Anos de   Solidão \", \"MIDDLEMARCH\", \"Ensaio sobre a cegueira\")) {\n            System.out.println(\"[\" + raw + \"] -> [\" + clean.apply(raw) + \"]\");\n        }\n        System.out.println(fold(List.of()).apply(\"no steps at all\"));\n    }\n}\n",
      "note": "One function, applied to three titles. With an empty list the fold returns `identity()` itself, so a pipeline with no steps passes its input through rather than failing."
    }
  ],
  "output": "[  Cem Anos de   Solidão ] -> [cem anos de solidao]\n[MIDDLEMARCH] -> [middlemarch]\n[Ensaio sobre a cegueira] -> [ensaio sobre a cegueira]\nno steps at all"
}
```

Every title came out in the same form: no spaces at the ends, single spaces inside, lower case, no
accents, so `Solidão` and `solidao` now match. The empty pipeline printed its input unchanged,
which is why the fold starts from `identity()` and not from the first step: **a list of zero steps
is a legitimate pipeline**, and the code needs no special case for it.

## Why fold instead of calling the steps in a loop

A loop that applied each step to a string would give the same answers for these three titles. The
fold gives you something the loop does not: **the pipeline as a value**. `clean` can be built once at
start-up from configuration, stored in a field, handed to a method that only knows it has a
`Function<String, String>`, and tested on its own with a list of inputs and expected outputs. When a
fifth step is needed, removing hyphens for instance, it is one more line in `STEPS`, and the code
that uses `clean` does not change.

Lesson 7's `reduce` is this same fold written for any stream: a starting value, and a way to combine
what you have with the next element. Here the elements are functions and combining is `andThen`.
