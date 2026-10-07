---
title: Chef, recipes written in Ruby
version: 2
---

Chef is the one tool in this lesson that you do not install, and that the machine these lessons were
recorded on did not have either. On yours the same check prints the same line:

```
ana@laptop:~/shop/salt$ command -v chef-client cinc-client knife || echo "none of them"
none of them
```

So this section shows a recipe and runs nothing. **The recipe below has no output beside it**, because
any output would be invented. Everything said about how Chef
behaves is about the tool in general, not about a run you can see.

## A recipe is Ruby

Chef's descriptions are **recipes**, and a recipe is a Ruby program. Its resources look like
declarations, but each one is a method call with a block, which is why the syntax is so light. The
same web server as before:

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

Put it beside Ana's Puppet manifest and the resources line up one for one: `package`, a directory, a
file, a configuration with a notification, a service. `template` renders an ERB file, Ruby's own
template format, with the variables it is given, the role Jinja played for Salt. `notifies :reload,
'service[nginx]'` is Puppet's `notify` and Salt's `onchanges`: reload nginx if, and only if, the
configuration changed. **The ideas are the same; the language is the difference.**

That difference is real in both directions. Because a recipe is Ruby, anything Ruby can do is available
around the resources: a loop over a list of sites, a condition on the platform, a call to a library.
Puppet's language has loops and conditions too, but not a whole general-purpose language in the
middle of the description. That power is also the classic way to get a surprise,
because Chef reads a run in **two phases**. First it evaluates the Ruby of every recipe and collects
the resources; then it converges them, one by one, in the order they were written. Plain Ruby written
between resources runs in the first phase, before any resource has been applied, so a line that reads
a file a resource is about to create finds nothing there.

## Cookbooks, the server, and local mode

Recipes live in a **cookbook**, a directory with a `metadata.rb` naming it and its version, a
`recipes/` directory, a `templates/` directory for files like `shop.conf.erb`, and `attributes/` for
default values. A machine's **run-list** says which recipes apply to it, in which order.

In the pull arrangement, `chef-client` runs on each machine, fetches its run-list and the cookbooks it
needs from a Chef Infra Server, and converges. Cookbooks reach the server from a workstation with
`knife`, Chef's command-line tool. Without a server, `chef-client --local-mode` reads cookbooks from the
machine's own disk, which is Chef's equivalent of `puppet apply` and `salt-call --local`.

You will also see **Cinc**, a community build of Chef's open-source code distributed under a different
name, used where Chef's own binaries and their licence terms do not suit. The recipes are the same.

Chef the company has belonged to Progress Software since 2020. Recognising a recipe and a cookbook, and
knowing which phase a line of Ruby runs in, is enough to read an existing Chef codebase; writing one is
outside this course.
