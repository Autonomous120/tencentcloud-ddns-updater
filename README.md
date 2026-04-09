# tencentcloud-ddns-updater
A lightweight DDNS updater using Tencent Cloud API 3.0, with full IPv4 and IPv6 support, automatically updating your Dynamic DNS records to match your current public IP address.

## Features

- Uses **Tencent Cloud API 3.0** for improved security and reliability.  
- Implements an **IP caching mechanism** to minimize API call frequency.

## Usage

1. **Obtain your `secretId` and `secretKey`** from [Tencent Cloud](https://cloud.tencent.com/) and add them to the `.env` file.  
2. **Set your top-level domain** in the `domain` to the `.env` file.  
   > ⚠️ Do **not** enter a subdomain here.  
3. **Retrieve the `recordId`** by running the following scripts once:  
   - `GetRecordId_ipv4.sh`  
   - `GetRecordId_ipv6.sh`  
   Then, paste the obtained `recordId` into `.env` file  
4. **Run the update scripts** to enable automatic DNS updates:  
   - `ModifyDynamicDNS_ipv4.sh`  
   - `ModifyDynamicDNS_ipv6.sh`
5. **(Optional)** After testing, set up a `cron` job to run the update scripts periodically. For example, to run both scripts every 5 minutes, add the following line to your crontab:

   ```
   */5 * * * * /path/to/ModifyDynamicDNS_ipv4.sh && /path/to/ModifyDynamicDNS_ipv6.sh
   ```
6. **Router-only IPv4 variant**: I also provide a router-specific script `ModifyDynamicDNS_ipv4_Router.sh` which obtains the public IPv4 address by querying your router. This variant is intended **for deployment on routers only** — do not run it on non-router hosts. If your router does not support, use the regular `ModifyDynamicDNS_ipv4.sh` instead.

# tencentcloud-ddns-updater  
一个轻量级的 DDNS 更新脚本，使用腾讯云 API 3.0，支持 IPv4 和 IPv6，自动更新 DDNS 记录以匹配当前公网 IP 地址。

## 功能特点

- 使用 **腾讯云 API 3.0**，提升安全性和稳定性。  
- 实现了 **IP 缓存机制**，减少 API 调用频率。

## 使用方法

1. **从[腾讯云](https://cloud.tencent.com/)获取你的 `secretId` 和 `secretKey`，并填写到 `.env` 文件中。**  
2. **在 `.env` 文件的 `domain` 字段中设置你的顶级域名。**  
   > ⚠️ 请勿填写子域名。  
3. **运行以下脚本一次，获取 `recordId`：**  
   - `GetRecordId_ipv4.sh`  
   - `GetRecordId_ipv6.sh`  
   然后将获取到的 `recordId` 填入 `.env` 文件 
4. **运行更新脚本以完成自动 DNS 更新：**  
   - `ModifyDynamicDNS_ipv4.sh`  
   - `ModifyDynamicDNS_ipv6.sh`  
5. **（可选）** 测试通过后，设置 `cron` 定时任务周期性运行更新脚本。比如每 5 分钟运行一次两个脚本，可在 crontab 中添加以下内容：

   ```
   */5 * * * * /path/to/ModifyDynamicDNS_ipv4.sh && /path/to/ModifyDynamicDNS_ipv6.sh
   ```
6. **仅限路由器使用的 IPv4 版本**：提供了专门针对路由器的脚本 `ModifyDynamicDNS_ipv4_Router.sh`，通过查询路由获取公网 IPv4 地址。该脚本仅适合 **在路由器上部署**，请勿在非路由器设备上运行。如果路由器不支持，请使用 `ModifyDynamicDNS_ipv4.sh` 脚本。
