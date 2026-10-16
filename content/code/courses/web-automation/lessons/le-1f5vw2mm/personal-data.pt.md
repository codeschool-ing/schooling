---
title: Dado de teste nunca é dado real de alguém
version: 1
---

**Os dados de uma suíte de testes são gerados, nunca copiados da produção.** A tentação é fazer o
contrário. A produção tem nomes realistas, endereços com acentos e apóstrofos, pedidos com
históricos estranhos, tudo o que falta a um cliente gerado. O pedido de costume é *uma cópia do
banco de ontem para o ambiente de teste*, e quem testa e faz esse pedido tem boa intenção. Mesmo
assim é o pedido errado, por três motivos que não dependem do cuidado de ninguém.

## Por que uma cópia é um vazamento esperando a vez

**Dado de teste viaja.** Tudo o que este curso produziu até aqui mostra para onde. Um teste do
Playwright que falha deixa um contexto de erro em `test-results/`, a página como estava; a aula 16
acrescenta capturas de tela, vídeos e rastros, que registram cada requisição e cada campo digitado.
Um servidor de build guarda isso como artefatos, ligados a uma execução que a equipe inteira pode
abrir, e um relato de defeito os cita. O nome de um cliente real num teste é o nome de um cliente
real em cada um desses lugares, guardado pelo tempo que alguém guardar.

**Ambientes de teste são menos protegidos que a produção**, de propósito: mais gente lê, logins são
compartilhados, e ninguém acorda ninguém de madrugada quando um fica exposto. As proteções em volta
dos dados de produção param na cópia.

**E a lei não faz distinção.** No Brasil, a LGPD, a Lei Geral de Proteção de Dados (Lei
13.709/2018), rege qualquer tratamento de dados pessoais, e copiar um banco é tratamento. Testar uma
aplicação não está entre as finalidades com que os clientes concordaram ao entregar seus dados, e
as obrigações que vêm com os dados, limitá-los ao necessário, mantê-los seguros, apagá-los a
pedido, acompanham os dados até o ambiente de teste. O GDPR europeu diz o mesmo, e assim fazem as
leis da maioria dos países que têm uma. Se uma cópia específica poderia ser lícita é pergunta para
quem responde por proteção de dados na sua empresa, e a resposta padrão de quem testa é não fazê-la.

Quando a equipe precisa mesmo de dados com a forma da produção, a resposta é a **anonimização**:
trocar o que identifica uma pessoa, de um jeito que não se desfaz, antes de os dados saírem da
produção. Fazer isso direito é mais difícil que trocar a coluna do nome, porque uma data de
nascimento, um CEP e um cargo juntos muitas vezes identificam uma pessoa só. Esse é o assunto da
aula 20 de `manual-testing`, e não se repete aqui.

## Como são dados gerados

Tudo o que esta aula criou foi gerado: `maria-` e uma cauda aleatória, `joao-` e uma cauda
aleatória. Isso basta para a maior parte dos testes automatizados, e quando um teste precisa de
mais realismo, gere isso também:

- **nomes com os caracteres difíceis**: `Conceição`, `D'Ávila`, `Nguyễn`, um nome de uma letra e um
  de oitenta. Um formulário que quebra num apóstrofo quebra para clientes reais, e uma lista gerada
  pode trazer cada caso difícil de propósito, onde uma cópia os traz por acaso;
- **endereços de e-mail em domínios reservados para exemplos**: `example.com`, `example.org` e
  `example.net` são reservados pelos órgãos de padrões da internet e não entregam para ninguém. Um
  teste que manda um e-mail de boas-vindas para `maria-3f1c7a02@example.com` não chega à caixa de
  um desconhecido; um que usa um endereço plausível num provedor real pode chegar;
- **documentos claramente falsos.** O CPF tem dígitos verificadores, então o formulário o valida, e
  um gerador que produz CPFs válidos pode produzir o número real de alguém. Prefira os valores que a
  equipe de desenvolvimento publica para testes, ou uma validação desligada no ambiente de teste;
  nunca um número que veio de uma pessoa.

Existem bibliotecas que geram nomes, endereços e empresas realistas em muitas línguas; a Faker, na
versão JavaScript `@faker-js/faker`, é a comum. Ela não foi instalada para este curso, porque um
prefixo e um UUID fizeram tudo o que estes testes precisavam, e cada dependência é mais uma coisa
para manter atualizada. Se um teste precisa de dados realistas e variados, é uma escolha razoável;
fixe a semente com `faker.seed()` para que uma execução que falhou possa ser reproduzida com os
mesmos dados.

## A regra de quem testa

Quando você encontrar dados pessoais reais num ambiente de teste, ou num fixture que alguém
versionou, o passo certo é o mesmo de um defeito: avisar quem é dono do ambiente, e não copiar
os dados adiante, nem no relato. Uma frase como *a tabela de usuários do staging tem o que parecem
nomes e CPFs de clientes reais* basta, e colar um deles como prova faz mais uma cópia.
