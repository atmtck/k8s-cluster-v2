#!/bin/sh

hosts='
hbox1.atmtc.eu 10.90.0.1/28 10.244.1.0/24
hbox2.atmtc.eu 10.90.0.2/28 10.244.2.0/24
hbox3.atmtc.eu 10.90.0.3/28 10.244.3.0/24
'
port='51820'
mtu='1412'
tmp_file="tmp.txt"

presharedkey=$( wg genkey )

printf "%s" "$hosts" | tail -n +2 | while IFS='' read line;do
    hostname=$( echo "$line" | cut -d ' ' -f 1 )
    ip=$( echo "$line" | cut -d ' ' -f 2 )
    privkey=$( wg genkey )
    pubkey=$( echo $privkey | wg pubkey )
    echo "$line $privkey $pubkey" >> $tmp_file
done

cat $tmp_file | while read host; do
    outdir="$( echo "$host" | cut -d '.' -f 1 )"
    outfile="$outdir/wg0.conf"
    ip=$( echo "$host" | cut -d ' ' -f 2 | cut -d '/' -f 1 )
    mask=$( echo "$host" | cut -d ' ' -f 2 | cut -d '/' -f 2 )
    privkey=$( echo "$host" | cut -d ' ' -f 4 )

    mkdir -p $outdir

    > $outfile
    echo "[Interface]" >> $outfile
    echo "PrivateKey = $privkey" >> $outfile
    echo "Address = $ip/$mask" >> $outfile
    echo "MTU = $mtu" >> $outfile
    echo "ListenPort = $port" >> $outfile
    echo "Table = off" >> $outfile

    cat $tmp_file | while read peer_host; do
        if [ "$host" != "$peer_host" ]; then
            hostname=$( echo "$peer_host" | cut -d ' ' -f 1 )
            ip=$( echo "$peer_host" | cut -d ' ' -f 2 | cut -d '/' -f 1 )
            pod_network=$( echo "$peer_host" | cut -d ' ' -f 3)
            pubkey=$( echo "$peer_host" | cut -d ' ' -f 5 )

            echo "" >> $outfile
            echo "[Peer]" >> $outfile
            echo "Endpoint = $hostname:$port" >> $outfile
            echo "PublicKey = $pubkey" >> $outfile
            echo "PresharedKey = $presharedkey" >> $outfile
            echo "AllowedIPs = $ip/32,$pod_network" >> $outfile
        fi
    done
done

rm $tmp_file
