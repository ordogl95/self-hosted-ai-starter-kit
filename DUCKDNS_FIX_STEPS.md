# DuckDNS Certificate Fix - Your Specific Steps

## Your Details
- **Domain**: ordogl95homelab.duckdns.org
- **Token**: fc6a7476-01b7-49fb-83a6-4d1f2ea15714

## The Issue
The Let's Encrypt verification is timing out because DNS TXT records are not propagating fast enough. The default 30-second timeout is insufficient for DuckDNS API.

## Fix - Follow These Steps (5 minutes)

### Step 1: Open NPM Dashboard
1. Open browser and go to: **http://localhost:81**
2. Log in with: 
   - Username: `admin@example.com`
   - Password: `changeme`

### Step 2: Edit Your Certificate
1. Click **SSL Certificates** in the left menu
2. Find your certificate named **"DuckDna"** (or similar)
3. Click the **Edit** button (pencil icon 📝)

### Step 3: Update Propagation Time
1. Look for the **DNS Challenge** or **DNS Settings** section
2. Find the field that says **"DNS Propagation Seconds"** or similar
3. Change the value from `30` to `180` (giving 3 minutes for DNS to propagate)
4. Scroll down and click **Save**

### Step 4: Retry the Certificate
1. After saving, you should see a **"Force Renew"** button
2. Click it to request the certificate again
3. You might see a dialog asking to confirm - click **Yes**

### Step 5: Monitor Progress
Open a terminal and run:
```bash
docker logs npm -f
```

You should see messages like:
```
[SSL] › ℹ  info  Requesting LetsEncrypt certificates via DuckDNS...
[Certbot] › ▶  start  Installing duckdns...
[Certbot] › ☒  complete  Installed duckdns
```

Wait for up to 3 minutes. Success looks like:
```
[Certificate] › ✓ Certificate renewal complete!
```

### Troubleshooting - If It Still Fails

**If you see "Incorrect TXT record" error:**
- Increase to `240` or even `300` seconds
- Try again

**If you see "SERVFAIL" error:**
- This is temporary DNS issue
- Wait 10 minutes and try again

**If you see "TXT update KO" error:**
- Double-check your token at: https://www.duckdns.org/
- Make sure you copied the full token correctly
- Return to NPM and verify it's formatted as: `dns_duckdns_token = fc6a7476-01b7-49fb-83a6-4d1f2ea15714`

### Verification Command

To check if your token is properly saved in NPM (after saving in step 3):
```bash
docker exec npm-db psql -U npm -d npm -c "SELECT nice_name, expires_on FROM certificate ORDER BY id DESC LIMIT 1;"
```

## Expected Result
After completing these steps, you should see:
- ✅ Certificate status shows as "Active" in NPM
- ✅ Certificate expiration date visible (typically 3 months from now)
- ✅ Docker log shows "Certificate renewal complete!"
- ✅ Your domain now has a valid SSL/TLS certificate from Let's Encrypt

## Important Notes
- **DNS propagation in DuckDNS is slow** - this is normal for free DNS services
- The 180-300 second wait gives enough time for the API to update
- If it fails once, trying again in 10 minutes usually works
- Your token `fc6a7476-01b7-49fb-83a6-4d1f2ea15714` should be kept secret!

## Next Steps After Certificate Works
1. Create a proxy host in NPM pointing to your services
2. Assign this DuckDNS certificate to the proxy host
3. Access your services securely via `https://ordogl95homelab.duckdns.org`
