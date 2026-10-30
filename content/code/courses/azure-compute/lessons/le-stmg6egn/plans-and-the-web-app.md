---
title: The plan, and the web app that runs on it
version: 1
---

The easy picture of App Service is a small server per web app: you create an app, Azure gives it
somewhere to run, and each app is billed for itself. **The machines belong to the plan, not to the
app.** An App Service plan, `Microsoft.Web/serverfarms` in a template, is a set of virtual machines
in one region: an operating system, a size, a number of instances and a pricing tier. A web app,
`Microsoft.Web/sites`, is what runs on them, and Microsoft's documentation says it plainly: an app
always runs in a plan, and when it runs, it runs on every instance the plan has. Outside the Free
and Shared tiers you pay for each instance of the plan, whatever runs on it and however busy it is.
This section declares a plan and the shop as a web app in Bicep and compiles them. Nothing is
created, because that needs a subscription.

## The tiers, and what each one adds

The tier decides two things at once: whose machines your apps run on, and which features the plan
has. The table is Microsoft's limits page, read on 2026-10-30, cut down to the rows this lesson
uses.

| tier | the machines | instances at most | adds |
| --- | --- | --- | --- |
| Free (F1) | a VM shared with other customers' apps, with a CPU quota of 60 minutes a day | 1 | nothing to scale; Linux and Windows |
| Shared (D1) | the same, 240 minutes a day | 1 | Windows only |
| Basic (B1 to B3) | dedicated VMs, shared only by apps in the same plan | 3 | Always On, custom domains with TLS, manual scale-out |
| Standard (S1 to S3) | dedicated | 10 | autoscale, 5 deployment slots per app |
| Premium v3 and v4 (P0v3, P1v3…) | dedicated, newer hardware | 30 | 20 slots, and automatic scaling, which adds instances on HTTP load without rules |
| Isolated v2 (I1v2…) | dedicated VMs in an App Service Environment, on a virtual network of your own | 100 | 20 slots, network isolation from other customers |

**Slots begin at Standard and autoscale begins at Standard**, which is why the shop's plan is not
Basic. The Basic tier is a fine place for a site that is restarted in place when it changes; the
shop wants what the next two sections build, and those need Standard or above.

Zone redundancy is not a row in that table. It is a property of the plan, `zoneRedundant`, and the
documentation sets two conditions: at least two instances, and a plan whose `maximumNumberOfZones`
is more than one. That number depends on the region and on the scale unit the plan was placed on,
not on the tier's name alone. A plan that answers one has to be made again, in a new resource
group. Brazil South has availability zones, lesson 6, and Microsoft's own example of a zone
redundant plan is a `P1V3` with two workers, which is the shop's.

## Several apps, one plan

Because the plan is the machines, every app placed on it shares them. Three apps on a plan of two
instances is six copies running, three on each machine, and the bill is still two instances. The
documentation lists what shares the machines: every app in the plan, **every deployment slot of
every app**, and the diagnostic logs, backups and WebJobs they run. It counts an active slot as an
active app for exactly that reason.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"A box for the App Service plan shop-plan, P1v3, Linux, two instances, zone redundant. Inside it two instances side by side, in zone 1 and zone 2. Each instance runs the same three things: shop-sp, the production slot, with the image shop:1.0; shop-sp/staging, the staging slot, with shop:1.1; and another app, shop-admin. Below, two notes: the bill is two instances whatever runs on them, and autoscale changes the instance count, so all three move together.\"><rect x=\"20\" y=\"15\" width=\"680\" height=\"245\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"38\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">App Service plan</text><text x=\"152.4\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">shop-plan</text><text x=\"682\" y=\"35\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">P1v3 · Linux · 2 instances, zone redundant</text><rect x=\"40\" y=\"55\" width=\"305\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">instance 1</text><text x=\"330\" y=\"73\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zone 1</text><rect x=\"55\" y=\"88\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"68\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp</text><text x=\"68\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">production slot</text><text x=\"318\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop:1.0</text><rect x=\"55\" y=\"138\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp/staging</text><text x=\"68\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">staging slot</text><text x=\"318\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop:1.1</text><rect x=\"55\" y=\"188\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-admin</text><text x=\"68\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">another app</text><rect x=\"375\" y=\"55\" width=\"305\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">instance 2</text><text x=\"665\" y=\"73\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zone 2</text><rect x=\"390\" y=\"88\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"403\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp</text><text x=\"403\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">production slot</text><text x=\"653\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop:1.0</text><rect x=\"390\" y=\"138\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"403\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp/staging</text><text x=\"403\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">staging slot</text><text x=\"653\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop:1.1</text><rect x=\"390\" y=\"188\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"403\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-admin</text><text x=\"403\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">another app</text><text x=\"20\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">billed: 2 instances, whatever runs on them</text><text x=\"20\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">autoscale changes the instance count, so all three move together</text></svg>", "caption": "The plan is the machines and an app is what runs on them. A slot is an app too, on the same instances, which is why staging a new version uses the capacity production is serving from."}
```

That is a saving and a risk in the same sentence. The shop's back office, a small admin site the
three developers use, costs nothing extra on the shop's plan. It also scales with it: autoscale
changes the plan's instance count, so every app in it goes up and down together. And if the admin
site starts a heavy export at noon, the order API is on the same processors. Microsoft's guidance
is to give an app its own plan when it is resource intensive, when it must scale on its own, or
when it belongs in another region, and it gives rough densities, 16 apps for a `P1v3`. There is
also *per-app scaling*, which limits an app to fewer of the plan's instances, but the plan is still
what you pay for.

## The shop, as a container

App Service runs code in a runtime it maintains, Python or .NET or Node, or a container image you
built. The shop is an image already, the `shop:1.0` of lesson 7, so the web app runs that. On Linux
the image is named in one string, `linuxFxVersion`, with the word `DOCKER` and a vertical bar in
front of it.

Three things about a container on App Service come from its documentation and decide how the file
below is written:

- The port. App Service sends requests to one port of the container. The settings reference
  says it tries 80 and 8080 by itself, and the page on custom containers says it assumes 80. The
  shop listens on 8080, so the file says so with `WEBSITES_PORT`, and does not depend on which page
  is current. That setting is read by the platform and is not passed to the container.
- App settings are environment variables. Every other name and value under `appSettings`
  reaches the container's process as an environment variable, which is how the shop already reads
  `PORT` and `SHOP_VERSION`. `SHOP_ENV` is one the shop does not read yet; the next section needs it.
- The registry's credentials go in three settings whose names start `DOCKER_REGISTRY_SERVER_`,
  and the documentation says these three are not exposed to the application. The password arrives
  as a `@secure()` parameter, as in lesson 8. A managed identity with `AcrPull`, `azure-foundations`
  lesson 8, removes it, with `acrUseManagedIdentityCreds: true` in `siteConfig`.

Here is the whole file. It carries the `staging` slot and the warm-up settings that sections 03
and 04 explain, because it is the file as it stands the day `shop:1.1` is staged. Save it as
`~/azure/shop-web.bicep`:

```bicep
// shop-web.bicep
param location string = 'brazilsouth'
param registry string = 'shopregistry.azurecr.io'
@secure()
param registryPassword string

resource plan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: 'shop-plan'
  location: location
  kind: 'linux'
  sku: {
    name: 'P1v3'
    capacity: 2
  }
  properties: {
    reserved: true
    zoneRedundant: true
  }
}

resource site 'Microsoft.Web/sites@2024-11-01' = {
  name: 'shop-sp'
  location: location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${registry}/shop:1.0'
      alwaysOn: true
      healthCheckPath: '/healthz'
      appSettings: [
        { name: 'WEBSITES_PORT', value: '8080' }
        { name: 'DOCKER_REGISTRY_SERVER_URL', value: 'https://${registry}' }
        { name: 'DOCKER_REGISTRY_SERVER_USERNAME', value: 'shopregistry' }
        { name: 'DOCKER_REGISTRY_SERVER_PASSWORD', value: registryPassword }
        { name: 'WEBSITE_WARMUP_PATH', value: '/healthz' }
        { name: 'WEBSITE_WARMUP_STATUSES', value: '200' }
        { name: 'WEBSITE_SWAP_WARMUP_PING_PATH', value: '/healthz' }
        { name: 'WEBSITE_SWAP_WARMUP_PING_STATUSES', value: '200' }
        { name: 'SHOP_ENV', value: 'production' }
      ]
    }
  }
}

resource staging 'Microsoft.Web/sites/slots@2024-11-01' = {
  parent: site
  name: 'staging'
  location: location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${registry}/shop:1.1'
      alwaysOn: true
      healthCheckPath: '/healthz'
      appSettings: [
        { name: 'WEBSITES_PORT', value: '8080' }
        { name: 'DOCKER_REGISTRY_SERVER_URL', value: 'https://${registry}' }
        { name: 'DOCKER_REGISTRY_SERVER_USERNAME', value: 'shopregistry' }
        { name: 'DOCKER_REGISTRY_SERVER_PASSWORD', value: registryPassword }
        { name: 'WEBSITE_WARMUP_PATH', value: '/healthz' }
        { name: 'WEBSITE_WARMUP_STATUSES', value: '200' }
        { name: 'WEBSITE_SWAP_WARMUP_PING_PATH', value: '/healthz' }
        { name: 'WEBSITE_SWAP_WARMUP_PING_STATUSES', value: '200' }
        { name: 'SHOP_ENV', value: 'staging' }
      ]
    }
  }
}

resource sticky 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: site
  name: 'slotConfigNames'
  properties: {
    appSettingNames: [
      'SHOP_ENV'
    ]
  }
}

output production string = site.properties.defaultHostName
output staging string = staging.properties.defaultHostName
```

`kind: 'linux'` with `reserved: true` makes the plan a Linux one. `sku` names the size, `P1v3`, and
`capacity` is the number of instances. The site points at the plan with `serverFarmId`, and that
reference is all that places an app on its machines. `alwaysOn` keeps the app loaded when nobody
has called it for a while, and needs Basic or above. `healthCheckPath` is section 04's.

## Compiled

The CLI is the other way to create the same plan, and its help shows three of the plan's decisions:

```
ana@laptop:~/azure$ az appservice plan create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(is-linux|number-of-workers|zone-redundant) ' | sed 's/ Global Policy Arguments//'
 --is-linux : Host web app on Linux worker. Defaults to true unless --hyper-v is specified. Use "--is-linux false" to create a Windows plan. Allowed values: false, true. 
 --number-of-workers : Number of workers to be allocated. Default: 1. 
 --zone-redundant -z : Enable zone redundancy for high availability. Minimum instance count is 2. 
```

Then the file:

```
ana@laptop:~/azure$ bicep build shop-web.bicep
ana@laptop:~/azure$ jq -c '.resources[] | {type, name}' shop-web.json
{"type":"Microsoft.Web/serverfarms","name":"shop-plan"}
{"type":"Microsoft.Web/sites","name":"shop-sp"}
{"type":"Microsoft.Web/sites/slots","name":"[format('{0}/{1}', 'shop-sp', 'staging')]"}
{"type":"Microsoft.Web/sites/config","name":"[format('{0}/{1}', 'shop-sp', 'slotConfigNames')]"}
ana@laptop:~/azure$ jq -r '.resources[1].properties.siteConfig.linuxFxVersion' shop-web.json
[format('DOCKER|{0}/shop:1.0', parameters('registry'))]
```

No warnings, four resources, and the image reaches the template as a string the compiler builds
with `format`. **To the compiler, `linuxFxVersion` is text.** It checks that the property exists
and that the value is a string, and nothing about what the string says. A port written as a number
is a type, which it knows:

```
ana@laptop:~/azure$ sed "s/value: '8080'/value: 8080/" shop-web.bicep > port.bicep
ana@laptop:~/azure$ bicep build port.bicep
/home/ana/azure/port.bicep(33,41) : Warning BCP036: The property "value" expected a value of type "null | string" but the provided value is of type "8080". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
/home/ana/azure/port.bicep(60,41) : Warning BCP036: The property "value" expected a value of type "null | string" but the provided value is of type "8080". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

Two warnings, one per slot, and a template written anyway: lesson 1's rule, treat every warning as
a refusal. Now two mistakes it does not know:

```
ana@laptop:~/azure$ sed 's/DOCKER|/DOCKER:/' shop-web.bicep > colon.bicep
ana@laptop:~/azure$ bicep build colon.bicep
ana@laptop:~/azure$ sed '/reserved: true/d' shop-web.bicep > windows.bicep
ana@laptop:~/azure$ bicep build windows.bicep
ana@laptop:~/azure$ jq -c '.resources[0].properties' windows.json
{"zoneRedundant":true}
```

Both compile without a word. The first names the image `DOCKER:shopregistry.azurecr.io/shop:1.0`,
which is no runtime App Service knows. The second is worse, because the template that comes out is
valid and means something else: the REST API's own description of `reserved` is *true if Linux app
service plan, false otherwise*, and its default is false. **Without `reserved: true` the plan is a
Windows plan**, and `kind: 'linux'` on its own does not make it otherwise. The CLI goes the other
way, `--is-linux` defaults to true, so a plan made by hand and a plan made from a file missing one
line are different machines.

The CLI's command for the app takes the image directly:

```
ana@laptop:~/azure$ az webapp create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(container-image-name|runtime) '
 --container-image-name -c : The container custom image name and optionally the tag name (e.g., `<registry- name>/<image-name>:<tag>`). Note: if --container-registry-url is also provided, use `<image-name>:<tag>` without the registry name. 
 --runtime -r : Canonicalized web runtime in the format of Framework:Version, e.g. "PYTHON:3.14".Use `az webapp list-runtimes` for available list. 
```

None of these was run against Azure. Creating the plan from the file would be
`az deployment group create --resource-group shop --template-file shop-web.bicep`, which needs a
subscription, and this course has none.
