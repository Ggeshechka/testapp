#!/bin/bash
# 1. Запускаем Xray в фоне
sudo ./xray run -c config.json &
sleep 2

# 2. Настраиваем интерфейс
sudo ip addr add 172.19.0.1/30 dev xray0
sudo ip link set dev xray0 up

# 3. Магия маршрутизации
# Создаем правило: весь трафик БЕЗ метки 255 отправлять в таблицу 100
sudo ip rule add not fwmark 255 lookup 100
# В таблице 100 говорим, что путь по умолчанию — через наш TUN
sudo ip route add default dev xray0 table 100

echo "TUN поднят. Для остановки нажмите Ctrl+C"

# Очистка при выходе
trap "sudo ip rule del not fwmark 255 lookup 100; sudo killall xray; echo 'Сеть восстановлена';" SIGINT SIGTERM

wait
