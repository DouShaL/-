#!/bin/bash

BASE_URL="http://10.160.63.9:801"
USERNAME=""  # 账户
PASSWORD=""  # 密码
OPERATOR=""  # 运营商 keda/cmcc/unicom/telecom

echo "==========================="
echo " 🍎苏科大校园网自动认证脚本"
echo "=========================== "
echo

# 检查网络
check_network() {
    echo "[$(date +"%T")] 检查网络连通性..."
    ping -c 1 10.160.63.9 >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "[$(date +"%T")] 服务器不可达，3秒后重试..."
        sleep 3
        check_network
    else
        echo "[$(date +"%T")] 网络正常."
        echo
    fi
}

# 获取本机IP
get_ip() {
    WLAN_USER_IP=$(ifconfig | grep "inet " | awk '{print $2}' | grep "^10\.160\." | head -n 1)

    if [[ -z "$WLAN_USER_IP" ]]; then
        echo "[$(date +"%T")] 未找到10.160网段IP，使用默认值"
        WLAN_USER_IP="10.160.23.239"
    fi

    echo "[$(date +"%T")] 当前IP: $WLAN_USER_IP"
    echo
}

# 登录
login() {
    timestamp=$(($(date +%s) * 1000))
    callback_ts=$((($(date +%s) + 15) * 1000))

    LOGIN_URL="$BASE_URL/eportal/?c=Portal&a=login&callback=dr$callback_ts&login_method=1&user_account=${USERNAME}@${OPERATOR}&user_password=$PASSWORD&wlan_user_ip=$WLAN_USER_IP&wlan_user_mac=000000000000&wlan_ac_ip=221.178.235.146&wlan_ac_name=JSSUZ-MC-CMNET-BRAS-KEDA_ME60X8&jsVersion=3.0&_=${timestamp}"

    echo "[$(date +"%T")] 正在登录..."

    RESPONSE=$(curl -s "$LOGIN_URL")

    if [[ -z "$RESPONSE" ]]; then
        echo "[$(date +"%T")] *** 请求失败（无响应）***"
        echo
        sleep 6
        check_network
        login
    else
        echo "[$(date +"%T")] 服务器响应: $RESPONSE"
        echo
    fi

    if echo "$RESPONSE" | grep -q '"result":"1"'; then
        echo "[$(date +"%T")] *** 登录成功 ***"
        exit 0
    fi

    if echo "$RESPONSE" | grep -q '"ret_code":"2"'; then
        echo "[$(date +"%T")] *** 已经在线 ***"
        exit 0
    fi

    echo "[$(date +"%T")] *** 登录失败，6秒后重试... ***"
    sleep 6
    login
}

# 执行流程
check_network
get_ip
login
