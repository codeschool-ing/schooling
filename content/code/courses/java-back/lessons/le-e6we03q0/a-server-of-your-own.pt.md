---
title: Um servidor de banco de dados, e onde ele roda
version: 1
---

Até agora a livraria guardava os livros num `Map`, e cada reinício trazia de volta os mesmos três.
Um catálogo de verdade precisa sobreviver ao processo que o serve, então a partir desta aula os
livros moram no **PostgreSQL**, um servidor de banco de dados: um programa separado, escutando numa
porta, ao qual a aplicação se conecta como cliente. É o mesmo formato da livraria com o `curl` na
aula 6, uma camada abaixo. Desta vez quem é cliente é a livraria.

Isso tem uma consequência antes de qualquer código. **A aplicação não contém o banco de dados.** O
driver no `pom.xml` da livraria sabe conversar com o PostgreSQL; ele não é o PostgreSQL. Um servidor
precisa estar rodando em algum lugar que a livraria alcance, e é isso que se prepara primeiro.

O curso usa o **PostgreSQL 16**, e todas as transcrições foram gravadas com ele. Ele é gratuito,
roda em qualquer sistema que você provavelmente tenha, e é o banco contra o qual foi escrita a maior
parte dos projetos Spring que você vai ler. Há três lugares para rodá-lo.

## Na mesma máquina virtual — o caminho recomendado

A aula 1 recomendou uma máquina virtual com Ubuntu Server 24.04 para o JDK e o Maven. Instale o
PostgreSQL **nessa mesma máquina**, pelos pacotes do próprio Ubuntu, e a livraria o alcança em
`localhost`, que é exatamente o que a configuração dela vai dizer. A sua tela então bate com as
transcrições em tudo, menos nos tempos e no nome do prompt.

**O que custa:** uns 170 MB de disco para os pacotes, a maior parte uma biblioteca de compilação que o
PostgreSQL usa para acelerar consultas grandes, mais os dados, que neste curso ficam na casa das
dezenas de megabytes. O servidor ocupa pouca memória enquanto está ocioso, então os 4 GB que a máquina
recebeu na aula 1 continuam bastando.

Se você já fez o `sql-databases` nesta máquina, o PostgreSQL 16 está instalado; pule para a parte da
próxima seção que cria o papel e o banco da livraria. Aquele curso vem depois deste na trilha
`backend`, e a primeira aula dele vai encontrar o servidor que você instala aqui.

## Instalado direto no seu computador

Se o seu computador **roda Ubuntu ou Debian** e você pulou a máquina virtual na aula 1, os comandos
da próxima seção funcionam nele como estão impressos.

No macOS, o Postgres.app (postgresapp.com) e o Homebrew (`brew install postgresql@16`) o instalam; no
Windows, o instalador indicado em postgresql.org. Cada um cria o primeiro usuário do seu jeito, então
os comandos `sudo -u postgres` abaixo não vão bater com o que você vê. O que importa é o estado final:
um servidor em `localhost:5432`, um papel `bookshop` com a senha `bookshop`, e um banco `bookshop`
que pertence a ele. Com isso, o Java desta aula roda sem mudança nenhuma.

## Online, no servidor de outra pessoa

Serviços de PostgreSQL hospedado dão a você um banco e um endereço, e alguns têm um plano gratuito;
Neon e Supabase são dois, no momento em que este texto foi escrito. **Não custa nada ao seu
computador**, e custa uma conta e uma conexão de rede a cada execução. A configuração da livraria
passa então a nomear o host, o usuário e a senha deles no lugar de `localhost`, e um serviço hospedado
pede uma conexão criptografada, que a própria página dele escreve como uma URL para colar. Nenhuma
aula depende de provedor algum.

Use esse caminho se os outros dois estiverem fora de alcance hoje. O preço é justamente o que a
máquina virtual foi escolhida para evitar: **quando a sua tela e uma transcrição discordam, a
diferença pode ser o serviço**, e não o que você digitou.

Contêineres são o quarto caminho, e o curso chega lá: a aula 19 instala o Docker para que os testes
possam subir um PostgreSQL descartável, e a aula 23 roda a livraria e o banco dela lado a lado em
contêineres. Até lá, o servidor é um pacote na sua máquina.
