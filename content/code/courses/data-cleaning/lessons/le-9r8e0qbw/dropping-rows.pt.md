---
title: Descartar linhas, e quem sai junto
version: 1
---

**Descartar toda linha com um vazio é o padrão em mais ferramentas do que deveria**, e é a escolha
certa numa única situação: os vazios são MCAR e as linhas que sobram bastam. Em qualquer outro
caso, descartar muda não só quantas linhas há, mas **quem** elas são.

Ana quer a idade média dos clientes da Quitanda Verde. Descartar os clientes sem ano de nascimento
utilizável parece inofensivo:

```
ana@lab:~/clean$ python -c "from customers import customers as c; print(len(c)); print((c['signup_channel'].value_counts(normalize=True) * 100).round(1).to_string()); kept = c.dropna(subset=['birth_year']); print(len(kept)); print((kept['signup_channel'].value_counts(normalize=True) * 100).round(1).to_string())"
2376
signup_channel
site           42.2
app            30.4
store          25.5
import-2023     1.9
1601
signup_channel
site           51.0
app            38.8
store           8.4
import-2023     1.8
```

2.376 clientes viram 1.601, e a composição muda por completo. **Os clientes das lojas eram um quarto
da base e são 8,4% do que sobrou.** A aula 3 achou o porquê: o formulário das lojas produziu os
marcadores, então os vazios se concentram ali. Qualquer afirmação sobre "os nossos clientes" feita a
partir das linhas restantes é agora, sobretudo, uma afirmação sobre clientes do site e do
aplicativo.

Se isso importa depende de novo da pergunta. Se os clientes das lojas têm a mesma idade que os
outros, a média sobrevive; se são mais velhos, ela está errada numa direção que ninguém anunciou.
**Descartar transforma uma pergunta sobre valores faltantes numa pergunta sobre as pessoas que
ficam**, e o perfil de quem fica é a checagem a fazer toda vez.

Três coisas tornam o descarte mais defensável:

- **descartar por pergunta, não por arquivo.** `dropna(subset=["birth_year"])` descarta para a
  pergunta da idade e nada mais. Descartar toda linha com qualquer vazio em qualquer coluna tiraria a
  maioria dos clientes das lojas de perguntas que nunca precisaram de ano de nascimento;
- **informar em quantas linhas a resposta se apoia**, ao lado da resposta: "idade média dos 1.601
  clientes com ano conhecido";
- **conferir a composição antes e depois**, como acima. Uma mudança de 25,5% para 8,4% é o sinal de
  parar e procurar outra estratégia.

O que descartar nunca faz é inventar alguma coisa. Esse é todo o seu atrativo, e ele é real: uma
amostra honesta menor pode ser melhor do que uma maior cheia de palpites. O resto desta aula são os
palpites, e o que eles custam.
