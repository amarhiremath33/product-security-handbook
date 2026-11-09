# 06 — Linux Networking

> **Module:** 01 – Linux · **Level:** 🟡 Intermediate → 🔴 Advanced · **Time:** ~3 hours
> **Lab environment:** WSL2 or VM (Docker works for most commands) — see [labs/README.md](../labs/README.md)
> Deep networking theory (OSI, TCP/IP, subnetting) comes in Module 02. This chapter is about **doing networking on Linux**.

---

## Objectives

After this chapter you will be able to:

- Find a machine's IP addresses, interfaces, routes and DNS servers.
- Test connectivity layer by layer: link → IP → DNS → port → application.
- See which ports are open and which process owns them.
- Make HTTP requests and inspect TLS with `curl` and `openssl`.
- Capture and read packets with `tcpdump`.
- Know where network configuration lives on Ubuntu (netplan, systemd-resolved).

---

## The Path of a Request

What happens when you run `curl https://example.com` — and which command checks each step:

```text
 1. Name → IP         DNS lookup               dig example.com · resolvectl query
        │
 2. Which way?        Routing table            ip route get 93.184.215.14
        │
 3. Next hop MAC      ARP / neighbour table    ip neigh
        │
 4. Out the NIC       Interface up, has IP     ip -br addr · ip link
        │
 5. Reach the host    ICMP / path              ping · tracepath · mtr
        │
 6. Open the port     TCP handshake            nc -zv host 443 · curl -v
        │
 7. TLS               Certificate, protocol    openssl s_client
        │
 8. Application       HTTP response            curl -I
```

When something is "down", walk this list from the top. The first step that fails is where the problem is.

---

## 🟢 Interfaces and Addresses

```bash
ip addr                    # all interfaces and IPs (short: ip a)
ip -br addr                # brief, one line per interface
ip -br link                # interfaces and state (UP/DOWN) with MAC
ip -4 addr show dev eth0   # IPv4 only, one interface
hostname -I                # just the IPs
```

Example `ip -br addr`:

```text
lo      UNKNOWN  127.0.0.1/8 ::1/128
eth0    UP       10.0.2.15/24 fe80::a00:27ff:fe4e:66a1/64
docker0 DOWN     172.17.0.1/16
```

| Interface | Meaning |
|---|---|
| `lo` | Loopback — `127.0.0.1`, only reachable from this machine |
| `eth0`, `ens33`, `enp0s3` | Wired NIC (naming depends on hardware) |
| `wlan0`, `wlp2s0` | Wi-Fi |
| `docker0`, `br-*`, `veth*` | Docker bridges and container links |
| `tun0`, `wg0` | VPN tunnels |

`10.0.2.15/24`: the IP is `10.0.2.15`; `/24` means the first 24 bits are the network, so `10.0.2.0–10.0.2.255` is the local subnet.

**Private IP ranges** (not routable on the internet): `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`. Also `127.0.0.0/8` (loopback) and `169.254.0.0/16` (link-local — no DHCP answer, and also the cloud metadata address `169.254.169.254`).

> `ifconfig`, `netstat`, `route` and `arp` are from the old `net-tools` package. Modern replacements: `ip addr`, `ss`, `ip route`, `ip neigh`.

---

## 🟢 Routing

```bash
ip route                         # routing table (short: ip r)
ip route get 8.8.8.8             # which route and interface would be used
```

```text
default via 10.0.2.2 dev eth0 proto dhcp metric 100     ← anything not matched goes to the gateway
10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15   ← local subnet, deliver directly
172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1
```

No `default` route → you can reach the local subnet but not the internet.

### Neighbours (ARP)

```bash
ip neigh            # IP → MAC mapping of devices on your subnet
```

---

## 🟢 Connectivity

```bash
ping -c 4 8.8.8.8              # IP reachability (ICMP) — many firewalls block ping, so no reply ≠ down
ping -c 4 google.com           # also tests DNS
tracepath google.com           # path and hop count (no root needed)
traceroute google.com          # sudo apt install traceroute
mtr google.com                 # live traceroute + packet loss per hop (sudo apt install mtr-tiny)
```

---

## 🟢 DNS

```bash
resolvectl status              # which DNS servers each interface uses (systemd-resolved)
cat /etc/resolv.conf           # on Ubuntu usually points at 127.0.0.53 (the local resolver)
cat /etc/hosts                 # local overrides — checked before DNS
getent hosts example.com       # resolve exactly like applications do (hosts file + DNS)
```

`dig` (from `dnsutils` / `bind9-dnsutils`):

```bash
dig example.com                # A record, full answer
dig +short example.com         # just the IP
dig example.com AAAA           # IPv6
dig example.com MX             # mail servers
dig example.com TXT            # SPF, verification records
dig example.com NS             # authoritative name servers
dig @1.1.1.1 example.com       # ask a specific DNS server
dig -x 8.8.8.8                 # reverse lookup (IP → name)
dig +trace example.com         # follow the delegation from the root servers
```

Order of name resolution is set in `/etc/nsswitch.conf` (`hosts: files dns` → `/etc/hosts` first).

> 🔐 `/etc/hosts` overrides DNS for every program. Malware edits it to redirect banking or update domains; admins edit it and forget. Always check it when "DNS is wrong on just this machine".

---

## 🟡 Ports and Sockets: `ss`

```bash
ss -tulpn                  # listening TCP/UDP ports + process (use sudo to see all processes)
ss -tan                    # all TCP sockets, numeric
ss -tn state established   # active connections
ss -s                      # summary counts
ss -tnp 'dport = :443'     # connections to remote port 443
ss -tlnp 'sport = :22'     # who listens on port 22
```

Flags: `t` TCP · `u` UDP · `l` listening · `p` process · `n` numeric (don't resolve names) · `a` all.

Reading `sudo ss -tlnp`:

```text
State  Recv-Q Send-Q Local Address:Port  Peer Address:Port Process
LISTEN 0      128          0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=812,fd=3))
LISTEN 0      511        127.0.0.1:6379       0.0.0.0:*    users:(("redis-server",pid=901,fd=6))
LISTEN 0      4096              *:8080              *:*    users:(("java",pid=1500,fd=40))
```

| Bind address | Reachable from |
|---|---|
| `127.0.0.1` / `::1` | This machine only ✅ |
| `0.0.0.0` / `*` / `[::]` | **Every** interface — the network, possibly the internet |
| A specific IP | Only via that interface |

> 🔐 A database or admin panel listening on `0.0.0.0` is one of the most common real-world exposures. Redis, Elasticsearch, MongoDB, Docker API (`2375`) and Kubernetes kubelet (`10250`) exposed this way have caused many breaches.

### Common ports

| Port | Service | Port | Service |
|---|---|---|---|
| 22 | SSH | 443 | HTTPS |
| 25 | SMTP | 3306 | MySQL |
| 53 | DNS | 5432 | PostgreSQL |
| 80 | HTTP | 6379 | Redis |
| 123 | NTP (UDP) | 8080/8443 | Alt HTTP/HTTPS |
| 2375/2376 | Docker API | 6443 | Kubernetes API |
| 9200 | Elasticsearch | 27017 | MongoDB |

Full list: `less /etc/services`.

---

## 🟡 Testing Ports and Applications

```bash
nc -zv example.com 443          # is the TCP port open? (netcat)
nc -zv -w2 10.0.0.5 20-25       # scan a small range
timeout 2 bash -c '</dev/tcp/example.com/443' && echo open   # no tools needed

curl -I https://example.com                 # response headers only
curl -v https://example.com -o /dev/null    # full detail: DNS, TCP, TLS, request, response
curl -sS -L https://example.com             # silent, show errors, follow redirects
curl -X POST -H 'Content-Type: application/json' -d '{"a":1}' https://httpbin.org/post
curl -w '%{http_code} %{time_total}s\n' -o /dev/null -s https://example.com   # status + timing
curl --resolve example.com:443:1.2.3.4 https://example.com   # test a specific server IP
wget https://example.com/file.tar.gz        # download a file
```

### TLS inspection

```bash
openssl s_client -connect example.com:443 -servername example.com </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates      # who issued it, when it expires

curl -vI https://example.com 2>&1 | grep -E 'SSL connection|subject|expire'
```

---

## 🔴 Packet Capture: `tcpdump`

```bash
sudo tcpdump -D                              # list interfaces
sudo tcpdump -i any -n port 53               # watch DNS queries
sudo tcpdump -i eth0 -n host 10.0.0.5        # traffic to/from one host
sudo tcpdump -i eth0 -n 'tcp port 80' -A     # print HTTP payloads as ASCII
sudo tcpdump -i any -n 'tcp[tcpflags] & tcp-syn != 0'   # new TCP connections (SYN packets)
sudo tcpdump -i any -w capture.pcap          # save to a file (open in Wireshark)
tcpdump -r capture.pcap -n | head            # read a capture
```

Flags: `-n` no name resolution · `-i` interface · `-c 100` stop after 100 packets · `-A` ASCII · `-X` hex + ASCII · `-w`/`-r` write/read file.

> 🔐 Anything sent over plain HTTP, FTP, Telnet, or unencrypted database connections — including passwords and tokens — is visible to anyone who can capture traffic. The lab below proves it.

---

## 🔴 Network Configuration on Ubuntu

| Layer | Tool / file |
|---|---|
| Config files (servers) | `/etc/netplan/*.yaml` → `sudo netplan try` / `sudo netplan apply` |
| Backend | `systemd-networkd` (servers) or `NetworkManager` (desktops: `nmcli`, `nmtui`) |
| DNS resolver | `systemd-resolved` (`resolvectl`) |
| Hostname | `hostnamectl set-hostname web01` |
| Temporary changes | `ip addr add`, `ip route add` — lost at reboot |

Static IP example (`/etc/netplan/01-static.yaml`, `chmod 600`):

```yaml
network:
  version: 2
  ethernets:
    eth0:
      addresses: [192.168.1.50/24]
      routes:
        - to: default
          via: 192.168.1.1
      nameservers:
        addresses: [1.1.1.1, 8.8.8.8]
```

```bash
sudo netplan try        # applies, and rolls back after 120 s unless you confirm — safe over SSH
```

Temporary changes (great for labs, gone after reboot):

```bash
sudo ip addr add 10.99.0.10/24 dev eth0
sudo ip route add 10.98.0.0/24 via 10.99.0.1
sudo ip link set eth0 down / up      # ⚠️ over SSH this disconnects you
```

### Kernel network settings (sysctl)

```bash
sysctl net.ipv4.ip_forward                  # 1 = this machine routes packets (needed for Docker/K8s)
sysctl net.ipv4.conf.all.rp_filter          # reverse-path filtering (anti-spoofing)
sysctl net.ipv4.tcp_syncookies              # SYN flood protection
```

Hardening values are covered in [chapter 12](12-Linux-Security-Hardening.md).

### Firewall (preview)

```bash
sudo ufw status verbose        # Ubuntu's simple firewall front end
sudo nft list ruleset          # the real rules (nftables)
sudo iptables -S               # legacy view
```

Full firewall setup is in [chapter 12](12-Linux-Security-Hardening.md).

---

## In Production — Troubleshooting Flow

"The app can't reach the database at `db.internal:5432`":

```bash
getent hosts db.internal                 # 1. DNS resolves? (and not overridden in /etc/hosts?)
ip route get <db-ip>                     # 2. route exists, right interface?
ping -c 2 <db-ip>                        # 3. host reachable? (may be blocked — not conclusive)
nc -zv <db-ip> 5432                      # 4. port open? "refused" = nothing listening; "timeout" = firewall
# on the DB host:
sudo ss -tlnp 'sport = :5432'            # 5. listening — on 127.0.0.1 only, or 0.0.0.0?
sudo ufw status / sudo nft list ruleset  # 6. host firewall blocking?
# also check cloud security groups / network ACLs
```

**Connection refused** = reached the host, nothing listening (or a REJECT rule).
**Timeout** = packets dropped — firewall, security group or routing.

---

## Product Security Perspective

| Check | Command | Red flag |
|---|---|---|
| What is exposed? | `sudo ss -tulpn` | Databases, admin panels, debug ports on `0.0.0.0` |
| Who is connected? | `sudo ss -tnp state established` | Unknown remote IPs, odd ports (4444, 1337), IRC (6667) |
| Unexpected outbound traffic | `sudo ss -tnp` / `sudo tcpdump -n 'tcp[tcpflags] & tcp-syn != 0'` | Connections to mining pools or unknown hosts — possible C2 |
| DNS tampering | `cat /etc/hosts`, `resolvectl status` | Unknown entries or DNS servers |
| Plain-text protocols | `tcpdump -A` | Credentials visible on the wire |
| IP forwarding on a non-router | `sysctl net.ipv4.ip_forward` | `1` on a host that shouldn't route |
| Cloud metadata access | `curl -s http://169.254.169.254/` from an app container | Reachable from apps → SSRF can steal cloud credentials |

> 🔐 **SSRF and metadata:** if an app fetches user-supplied URLs, an attacker may make it request `http://169.254.169.254/latest/meta-data/iam/security-credentials/` on AWS and steal the instance's IAM credentials (the Capital One breach, 2019). Mitigations: IMDSv2, egress filtering, URL allow-lists.

---

## Hands-on Lab 🟢→🔴

Install the tools:

```bash
sudo apt update && sudo apt install -y iproute2 iputils-ping dnsutils netcat-openbsd curl tcpdump traceroute
```

### Part 1 — Know your machine 🟢

```bash
ip -br addr
ip route
ip route get 1.1.1.1
ip neigh
resolvectl status 2>/dev/null | head -20 || cat /etc/resolv.conf
```

Write down: your IP, subnet, default gateway, DNS server.

### Part 2 — DNS 🟢

```bash
dig +short github.com
dig github.com MX +short
dig @1.1.1.1 +short github.com
dig -x 1.1.1.1 +short
echo "127.0.0.1 example.com" | sudo tee -a /etc/hosts
getent hosts example.com            # → 127.0.0.1 (hosts file wins)
dig +short example.com              # → real IP (dig ignores /etc/hosts!)
sudo sed -i '/127.0.0.1 example.com/d' /etc/hosts
```

### Part 3 — Listening ports and bind addresses 🟡

```bash
python3 -m http.server 8001 --bind 127.0.0.1 >/dev/null 2>&1 &
python3 -m http.server 8002 --bind 0.0.0.0  >/dev/null 2>&1 &
sleep 1
sudo ss -tlnp | grep -E '800[12]'
curl -sI http://127.0.0.1:8001 | head -1
curl -sI http://$(hostname -I | awk '{print $1}'):8001 | head -1   # fails: bound to loopback only
curl -sI http://$(hostname -I | awk '{print $1}'):8002 | head -1   # works: bound to all interfaces
```

Which one would be reachable from the internet if this were a cloud VM with no firewall?

### Part 4 — Refused vs timeout 🟡

```bash
nc -zv -w3 127.0.0.1 8002     # succeeded
nc -zv -w3 127.0.0.1 8009     # refused — nothing listening
nc -zv -w3 10.255.255.1 80    # timeout — nobody answers
```

### Part 5 — Sniff a password over HTTP 🔴

Terminal 1:

```bash
sudo tcpdump -i lo -n -A 'tcp port 8002' | grep -iE 'authorization|password'
```

Terminal 2:

```bash
curl -s -u admin:Sup3rSecret http://127.0.0.1:8002/ >/dev/null
curl -s -d 'username=admin&password=Sup3rSecret' http://127.0.0.1:8002/ >/dev/null
```

Terminal 1 shows the `Authorization: Basic YWRtaW46U3VwM3JTZWNyZXQ=` header and the form body. Decode it:

```bash
echo YWRtaW46U3VwM3JTZWNyZXQ= | base64 -d
```

Basic auth is **encoding, not encryption** — only TLS protects it.

### Part 6 — TLS 🔴

```bash
openssl s_client -connect github.com:443 -servername github.com </dev/null 2>/dev/null \
  | openssl x509 -noout -subject -issuer -dates
curl -sv https://github.com -o /dev/null 2>&1 | grep -E 'SSL connection|ALPN'
curl -sI https://expired.badssl.com     # fails: certificate expired — good, curl protects you
```

Clean up:

```bash
kill %1 %2 2>/dev/null; pkill -f 'http.server 800'
```

**Questions**

1. Why did `getent` and `dig` give different answers in Part 2?
2. What's the security difference between binding to `127.0.0.1` and `0.0.0.0`?
3. What does "refused" tell you that "timeout" doesn't?
4. Why is Basic auth over HTTP equivalent to sending the password in clear text?

---

## Common Mistakes

- Assuming "no ping reply" means the host is down — ICMP is often blocked.
- Testing DNS with `dig` and forgetting `/etc/hosts` (apps use `getent`-style resolution).
- Binding services to `0.0.0.0` by default instead of `127.0.0.1` or a private IP.
- Changing network settings over SSH without a rollback (`netplan try` exists for this).
- Running `tcpdump` without `-n` on a busy system — reverse DNS lookups slow it down and add traffic.
- Forgetting cloud firewalls (security groups) — the host firewall isn't the only one.

---

## Interview Questions

**1. How do you find which process is listening on a port?**
`sudo ss -tlnp 'sport = :PORT'` or `sudo lsof -i :PORT`.

**2. "Connection refused" vs "connection timed out"?**
Refused: the host answered with a TCP RST — nothing listening or a REJECT rule. Timeout: no answer — packets dropped by a firewall, wrong route, or host down.

**3. What's the difference between `0.0.0.0` and `127.0.0.1` as a bind address?**
`127.0.0.1` accepts connections only from the local machine; `0.0.0.0` accepts them on all interfaces.

**4. How does Linux resolve a hostname?**
Following `/etc/nsswitch.conf`, usually `/etc/hosts` first, then DNS via the resolver configured in `/etc/resolv.conf` (often systemd-resolved at `127.0.0.53`).

**5. How would you troubleshoot "can't reach service X"?**
Layer by layer: DNS → route → reachability → port (`nc`) → listener on the server (`ss`) → host firewall → cloud firewall → application logs.

**6. What does `tcpdump -i any -n port 53` show?**
All DNS traffic on all interfaces, without resolving names.

**7. 🔐 What is the cloud metadata service and why is it a target?**
A link-local HTTP endpoint (`169.254.169.254`) that gives instances config and temporary credentials. SSRF vulnerabilities can make an app fetch those credentials for an attacker. Use IMDSv2 and block app access where not needed.

**8. 🔐 How would you detect a reverse shell on a host?**
Look for established outbound connections owned by shells or interpreters (`ss -tnp | grep -E 'bash|sh|python|nc'`), unusual remote ports, and a web-server process with a shell child (`ps -ef --forest`).

---

## Summary

- `ip` shows interfaces, addresses, routes and neighbours; `ss` shows sockets.
- Troubleshoot layer by layer: DNS → route → reachability → port → app.
- Bind address decides exposure; `0.0.0.0` means "everyone who can route to me".
- `curl`, `openssl s_client` and `tcpdump` let you see exactly what's on the wire.
- Plain-text protocols leak credentials; metadata endpoints are high-value targets.

**Next:** [07 — systemd & Services](07-Systemd-and-Services.md)

---

## References

- `man ip`, `man ss`, `man dig`, `man tcpdump`, `man curl`, `man netplan`
- Netplan documentation — https://netplan.readthedocs.io/
- tcpdump filter syntax — `man pcap-filter`
- OWASP SSRF — https://owasp.org/www-community/attacks/Server_Side_Request_Forgery
