@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
title 校园网自动登录

:: 配置信息
set "BASE_URL=http://10.160.63.9:801"
set "USERNAME="	:: 学号
set "PASSWORD="	:: 密码
set "OPERATOR="		:: 运行商：keda(校园网) cmcc(中国移动) unicom(中国联通) telecom(中国电信)

echo ==========================
echo  苏科大校园网自动认证脚本
echo ==========================
echo.

:check_network
echo [%time%] 检查网络连通性...
ping -n 1 10.160.63.9 >nul 2>&1
if errorlevel 1 (
    echo [%time%] 校园网认证服务器无法访问，3秒后重试...
    timeout /t 3 /nobreak >nul
    goto :check_network
)
echo [%time%] 网络连接正常.
echo.

:: 获取IP地址
set WLAN_USER_IP=
for /f "tokens=1,2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do (
    set "ip_line=%%b"
    set "ip_line=!ip_line: =!"
    for %%c in (!ip_line!) do (
        echo %%c | findstr "^10\.160\." >nul
        if !errorlevel! equ 0 set "WLAN_USER_IP=%%c"
    )
)
if "!WLAN_USER_IP!"=="" (
    echo [%time%] 警告: 未能自动获取IP，使用默认值
    set "WLAN_USER_IP=10.160.23.239"
)
echo [%time%] 当前IP: !WLAN_USER_IP!
echo.

:: 生成时间戳并构建URL
for /f %%i in ('powershell -Command "Get-Date -UFormat '%%s'"') do set "unix_time=%%i"
set "timestamp=!unix_time!000"

for /f %%i in ('powershell -Command "[int](Get-Date -UFormat '%%s') + 15"') do set "callback_unix=%%i"
set "callback_timestamp=!callback_unix!000"

set "LOGIN_URL=!BASE_URL!/eportal/?c=Portal&a=login&callback=dr!callback_timestamp!&login_method=1&user_account=!USERNAME!@!OPERATOR!&user_password=!PASSWORD!&wlan_user_ip=!WLAN_USER_IP!&wlan_user_mac=000000000000&wlan_ac_ip=221.178.235.146&wlan_ac_name=JSSUZ-MC-CMNET-BRAS-KEDA_ME60X8&jsVersion=3.0&_=!timestamp!"

echo [%time%] 正在登录，请稍候...

:: 使用for循环直接获取curl输出
set "RESPONSE="
for /f "delims=" %%i in ('curl "!LOGIN_URL!" -s 2^>nul') do (
    set "RESPONSE=%%i"
)

if "!RESPONSE!"=="" (
    echo [%time%] *** 请求失败（无响应）*** 
    timeout /t 6 /nobreak >nul
    echo.
    goto :check_network
) else (
    echo [%time%] 服务器响应: !RESPONSE!
    echo.

    echo !RESPONSE! | find "result"":""1" >nul
    if !errorlevel! equ 0 (
        echo [%time%] *** 登录成功 ***
        goto :end
    )

    echo !RESPONSE! | find "ret_code"":""2" >nul
    if !errorlevel! equ 0 (
        echo [%time%] *** 已经在线 ***
        goto :end
    )
    
    echo [%time%] *** 登录失败，6秒后重启脚本... ***
    timeout /t 6 /nobreak >nul
    echo.
    goto :check_network
)

:end
echo.
echo [%time%] 认证成功，脚本完成，按任意键关闭。
pause >nul
