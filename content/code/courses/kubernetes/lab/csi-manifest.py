"""Writes the manifest lesson 27 installs: the CSI host-path driver as its
v1.18.0 release deploys it on a cluster of several nodes
(deploy/kubernetes-distributed), trimmed to the driver and two sidecars.

    python3 csi-manifest.py HOSTPATH_DIR PROVISIONER_DIR "VERSIONS" > csi-hostpath.yaml

The pieces are read from the projects' own Go modules: the provisioner's RBAC,
and the driver's CSIDriver object, DaemonSet and StorageClass. What is changed,
and nothing else:
  - every image is the one lab.sh built from source, lab.local/NAME:VERSION
    (the release's distributed manifest still names hostpathplugin v1.17.1;
    the lab runs the v1.18.0 it built);
  - the liveness sidecar is left out, and the driver's liveness probe with it,
    because its image would be one more build and no lesson needs it.
"""
import sys
import yaml

hostpath, provisioner, versions = sys.argv[1:4]
v_hostpath, v_prov, v_reg = versions.split()
IMAGES = {'hostpath': 'lab.local/hostpathplugin:' + v_hostpath,
          'csi-provisioner': 'lab.local/csi-provisioner:' + v_prov,
          'node-driver-registrar': 'lab.local/csi-node-driver-registrar:' + v_reg}

docs = [d for d in yaml.safe_load_all(open(provisioner + '/deploy/kubernetes/rbac.yaml')) if d]
base = hostpath + '/deploy/kubernetes-distributed/hostpath/'
docs.extend(d for d in yaml.safe_load_all(open(base + 'csi-hostpath-driverinfo.yaml')) if d)
for d in yaml.safe_load_all(open(base + 'csi-hostpath-plugin.yaml')):
    if not d:
        continue
    if d['kind'] == 'DaemonSet':
        spec = d['spec']['template']['spec']
        spec['containers'] = [c for c in spec['containers'] if c['name'] in IMAGES]
        for c in spec['containers']:
            c['image'] = IMAGES[c['name']]
            c.pop('livenessProbe', None)
            if c['name'] == 'hostpath':
                c.pop('ports', None)
    docs.append(d)
docs.extend(d for d in yaml.safe_load_all(open(base + 'csi-hostpath-storageclass-fast.yaml')) if d)
print(yaml.safe_dump_all(docs, sort_keys=False), end='')
