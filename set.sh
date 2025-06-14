# 建立主要的掛載根目錄
sudo mkdir -p /home/Wazuh

# 1. 為 OpenSearch 建立資料目錄
sudo mkdir -p /home/Wazuh/opensearch_data

# 2. 為 Wazuh Manager 建立資料目錄 (與上次相同)
sudo mkdir -p /home/Wazuh/manager_etc
sudo mkdir -p /home/Wazuh/manager_logs
sudo mkdir -p /home/Wazuh/manager_queue

# 設定正確的權限，避免容器寫入問題
# OpenSearch 容器使用者 UID/GID 是 1000
# Wazuh Manager 容器使用者 UID/GID 也是 1000
sudo chown -R 1000:1000 /home/Wazuh