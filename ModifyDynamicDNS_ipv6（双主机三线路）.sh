#!/usr/bin/env bash

# ===========输入外部文件============
script_dir=$(dirname "$0")
env_file="$script_dir/.env"
cache_file="$script_dir/current_ipv6.txt"

# ======检查 .env 文件是否存在并加载=======
if [ -f "$env_file" ]; then
  export $(grep -v '^#' "$env_file" | grep -v '^$' | xargs)
else
  echo ".env 文件不存在"
  exit 1
fi

# ========线路配置==============
subdomains=(
  '******'
  '******'
  '******'
)

recordIds=(
  "************"
  "************"
  "************"
)

recordLines=(
  "**"
  "**"
  "**"
)

# =======DNSPod API 3.0 Parameters========
signatureMethod='HmacSHA1'
region='ap-guangzhou'
url="https://dnspod.tencentcloudapi.com"
version="2021-03-23"

# ========获取当前IPv6====================
ip=$(ip route get 240e:1f:1::1 | awk -F'src ' '{print $2}' | cut -d' ' -f1)

if [[ -z "$ip" ]]; then
    echo "获取IPv6失败"
    exit 1
fi

echo "当前IPv6: $ip"

# ========读取缓存====================
if [[ -f $cache_file ]]; then
    cached_ip=$(cat $cache_file)
else
    cached_ip=""
fi

# ========比较IPv6====================
if [[ "$ip" != "$cached_ip" ]]; then

    total=${#recordIds[@]}

    for ((i=0; i<total; i++)); do

        subdomain="${subdomains[$i]}"
        recordId="${recordIds[$i]}"
        recordLine="${recordLines[$i]}"

        echo "=================================="
        echo "开始更新主机记录：$subdomain ，线路: $recordLine"
        echo "RecordId: $recordId"

        # ========API: ModifyDynamicDNS==========
        action='ModifyDynamicDNS'
        timestamp=$(date +%s)
        nonce=$(head -200 /dev/urandom | cksum | cut -f2 -d" ")

        src=$(printf "GETdnspod.tencentcloudapi.com/?Action=%s&Domain=%s&Nonce=%s&RecordId=%s&RecordLine=%s&Region=%s&SecretId=%s&SignatureMethod=%s&SubDomain=%s&Timestamp=%s&Value=%s&Version=%s" \
            "$action" "$domain" "$nonce" "$recordId" "$recordLine" "$region" "$secretId" "$signatureMethod" "$subdomain" "$timestamp" "$ip" "$version")

        signature=$(echo -n "$src" | openssl dgst -sha1 -hmac "$secretKey" -binary | base64)

        params=$(printf "Action=%s&Domain=%s&Nonce=%s&RecordId=%s&RecordLine=%s&Region=%s&SecretId=%s&SignatureMethod=%s&SubDomain=%s&Timestamp=%s&Value=%s&Version=%s" \
            "$action" "$domain" "$nonce" "$recordId" "$recordLine" "$region" "$secretId" "$signatureMethod" "$subdomain" "$timestamp" "$ip" "$version")

        # =======API请求失败重试机制=======
        retry=3

        while [[ $retry -gt 0 ]]; do

            ret=$(curl -s -G \
                -d "$params" \
                --data-urlencode "Signature=$signature" \
                "$url")

            if echo "$ret" | grep '"RecordId"' > /dev/null; then
                echo "[$recordLine] 更新成功"
                break
            else
                ((retry--))
                echo "[$recordLine] 更新失败，剩余重试次数：$retry"
                echo "$ret"

                if [[ $retry -gt 0 ]]; then
                    sleep 5
                fi
            fi
        done

        if [[ $retry -eq 0 ]]; then
            echo "[$recordLine] 多次尝试后更新失败"
        fi

        # ========避免API调用过快========
        if [[ $i -lt $((total - 1)) ]]; then
            echo "等待30秒后继续..."
            sleep 30
        fi

    done

    # ========全部完成后更新缓存========
    echo "$ip" > "$cache_file"

    echo "=================================="
    echo "全部线路更新完成"

else
    echo "IP未变化，无需更新"
fi