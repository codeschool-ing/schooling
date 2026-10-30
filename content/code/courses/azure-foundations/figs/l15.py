"""Lesson 15: tags, cost allocation and exporting usage."""
from figures import Fig, T, figure


@figure('l15-two-inheritances', 15)
def two_inheritances():
    f = Fig('l15-two-inheritances', 720, 300, T(
        'The resource group rg-shop-prod-app carries the tag cost-centre cc-410, and the virtual '
        'machine vm-shop-web-2 inside it has no tags. Two ways bring the group\'s tag down. On the '
        'left, an Azure Policy assignment with the modify effect writes the tag onto the resource '
        'itself, when it is created or remediated. On the right, Cost Management\'s tag inheritance '
        'leaves the resource as it is and adds the tag only to its usage records in the cost data.',
        'O grupo de recursos rg-shop-prod-app leva a tag cost-centre cc-410, e a máquina virtual '
        'vm-shop-web-2 dentro dele não tem tags. Dois caminhos trazem a tag do grupo para baixo. À '
        'esquerda, uma atribuição do Azure Policy com o efeito modify escreve a tag no próprio recurso, '
        'quando ele é criado ou remediado. À direita, a herança de tags do Cost Management deixa o '
        'recurso como está e acrescenta a tag só aos seus registros de uso nos dados de custo.'))
    # the group, top centre
    f.rect(220, 16, 280, 92, stroke='--wire', fill='--ink', dash='4 3')
    f.text(232, 32, T('resource group', 'grupo de recursos'), size=9.5, anchor='start', fill='--paper-dim')
    f.text(488, 32, 'rg-shop-prod-app', size=10, anchor='end', mono=True)
    f.text(360, 52, 'cost-centre: cc-410', size=10.5, mono=True, fill='--amber')
    f.rect(270, 64, 180, 34, stroke='--wire', fill='--panel')
    f.text(360, 81, 'vm-shop-web-2', size=10, mono=True)
    # left: the policy writes the resource
    f.arrow([(300, 110), (300, 130), (170, 130), (170, 154)], stroke='--phosphor', width=1.4)
    f.rect(30, 156, 280, 112, stroke='--phosphor', fill='--panel')
    f.text(170, 174, T('Azure Policy, effect modify', 'Azure Policy, efeito modify'), size=10.5, weight='600', fill='--phosphor')
    f.rect(70, 190, 200, 44, stroke='--wire', fill='--ink')
    f.text(170, 204, 'vm-shop-web-2', size=10, mono=True)
    f.text(170, 222, 'cost-centre: cc-410', size=9.5, mono=True, fill='--amber')
    f.text(170, 252, T('the tag is written on the resource', 'a tag é escrita no recurso'), size=9.5, fill='--paper-dim')
    # right: cost management writes the records
    f.arrow([(420, 110), (420, 130), (550, 130), (550, 154)], stroke='--paper', width=1.4)
    f.rect(410, 156, 280, 112, stroke='--paper', fill='--panel')
    f.text(550, 174, T('Cost Management tag inheritance', 'herança de tags do Cost Management'), size=10.5, weight='600')
    f.rect(430, 190, 240, 44, stroke='--wire', fill='--ink')
    f.text(550, 204, 'vm-shop-web-2  3.20  Tags:', size=9.5, mono=True)
    f.text(550, 222, '{"cost-centre": "cc-410"}', size=9.5, mono=True, fill='--amber')
    f.text(550, 252, T('only the usage records gain it', 'só os registros de uso a ganham'), size=9.5, fill='--paper-dim')
    return f, T('One rule changes the resource; the other changes only what the bill says about it.',
                'Uma regra muda o recurso; a outra muda só o que a fatura diz dele.')
