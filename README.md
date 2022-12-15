# V2Ray
How to Install V2Ray on Linux


This script is completely translated into English. And now you can easily install it.


First, perform upgrades and updates to your VPS:

```
apt-get update -y && apt-get upgrade -y
```


Now we can install curl (if you don't have it already) and download and run the script from GitHub:

```
apt install curl -y
```

```
bash <(curl -Ls https://raw.githubusercontent.com/m9h4s/V2Ray/main/install.sh)
```

Management panel address:
IP:54321


-------------------------------------


To bypass the national internet:

```
apt-get update -y && apt-get upgrade -y
```


Guide:
To bypass the national internet
Put a suitable IP instead of [].

```
sysctl net.ipv4.ip_forward=1
iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination [The IP of the server that wants to act as an intermediary]
iptables -t nat -A PREROUTING -j DNAT --to-destination [IP address of the destination server]
iptables -t nat -A POSTROUTING -j MASQUERADE
```
