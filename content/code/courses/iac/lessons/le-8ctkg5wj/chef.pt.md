---
title: Chef, receitas escritas em Ruby
version: 1
---

O Chef é a única ferramenta desta aula que o laboratório não tem:

```
ana@laptop:~/shop/salt$ command -v chef-client cinc-client knife || echo "none of them"
none of them
```

Então esta seção mostra uma receita e não roda nada. **A receita abaixo é ilustrativa, não foi rodada
aqui e não tem saída ao lado**, porque qualquer saída seria inventada. Tudo o que se diz sobre como o
Chef se comporta é sobre a ferramenta em geral, não sobre uma execução que você possa ver.

## Uma receita é Ruby

As descrições do Chef são **receitas** (recipes), e uma receita é um programa Ruby. Os recursos dela
parecem declarações, mas cada um é uma chamada de método com um bloco, e é por isso que a sintaxe é tão
leve. O mesmo servidor web de antes:

```
package 'nginx'

directory '/var/www/shop' do
  mode '0755'
end

file '/var/www/shop/index.html' do
  content "<h1>shop</h1>\n"
  mode '0644'
end

template '/etc/nginx/sites-enabled/shop' do
  source 'shop.conf.erb'
  variables(port: 80)
  notifies :reload, 'service[nginx]'
end

service 'nginx' do
  action [:enable, :start]
end
```

Ponha ao lado do manifest Puppet da Ana e os recursos se alinham um a um: `package`, um diretório, um
arquivo, uma configuração com uma notificação, um serviço. O `template` renderiza um arquivo ERB, o
formato de template do próprio Ruby, com as variáveis que recebe, o papel que o Jinja fazia no Salt.
`notifies :reload, 'service[nginx]'` é o `notify` do Puppet e o `onchanges` do Salt: recarregar o nginx
se, e somente se, a configuração mudou. **As ideias são as mesmas; a diferença é a linguagem.**

Essa diferença é real nos dois sentidos. Como uma receita é Ruby, tudo o que o Ruby faz está disponível
em volta dos recursos: um laço sobre uma lista de sites, uma condição sobre a plataforma, a chamada de
uma biblioteca. A linguagem do Puppet também tem laços e condições, mas não uma linguagem de uso geral
inteira no meio da descrição. Esse poder também é o jeito clássico de levar um susto, porque o Chef lê
uma execução em **duas fases**. Primeiro avalia o Ruby de todas as receitas e coleta os recursos;
depois converge esses recursos, um a um, na ordem em que foram escritos. Ruby puro escrito entre
recursos roda na primeira fase, antes de qualquer recurso ser aplicado, então uma linha que lê um
arquivo que um recurso está para criar não encontra nada lá.

## Cookbooks, o servidor e o modo local

As receitas moram num **cookbook**, um diretório com um `metadata.rb` que dá nome e versão a ele, um
diretório `recipes/`, um `templates/` para arquivos como o `shop.conf.erb`, e `attributes/` para valores
padrão. A **run-list** de uma máquina diz quais receitas valem para ela, e em que ordem.

No arranjo de pull, o `chef-client` roda em cada máquina, busca num Chef Infra Server a run-list e os
cookbooks de que precisa, e converge. Os cookbooks chegam ao servidor a partir de uma estação de
trabalho com o `knife`, a ferramenta de linha de comando do Chef. Sem servidor, `chef-client
--local-mode` lê os cookbooks do disco da própria máquina, que é o equivalente no Chef do `puppet apply`
e do `salt-call --local`.

Você também vai ver o **Cinc**, uma compilação comunitária do código aberto do Chef distribuída com
outro nome, usada onde os binários do próprio Chef e os termos de licença deles não servem. As receitas
são as mesmas.

O Chef, a empresa, pertence à Progress Software desde 2020. Reconhecer uma receita e um cookbook, e
saber em que fase uma linha de Ruby roda, basta para ler um código Chef que já existe; escrever um fica
fora deste curso.
