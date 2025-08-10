# tencentcloud-ddns-updater
A lightweight DDNS updater using Tencent Cloud API 3.0, with full IPv4 and IPv6 support, automatically updating your Dynamic DNS records to match your current public IP address.

## Features

- Uses **Tencent Cloud API 3.0** for improved security and reliability.  
- Implements an **IP caching mechanism** to minimize API call frequency.

## Usage

1. **Obtain your `secretId` and `secretKey`** from [Tencent Cloud](https://cloud.tencent.com/) and add them to the `.env` file.  
2. **Set your top-level domain** in the `domain` field of each script.  
   > ⚠️ Do **not** enter a subdomain here.  
3. **Retrieve the `recordId`** by running the following scripts once:  
   - `tencent_ddns_get_RecordId_ipv4.sh`  
   - `tencent_ddns_get_RecordId_ipv6.sh`  
   Then, paste the obtained `recordId` into:  
   - `tencent_ddns_ModifyDynamicDNS_ipv4.sh`  
   - `tencent_ddns_ModifyDynamicDNS_ipv6.sh`  
4. **Run the update scripts** to enable automatic DNS updates:  
   - `tencent_ddns_ModifyDynamicDNS_ipv4.sh`  
   - `tencent_ddns_ModifyDynamicDNS_ipv6.sh`
