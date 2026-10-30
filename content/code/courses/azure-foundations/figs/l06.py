"""Lesson 6: Microsoft Entra ID, users, groups and administrative units."""
from figures import Fig, T, figure


@figure('l06-au-scope', 6)
def au_scope():
    f = Fig('l06-au-scope', 720, 300, T(
        'The shop\'s tenant holds the office staff, among them bia, and an administrative unit called '
        'au-shop-stores holding the store staff. A store manager holds the role User Administrator '
        'scoped to the unit. An arrow from the manager reaches into the unit and resets passwords '
        'there; a second arrow towards bia, outside the unit, is refused.',
        'O tenant da loja guarda o pessoal do escritório, entre eles bia, e uma unidade administrativa '
        'chamada au-shop-stores com o pessoal das lojas físicas. Uma gerente de loja tem o papel User '
        'Administrator com escopo na unidade. Uma seta da gerente entra na unidade e redefine senhas lá; '
        'uma segunda seta, na direção de bia, fora da unidade, é recusada.'))
    f.rect(20, 14, 680, 272, stroke='--phosphor', fill='--ink')
    f.text(36, 32, T('tenant', 'tenant'), size=9.5, anchor='start', fill='--phosphor')
    f.text(684, 32, 'shop.example', size=10, anchor='end', mono=True)
    # the manager
    f.rect(270, 52, 180, 56, stroke='--amber', fill='--panel')
    f.text(360, 70, T('store manager', 'gerente de loja'), size=10.5, weight='600')
    f.text(360, 91, 'User Administrator', size=9.5, mono=True, fill='--paper-dim')
    # office staff
    f.rect(44, 150, 250, 112, stroke='--wire', fill='--panel')
    f.text(169, 168, T('office staff', 'pessoal do escritório'), size=10, fill='--paper-dim')
    for i, u in enumerate(['bia', 'ana']):
        f.rect(70 + i * 105, 190, 90, 48, stroke='--wire', fill='--scan')
        f.text(115 + i * 105, 214, u, size=10.5, mono=True)
    # the unit
    f.rect(420, 150, 256, 112, stroke='--amber', fill='--panel', dash='5 4')
    f.text(548, 168, 'au-shop-stores', size=10.5, mono=True)
    for i, u in enumerate(['lia', 'rui']):
        f.rect(448 + i * 105, 190, 90, 48, stroke='--wire', fill='--scan')
        f.text(493 + i * 105, 214, u, size=10.5, mono=True)
    f.arrow([(400, 109), (500, 149)], stroke='--amber', width=1.5)
    f.text(498, 124, T('resets passwords', 'redefine senhas'), size=9.5, anchor='start', fill='--amber')
    f.arrow([(320, 109), (190, 149)], stroke='--paper-dim', width=1.3, dash='4 3')
    f.text(212, 124, T('refused: outside the scope', 'recusado: fora do escopo'), size=9.5, anchor='end',
           fill='--paper-dim')
    return f, T('A directory role scoped to a unit reaches the unit\'s members and nobody else.',
                'Um papel de diretório com escopo numa unidade alcança os membros dela e ninguém mais.')


@figure('l06-two-role-systems', 6)
def two_systems():
    f = Fig('l06-two-role-systems', 720, 250, T(
        'Two separate role systems side by side. On the left, directory roles of Entra ID, such as '
        'Global Administrator and User Administrator, act on users, groups and applications, and are '
        'scoped to the tenant or an administrative unit. On the right, Azure roles such as Owner, '
        'Contributor and Reader act on resources, and are scoped to a management group, a subscription, '
        'a resource group or a resource. Nothing crosses between them.',
        'Dois sistemas de papéis separados, lado a lado. À esquerda, os papéis de diretório do Entra ID, '
        'como Global Administrator e User Administrator, agem sobre usuários, grupos e aplicações, com '
        'escopo no tenant ou numa unidade administrativa. À direita, os papéis do Azure, como Owner, '
        'Contributor e Reader, agem sobre recursos, com escopo num grupo de gerenciamento, numa '
        'assinatura, num grupo de recursos ou num recurso. Nada passa de um para o outro.'))
    cols = [(30, T('directory roles', 'papéis de diretório'), ['Global Administrator', 'User Administrator'],
             T('act on users, groups, applications', 'agem sobre usuários, grupos, aplicações'),
             T('scope: tenant or administrative unit', 'escopo: tenant ou unidade administrativa'), '--phosphor'),
            (380, T('Azure roles', 'papéis do Azure'), ['Owner', 'Contributor', 'Reader'],
             T('act on resources', 'agem sobre recursos'),
             T('scope: group, subscription, resource', 'escopo: grupo, assinatura, recurso'), '--amber')]
    for x, head, roles, acts, scope, stroke in cols:
        f.rect(x, 20, 310, 210, stroke=stroke, fill='--panel')
        f.text(x + 155, 42, head, size=11, weight='600')
        for i, r in enumerate(roles):
            f.rect(x + 40, 60 + i * 34, 230, 26, stroke='--wire', fill='--scan')
            f.text(x + 155, 73 + i * 34, r, size=10, mono=True)
        f.text(x + 155, 182, acts, size=10, fill='--paper-dim')
        f.text(x + 155, 206, scope, size=10, fill='--paper-dim')
    return f, T('A Global Administrator reads no virtual machine until an Azure role says so; an Owner resets no password.',
                'Um Global Administrator não lê máquina virtual até um papel do Azure permitir; um Owner não redefine senha.')
