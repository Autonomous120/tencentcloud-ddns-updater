#!/usr/bin/env bash

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

# ========Domain Parameters==============
recordtype='AAAA'

# =======DnsPod API 3.0 Parameters========
signatureMethod='HmacSHA1'
region=ap-guangzhou
url="https://dnspod.tencentcloudapi.com"
version="2021-03-23"

# =======API: DescribeRecordList==========
action='DescribeRecordList'
timestamp=$(date +%s)
nonce=$(head -200 /dev/urandom | cksum | cut -f2 -d" ")

src=$(printf "GETdnspod.tencentcloudapi.com/?Action=%s&Domain=%s&Nonce=%s&RecordType=%s&Region=%s&SecretId=%s&SignatureMethod=%s&Subdomain=%s&Timestamp=%s&Version=%s" $action $domain $nonce $recordtype $region $secretId $signatureMethod $subdomain $timestamp $version)
signature=$(echo -n $src | openssl dgst -sha1 -hmac $secretKey -binary | base64)    # 生成签名串
params=$(printf "Action=%s&Domain=%s&Nonce=%s&RecordType=%s&Region=%s&SecretId=%s&SignatureMethod=%s&Subdomain=%s&Timestamp=%s&Version=%s" $action $domain $nonce $recordtype $region $secretId $signatureMethod $subdomain $timestamp $version)

ret=$(curl -s -G -d "$params" --data-urlencode "Signature=$signature" "$url")
echo $ret
