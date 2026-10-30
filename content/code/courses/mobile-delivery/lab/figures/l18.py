"""Lesson 18: conversion.ts."""
P = [
    ("// conversion.ts: two variants of the store page, and whether the difference between them is larger than chance\nconst [visitsA, installsA, visitsB, installsB] = process.argv.slice(2, 6).map(Number);\nconst a = installsA / visitsA;\nconst b = installsB / visitsB;",
     "Visitors and installs for each variant, from the command line, and each variant's conversion rate.",
     "Visitantes e instalações de cada variante, pela linha de comando, e a taxa de conversão de cada uma."),
    ("const se = Math.sqrt((a * (1 - a)) / visitsA + (b * (1 - b)) / visitsB);\nconst low = b - a - 1.96 * se;\nconst high = b - a + 1.96 * se;",
     "The standard error of a difference between two proportions, and 1.96 of them either side: the usual 95% interval.",
     "O erro-padrão de uma diferença entre duas proporções, e 1,96 deles para cada lado: o intervalo de 95% de costume."),
    ("const pts = (x: number) => `${(100 * x).toFixed(1)}`;\nconsole.log(`A ${pts(a)}%  B ${pts(b)}%  difference ${pts(b - a)} points, 95% interval ${pts(low)} to ${pts(high)}`);\nconsole.log(low > 0 ? \"B converts better\" : high < 0 ? \"A converts better\" : \"not enough evidence either way\");",
     "The verdict follows the interval: entirely above 0, entirely below, or straddling it.",
     "O veredito segue o intervalo: todo acima de 0, todo abaixo, ou cruzando o zero."),
]
EXAMPLES = {"install-conversion": [{"language": "typescript", "file": "conversion.ts", "parts": P}]}
