---
title: O que nunca vai para um log, e uma linha por evento
version: 1
---

O login antigo escrevia a senha no log. Ninguém decidiu isso; alguém escreveu uma linha de depuração
com todos os campos, e ela ficou. **Um log é copiado, guardado e pesquisado por gente que não é o
paciente**, então algumas coisas nunca vão para ele, seja qual for a conveniência.

| nunca registre | porque | registre em vez disso |
|---|---|---|
| senhas, mesmo as erradas | uma senha errada muitas vezes é a certa de outro site, ou está a um erro de digitação | que a tentativa falhou, e para quem |
| ids de sessão, tokens, chaves de API | quem lê a linha consegue agir como aquela sessão ou serviço | que uma sessão começou ou terminou |
| números completos de cartão | as regras dos cartões proíbem guardá-los, e um log é armazenamento | nada; o provedor de pagamento tem o registro |
| notas clínicas, resultados de exames, diagnósticos | dado de saúde é a categoria mais protegida na LGPD | o identificador do registro, para a equipe consultar com autorização |
| os dados completos de uma pessoa quando um identificador basta | cada cópia é mais um lugar que um pedido de exclusão precisa alcançar | o identificador |

O teste `test_a_password_is_never_logged` segura a primeira linha: se alguém devolver o campo a uma
linha de log, ele falha.

### Um evento, uma linha

O quarto teste enviou um nome com uma quebra de linha. Com `%s`, o código antigo escrevia o nome como
chegava, então uma tentativa de login virava **duas linhas no log**, a segunda começando com um texto
que o remetente escolheu. Um log lido por pessoas, e por ferramentas que tratam cada linha como um
evento, pode então ser levado a mostrar um evento que nunca aconteceu. A correção é a mesma ideia da
aula 4, para mais um contexto: **codifique um valor para o lugar onde ele é escrito**. O `%r` escreve
o nome como literal do Python, com aspas e `\n`, então a quebra de linha continua visível e dentro de
uma linha só:

```
INFO portal sign-in succeeded name='lucia'
```

Log estruturado, um objeto JSON por linha com cada valor no seu campo, resolve o mesmo problema por
construção, e é o que a maioria dos serviços de log prefere. O módulo `logging` do Python consegue
produzi-lo com um formatador pequeno ou uma biblioteca; a regra por baixo não muda.
