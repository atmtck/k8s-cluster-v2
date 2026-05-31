#!/bin/sh

nodes='
hbox1.atmtc.eu 10.90.0.1 10.244.1.0/24
hbox2.atmtc.eu 10.90.0.2 10.244.2.0/24
hbox3.atmtc.eu 10.90.0.3 10.244.3.0/24
'

template='
---
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    linuxDataplane: Nftables
    bgp: Enabled
    mtu: 1412
    nodeAddressAutodetectionV4:
      interface: wg0
    ipPools:
      ###ip_pools###
---
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}'

ip_pool_template='
      - cidr: "###pod_network_cidr###"
        blockSize: ###pod_network_mask###
        encapsulation: "None"
        nodeSelector: "kubernetes.io/hostname == '###hostname###'"'

ip_pools=$(
printf "%s" "$nodes" | tail -n +2 | while read -r line; do

    hostname=$( echo "$line" | cut -d ' ' -f 1 )
    pod_network_cidr=$( echo "$line" | cut -d ' ' -f 3 )
    pod_network_mask=$( echo "$pod_network_cidr" | cut -d '/' -f 2 )

    printf "%s\n" "$ip_pool_template" | tail -n +2 | \
      sed "s@###hostname###@$hostname@g" | \
      sed "s@###pod_network_cidr###@$pod_network_cidr@g" | \
      sed "s@###pod_network_mask###@$pod_network_mask@g"
done )

printf "%s" "$template" | tail -n +2 | awk -v pools="$ip_pools" '{
  if ($0 ~ "###ip_pools###") print pools
  else print
}' > calico-deployment.yaml
