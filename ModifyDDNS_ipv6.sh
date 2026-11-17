#!/usr/bin/env bash

# ===========输入外部文件============
script_dir=$(dirname "$0")		# 获取当前脚本所在的目录
env_file="$script_dir/.env"		# 定义.env 文件的相对路径
cache_file="$script_dir/current_ipv6.txt"		# 定义IP缓存文件的相对路径

# ======检查 .env 文件是否存在并加载=======
if [ -f "$env_file" ]; then
  # 加载非空行且不包含注释的行（忽略以#开头的行）
  export $(grep -v '^#' "$env_file" | grep -v '^$' | xargs)
else
  echo ".env 文件不存在"
  exit 1
fi

# ========线路信息==============
subdomain='*****'
recordId='***********'
recordLine='**'

# =======DNSPod API 3.0 Parameters========
signatureMethod='HmacSHA1'
region=ap-guangzhou
url="https://dnspod.tencentcloudapi.com"
version="2021-03-23"

# ========获取并校验IPv6地址====================
# 获取当前路由选择的IPv6源地址
ip=$(ip -6 route get 240e:1f:1::1 2>/dev/null | awk -F'src ' '{print $2}' | awk '{print $1}')

# 只允许全球单播地址（GUA，2000::/3），拒绝 fe80::/10、fc00::/7 等地址
# 2000::/3 对应 IPv6 首段数值范围 0x2000–0x3FFF
if [[ -z "$ip" ]]; then
    echo "未能获取IPv6地址，取消更新"
    exit 1
fi

first_hextet="${ip%%:*}"
if ! [[ "$first_hextet" =~ ^[0-9a-fA-F]{1,4}$ ]]; then
    echo "获取到的IPv6地址格式异常：$ip，取消更新"
    exit 1
fi

first_value=$((16#$first_hextet))
if (( first_value < 0x2000 || first_value > 0x3FFF )); then
    echo "获取到的IPv6地址不是全球单播地址（GUA）：$ip，取消更新"
    exit 1
fi

# 从缓存文件读取之前的IPv6地址
if [[ -f $cache_file ]]; then
    cached_ip=$(cat $cache_file)
else
    cached_ip=""
fi

# 如果本地IP与缓存中的不一致，才进行API调用
if [[ "$ip" != "$cached_ip" ]]; then
     # ========API: ModifyDynamicDNS==========       
		action='ModifyDynamicDNS'
        timestamp=$(date +%s)
        nonce=$(head -200 /dev/urandom | cksum | cut -f2 -d" ")

        src=$(printf "GETdnspod.tencentcloudapi.com/?Action=%s&Domain=%s&Nonce=%s&RecordId=%s&RecordLine=%s&Region=%s&SecretId=%s&SignatureMethod=%s&SubDomain=%s&Timestamp=%s&Value=%s&Version=%s" \
            $action $domain $nonce $recordId $recordLine $region $secretId $signatureMethod $subdomain $timestamp $ip $version)
        signature=$(echo -n $src | openssl dgst -sha1 -hmac $secretKey -binary | base64)
        params=$(printf "Action=%s&Domain=%s&Nonce=%s&RecordId=%s&RecordLine=%s&Region=%s&SecretId=%s&SignatureMethod=%s&SubDomain=%s&Timestamp=%s&Value=%s&Version=%s" \
            $action $domain $nonce $recordId $recordLine $region $secretId $signatureMethod $subdomain $timestamp $ip $version)

        # =======API请求失败重试机制=======
        retry=3
        while [[ $retry -gt 0 ]]; do
            ret=$(curl -s -G -d "$params" --data-urlencode "Signature=$signature" "$url")
            if echo $ret | grep 'RecordId' > /dev/null; then
                echo "$ip" > "$cache_file"  # 更新缓存文件
                echo '更新成功'
                break
            else
                ((retry--))
                echo "更新失败，剩余重试次数：$retry"
                sleep 5  # 等待5秒后重试
            fi
        done

        if [[ $retry -eq 0 ]]; then
            echo '多次尝试后更新失败，退出'
            exit 1
        fi
else
    echo "IP未变化，无需更新"
fi
