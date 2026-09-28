---
title: "PaaS: você entrega o código, e a plataforma o roda"
version: 1
---

Com a **plataforma como serviço** não existe máquina onde entrar. Você entrega à plataforma a sua
aplicação, e ela a monta, a inicia, a reinicia quando cai e manda para ela as requisições que chegam.
O que você entrega é uma de duas coisas: o código-fonte, com um arquivo que lista os pacotes de que ele
precisa e uma linha dizendo qual comando o inicia; ou uma **imagem de contêiner**, a aplicação já
empacotada com o runtime, que é o assunto da próxima seção.

O Heroku foi um dos primeiros a vender esse formato, e o Google App Engine, o AWS Elastic Beanstalk e o
Azure App Service são outros. Eles diferem nos detalhes e compartilham a ideia: a linha subiu além do
sistema operacional e além do runtime, e **a plataforma opera tudo até a borda do seu código**.

## O que a plataforma assume

Comparada com a pilha, a plataforma agora faz as tarefas que enchiam a maior parte da lista do IaaS:

- ela escolhe o sistema operacional, instala e aplica os patches;
- ela instala o runtime que você indicou, o Python 3.11 por exemplo, e aplica as correções de segurança
  dele;
- ela roda quantas cópias da aplicação você pedir, e substitui a que morrer;
- ela põe um balanceador de carga na frente delas e dá a você um endereço, muitas vezes já com um
  certificado TLS;
- ela coleta o que a sua aplicação escreve nos logs.

Para uma equipe de três desenvolvedores com uma loja para manter, essa lista é boa parte de um trabalho
que ninguém da equipe queria. **É isso que o PaaS vende: operação como recurso do produto.**

## Do que você abre mão

A mesma lista, lida ao contrário, é o que você não controla mais.

As **versões do runtime são o cardápio da plataforma**. Se ela suporta Python 3.11 e 3.12, essas são as
suas opções; quando ela aposenta uma, anuncia uma data, e tirar a sua aplicação de lá antes disso é
trabalho seu. Você não consegue instalar um pacote de sistema qualquer nem mudar um ajuste do kernel,
porque não existe máquina sua onde fazer isso.

As plataformas também impõem **limites que um servidor não imporia**: quanto tempo uma requisição pode
levar antes de ser cortada, quanta memória uma cópia pode usar, e se um arquivo que a aplicação grava no
disco local sobrevive a um reinício. Em muitas plataformas não sobrevive. As cópias são descartadas e
substituídas à vontade, então o que foi gravado localmente vai junto, e uma loja que salva no próprio
disco as fotos de produto enviadas perde todas no próximo deploy. O lugar delas é o armazenamento de
objetos, que a aula 5 descreve.

## O que continua seu

A linha fica na aplicação, então a aplicação está do seu lado dela, **com tudo o que ela importa**. A
plataforma aplica os patches no interpretador Python; ela não corrige o framework web que o seu código
lista entre os pacotes. Uma falha conhecida nesse framework é sua para corrigir, exatamente como seria
numa máquina virtual.

A configuração também é sua: a senha do banco de dados que a aplicação lê, as configurações que mudam
entre teste e produção, que na maioria das plataformas são definidas como variáveis de ambiente pela
interface da própria plataforma. Também são seus os dados, onde quer que a aplicação os guarde, e a
questão de quem na sua equipe tem acesso à conta da plataforma, porque quem consegue publicar nela
consegue trocar a sua loja por outra coisa.

O PaaS tira o maior bloco de trabalho de rotina da pilha e deixa para você as partes específicas do seu
negócio. **Se a troca é boa depende de você precisar ou não das partes que ele levou**, e a última
seção de leitura desta aula transforma isso numa tabela.
