---
title: "EKS Pod Identity: the same result, without the provider"
version: 1
---

IRSA works, and it has a running cost that shows up once there are several clusters. **Each cluster
needs its own IAM OIDC provider, and every role that a workload in several clusters uses needs one
trust statement per cluster.** Move the resizer to a new cluster during an upgrade and somebody has
to edit the trust policy of its role first. A trust policy is also limited in length, 2,048
characters by default, so a role shared by many clusters runs out of room. **EKS Pod Identity**,
which AWS launched at the end of 2023, keeps the outcome and moves the decision: the role trusts one
AWS service, and the link between a service account and a role becomes a record in EKS called an
**association**.

## A role that trusts EKS, once

Here is the whole trust policy of a Pod Identity role. Compare it with `trust.json` two sections
back; what is missing is the point:

```schooling-example
{"language": "json", "file": "pod-trust.json", "parts": [{"code": "{\n  \"Version\": \"2012-10-17\",\n  \"Statement\": [\n    {\n      \"Effect\": \"Allow\",\n      \"Principal\": {\n        \"Service\": \"pods.eks.amazonaws.com\"\n      },\n", "note": "**The principal is a service, not an issuer.** The same file serves every cluster in the account, so a new cluster needs no change here, and no OIDC provider at all."}, {"code": "      \"Action\": [\n        \"sts:AssumeRole\",\n        \"sts:TagSession\"\n      ]\n    }\n  ]\n}\n", "note": "`sts:TagSession` lets EKS stamp each session with the cluster, the namespace and the service account it is for. There is no condition naming a service account: that choice moved to the association."}]}
```

Save it as `~/aws/pod-trust.json`, the notes left out, and create the role. Then ask EKS to associate
it with the service account, which is the call that replaces both the OIDC provider and the
annotation:

```
ana@laptop:~/aws$ aws iam create-role --role-name photos-pod-identity --assume-role-policy-document file://pod-trust.json --query Role.Arn
"arn:aws:iam::123456789012:role/photos-pod-identity"
ana@laptop:~/aws$ aws eks create-pod-identity-association --cluster-name shop --namespace shop --service-account photos --role-arn arn:aws:iam::123456789012:role/photos-pod-identity

aws: [ERROR]: An error occurred (404) when calling the CreatePodIdentityAssociation operation: <!doctype html>
<html lang=en>
<title>404 Not Found</title>
<h1>Not Found</h1>
<p>The requested URL was not found on the server. If you entered the URL manually please check your spelling and try again.</p>
```

**The role is moto's, and the 404 is too: moto 5.2.3 does not implement Pod Identity associations
at all.** The HTML page is its web framework saying it has no route for the request, and on AWS the
same command returns the association, with an id. What follows comes from AWS's documentation and
was not run against EKS. An association names four things: the cluster, the namespace, the service
account and the role. There is nothing to annotate in Kubernetes and nothing to create in IAM per
cluster; a new cluster gets the same role with one more association.

## The agent on every node

The other half lives on the nodes. Pod Identity needs the **EKS Pod Identity Agent**, an EKS add-on
that runs as a DaemonSet, one pod per node on the node's own network, listening on
`169.254.170.23`, port 80. When a pod with an associated service account is created, EKS adds two
variables to its containers, and they point the SDK somewhere new:

- **`AWS_CONTAINER_CREDENTIALS_FULL_URI`**, `http://169.254.170.23/v1/credentials`, the agent;
- **`AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE`**, a service account token for the audience
  `pods.eks.amazonaws.com`, projected into the pod like IRSA's.

The SDK sends a GET to that address with the token in the `Authorization` header. The agent passes
the token to the EKS Auth API, `AssumeRoleForPodIdentity`, which checks it and returns credentials
for the associated role, and the agent hands them back. This is the same container credentials
mechanism ECS has long used to give a task its role, which is why every current SDK already
understands it.

You can watch that conversation on your laptop, with a stand-in for the agent that is small enough
to read. Save it as `~/aws/agent.py`:

```schooling-example
{"language": "python", "file": "agent.py", "parts": [{"code": "import base64\nimport json\nfrom http.server import BaseHTTPRequestHandler, HTTPServer\n\nimport boto3\n\nROLE = 'arn:aws:iam::123456789012:role/photos-pod-identity'\nsts = boto3.client('sts')\n\n\n", "note": "A stand-in for the agent, small enough to read. `boto3` came with moto into the virtual environment, and it finds moto through the same `AWS_ENDPOINT_URL` as the command line."}, {"code": "def claims(token):\n    payload = token.split('.')[1]\n    return json.loads(base64.urlsafe_b64decode(payload + '=='))\n\n\n", "note": "It reads the token's middle part to print who it is for. **It verifies nothing.** The real agent never decodes the token itself: it sends it to the EKS Auth API, which checks the signature."}, {"code": "class Agent(BaseHTTPRequestHandler):\n    def do_GET(self):\n        who = claims(self.headers['Authorization'])\n        print('token for', who['sub'], 'audience', who['aud'][0], flush=True)\n        c = sts.assume_role(RoleArn=ROLE, RoleSessionName='photos-pod')['Credentials']\n", "note": "The SDK in the pod sends the token in the `Authorization` header of a plain GET. The stand-in then assumes the role, which is the step the real agent asks EKS to do on its behalf."}, {"code": "        body = json.dumps({\n            'AccessKeyId': c['AccessKeyId'],\n            'SecretAccessKey': c['SecretAccessKey'],\n            'Token': c['SessionToken'],\n            'Expiration': c['Expiration'].isoformat(),\n        })\n        self.send_response(200)\n        self.send_header('Content-Type', 'application/json')\n        self.end_headers()\n        self.wfile.write(body.encode())\n\n    def log_message(self, *args):\n        pass\n\n\n", "note": "The answer is the JSON every AWS SDK expects from a container credentials endpoint: the three parts of a temporary credential and when it expires. `log_message` only silences the server's own line per request."}, {"code": "HTTPServer(('127.0.0.1', 8099), Agent).serve_forever()\n", "note": "The real agent listens on `169.254.170.23`, port 80, on every node. The stand-in uses a loopback address, which the SDK also accepts, and a port nobody else wants."}]}
```

Run it in a **second terminal**, after the lines every new terminal starts with, as `python3
agent.py`; it prints nothing until somebody asks. Then, in the working terminal, write a token for the
agent's audience, set the two variables the way EKS would, and take the keys away again:

```
ana@laptop:~/aws$ python3 mktoken.py "$ISSUER" pods.eks.amazonaws.com > pod-token
ana@laptop:~/aws$ export AWS_CONTAINER_CREDENTIALS_FULL_URI=http://127.0.0.1:8099/v1/credentials
ana@laptop:~/aws$ export AWS_CONTAINER_AUTHORIZATION_TOKEN_FILE=~/aws/pod-token
ana@laptop:~/aws$ unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
ana@laptop:~/aws$ aws sts get-caller-identity
{
    "UserId": "AROARZPUZDIKDGV27IZWU:photos-pod",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/photos-pod-identity/photos-pod"
}
```

And in the agent's terminal:

```
token for system:serviceaccount:shop:photos audience pods.eks.amazonaws.com
```

The command line found no keys and no web identity variables, saw the container variables, asked
the address they named, and signed its call with what came back. **The application never knew
which of the two mechanisms gave it a role**, and that is why moving a workload from IRSA to Pod
Identity needs no change to its code. The stand-in decodes the token only to print it; the real agent
never trusts its contents, and lets the EKS Auth API verify the signature. Stop it with Ctrl+C, and
in the working terminal unset the two variables and export the test keys again.

## What each one gives you

Pod Identity also tags every session it creates with where it came from: `eks-cluster-name`,
`kubernetes-namespace`, `kubernetes-service-account`, `kubernetes-pod-name` and a few more. A
permission policy can test those tags, so one role can let each namespace read only its own prefix
of a bucket. IRSA has nothing comparable without writing a role per namespace.

| | IRSA | EKS Pod Identity |
| --- | --- | --- |
| trust policy names | the cluster's OIDC issuer and one service account | the service `pods.eks.amazonaws.com` |
| per new cluster | an OIDC provider, and a trust statement in every role | one association per service account |
| link to the service account | an annotation in Kubernetes | an association in EKS |
| on the node | nothing | the Pod Identity Agent add-on |
| session tags | none | cluster, namespace, service account, pod |
| works on Fargate | yes | no |

The last row decides some clusters on its own. **Pods on Fargate cannot use Pod Identity**, because
there is no node of yours to run the agent on, so the Fargate profiles of lesson 12 keep IRSA. Pod
Identity also needs an SDK recent enough to know the container credentials variables, which matters
for an old image nobody rebuilds. Both reach the same place: a role per workload, credentials that
expire, nothing stored. And both still rely on lesson 7's hop limit to keep pods away from the
node's own role, because neither one stops a pod that can reach the instance metadata service from
asking it.
