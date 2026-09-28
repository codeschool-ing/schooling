#!/usr/bin/env python3
"""The price sheet every number in the cloud course comes from.

AWS publishes its whole price list as JSON, with no account and no key:
https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/index.json names one
"offer" per service, and each offer keeps every version it ever published. This
script reads ONE PINNED VERSION of each offer, for two regions, and prints the
prices the course quotes. Pinned, so that running it next year prints the same
sheet: the prices move, the files they were read from do not.

    python3 prices.py            # the whole sheet
    python3 prices.py lambda     # one block of it

Nothing here needs credentials, and nothing here is a bill. It is a reading of a
published list, taken on the date in each offer's `publicationDate`, and the
course says so wherever it quotes a line. The EC2 files are large (about 290 MB
for sa-east-1 and 480 MB for us-east-1), so they are downloaded once into
~/.cache/cloud-prices and read from there afterwards.

Standard library only: urllib and json.
"""
import json
import os
import sys
import urllib.request

BASE = 'https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws'
CACHE = os.path.expanduser('~/.cache/cloud-prices')
REGIONS = ['sa-east-1', 'us-east-1']
# How each region spells a usage type. us-east-1 is the oldest region and most of
# its usage types carry no prefix at all; a few newer services give it one.
PREFIX = {'sa-east-1': ['SAE1-'], 'us-east-1': ['', 'USE1-']}
VERSION = {
    'AmazonEC2': '20260925174521',
    'AWSLambda': '20260919002359',
    'AmazonS3': '20260926015512',
    'AWSDataTransfer': '20260916132208',
    'AmazonEFS': '20260911124425',
    'AmazonVPC': '20260917190528',
}


def offer(code, region):
    os.makedirs(CACHE, exist_ok=True)
    path = os.path.join(CACHE, f'{code}-{VERSION[code]}-{region}.json')
    if not os.path.exists(path):
        url = f'{BASE}/{code}/{VERSION[code]}/{region}/index.json'
        urllib.request.urlretrieve(url, path + '.part')
        os.rename(path + '.part', path)
    with open(path) as f:
        return json.load(f)


def dims(doc, sku, term='OnDemand'):
    for t in doc['terms'].get(term, {}).get(sku, {}).values():
        for d in t['priceDimensions'].values():
            yield t.get('termAttributes', {}), d


def by_usage(doc, region, usage, first=True):
    """The price of a usage type, in its first tier unless first is False."""
    want = {prefix + usage for prefix in PREFIX[region]}
    found = []
    for sku, p in doc['products'].items():
        if p['attributes'].get('usagetype') in want:
            for _, d in dims(doc, sku):
                found.append((float(d['beginRange']), float(d['pricePerUnit']['USD'])))
    if not found:
        return None
    found.sort()
    return found[0][1] if first else found


def instance(doc, name, reserved=False):
    for sku, p in doc['products'].items():
        a = p['attributes']
        if (a.get('instanceType') == name and a.get('operatingSystem') == 'Linux'
                and a.get('tenancy') == 'Shared' and a.get('preInstalledSw') == 'NA'
                and a.get('capacitystatus') == 'Used'
                and a.get('licenseModel') == 'No License required'):
            if not reserved:
                for _, d in dims(doc, sku):
                    return a, float(d['pricePerUnit']['USD'])
            for ta, d in dims(doc, sku, 'Reserved'):
                if (ta.get('LeaseContractLength') == '1yr' and ta.get('PurchaseOption') == 'No Upfront'
                        and ta.get('OfferingClass') == 'standard'):
                    return a, float(d['pricePerUnit']['USD'])
    return None, None


def row(label, values, fmt='{:.4f}'):
    cells = ''.join(f'{(fmt.format(v) if v is not None else "-"):>13}' for v in values)
    print(f'  {label:<34}{cells}')


def head(title):
    print()
    print(title)


INSTANCES = ['t3.micro', 't4g.small', 't3.medium', 'm7i.large', 'm7g.large', 'c7i.large', 'm7i.xlarge']


def ec2():
    docs = {r: offer('AmazonEC2', r) for r in REGIONS}
    head('EC2, Linux, on demand, USD per hour')
    for name in INSTANCES:
        a, _ = instance(docs[REGIONS[0]], name)
        label = f'{name:<11}{a["vcpu"]:>2} vCPU {a["memory"]:>7}'
        row(label, [instance(docs[r], name)[1] for r in REGIONS], '{:.5f}')
    head('EC2, Linux, 1-year reserved, no upfront, USD per hour')
    for name in INSTANCES:
        row(name, [instance(docs[r], name, reserved=True)[1] for r in REGIONS], '{:.5f}')
    head('EBS, USD per GB-month')
    for usage, label in [('EBS:VolumeUsage.gp3', 'gp3 SSD volume'),
                         ('EBS:VolumeUsage.st1', 'st1 HDD volume'),
                         ('EBS:SnapshotUsage', 'snapshot')]:
        row(label, [by_usage(docs[r], r, usage) for r in REGIONS])
    head('Networking, USD')
    for usage, label in [('NatGateway-Hours', 'NAT gateway, per hour'),
                         ('NatGateway-Bytes', 'NAT gateway, per GB processed'),
                         ('LoadBalancerUsage', 'load balancer (ALB), per hour')]:
        row(label, [by_usage(docs[r], r, usage) for r in REGIONS])
    vpc = {r: offer('AmazonVPC', r) for r in REGIONS}
    row('public IPv4 address, per hour',
        [by_usage(vpc[r], r, 'PublicIPv4:InUseAddress') for r in REGIONS])


def storage():
    s3 = {r: offer('AmazonS3', r) for r in REGIONS}
    head('S3, USD per GB-month (first tier)')
    for usage, label in [('TimedStorage-ByteHrs', 'Standard'),
                         ('TimedStorage-SIA-ByteHrs', 'Standard-Infrequent Access'),
                         ('TimedStorage-GIR-ByteHrs', 'Glacier Instant Retrieval'),
                         ('TimedStorage-GlacierByteHrs', 'Glacier Flexible Retrieval')]:
        row(label, [by_usage(s3[r], r, usage) for r in REGIONS], '{:.5f}')
    head('S3 requests, USD per 1,000')
    for usage, label in [('Requests-Tier1', 'PUT, COPY, POST, LIST'),
                         ('Requests-Tier2', 'GET and the rest')]:
        row(label, [by_usage(s3[r], r, usage) * 1000 for r in REGIONS], '{:.5f}')
    efs = {r: offer('AmazonEFS', r) for r in REGIONS}
    head('EFS, USD per GB-month')
    row('Standard', [by_usage(efs[r], r, 'TimedStorage-ByteHrs') for r in REGIONS])


def transfer():
    dt = {r: offer('AWSDataTransfer', r) for r in REGIONS}
    head('Data transfer, USD per GB')
    # Egress is priced in tiers of monthly volume, and the tiers are the point:
    # the first 10 TB of a month cost more per GB than the next 40.
    tiers = {r: by_usage(dt[r], r, 'DataTransfer-Out-Bytes', first=False) for r in REGIONS}
    names = ['first 10 TB', 'next 40 TB', 'next 100 TB', 'over 150 TB']
    for i, name in enumerate(names):
        row(f'out to the internet, {name}', [tiers[r][i][1] for r in REGIONS])
    row('between zones, each direction',
        [by_usage(dt[r], r, 'DataTransfer-Regional-Bytes') for r in REGIONS])
    row('to the other region',
        [by_usage(dt['sa-east-1'], 'sa-east-1', 'USE1-AWS-Out-Bytes'),
         by_usage(dt['us-east-1'], 'us-east-1', 'USE1-SAE1-AWS-Out-Bytes')])
    row('in from the internet',
        [by_usage(dt[r], r, 'DataTransfer-In-Bytes') for r in REGIONS])


def lam():
    fn = {r: offer('AWSLambda', r) for r in REGIONS}
    head('Lambda, USD')
    row('per 1 million requests',
        [by_usage(fn[r], r, 'Request') * 1_000_000 for r in REGIONS], '{:.2f}')
    row('per GB-second, x86',
        [by_usage(fn[r], r, 'Lambda-GB-Second') for r in REGIONS], '{:.10f}')
    row('per GB-second, Arm',
        [by_usage(fn[r], r, 'Lambda-GB-Second-ARM') for r in REGIONS], '{:.10f}')
    # The free allowance is in the list too, as a price of zero up to a limit.
    free = {r: offer('AWSLambda', r) for r in REGIONS}
    for usage, label in [('Request', 'free tier, requests'),
                         ('Lambda-GB-Second', 'free tier, GB-seconds')]:
        limits = []
        for r in REGIONS:
            limit = None
            for sku, p in free[r]['products'].items():
                if p['attributes'].get('usagetype') == 'Global-' + usage:
                    for _, d in dims(free[r], sku):
                        limit = float(d['endRange'])
            limits.append(limit)
        row(label, limits, '{:,.0f}')


BLOCKS = {'ec2': ec2, 'storage': storage, 'transfer': transfer, 'lambda': lam}


def main():
    wanted = sys.argv[1:] or list(BLOCKS)
    print('AWS public price list, USD, excluding tax')
    for code, version in VERSION.items():
        print(f'  offer {code:<16} version {version}')
    print(f'  {"":<34}' + ''.join(f'{r:>13}' for r in REGIONS))
    for name in wanted:
        BLOCKS[name]()


if __name__ == '__main__':
    main()
