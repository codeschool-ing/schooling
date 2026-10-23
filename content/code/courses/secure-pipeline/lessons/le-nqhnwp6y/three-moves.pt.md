---
title: Três movimentos, e quando cada um é o certo
version: 1
---

A aula 5 tratou uma dependência como uma lista de avisos: um scanner aponta um pacote e uma versão,
e a correção é a versão que o aviso diz estar corrigida. Isso resolve o achado à sua frente. Não
responde à pergunta que decide a maior parte do risco de um serviço ao longo de um ano: **o que
fazemos com esta dependência daqui em diante?** Há três movimentos, e cada um é o certo numa
situação diferente.

| movimento | o que é | certo quando |
|---|---|---|
| **atualizar** | pegar uma versão mais nova, de propósito, com o changelog lido e os testes rodados | o projeto está saudável e a versão nova é a que os mantenedores suportam |
| **fixar** | travar a versão exata e o hash de cada arquivo, e mudar só de propósito | sempre, como base de onde todo outro movimento parte |
| **substituir** | deixar de depender dele, por outro pacote ou por código próprio | o projeto parou de corrigir o que importa para você |

**Fixar não é alternativa a atualizar; é o que faz de uma atualização uma decisão.** Um serviço
cujas dependências flutuam pega o que foi publicado ontem à noite, em produção, sem ninguém ter
lido uma palavra. Um serviço que fixa atualiza quando alguém escolhe, e as checagens do pipeline
rodam sobre a mudança. O resto da aula faz os três com o linkbox: o pin com hashes, uma atualização
do gunicorn atravessando quatro versões major, e uma substituição argumentada.

@@FIGURE moves@@

### Lendo a saúde de um pacote

Antes de escolher um movimento, olhe o pacote como projeto, e não como número de versão. Quatro
perguntas, cada uma com um lugar onde ler a resposta:

- **Ele é mantido?** O histórico de releases: quão recente, quão regular, e se majors antigos ainda
  recebem correções.
- **Quem o mantém?** Os commits recentes do repositório: uma pessoa ou várias, e se quem o escreveu
  ainda é quem faz merge.
- **O que ele puxa?** As dependências dele, que também são suas.
- **O que está aberto contra ele?** Avisos sem versão corrigida, e a resposta dos mantenedores a eles.

Quantos outros projetos dependem dele também importa, porque um pacote com muitos dependentes é
vigiado por muitos olhos e também é um prêmio maior. Serviços como deps.dev e libraries.io respondem
a essa pergunta; nenhum dos dois foi alcançável da máquina de gravação, então ela fica nomeada aqui e
não mostrada.

### Do que o linkbox realmente depende

O `requirements.txt` da aula 5 nomeia oito pacotes, e dois deles são o que o linkbox pediu. O `uv pip
tree` mostra quem puxa o quê, no ambiente virtual montado a partir desses pins:

@@FENCE 2@@

Duas árvores. O Flask traz seis pacotes, e **o gunicorn traz o `packaging`**, o pacote que a lista de
materiais da aula 13 achou na imagem embora nenhum arquivo de requisitos o nomeasse. Ele chegou lá
porque o gunicorn 22 o declara como dependência, e a lista plana de pins da aula 5 não tinha como
dizer isso.

### O gunicorn como projeto

O PyPI responde à primeira pergunta para qualquer pacote com um documento JSON. Os últimos doze
releases do gunicorn, pela data em que o primeiro arquivo foi enviado:

@@FENCE 3@@

Quatro versões major desde o 22 que o linkbox fixa, a mais recente em agosto, e releases menores
regulares no meio. É um projeto em movimento, o que é boa notícia para a saúde dele e um custo para
quem fica para trás: **quanto mais um pin fica para trás, maior o salto quando um aviso o forçar.** O
segundo comando lista o que cada versão exige fora dos extras opcionais. O gunicorn 22 exige o
`packaging` diretamente; o gunicorn 26 não exige nada, e só cita o `packaging` em extras que o
linkbox não instala.

Então uma atualização do gunicorn tiraria um pacote da imagem, além de levar o servidor quatro majors
adiante. É uma decisão com um changelog para ler, e uma seção mais adiante desta aula a toma. Antes,
os pins precisam virar algo contra o que uma atualização possa ser medida.
