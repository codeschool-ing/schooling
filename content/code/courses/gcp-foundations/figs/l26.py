"""Lesson 26: three doors, one API."""
from figures import Fig, T, figure


@figure('l26-doors', 26)
def doors():
    f = Fig('l26-doors', 720, 290, T(
        'Four doors on the left: the console, gcloud, curl and Terraform. Each sends the same request, a PUT '
        'of a topic\'s name to /v1/projects/planner-dev/topics, to one API in the middle, which holds the '
        'topics orders, invoices and shipments on the right. Terraform alone has a second arrow, a GET back '
        'from the API to its state file, labelled refresh: it reads what exists, and a plan compares that with '
        'its files. A change made through another door shows up there as drift.',
        'Quatro portas à esquerda: o console, o gcloud, o curl e o Terraform. Cada uma manda o mesmo pedido, um '
        'PUT do nome de um tópico em /v1/projects/planner-dev/topics, a uma API no meio, que guarda os tópicos '
        'orders, invoices e shipments à direita. Só o Terraform tem uma segunda seta, um GET de volta da API '
        'para o arquivo de estado dele, chamada refresh: ele lê o que existe, e um plano compara isso com os '
        'arquivos. Uma mudança feita por outra porta aparece ali como drift.'))
    doors = [T('the console', 'o console'), 'gcloud', 'curl', 'Terraform']
    for i, name in enumerate(doors):
        y = 20 + i * 52
        f.rect(20, y, 150, 40, stroke='--phosphor' if i == 3 else '--wire', fill='--panel', width=1.4)
        f.text(95, y + 20, name, size=10, mono=i in (1, 2))
        f.arrow([(172, y + 20), (296, 120)], stroke='--paper-dim', width=1.2)
    f.rect(300, 80, 160, 80, stroke='--amber', fill='--scan', width=1.6)
    f.text(380, 104, T('one API', 'uma API'), size=10.5)
    f.text(380, 126, 'PUT /v1/…/topics/NAME', size=8.5, mono=True, fill='--paper-dim')
    f.text(380, 144, 'pubsub.googleapis.com', size=8.5, mono=True, fill='--paper-dim')
    f.arrow([(462, 120), (536, 120)], stroke='--amber', width=1.4)
    f.rect(540, 60, 160, 120, stroke='--wire', fill='--panel', width=1.2)
    for i, n in enumerate(('orders', 'invoices', 'shipments')):
        f.text(620, 92 + i * 26, n, size=10, mono=True)
    f.path('M380 162 C 380 236, 110 248, 110 220', stroke='--phosphor', width=1.4, dash='5 3', arrow=True)
    f.text(400, 236, T('refresh: GET what exists, then compare with the files',
                       'refresh: GET do que existe, depois comparar com os arquivos'), size=9.5, fill='--phosphor')
    f.text(360, 274, T('a change through another door is what a plan reports as drift',
                       'uma mudança por outra porta é o que um plano relata como drift'), size=9.5, fill='--paper-dim')
    return f, T('Every door sends the same request; only Terraform reads back and compares.',
                'Toda porta manda o mesmo pedido; só o Terraform lê de volta e compara.')
