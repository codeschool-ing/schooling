---
title: Escolher uma ferramenta, e o relato que cabe em todas
version: 1
---

A maioria de quem testa não escolhe ferramenta de acompanhamento. Chega a uma empresa que escolheu
uma anos atrás, e o trabalho é usá-la bem. Por isso esta seção começa pela habilidade que viaja,
pôr o relato da aula 15 na ferramenta que estiver na sua frente, e termina com as perguntas a fazer
no dia em que alguém pedir que você escolha.

## O relato, mapeado

É aqui que cada parte do relato da aula 15 costuma cair, em qualquer um dos quatro produtos desta
aula:

| relato | para onde vai na ferramenta |
|---|---|
| título | o resumo do item, ou o título do cartão |
| ambiente | um campo de ambiente onde a ferramenta tem um, como o Jira; senão, as primeiras linhas da descrição |
| pré-condições, passos, esperado, obtido | a descrição, num formato fixo com um título para cada parte |
| reprodutibilidade | a descrição, depois do resultado obtido |
| evidência | a transcrição como texto na descrição, num bloco de código; uma captura ou gravação como anexo |
| severidade | um campo personalizado que o time cria; num quadro, uma etiqueta |
| prioridade | o campo de prioridade que já vem no Jira e no YouTrack; num quadro, uma etiqueta ou a posição do cartão |
| versão em que foi achado | um campo de *versão afetada*, ou uma etiqueta |
| ligações | duplicados, o requisito, a mudança que causou uma regressão: as ligações da ferramenta, ou a descrição |

**Quatro dos nove campos da aula 15 vão para um único campo de texto livre**, a descrição, e é ali
que a maioria dos relatos em qualquer ferramenta dá errado. A ferramenta confere que existe um
resumo; não consegue conferir que a descrição tem passos que um estranho consegue repetir. Por isso
**o time combina um modelo de descrição**, os mesmos títulos na mesma ordem em todo defeito, e
algumas ferramentas conseguem começar cada bug novo com ele. Com um modelo, o leitor da seção 02 da
aula 15 acha os passos no mesmo lugar em todo relato. Sem um, cada testador inventa um formato e todo
relato é lido do começo.

Esta é a descrição do relato do traceback da aula 15, como seria colada em qualquer um dos quatro:

```localised
Pré-condições
boxoffice 1.1, recém-iniciado (/health responde "ok boxoffice 1.1").

Passos
1. Abra http://127.0.0.1:8000/book?show=S2
2. E-mail: member@example.org
3. Espetáculo: deixe em Hamlet
4. Ingressos: two
5. Clique em Book.

Reprodução em uma linha
curl -s -o /dev/null -w '%{http_code}\n' -d 'email=member@example.org&show=S2&quantity=two' http://127.0.0.1:8000/book

Esperado
O formulário de novo, com "You can book 1 to 6 tickets." (R4, R7)

Obtido
500, e um traceback do Python que termina em:
ValueError: invalid literal for int() with base 10: 'two'

Reprodutibilidade
Sempre; também com a quantidade vazia e com 2.5.
```

## Quando é você quem escolhe

Cinco perguntas decidem a maioria das escolhas, e nenhuma é sobre qual produto tem mais
funcionalidades.

**Quem registra relatos?** Só o time, ou também clientes, funcionários da bilheteria, gente de fora
da empresa? Uma ferramenta que quem relata não alcança, ou acha difícil demais, recebe menos relatos,
e os que faltam são os que os clientes teriam mandado.

**O ciclo de vida precisa ser cobrado?** Um time de duas pessoas que sentam juntas consegue manter
as regras da aula 16 como hábito, e um quadro basta. Um time de quarenta em três produtos não
consegue, e precisa de uma ferramenta que recuse um movimento que as regras proíbem.

**O que precisa se ligar a ela?** O repositório de código, para uma correção se ligar ao item; a
ferramenta de casos de teste da aula 18, para um caso que falhou virar defeito com um clique; a wiki
onde moram os requisitos. Uma ferramenta a que nada se liga vira um segundo lugar para digitar a
mesma coisa.

**Ela responde às perguntas da aula 16?** Idade dos defeitos abertos por severidade, taxa de
reabertura, defeitos que escaparam: se a ferramenta não consegue buscá-los, ninguém vai contá-los à
mão por muito tempo.

**Dá para sair?** Toda ferramenta é trocada um dia. Uma ferramenta cujos itens, histórico e anexos
podem ser exportados num formato legível pode ser deixada; uma que não pode mantém o histórico do
time como refém.

Duas perguntas ficaram de fora de propósito. **Preço** importa e muda depressa demais para um curso
citar: as páginas dos próprios fornecedores são a única resposta atual, e cada um oferece um período
de teste. **Popularidade** é um desempate razoável, porque uma ferramenta muito usada facilita
contratar, e um motivo fraco sozinho, porque a ferramenta que toda empresa usa está configurada de um
jeito diferente em cada empresa.

Para o boxoffice, um teatro com um desenvolvedor e uma testadora, um quadro com uma lista por estado e
uma etiqueta por severidade carregaria tudo o que este curso relatou até aqui. No dia em que o teatro
contratar um segundo desenvolvedor e vender os ingressos de uma segunda sala, as cinco perguntas
valem ser feitas de novo.
