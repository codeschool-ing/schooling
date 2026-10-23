---
title: Uma regra que roda, não uma página que se lê
version: 1
---

A maioria das organizações já tem políticas de segurança. Elas moram numa página de wiki com um
título como "Padrões para contêineres" e dizem coisas sensatas: as imagens vêm do registry interno,
nada roda como root, todo contêiner tem limite de memória. A página é lida uma vez, por um
desenvolvedor novo na primeira semana, e aplicada na revisão de código por quem por acaso se lembrar
dela. **Uma regra que depende de alguém lembrar dela vale nos dias em que alguém lembra.** Nada avisa
quando a página e os repositórios deixaram de concordar, e numa plataforma com cem serviços eles
deixaram de concordar faz tempo.

Política como código tira a regra da página e a põe no repositório, numa linguagem que uma máquina
avalia. Quatro coisas mudam, e cada uma é algo em que este curso já se apoiou em algum lugar:

| uma regra numa página | uma regra como código |
|---|---|
| editada por quem tem acesso à wiki, sem revisão | mudada num commit, revisada como qualquer linha de código |
| aplicada pela memória | avaliada a cada push, pelo pipeline |
| ninguém sabe se ainda bate com o que devia pegar | tem testes próprios, que falham quando ela para de recusar o que deveria |
| vale quando alguém confere | recusa num ponto em que recusar custa pouco: antes do merge, antes do deploy |

Você já escreveu política como código duas vezes. O portão da aula 7 é uma: uma regra sobre quais
achados quebram o build, num arquivo com testes. A política de admissão da aula 10 é outra: duas
regras em CEL que o cluster aplica a todo Deployment. Esta aula acrescenta um motor genérico, para o
mesmo tipo de regra poder ser escrito sobre qualquer arquivo que descreva como algo é construído ou
executado.

### OPA, Rego e conftest

**Open Policy Agent (OPA)** é um motor que recebe duas coisas, um documento em JSON e um conjunto de
regras, e responde com uma decisão. Ele não sabe nada de Kubernetes nem de Dockerfiles; avalia regras
sobre qualquer JSON que receber. Essa generalidade é o motivo de ele aparecer em vários lugares: como
**Gatekeeper**, um controlador de admissão para Kubernetes; dentro de serviços que perguntam a ele se
uma requisição é permitida; e no CI, por meio do conftest.

**Rego** é a linguagem em que as regras são escritas. Ela é declarativa: uma regra diz o que precisa
ser verdade para uma conclusão valer, e o motor descobre se vale. A próxima seção lê uma regra de
cada vez.

**Conftest** é uma ferramenta de linha de comando construída sobre o OPA para checar arquivos de
configuração. Ela converte um arquivo em JSON (YAML, Dockerfile, HCL, TOML, INI e mais uns vinte
formatos), avalia cada regra de um diretório de políticas contra ele, imprime o que falhou e sai com
1 se algo falhou. Esse status de saída é tudo de que um estágio do pipeline precisa.

Os arquivos que esta aula checa são os do linkbox que dizem como ele é construído e como roda: o
`Dockerfile` e os manifestos em `k8s/`. Eles são a infraestrutura do projeto, por escrito, e
checá-los antes de qualquer coisa ser construída ou aplicada é o que "verificação de infraestrutura"
quer dizer aqui. A mesma abordagem cobre Terraform, valores de Helm ou um workflow de CI, com um
conversor para cada um.

### Instalando o conftest

O conftest é um binário só, publicado no GitHub com um arquivo de checksums ao lado. No Linux, a
partir do seu diretório home:

```
ana@vm:~$ curl -fsSLO https://github.com/open-policy-agent/conftest/releases/download/v0.71.0/conftest_0.71.0_Linux_x86_64.tar.gz
ana@vm:~$ curl -fsSL https://github.com/open-policy-agent/conftest/releases/download/v0.71.0/checksums.txt | grep ' conftest_0.71.0_Linux_x86_64.tar.gz$' | sha256sum --check
conftest_0.71.0_Linux_x86_64.tar.gz: OK
ana@vm:~$ tar -xzf conftest_0.71.0_Linux_x86_64.tar.gz conftest
ana@vm:~$ install -m 755 conftest ~/.local/bin/
ana@vm:~$ rm conftest conftest_0.71.0_Linux_x86_64.tar.gz
ana@vm:~$ conftest --version
Conftest: 0.71.0
OPA: 1.21.0
```

A mesma página de releases tem builds para macOS e Windows, e o Homebrew o instala com
`brew install conftest`. A versão importa por um motivo: o conftest 0.71 roda o OPA 1.21 e lê **Rego
v1**, a sintaxe que todas as regras desta aula usam. Guias mais antigos na web escrevem regras como
`deny[msg] { ... }`, que é Rego v0, e um conftest atual as recusa a menos que alguém diga o contrário.
Se um exemplo que você achou não for aceito pelo parser, essa é a primeira coisa a conferir.

### O que torna uma regra boa de escrever

Nem toda linha de uma página de padrões deve virar código. Uma regra merece o lugar quando três
coisas são verdade:

- **Um arquivo consegue mostrá-la.** "As imagens vêm do registry interno" aparece num manifesto. "O
  código é revisado por alguém que o entende" não aparece, e nenhum conversor vai fazê-lo aparecer.
- **A resposta é sim ou não.** "Um limite de memória está declarado" é uma checagem. "O limite de
  memória é sensato" precisa de uma pessoa, ou de um número que ninguém consegue defender.
- **Alguém sai prejudicado quando ela é quebrada.** Uma regra que recusa tabs em YAML desperdiça o
  tempo de todo mundo e ensina as pessoas a ignorar o estágio, a fadiga de alertas que a aula 7
  descreveu.

Todas as regras desta aula passam nesse teste, e cada uma corresponde a uma decisão que uma aula
anterior tomou e defendeu: digests na aula 15, o usuário sem privilégio nas aulas 8 e 9, o contexto
de segurança e os limites na aula 10. **Política como código não inventa a política.** Ela faz as
decisões já tomadas continuarem tomadas.
