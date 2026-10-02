---
title: Puppet, um manifest e um catálogo
version: 1
---

O Puppet descreve uma máquina como um conjunto de **recursos**, cada um com um tipo, um título e
atributos, escritos numa linguagem própria. Não é YAML nem Ruby, embora o Puppet em si seja escrito
em Ruby. O primeiro manifest da Ana cuida de um diretório, dois arquivos e um comando que só deve rodar
quando o arquivo de configuração muda:

```
$root = '/home/ana/web'

file { $root:
  ensure => directory,
  mode   => '0755',
}

file { "${root}/index.html":
  ensure  => file,
  content => "<h1>shop</h1>\n",
  mode    => '0644',
}

file { "${root}/shop.conf":
  ensure  => file,
  content => "listen 80;\nroot ${root};\n",
  mode    => '0644',
  notify  => Exec['reload-web'],
}

exec { 'reload-web':
  command     => "/bin/sh -c 'echo reloaded >> ${root}/reloads.log'",
  refreshonly => true,
}
```

Num servidor web de verdade esses caminhos estariam em `/var/www` e `/etc/nginx`. **No laboratório eles
ficam na home da Ana**, porque ela não é root e o laptop é a única máquina que existe ali; os recursos e
o jeito como o Puppet os aplica são os mesmos. `$root` é uma variável, e `"${root}/index.html"` a coloca
dentro de uma string, o que só funciona com aspas duplas. Cada `file` diz o que precisa ser verdade
(`ensure => file`, este `content`, este `mode`), e não como chegar lá.

Os dois últimos recursos estão ligados. `notify => Exec['reload-web']` no `shop.conf` diz: quando este
recurso mudar, avise aquele. `refreshonly => true` no `exec` diz que ele só roda quando avisado. Num
servidor o comando recarregaria o nginx; aqui ele acrescenta uma linha num log, para você contar
quantas vezes rodou. A aula 18 tem a mesma ideia na forma de um handler.

Um manifest pode ser conferido sem rodar, e vale fazer isso antes que um agente o busque:

```
ana@laptop:~/shop/puppet$ puppet parser validate site.pp && echo valid
valid
```

## A primeira execução, e a segunda

```
ana@laptop:~/shop/puppet$ puppet apply site.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.03 seconds
Notice: /Stage[main]/Main/File[/home/ana/web]/ensure: created
Notice: /Stage[main]/Main/File[/home/ana/web/index.html]/ensure: defined content as '{sha256}783652ab6a6189ef05ab6994f3bdeb6fc0cdcec3150ad6df4f6c56fff8a0a993'
Notice: /Stage[main]/Main/File[/home/ana/web/shop.conf]/ensure: defined content as '{sha256}292f046193dabb234e26be4c8d5cb125558e85ac5094b1419ffed38a4d949aae'
Notice: /Stage[main]/Main/Exec[reload-web]: Triggered 'refresh' from 1 event
Notice: Applied catalog in 0.05 seconds
```

Leia de cima para baixo. O aviso é do laboratório: o Facter, a parte do Puppet que levanta fatos sobre
a máquina, não achou endereço de rede, porque uma execução do laboratório não tem rede. **`Compiled
catalog for laptop` é a linha importante.** O catálogo é o manifest resolvido para uma máquina: cada
recurso, com as variáveis preenchidas e os relacionamentos resolvidos. Com um agente, o servidor o
compila e o envia; o `puppet apply` compila na hora. Depois vem um `Notice` por mudança: o diretório
criado, dois arquivos escritos (o Puppet registra o conteúdo deles como um checksum SHA-256) e o
`exec` rodado uma vez porque o `shop.conf` mudou.

A segunda execução do mesmo manifest:

```
ana@laptop:~/shop/puppet$ puppet apply site.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.04 seconds
Notice: Applied catalog in 0.01 seconds
```

Nada entre compilar e aplicar: todos os recursos já estavam como descritos. Essa é a propriedade que a
aula 1 chamou de idempotente, e é ela que permite a um agente rodar a cada trinta minutos sem fazer
nada na maior parte das vezes.

Agora alguém edita a configuração à mão, e o Puppet roda de novo:

```
ana@laptop:~/shop/puppet$ echo "listen 8080;" > ~/web/shop.conf
ana@laptop:~/shop/puppet$ puppet apply site.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.04 seconds
Notice: /Stage[main]/Main/File[/home/ana/web/shop.conf]/content: content changed '{sha256}717bae503ae6108953042113e8bb6284b71a2c1c73665b7cc9cc06711dbe7138' to '{sha256}292f046193dabb234e26be4c8d5cb125558e85ac5094b1419ffed38a4d949aae'
Notice: /Stage[main]/Main/Exec[reload-web]: Triggered 'refresh' from 1 event
Notice: Applied catalog in 0.03 seconds
ana@laptop:~/shop/puppet$ cat ~/web/shop.conf ~/web/reloads.log
listen 80;
root /home/ana/web;
reloaded
reloaded
```

O Puppet comparou o arquivo com a descrição, achou um checksum diferente, escreveu de volta o conteúdo
descrito e avisou o `exec`, que rodou uma segunda vez. O log tem duas linhas, uma por mudança. Um agente
teria feito isso sozinho, na execução seguinte.

## Pacote, arquivo, serviço

O formato que um servidor web de verdade recebe são três tipos de recurso que aparecem em quase todo
código Puppet:

```
package { 'nginx':
  ensure => installed,
}

file { '/etc/nginx/sites-enabled/shop':
  ensure  => file,
  content => "server { listen 80; root /var/www/shop; }\n",
  require => Package['nginx'],
  notify  => Service['nginx'],
}

service { 'nginx':
  ensure => running,
  enable => true,
}
```

`require` e `notify` são **relacionamentos**: instalar o pacote antes de escrever a configuração dele, e
reiniciar o serviço quando a configuração mudar. O Puppet monta um grafo com eles e aplica os recursos
numa ordem que o respeita. Onde dois recursos não têm relacionamento, ele segue a ordem do manifest,
mas um manifest que depende dessa ordem sem dizer quebra no dia em que alguém move um recurso para
outro arquivo.

A Ana não é root e o laboratório não tem rede para o `apt`, então este roda com `--noop`, que compara e
informa sem mudar nada:

```
ana@laptop:~/shop/puppet$ puppet apply --noop server.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.32 seconds
Notice: /Stage[main]/Main/Package[nginx]/ensure: current_value 'purged', should be 'present' (noop)
Notice: /Stage[main]/Main/File[/etc/nginx/sites-enabled/shop]/ensure: current_value 'absent', should be 'file' (noop)
Notice: /Stage[main]/Main/Service[nginx]/ensure: current_value 'stopped', should be 'running' (noop)
Notice: Class[Main]: Would have triggered 'refresh' from 3 events
Notice: Stage[main]: Would have triggered 'refresh' from 1 event
Notice: Applied catalog in 1.70 seconds
```

Cada linha traz o valor atual e o que deveria ter. Sem `--noop`, o pacote falha, e o grafo mostra seu
valor:

```
ana@laptop:~/shop/puppet$ puppet apply server.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.28 seconds
Error: Execution of '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install nginx' returned 100: E: Could not open lock file /var/lib/dpkg/lock-frontend - open (13: Permission denied)
E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), are you root?
Error: /Stage[main]/Main/Package[nginx]/ensure: change from 'purged' to 'present' failed: Execution of '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install nginx' returned 100: E: Could not open lock file /var/lib/dpkg/lock-frontend - open (13: Permission denied)
E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), are you root?
Notice: /Stage[main]/Main/File[/etc/nginx/sites-enabled/shop]: Dependency Package[nginx] has failures: true
Warning: /Stage[main]/Main/File[/etc/nginx/sites-enabled/shop]: Skipping because of failed dependencies
Warning: /Stage[main]/Main/Service[nginx]: Skipping because of failed dependencies
Notice: Applied catalog in 1.52 seconds
```

O arquivo e o serviço foram **pulados porque a dependência deles falhou**, em vez de tentados mesmo
assim. Um arquivo de configuração para um pacote que não está instalado, e um serviço ligado sem ele,
são exatamente o que o `require` existe para evitar.

O `puppet resource` vira o mesmo mecanismo do avesso e descreve o que existe, na sintaxe do próprio
Puppet:

```
ana@laptop:~/shop/puppet$ puppet resource package nginx
package { 'nginx':
  ensure   => 'purged',
  provider => 'apt',
}
```

`provider => 'apt'` é a parte do Puppet que transforma o tipo geral `package` em comandos para o
gerenciador de pacotes do Ubuntu; em outro sistema, outro é escolhido. A palavra quer dizer outra coisa
no Terraform, onde um provider é o programa que conhece a API de uma nuvem.

Código Puppet é compartilhado em **módulos**, com uma coleção pública chamada Puppet Forge, e os dados
que mudam por máquina ou por ambiente costumam ficar separados do código, no **Hiera**. Vale
reconhecer os dois num código que já existe; nenhum deles é necessário para ler um manifest.
