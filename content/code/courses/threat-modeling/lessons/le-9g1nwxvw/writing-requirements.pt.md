---
title: Escrevendo um requisito que alguém consiga conferir
version: 1
---

"O portal precisa ser seguro" é uma frase com que ninguém discorda e que ninguém consegue testar.
É também o requisito de segurança mais comum do mundo. **Um bom requisito de segurança é um que
alguém que não estava na sala consegue verificar**, e quatro propriedades tornam isso possível.

| propriedade | a pergunta | falha assim |
|---|---|---|
| **específico** | diz qual parte do sistema e qual comportamento? | "o acesso precisa ser controlado" |
| **testável** | alguém consegue escrever um teste, ou um passo de revisão, que passa ou falha? | "as senhas precisam ser fortes" |
| **uma coisa só** | diz uma coisa só, para que não se faça metade e se marque o todo? | "uploads precisam ser validados, examinados e limitados" |
| **comportamento, não esperança** | diz o que o sistema faz, e não o que ninguém vai fazer? | "atacantes não podem conseguir ler exames" |

A última merece um segundo olhar. "Atacantes não podem conseguir ler exames" parece um requisito e é
uma esperança: descreve algo que o sistema não controla. A versão que funciona descreve o que o
portal faz: *devolve um exame só ao paciente a quem ele pertence.* Um teste consegue pedir o exame de
outra pessoa e conferir a resposta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l08-hope\" aria-label=\"Três requisitos como foram escritos e como foram reescritos. Atacantes não podem conseguir ler exames, uma esperança, vira: o portal devolve um exame só ao paciente dele. Uploads precisam ter tamanho limitado, sem número, vira: upload acima de 20 MB ou que não seja PDF é recusado. Senhas precisam ser fortes, não testável, vira: o cadastro recusa senhas achadas em listas vazadas.\"><defs><marker id=\"l08-hope-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"20.0\" width=\"300.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">“atacantes não podem conseguir ler exames”</text><text x=\"170.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">uma esperança</text><path d=\"M320.0 44.0 L370.0 44.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-hope-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"20.0\" width=\"330.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o portal devolve um exame só ao paciente dele</text><rect x=\"20.0\" y=\"85.0\" width=\"300.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">“uploads precisam ter tamanho limitado”</text><text x=\"170.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">sem número</text><path d=\"M320.0 109.0 L370.0 109.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-hope-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"85.0\" width=\"330.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"109.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">upload acima de 20 MB ou não PDF é recusado</text><rect x=\"20.0\" y=\"150.0\" width=\"300.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"170.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">“senhas precisam ser fortes”</text><text x=\"170.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--amber)\">não testável</text><path d=\"M320.0 174.0 L370.0 174.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l08-hope-tm-ah-paper-dim)\"></path><rect x=\"370.0\" y=\"150.0\" width=\"330.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"535.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o cadastro recusa senhas de listas vazadas</text></svg>", "caption": "A reescrita nomeia uma parte, um comportamento e, quando há, um número. Alguém que não estava na sala consegue conferir."}
```

### Números são decisões, escreva-os

"Uploads precisam ter tamanho limitado" não é testável até alguém escrever o número. Os **20 MB** do
R13 foram uma decisão: o maior exame que um paciente enviou em um ano tinha menos de 9 MB, e 20
deixavam folga. Escrever transforma uma discussão num valor que pode ser mudado depois, com um
motivo. O mesmo vale para as dez tentativas falhas por hora do R03 e os trinta dias do R06.

### Usando um padrão como catálogo

Ninguém precisa inventar requisitos de segurança do nada. O **OWASP Application Security
Verification Standard (ASVS)** é um catálogo de centenas deles, agrupados por área (autenticação,
gerência de sessão, controle de acesso, validação, registro e outras) e graduados em três níveis de
rigor. A versão 5.0, publicada em 2025, é a atual.

O ASVS é o lugar certo para procurar **como** enunciar um requisito e requisitos que a equipe
esqueceu. É o lugar errado para começar: adotar um nível inteiro dá uma lista que ninguém consegue
ligar de volta a uma ameaça, e o modelo perde o motivo de cada requisito existir. O hábito da Vereda
é o contrário: escrever o requisito a partir da ameaça, depois procurar a área do ASVS a que ele
pertence e emprestar a redação se ela for mais clara. O curso `secure-code` (aula 20) usa o ASVS
pelo lado de quem programa, como checklist durante a construção.

### Verificado pelo quê

Todo requisito diz como será conferido, e há três respostas honestas:

- **um teste**, automatizado, rodado a cada mudança: R01, R10, R13;
- **uma revisão**, uma pessoa conferindo uma configuração ou um projeto: R07, R15, R16, que são
  sobre permissões de nuvem e redes que nenhum teste unitário enxerga;
- **nada ainda**, o que é permitido desde que esteja anotado. É uma lacuna conhecida, e o programa
  de rastreabilidade acha cada uma delas.
