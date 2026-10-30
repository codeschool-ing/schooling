---
title: An image of your own, or a machine configured at boot
version: 1
---

Building an image sounds like specialist work with tools of its own. **An image of your own is a
machine you configured, cleaned of what made it one particular machine, and copied.** Every tool
that builds Azure images, from a portal button to Azure VM Image Builder, runs the same steps. And
there is a second way to get a configured machine, which is not to build an image at all but to
hand a stock one its instructions at first boot. This section does both, and says when each wins.

## The steps, on a subscription

None of this was run in this course, because each step needs a machine in a subscription. It is
Microsoft's documented sequence for a Linux machine, and every command is one you would type.

Step 1. Create a machine from a Marketplace image and configure it: install the packages, write the
configuration, put the application in place at a known version.

Step 2. Deprovision it from inside. Over SSH, on the machine itself:

```sh
sudo waagent -deprovision+user
```

`waagent` is the Azure Linux Agent, which every Marketplace Linux image carries. This deletes
what makes the machine one particular machine: the agent's provisioning data, files such as the
SSH host keys, and the last user account the platform created. **It cannot be undone**, and the
documentation says to run it only on a machine you are about to capture. Plain `-deprovision`
keeps that user.

Step 3. Tell Azure it is generalised. The machine is still running; stop it, then mark it:

```sh
az vm deallocate --resource-group shop-rg --name shop-build
az vm generalize --resource-group shop-rg --name shop-build
```

From then on the machine cannot be started again. It exists only to be copied.

Step 4. Capture it, as one of the two kinds of image of your own from the first section. A gallery
image version is `az sig image-version create ... --virtual-machine <the machine's id>`, which
the next section declares in Bicep instead. A managed image is one command:

```sh
az image create --resource-group shop-rg --name shop-web-2026-10-30 --source shop-build
```

**Prefer the gallery, and Microsoft's documentation says so too.** A managed image can only be made
from a generalised machine, can only create machines in its own region, cannot be shared with
another subscription, and, as the first section said, cannot give you Trusted Launch. The
documentation keeps it for a couple of simple images in development and test.

## Generalised or specialised

Step 2 is optional in a gallery, and skipping it gives a different kind of image:

| | generalised | specialised |
|---|---|---|
| step 2 | `waagent -deprovision` first | skipped |
| at first boot | gets a new name, a new user, new keys | is a copy of the original, accounts included |
| the machine's `osProfile` | given at creation, as for a Marketplace image | none: there is nothing to set up |
| boots | slower, because it is set up | faster, because it was already set up once |
| good for | many different machines from one image | copies of one machine, or a restore |

A specialised image keeps every account of the machine it was taken from, and its computer name,
so ten machines made from it start out with the same name. **For an image the shop's machines will
be made from, generalise.**

## Configuring at boot instead

The other way is to start every machine from the stock Ubuntu image and let it configure itself.
Azure passes a machine a block of **custom data** at creation, and Ubuntu's Marketplace images run
**cloud-init**, which reads that block at first boot and acts on it. Here is a cloud-init file for
the shop's machines. Save it as `cloud-init.yaml`:

```yaml
#cloud-config
# cloud-init.yaml
timezone: America/Sao_Paulo
package_update: true
packages:
  - docker.io
write_files:
  - path: /etc/shop/shop.env
    permissions: '0644'
    content: |
      SHOP_VERSION=1.0
      PORT=8080
runcmd:
  - systemctl enable --now docker
```

The first line has to stay the first line: `#cloud-config` is how cloud-init knows the block is a
configuration and not a script. The rest is in cloud-init's own vocabulary. The machine's clock
goes to São Paulo's time zone, the package index is refreshed and Docker installed, a file of
settings is written where a service could read it, and Docker is started. Nothing in it names
`apt`, because cloud-init calls the distribution's own package manager.

To hand it to the machine, add one line to `vm.bicep`, inside `osProfile` and after
`adminUsername`:

```bicep
    osProfile: {
      computerName: 'shop-web-1'
      adminUsername: adminUsername
      customData: loadFileAsBase64('cloud-init.yaml')
```

`loadFileAsBase64()` is a Bicep function that **reads the file while compiling**, not when the
machine is created, and writes its contents into the template already encoded, which is the form
the API wants custom data in:

```
ana@laptop:~/azure$ grep -n -B1 customData vm.bicep
34-      adminUsername: adminUsername
35:      customData: loadFileAsBase64('cloud-init.yaml')
ana@laptop:~/azure$ bicep build vm.bicep
ana@laptop:~/azure$ jq ".resources[0].properties.osProfile.customData" vm.json
"[variables('$fxv#0')]"
ana@laptop:~/azure$ jq -r '.variables["$fxv#0"]' vm.json | base64 -d | head -n 3
#cloud-config
# cloud-init.yaml
timezone: America/Sao_Paulo
ana@laptop:~/azure$ wc -c cloud-init.yaml
267 cloud-init.yaml
```

The compiler put the file into the template as a variable with a generated name, and the machine's
`customData` points at it. Decoded, it is the file. So the template is complete on its own, and a
change to `cloud-init.yaml` reaches Azure only through the next compile.

What a laptop cannot show is cloud-init running, because nothing here boots an Azure machine. Four
things about it are in Microsoft's documentation and matter in practice:

- **Custom data is limited to 64 KB**; this file is 267 bytes.
- **It is not for secrets.** The documentation advises against putting sensitive values there;
  `azure-operations` lesson 17 puts them in Key Vault instead.
- **It runs at first boot, and a single machine's custom data cannot be changed afterwards.** A
  scale set's can, and lesson 4 says what happens to the machines already running.
- **A failure inside it does not fail the creation.** cloud-init reports the machine ready without
  waiting for your configuration, so a package that failed to install is a machine that looks
  healthy. The documentation tells you to build your own way of hearing about it.

## Baking or configuring at boot

| | in the image | at first boot, with cloud-init |
|---|---|---|
| time from creation to serving | the boot | the boot and every install |
| depends on, at creation | nothing outside the machine | package mirrors, downloads |
| two machines a month apart | the same bytes | whatever was current each day |
| a security fix | a new image version, then new machines | the next machine created picks it up |

**Bake what is slow to install and changes rarely; configure at boot what differs per machine.**
For the shop that means Docker and the base packages in the image, and the version of the order
API and the settings file at boot. The two compose: a gallery image can carry custom data like any
other.

## The service that runs the steps for you

Done by hand, the four steps are a checklist somebody forgets a line of. **Azure VM Image Builder**
is Microsoft's managed service for them, built on HashiCorp's Packer. You submit an *image
template* that names a source image, a list of customisations (shell scripts and files, on Linux) and
where the result goes: a gallery, a managed image or a disk file. Running the template makes Image
Builder create a build machine in a staging resource group of its own, named `IT_` followed by
your resource group and the template's name, run the customisations, generalise, capture, and
delete the build machine. The documentation names its default build size, `Standard_D2ds_v4` for a
generation 2 image, and says the cost is that of the machines, disks, storage and network it
uses while it works. It is available in Brazil South. It was not run here: it needs a subscription.
