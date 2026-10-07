---
title: Dado sensível, e por que a ferramenta para em vez de adivinhar
version: 2
---

O art. 5, II da LGPD nomeia uma lista curta de dados pessoais que são **sensíveis**: origem racial ou
étnica, convicção religiosa, opinião política, filiação a sindicato ou a organização de caráter
religioso, filosófico ou político, e dados referentes à saúde, à vida sexual, genéticos ou
biométricos. Estão na lista porque o mau uso deles causa um tipo particular de dano, como ter negado
um emprego, um seguro ou um empréstimo.

A consequência que importa para uma chamada de modelo está no art. 11, que define as bases para tratar
dado sensível, e **a lista é menor que a do art. 7**. O legítimo interesse, a base flexível que cobre
boa parte do tratamento comum, não está nela. O consentimento específico para a finalidade está, e
também um punhado de situações que o artigo nomeia. Se alguma delas serve para um resumo de suporte é
uma pergunta para o encarregado da Tarefa. A resposta barata é perguntar antes se o resumo precisa da
informação.

## O que o resumo precisa saber

A Juliana escreveu que ficou internada com uma infecção nos rins. O que o atendente precisa saber é
que ela deu um motivo de saúde para o atraso e se oferece para entregar na sexta, porque é isso que
decide entre reembolso e prorrogação. **Qual doença ela teve não decide nada nesta disputa**, então
enviá-la a um fornecedor seria tratar dado sensível sem finalidade, que é exatamente o que o princípio
da necessidade proíbe.

Por isso o `guard minimise` recusa por padrão. Ele para com status 3 e não grava nada, e a mensagem
nomeia os dois caminhos: remover a frase, ou registrar a base legal do art. 11 e mudar a finalidade
para que ela diga por que o dado de saúde é necessário. Um padrão que enviasse a mensagem e
registrasse um aviso seria um padrão em que ninguém nunca decide.

Com `--sensitive remove`, a frase é substituída e o resto da mensagem sobrevive:

```
   "text": "[removed: a health matter] I can deliver by Friday."
```

O marcador é de propósito. Apagar a frase sem rastro deixaria o modelo lendo uma freelancer atrasada
que não dá motivo nenhum, e o resumo seria injusto com ela. O marcador diz ao modelo que houve um
motivo, e o resumo que o `llama3.2:3b` escreveu na seção anterior diz que ela *"initially mentioned a
health issue that may have caused a delay"*, que é tudo de que o atendente precisa, e nada sobre qual.

## A lista de palavras vê palavras

A verificação por trás da retenção é uma lista de palavras por categoria, no `minimise.py`, e ela é
exatamente tão boa quanto a lista. O `guard sensitive` mostra o que ela vê num texto. Salve-o como
`~/guard/tools/sensitive.py`:

```python
# sensitive.py: what the sensitive-data word list of minimise.py sees in a text.
#
#   guard sensitive TEXT
import sys

from minimise import sensitive_terms

found = sensitive_terms(sys.argv[1])
if not found:
    print("nothing found")
for cat, words in found.items():
    print("%s: %s" % (cat, ", ".join(words)))
```

```
ana@lab:~/guard$ guard sensitive 'I was in hospital for a week with a kidney infection'
health: hospital, infection
ana@lab:~/guard$ guard sensitive 'I spent a week in bed with a fever and the doctor said rest'
nothing found
ana@lab:~/guard$ guard sensitive 'My son has autism and I can only work at night'
nothing found
```

A segunda mensagem fala de doença e não tem nenhuma palavra da lista. A terceira fala da saúde de uma
criança, que é dado sensível de um terceiro, e a lista nunca ouviu falar de autismo. As duas iriam ao
fornecedor sem mudança.

Uma lista maior move a linha sem removê-la. Um classificador a move mais, seja um modelo ou um
endpoint de moderação como os da aula 6, e a taxa de erro dele é uma que você teria de medir nos seus
próprios tickets. Então a lista é uma rede com buracos, e **as decisões de projeto ficam onde a
segurança está**:

- **Não pergunte.** Um formulário que oferece *"motivo do atraso"* como texto livre vai coletar
  diagnósticos. Um que oferece a escolha entre *saúde*, *família*, *técnico* e *outro* coleta
  categorias.
- **Tire as superfícies de alto risco do caminho do modelo.** Se disputas sobre saúde são comuns, o
  recurso de resumo pode pular esses tickets, e uma pessoa os lê.
- **Diga no aviso de privacidade.** Clientes e freelancers devem saber que as mensagens deles podem
  ser resumidas por um modelo de terceiros, o que os direitos da próxima seção exigem de todo modo.
