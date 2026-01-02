# DuckDNS Certificate Setup for Nginx Proxy Manager

## Problem
The DuckDNS DNS validation is failing because the TXT records are not propagating correctly. Certbot is creating the TXT records but Let's Encrypt cannot verify them.

Common reasons:
1. **DNS propagation is too slow** - Default 30 seconds may not be enough
2. **Token authentication issue** - The DuckDNS API may be rejecting the token
3. **Network/firewall issue** - Docker container cannot reach DuckDNS or Let's Encrypt

## Solution

### Step 1: Increase DNS Propagation Time

The key to fixing this is increasing the wait time for DNS propagation to complete.

1. Access NPM Admin Dashboard: http://localhost:81
2. Navigate to: **SSL Certificates**
3. Click your DuckDNS certificate → **Edit**
4. Look for **DNS Settings** or **Propagation Seconds**
5. Change from `30` seconds to `120-180` seconds (2-3 minutes)
6. **Save** the certificate configuration
7. Click **Force Renew** to retry

This gives DuckDNS API more time to update the DNS records before Let's Encrypt verifies them.

### Step 2: Verify Your Token Format in NPM

Make sure your credentials are properly saved:

1. In NPM, go back to your certificate
2. In the **DNS API Credentials** section, paste your token in this format:
   ```
   dns_duckdns_token = fc6a7476-01b7-49fb-83a6-4d1f2ea15714
   ```
   (Replace with your actual token from https://www.duckdns.org/)

3. **Save** and **Force Renew**

### Step 3: Monitor the Logs

Watch the certificate request process:
```bash
docker logs npm -f
```

You should see:
- ✓ DuckDNS plugin installed
- ✓ LetsEncrypt requesting certificates
- ✓ Waiting for DNS propagation
- ✓ Certificate issued (success!)

If it fails, look for error messages about:
- "Incorrect TXT record" - DNS record issue
- "SERVFAIL" - DNS server problem
- "NXDOMAIN" - Domain not found

### Step 4: If Still Failing - Manual DNS Challenge

If automatic DNS validation continues to fail, try manual DNS records:

1. Go to https://www.duckdns.org/ and log in
2. For your domain, create TXT records manually as shown in NPM logs
3. Wait 2-3 minutes for propagation
4. Retry certificate in NPM

### Troubleshooting

**Error: "Incorrect TXT record found"**
- Increase propagation time to 180-300 seconds
- Check that your token is correct at https://www.duckdns.org/
- Try again after 5 minutes

**Error: "TXT update KO could not be set"**
- Your token may be invalid or expired
- Log into https://www.duckdns.org/ and regenerate your token if needed
- Update token in NPM certificate settings

**Error: "DNS problem: SERVFAIL looking up CAA"**
- This is a DNS infrastructure issue
- Temporary - just retry the certificate renewal after 10 minutes

**Error: "Some challenges have failed"**
- Wait 5 minutes and click "Force Renew" again
- Increase propagation time further (try 300 seconds)
- Verify domain is active at https://www.duckdns.org/

## Quick Fix Command

If you want to fix it immediately via command line:

```bash
docker exec npm bash -c 'mkdir -p /etc/letsencrypt/credentials && echo "dns_duckdns_token = YOUR_DUCKDNS_TOKEN" > /etc/letsencrypt/credentials/credentials-13 && chmod 600 /etc/letsencrypt/credentials/credentials-13'
```

Replace `YOUR_DUCKDNS_TOKEN` with your actual DuckDNS token from https://www.duckdns.org/

## Notes

- The token should be your DuckDNS account token, NOT your domain name
- Domain: `ordogl95homelab.duckdns.org`
- Token: The long alphanumeric string from your DuckDNS account dashboard
- Credentials files are numbered (credentials-11, credentials-12, etc.) - use the latest number from NPM logs
