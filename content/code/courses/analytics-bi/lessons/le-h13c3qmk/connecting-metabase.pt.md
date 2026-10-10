---
title: A primeira visita, e conectando a camada
version: 1
---

Abra `http://localhost:3000` no seu navegador (no UTM, o endereço da máquina no lugar de
`localhost`). O Metabase recebe uma instalação nova com uma configuração de quatro passos curtos, e
tudo nela pode ser mudado depois nas configurações de admin. As telas abaixo estão em inglês, como
o Metabase abre; um seletor no canto da tela muda o idioma.

1. **Let's get started**, depois **What should we call you?** O seu nome, um e-mail e uma senha.
   Esse é o primeiro administrador deste Metabase, e o e-mail é só um login: nada é enviado para
   ele.
2. **What will you use Metabase for?** *Self-service analytics for my own company*. A resposta só
   decide que dicas o Metabase mostra depois.
3. **Add your data.** Escolha **PostgreSQL** e preencha o formulário:

   | campo | valor |
   |---|---|
   | Display name | `Lantern` |
   | Host | `localhost` |
   | Port | `5432` |
   | Database name | `lantern` |
   | Username | `metabase` |
   | Password | a que você deu ao papel |
   | Schemas | *Only these...*, depois `semantic` |

   A última linha é a que mais importa. Com *All*, o Metabase ofereceria todo schema que o papel
   enxerga; só com `semantic`, quem o usa encontra a camada e mais nada, mesmo que alguém depois dê
   ao papel mais do que deveria. Depois, **Connect database**.
4. **Usage data preferences.** Uma caixa, marcada por padrão, deixa o Metabase coletar eventos
   anônimos de uso sobre como o produto é usado. Desmarque se preferir; ela nunca inclui os seus
   dados. Depois **Finish**, e **Take me to Metabase**.

O Metabase agora **sincroniza** o banco: lê a lista de tabelas e colunas, e os comentários delas,
para os próprios registros. Isso é rápido para seis objetos, e se repete num horário, o que vale
saber para o dia em que você acrescentar uma coluna e o Metabase ainda não a mostrar.

O Metabase também instala um **Sample Database** próprio, uma pequena loja chamada *Sample
Database*, para quem não tem dados para experimentar. Ele não faz mal. Pode ser removido nas
configurações de admin, em *Databases*, para ninguém montar um gráfico nele por engano.
