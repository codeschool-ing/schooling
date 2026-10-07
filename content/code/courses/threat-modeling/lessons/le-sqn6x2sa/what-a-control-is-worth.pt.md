---
title: Quanto vale um controle
version: 1
---

A aula 8 escreveu dezenove requisitos, e todos são boas ideias. Uma empresa pequena não consegue
construir dezenove boas ideias neste trimestre, então a pergunta muda de *isto vale a pena?* para
*o que primeiro?* A aritmética que responde usa os números da aula 9 e um número novo, **o custo do
controle.**

### O valor de um controle

Um controle vale **a perda esperada que ele remove**: o risco antes, menos o risco depois.

> valor por ano = perda esperada antes − perda esperada depois

Para o C1, segundo fator para a equipe, julgado só sobre a T03:

> antes: 0,3 por ano × R$ 250.000 = R$ 75.000
> depois: remove 80% da frequência, então 0,06 por ano × R$ 250.000 = R$ 15.000
> valor: R$ 60.000 por ano

Os 80% são uma estimativa como qualquer outra: o julgamento da equipe sobre quantas das tentativas
de phishing que funcionam hoje continuariam funcionando com segundo fator. Ela fica no
`controls.csv` ao lado do controle, onde alguém pode discutir com ela.

### O custo de um controle

**Tudo o que ele custa, por ano**, para ser posto contra uma perda anual:

| | exemplo para o C1 |
|---|---|
| licenças e hardware | licenças de aplicativo autenticador, duas chaves de reserva por clínica |
| construir | dois dias para ligar o segundo fator ao login do console |
| operar | redefinir fatores perdidos, talvez um por mês |
| atrito | quarenta pessoas gastando alguns segundos a mais em cada login |

Um custo único é distribuído pelos anos que o controle vai durar: dois dias de trabalho, uns R$
4.000, divididos por três anos, dão uns R$ 1.400 por ano, que é como o C3, a verificação de
assinatura do webhook, ganha o seu número. **Atrito é a linha que as pessoas esquecem**, e é a que
decide se um controle sobrevive: um segundo fator que leva um minuto toda vez é desligado por alguém
com pressa, e aí não custa nada e não protege nada.

### Retorno sobre investimento em segurança

A razão entre os dois às vezes se chama **retorno sobre investimento em segurança (ROSI)**, em geral
escrito como (valor − custo) ÷ custo. Esta aula usa o mais simples **economia ÷ custo**: um controle
que economiza R$ 20 para cada real gasto é claramente melhor negócio que um que economiza R$ 2, e as
duas formas põem os controles na mesma ordem. Qualquer razão acima de 1 significa que o controle
economiza mais do que custa, na média; abaixo de 1 não economiza, e a decisão precisa ser tomada por
outros motivos, que são o assunto da seção sobre além do dinheiro.
