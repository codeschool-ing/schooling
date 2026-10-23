---
title: IaaS, where the operating system is yours
version: 1
---

**On a virtual machine, everything from the operating system up is yours, and three settings decide
most of its exposure: the image it was built from, the network rule in front of it, and how it hands
out its own credentials.** This section launches the machine with all three wrong, as a hurried first
version would, then reads each back, fixes it and reads it again. Start moto in the first terminal,
empty, and read `env.sh` in both.

## A machine, built in a hurry

caio needs a machine for the booking system, and a security group that lets him and its users in.
He opens the administrative port, 22 for SSH, to the whole internet, alongside the web port, 443:

```
ana@laptop:~/aws$ aws ec2 create-security-group --group-name booking-vm --description "booking system" --query GroupId --output text
sg-e1a208744d0ad63a7
```

```
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-name booking-vm --protocol tcp --port 22 --cidr 0.0.0.0/0 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text
tcp	22	0.0.0.0/0
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-name booking-vm --protocol tcp --port 443 --cidr 0.0.0.0/0 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text
tcp	443	0.0.0.0/0
```

For the image he picks the first Ubuntu he finds in the list moto carries, and launches:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-1e749f67 --instance-type t3.micro --security-groups booking-vm --query "Instances[0].InstanceId" --output text
i-0336a691404379cff
```

## Three questions to the machine

**What is it running?** The image's own name answers:

```
ana@laptop:~/aws$ aws ec2 describe-images --image-ids ami-1e749f67 --query "Images[0].Description" --output text
Canonical, Ubuntu, 14.04 LTS, amd64 trusty image build on 2017-07-27
```

Ubuntu 14.04, built in July 2017. Canonical's standard support for 14.04 ended in 2019, so this
machine starts life years behind on security fixes. **Nobody at AWS will patch it**: the provider runs
the hypervisor below, and logging in to a customer's machine to update it is exactly what it has
promised never to do. Choosing a current image, and keeping it patched afterwards, is the first item
on the IaaS list.

**Who can reach the administrative port?** Ask the security group which rules are open to the whole
internet:

```
ana@laptop:~/aws$ aws ec2 describe-security-groups --group-names booking-vm --query "SecurityGroups[0].IpPermissions[?IpRanges[?CidrIp=='0.0.0.0/0']].[FromPort,ToPort]" --output text
22	22
443	443
```

**443 open to everyone is the service; 22 open to everyone is a door to the operating system** that
every automated scanner on the internet will find and try. The clinic's staff reach the machine from
one office, so the rule should name that office's address and nothing else.

**How does the machine give out its credentials?** A machine with a role attached gets temporary
credentials from a metadata service only it can reach. In its first version, any request from the
machine to that service was answered. In the second, **IMDSv2**, a program first has to ask for a
session token with a different kind of request, and only then gets an answer. That difference is what
stops a program on the machine that can be tricked into fetching an address for somebody else from
handing over the role's credentials, which is the step at the centre of the Capital One case of
lesson 2.

```
ana@laptop:~/aws$ aws ec2 describe-instances --query "Reservations[0].Instances[0].MetadataOptions.HttpTokens" --output text
optional
```

`optional` means the first version still answers. **AWS lets an account make `required` the default
for new machines, and several newer images ask for it themselves**; this one, from 2017, does not, and
moto applies no such default either.

## The fixes, and reading them back

Close 22 to the world and open it to the office alone, using `203.0.113.10`, an address from the range
set aside for documentation; then require tokens on the metadata service:

```
ana@laptop:~/aws$ aws ec2 revoke-security-group-ingress --group-name booking-vm --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-name booking-vm --protocol tcp --port 22 --cidr 203.0.113.10/32 --query "SecurityGroupRules[].[IpProtocol,FromPort,CidrIpv4]" --output text
tcp	22	203.0.113.10/32
ana@laptop:~/aws$ aws ec2 modify-instance-metadata-options --instance-id i-0336a691404379cff --http-tokens required --http-endpoint enabled --query InstanceMetadataOptions.HttpTokens --output text
required
```

Then the same questions, as evidence:

```
ana@laptop:~/aws$ aws ec2 describe-security-groups --group-names booking-vm --query "SecurityGroups[0].IpPermissions[?IpRanges[?CidrIp=='0.0.0.0/0']].[FromPort,ToPort]" --output text
443	443
ana@laptop:~/aws$ aws ec2 describe-instances --query "Reservations[0].Instances[0].MetadataOptions.HttpTokens" --output text
required
```

Only the web port is open to the world, and the metadata service wants a token. **The image is the
fix this lab cannot show**: a running machine cannot change its image, so the cure is a new machine
from a current one, and then a patching routine that keeps it current.

::: track security
The `defense-hardening` course treats that routine in its lesson 17: the window, the test, the rollout
and the exceptions. On IaaS every item of it lands on your list.
:::

::: track *
That routine has parts of its own: a window, a test, a rollout and the exceptions. On IaaS every one of
them lands on your list.
:::
