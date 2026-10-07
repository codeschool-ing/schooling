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
