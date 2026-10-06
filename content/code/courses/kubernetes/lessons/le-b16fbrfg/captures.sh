#!/usr/bin/env bash
# The terminal sessions quoted in lesson 6 of kubernetes, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash captures.sh
#
# THIS LESSON RUNS NO CLUSTER AND OPENS NO CLOUD ACCOUNT. It reads two prices
# that the providers publish to anybody:
#   - AWS's price list for EKS, one PINNED version of it, so running this next
#     year prints the same numbers: the prices move, the file does not.
#   - Google's GKE pricing page, which has no versions; what it prints is what
#     the page said on the day of the recording, 6 October 2026.
# Azure's price list (prices.azure.com) and its documentation were refused by
# the recording machine's network, so this lesson quotes no AKS price.
#
# It is the one lesson that needs the internet, so the proxy the recording
# machine reaches it through is passed on here (capture.sh drops it).
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

PROXY=${HTTPS_PROXY:-}
. "$(dirname "$0")/../../capture.sh"
[ -n "$PROXY" ] && export HTTPS_PROXY=$PROXY

block eks
put eks-prices.py <<'CODE'
"""Read the hourly prices of an EKS cluster from one pinned version of AWS's price list."""
import json, urllib.request

VERSION = "20260928194255"
URL = f"https://pricing.us-east-1.amazonaws.com/offers/v1.0/aws/AmazonEKS/{VERSION}/index.json"
WANTED = {"AmazonEKS-Hours:perCluster": "cluster, standard support",
          "AmazonEKS-Hours:extendedSupport": "extended support, added"}

offer = json.load(urllib.request.urlopen(URL))
print("price list published", offer["publicationDate"])
for sku, product in offer["products"].items():
    a = product["attributes"]
    if a.get("regionCode") not in ("us-east-1", "sa-east-1"):
        continue
    usage = a.get("usagetype", "")  # us-east-1 carries no region prefix
    what = next((name for key, name in WANTED.items() if usage.endswith(key)), None)
    if what is None:
        continue
    for term in offer["terms"]["OnDemand"][sku].values():
        for dim in term["priceDimensions"].values():
            print(f'{a["regionCode"]:10} {what:26} USD {float(dim["pricePerUnit"]["USD"]):.2f} per hour')
CODE
run 'python3 eks-prices.py | sort'
block gke
put gke-prices.py <<'CODE'
"""Print the sentences of Google's GKE pricing page that state a cluster's fee."""
import html, re, urllib.request

page = urllib.request.urlopen("https://cloud.google.com/kubernetes-engine/pricing").read().decode()
page = re.sub(r"<(script|style).*?</\1>", "", page, flags=re.S)
text = re.sub(r"\s+", " ", html.unescape(re.sub(r"<[^>]+>", " ", page)))
for sentence in re.split(r"(?<=[.)]) ", text):
    if re.search(r"management fee of|free tier provides|for a total of|for the control plane of", sentence):
        print("-", sentence.strip())
CODE
run 'python3 gke-prices.py'
