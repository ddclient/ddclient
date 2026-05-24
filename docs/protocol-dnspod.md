# DNSPod Dynamic DNS Setup

DNSPod is a DNS service operated by Tencent Cloud. It has an international
instance at [dnspod.com](https://www.dnspod.com/) and a domestic (China)
instance at [dnspod.cn](https://www.dnspod.cn/).

The API is documented at <https://docs.dnspod.com/api/>.

---

## Prerequisites

1. A DNSPod account with your domain already configured.
2. At least one existing **A** record (for IPv4) and/or **AAAA** record (for
   IPv6) for the hostname you want to update. ddclient will update an existing
   record — it will not create one for you.

---

## Step 1 — Create an API Token

1. Log in to the DNSPod console:
   - International: <https://console.dnspod.com/account/token>
   - China: <https://console.dnspod.cn/account/token>
2. Click **Create Token**, give it a name, and confirm.
3. Copy both values that are displayed:
   - **Token ID** — a numeric ID (e.g. `123456`)
   - **Token** — a long alphanumeric string

> **Important:** The Token is only shown once. Save it somewhere safe before
> closing the dialog.

---

## Step 2 — Configure ddclient

Add a block like the following to your `ddclient.conf`:

```
protocol=dnspod,
login=<Token ID>,
password=<Token>,
zone=example.com,
myhost.example.com
```

| Option     | Required | Description |
|------------|----------|-------------|
| `login`    | Yes      | Your DNSPod API Token ID |
| `password` | Yes      | Your DNSPod API Token value |
| `zone`     | No       | The root domain (e.g. `example.com`). If omitted, ddclient splits the hostname on the first dot: `myhost.example.com` → subdomain `myhost`, zone `example.com`. Set this explicitly when the zone has more than two labels (e.g. `host.sub.example.com` in zone `example.com`). |
| `server`   | No       | API endpoint. Defaults to `api.dnspod.com` (international). Use `dnsapi.cn` for the China instance. |

### Minimal example (IPv4 only)

```
protocol=dnspod,
login=123456,
password=abc123yourtokenvalue,
zone=example.com,
myhost.example.com
```

### Dual-stack example (IPv4 and IPv6)

```
usev4=webv4
usev6=webv6

protocol=dnspod,
login=123456,
password=abc123yourtokenvalue,
zone=example.com,
myhost.example.com
```

### Multiple hostnames in the same zone

```
protocol=dnspod,
login=123456,
password=abc123yourtokenvalue,
zone=example.com,
host1.example.com, host2.example.com
```

### China instance

```
protocol=dnspod,
login=123456,
password=abc123yourtokenvalue,
server=dnsapi.cn,
zone=example.com,
myhost.example.com
```

---

## Step 3 — Test the configuration

Run ddclient in foreground mode to confirm everything works before deploying:

```sh
ddclient -foreground -verbose -noquiet -debug -file /etc/ddclient/ddclient.conf
```

A successful update produces output like:

```
SUCCESS: myhost.example.com -- Updated successfully to 203.0.113.1.
```

If the record is already set to the correct IP, force an update to confirm
end-to-end connectivity:

```sh
ddclient -foreground -verbose -noquiet -debug -force -file /etc/ddclient/ddclient.conf
```

---

## Troubleshooting

| Symptom | Likely cause |
|---------|--------------|
| `Record.List: login failed` | Token ID or Token value is wrong. Double-check both fields. |
| `no A record found for host.example.com` | The A record doesn't exist yet in DNSPod. Create it manually first. |
| `hostname 'x' does not end with zone 'y'` | The `zone` value doesn't match the hostname. Verify the zone setting. |
| `Record.Ddns: ...` error | The update API call failed. Check the error message and the DNSPod status page. |
