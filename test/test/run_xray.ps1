# 1. Автоматический запрос прав Администратора
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath'`""
    exit
}

Write-Host "Запуск Xray-core..." -ForegroundColor Yellow
Start-Process -FilePath ".\xray.exe" -ArgumentList "run", "-c", "config.json" -WindowStyle Hidden

# Даем время на создание интерфейса
Write-Host "Ожидание интерфейса Wintun 'xray0'..." -ForegroundColor Cyan
Start-Sleep -Seconds 3

try {
    # 2. Настройка маршрутов
    $index = (Get-NetAdapter -Name "xray0" -ErrorAction Stop).InterfaceIndex
    
    # Получаем IP сервера и шлюз
    $serverIp = [System.Net.Dns]::GetHostAddresses("de.safelane.pro")[0].IPAddressToString
    $gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Sort-Object RouteMetric | Select-Object -First 1).NextHop
    
    Write-Host "Направляем IP сервера ($serverIp) мимо туннеля через ($gateway)..." -ForegroundColor DarkGray
    route add $serverIp mask 255.255.255.255 $gateway metric 1
    
    Write-Host "Заворачиваем весь остальной трафик в TUN (Индекс: $index)..." -ForegroundColor DarkGray
    route add 0.0.0.0 mask 0.0.0.0 0.0.0.0 IF $index metric 5
    
    Write-Host "TUN РЕЖИМ АКТИВЕН. Для остановки нажмите любую клавишу..." -ForegroundColor Green
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
    # 3. Очистка при выходе
    route delete $serverIp
    route delete 0.0.0.0 mask 0.0.0.0 0.0.0.0 IF $index

} catch {
    Write-Host "ОШИБКА: Интерфейс xray0 не найден!" -ForegroundColor Red
    Write-Host "Убедитесь, что wintun.dll находится в одной папке с xray.exe" -ForegroundColor Red
    Start-Sleep -Seconds 5
} finally {
    Stop-Process -Name "xray" -Force -ErrorAction SilentlyContinue
    Write-Host "Xray остановлен. Маршруты восстановлены." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
}
