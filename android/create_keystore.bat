@echo off
chcp 65001 >nul
setlocal

echo ========================================
echo   生成 Google Play 上传用发布版密钥库
echo   仅需执行一次，请妥善保管密钥和密码
echo ========================================
echo.

cd /d "%~dp0"

if exist "upload-keystore.jks" (
    echo [提示] 已存在 upload-keystore.jks，请勿重复生成。
    echo        如需重新生成，请先备份后删除该文件再运行本脚本。
    echo.
    pause
    exit /b 0
)

echo 接下来会依次要求输入以下内容，请牢记您设置的密码：
echo.
echo   1. 密钥库口令 - 输入两次，输入时不会显示属正常
echo   2. 密钥口令 - 可直接回车表示与密钥库口令相同
echo   3. 姓名、组织、城市等 - 可随意填写
echo   4. 最后问是否正确时，输入 y 并回车
echo.
echo ----------------------------------------
echo 下方若为英文或乱码，按顺序输入即可：
echo   Enter keystore password = 密钥库密码
echo   Re-enter new password = 再输一遍
echo   key password = 密钥密码或直接回车
echo   What is your first and last name = 姓名
echo   What is the name of your organizational unit = 单位，可填 a
echo   What is the name of your organization = 组织，可填 a
echo   What is the name of your City = 城市，可填 a
echo   What is the name of your State = 省份，可填 a
echo   What is the two-letter country code = 国家代码，填 CN
echo   Is CN, a, a, a, a correct - 输入 y
echo ----------------------------------------
echo.

set JAVA_TOOL_OPTIONS=-Duser.language=zh -Duser.country=CN
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

if exist "upload-keystore.jks" (
    echo.
    echo ----------------------------------------
    echo [完成] 已生成 upload-keystore.jks
    echo.
    echo 请按以下步骤继续：
    echo   1. 将本目录下的 key.properties.example 复制并重命名为 key.properties
    echo   2. 用记事本打开 key.properties，填写 storePassword 和 keyPassword 为刚才设的密码
    echo      keyAlias=upload   storeFile=../upload-keystore.jks
    echo   3. 在项目根目录执行 flutter build appbundle --release
    echo   4. 将 build\app\outputs\bundle\release\app-release.aab 上传到 Google Play
    echo.
    echo 重要：务必备份 upload-keystore.jks 并牢记密码，丢失将无法更新应用
) else (
    echo.
    echo [失败] 未成功生成密钥库，请检查 JDK 环境变量后重试
)

echo.
pause
