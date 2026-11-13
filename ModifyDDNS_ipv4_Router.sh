#!/usr/bin/env bash
# =======================================
# 此脚本通过查询路由的方式获取公网IPv4地址，只能在路由器部署

# ===========输入外部文件============
script_dir=$(dirname "$0")		# 获取当前脚本所在的目录
env_file="$script_dir/.env"		# 定义.env 文件的相对路径

# ======检查 .env 文件是否存在并加载=======
if [ -f "$env_file" ]; then
  # 加载非空行且不包含注释的行（忽略以#开头的行）
  export $(grep -v '^#' "$env_file" | grep -v '^$' | xargs)
else
  echo ".env 文件不存在"
  exit 1
fi

# =======TencentCloud API 3.0 Parameters========
signatureMethod='HmacSHA1'
timestamp=$(date +%s)
nonce=$(head -200 /dev/urandom | cksum | cut -f2 -d" ")
region=ap-guangzhou
url="https://dnspod.tencentcloudapi.com"
version="2021-03-23"

# Function to check if IP is private (RFC 1918)
is_private_ip() {
    local ip=$1
    if [[ $ip =~ ^192\.168\. || $ip =~ ^10\. || $ip =~ ^172\.1[6-9]\. || $ip =~ ^172\.2[0-9]\. || $ip =~ ^172\.3[0-1]\. ]]; then
        return 0 # It's a private IP
    else
        return 1 # It's not a private IP
    fi
}

# ===========API: DescribeRecord==========
ip=$(ip route get 223.5.5.5 | awk -F'src ' '{print $2}' | cut -d' ' -f1)        #获取本机公网IPv4地址（通过访问223.5.5.5获取路由）

# Check if IP is private, wait 1 minute if it is
if is_private_ip "$ip"; then
    echo "Detected private IP: $ip. Waiting 1 minute before retrying."
    sleep 60
    ip=$(ip route get 223.5.5.5 | awk -F'src ' '{print $2}' | cut -d' ' -f1)
fi

action='DescribeRecord'
src=$(printf "GETdnspod.tencentcloudapi.com/?Action=%s&Domain=%s&Nonce=%s&RecordId=%s&Region=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&Version=%s" $action $domain $nonce $recordId $region $secretId $signatureMethod $timestamp $version)
signature=$(echo -n $src | openssl dgst -sha1 -hmac $secretKey -binary | base64)    # 生成签名串
params=$(printf "Action=%s&Domain=%s&Nonce=%s&RecordId=%s&Region=%s&SecretId=%s&SignatureMethod=%s&Timestamp=%s&Version=%s" $action $domain $nonce $recordId $region $secretId $signatureMethod $timestamp $version)

ret=$(curl -s -G -d "$params" --data-urlencode "Signature=$signature" "$url")
echo $ret | grep $ip > /dev/null

# ============API: ModifyDynamicDNS=========
if [[ $? = 0 ]]; then
    echo '无需更新'
else
    action='ModifyDynamicDNS'
    recordLine='默认'

    src=$(printf "GETdnspod.tencentcloudapi.com/?Action=%s&Domain=%s&Nonce=%s&RecordId=%s&RecordLine=%s&Region=%s&SecretId=%s&SignatureMethod=%s&SubDomain=%s&Timestamp=%s&Value=%s&Version=%s" $action $domain $nonce $recordId $recordLine $region $secretId $signatureMethod $subdomain $timestamp $ip $version)
    signature=$(echo -n $src | openssl dgst -sha1 -hmac $secretKey -binary | base64)
    params=$(printf "Action=%s&Domain=%s&Nonce=%s&RecordId=%s&RecordLine=%s&Region=%s&SecretId=%s&SignatureMethod=%s&SubDomain=%s&Timestamp=%s&Value=%s&Version=%s" $action $domain $nonce $recordId $recordLine $region $secretId $signatureMethod $subdomain $timestamp $ip $version)

    ret=$(curl -s -G -d "$params" --data-urlencode "Signature=$signature" "$url")
    echo $ret | grep 'RecordId' > /dev/null

# ==============判断执行结果==============
    if [[ $? = 0 ]]; then
        echo '更新成功'
    else
        echo '更新失败'
        exit 1
    fi
fi
