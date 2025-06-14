# Wazuh-LangChain：AI 驅動的現代化安全監控平台

本專案旨在建立一個全容器化、易於管理，並具備 AI 互動能力的 Wazuh 安全監控平台。透過 Docker Compose 將 OpenSearch、Wazuh Manager 與 Wazuh Dashboard 整合為單一服務堆疊，並提供一個 Python/LangChain 介面，讓使用者能以自然語言對 Wazuh 系統進行查詢與操作。

## 核心架構

整個系統由兩個主要部分組成：**Wazuh 服務堆疊**和 **AI 代理層**，它們透過 Wazuh RESTful API 進行溝通。

### 系統流程圖

```mermaid
graph TD
    subgraph A[主機 Host]
        subgraph B[Docker 環境]
            style B fill:#f9f9f9,stroke:#333,stroke-width:2px

            O[fa:fa-database OpenSearch<br>(資料儲存)]
            WM[fa:fa-cogs Wazuh Manager<br>(核心引擎 & API Server)]
            WD[fa:fa-tachometer-alt Wazuh Dashboard<br>(Web UI)]

            WM -- 寫入索引/告警 --> O
            WD -- 查詢資料 --> O
            WD -- 呼叫 API --> WM
        end

        subgraph C[AI 代理層 (Python)]
            style C fill:#e6f7ff,stroke:#333,stroke-width:2px

            LC[fa:fa-robot LangChain Agent]
            SDK[fa:fa-code Wazuh Python SDK]
            TOOL[fa:fa-wrench 自訂工具<br>(e.g., list_agents)]

            LC -- 使用 --> TOOL
            TOOL -- 呼叫 --> SDK
        end

        subgraph D[資料持久化]
             style D fill:#e6ffe6,stroke:#333,stroke-width:2px
             V[fa:fa-folder-open /home/Wazuh]
             O -- 掛載 --> V
             WM -- 掛載 --> V
        end
        
        SDK -- 透過 HTTPS/443 --> WM
    end

    U[fa:fa-user 使用者] -- 瀏覽器訪問 --> WD
    U -- 自然語言查詢 --> LC

    classDef docker fill:#2496ed,stroke:#000,stroke-width:1px,color:#fff
    classDef python fill:#ffde57,stroke:#000,stroke-width:1px,color:#333
    class O,WM,WD docker
    class LC,SDK,TOOL python
```

✨ 主要特色
一鍵部署: 使用單一 docker-compose.yml 檔案啟動/關閉整個監控平台。
完全容器化: 所有服務（OpenSearch, Wazuh）皆在 Docker 中運行，保持主機環境乾淨。
資料持久化: 重要資料（設定、日誌、索引）皆掛載於主機目錄，安全可靠。
AI 賦能: 內建 LangChain 整合範例，可透過自然語言與系統互動。
高擴充性: 架構清晰，易於增加新功能或與其他系統整合。
🚀 部署指南
請依照以下步驟在您的主機上部署此平台。

1. 前置準備
確保您的主機已安裝最新版本的 Docker 和 Docker Compose。

2. 建立主機目錄與設定權限
所有服務的資料將儲存在 /home/Wazuh。
```
# 建立主要的掛載根目錄
sudo mkdir -p /home/Wazuh

# 為 OpenSearch 和 Wazuh Manager 建立各自的資料目錄
sudo mkdir -p /home/Wazuh/opensearch_data
sudo mkdir -p /home/Wazuh/manager_etc
sudo mkdir -p /home/Wazuh/manager_logs
sudo mkdir -p /home/Wazuh/manager_queue

# 設定正確的擁有者權限 (UID/GID 1000)，避免容器寫入問題
sudo chown -R 1000:1000 /home/Wazuh
```
3. 設定主機核心參數
OpenSearch 需要此設定才能正常啟動。
```
# 臨時設定
sudo sysctl -w vm.max_map_count=262144

# 寫入設定檔，使其永久生效
echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
```
4. 建立 docker-compose.yml
在您的工作目錄中建立 docker-compose.yml 檔案，並貼上以下內容。
```
YAML
version: '3.8'

services:
  opensearch:
    image: opensearchproject/opensearch:2.15.0
    hostname: opensearch
    restart: always
    environment:
      - cluster.name=wazuh-cluster
      - node.name=opensearch-1
      - discovery.type=single-node
      - bootstrap.memory_lock=true
      - "OPENSEARCH_JAVA_OPTS=-Xms1g -Xmx1g"
      - "DISABLE_SECURITY_PLUGIN=false"
      - "OPENSEARCH_SECURITY_ADMIN_PASSWORD=YourSecureAdminPassword!" # 請務必修改此密碼
    ulimits:
      memlock:
        soft: -1
        hard: -1
      nofile:
        soft: 65536
        hard: 65536
    volumes:
      - /home/Wazuh/opensearch_data:/usr/share/opensearch/data
    ports:
      - "9200:9200"
      - "9600:9600"
    networks:
      - wazuh-net
    healthcheck:
      test: ["CMD-SHELL", "curl -s -k -u admin:YourSecureAdminPassword! 'https://localhost:9200/_cluster/health?wait_for_status=yellow&timeout=5s'"]
      interval: 30s
      timeout: 10s
      retries: 5

  wazuh-manager:
    image: wazuh/wazuh-manager:4.7.4
    hostname: wazuh-manager
    restart: always
    depends_on:
      opensearch:
        condition: service_healthy
    environment:
      - INDEXER_URL=https://opensearch:9200
      - INDEXER_USERNAME=admin
      - INDEXER_PASSWORD=YourSecureAdminPassword! # 需與 OpenSearch 密碼一致
      - INDEXER_SSL_VERIFY=false
    ports:
      - "1514:1514/udp"
      - "1515:1515/tcp"
      - "55000:55000/tcp"
    volumes:
      - /home/Wazuh/manager_etc:/var/ossec/etc
      - /home/Wazuh/manager_logs:/var/ossec/logs
      - /home/Wazuh/manager_queue:/var/ossec/queue
    networks:
      - wazuh-net

  wazuh-dashboard:
    image: wazuh/wazuh-dashboard:4.7.4
    hostname: wazuh-dashboard
    restart: always
    depends_on:
      opensearch:
        condition: service_healthy
      wazuh-manager:
        condition: service_started
    environment:
      - OPENSEARCH_HOSTS=["https://opensearch:9200"]
      - WAZUH_API_URL=https://wazuh-manager
      - OPENSEARCH_USERNAME=admin
      - OPENSEARCH_PASSWORD=SecretPassword # 這是 Dashboard 登入密碼，可自訂
      - OPENSEARCH_SSL_VERIFICATIONMODE=none
    ports:
      - "443:5601"
    networks:
      - wazuh-net

networks:
  wazuh-net:
    driver: bridge
```
5. 一鍵啟動
在 docker-compose.yml 所在的目錄下，執行以下指令：
```
docker-compose up -d
```
6. 驗證與訪問
檢查容器狀態: docker-compose ps (應看到三個服務皆為 running/up)
訪問儀表板: 打開瀏覽器，訪問 https://<你的主機IP>。使用您在 wazuh-dashboard 服務中設定的帳號(admin)和密碼(SecretPassword)登入。

3. Python 整合腳本
以下是一個完整的範例，它建立了一個 LangChain 工具來查詢線上中的 Wazuh Agent。
```
import os
from wazuh_api.wazuh_api import WazuhApi
from langchain.tools import Tool
from langchain_openai import ChatOpenAI
from langchain.agents import initialize_agent, AgentType

# --- 1. Wazuh API 連線資訊 ---
WAZUH_MANAGER_URL = "https://localhost"
WAZUH_API_USER = "apiuser"  # 上一步驟建立的使用者
WAZUH_API_PASSWORD = "YourApiUserPassword" # 您為 apiuser 設定的密碼

# --- 2. 封裝 API 功能的 Python 函數 ---
def get_active_wazuh_agents():
    """連接 Wazuh API，獲取所有活躍 agent 的列表。"""
    try:
        wazuh = WazuhApi(url=WAZUH_MANAGER_URL, user=WAZUH_API_USER, 
                         password=WAZUH_API_PASSWORD, verify_ssl=False)
        response = wazuh.get_agents(params={'status': 'active'})
        agents = response.json()['data']['affected_items']
        if not agents:
            return "目前沒有任何活躍的 Wazuh Agent。"
        agent_info = [f"Name: {a['name']}, IP: {a.get('ip', 'N/A')}, Status: {a['status']}" for a in agents]
        return "\n".join(agent_info)
    except Exception as e:
        return f"呼叫 Wazuh API 時發生錯誤: {e}"

# --- 3. 將函數包裝成 LangChain 工具 ---
wazuh_agent_tool = Tool(
    name="get_wazuh_active_agents",
    func=get_active_wazuh_agents,
    description="非常有用！當你需要查詢 Wazuh 中所有活躍的、在線的 Agent (代理程式) 列表時，請務必使用此工具。"
)

# --- 4. 建立並執行 LangChain Agent ---
# 設定您的 OpenAI API Key
# os.environ["OPENAI_API_KEY"] = "sk-..."

tools = [wazuh_agent_tool]
llm = ChatOpenAI(temperature=0, model_name="gpt-4")
agent = initialize_agent(
    tools, llm, agent=AgentType.ZERO_SHOT_REACT_DESCRIPTION, verbose=True
)

# --- 5. 用自然語言提問 ---
question = "幫我看看現在有哪些 Wazuh agents 正在線上?"
response = agent.run(question)
print("\n--- Agent 的最終回答 ---")
print(response)
```
🔭 未來擴充方向
這個平台提供了絕佳的基礎，以下是一些可能的擴充方向：

更精細的 LangChain 工具集:

告警查詢: 建立工具查詢特定時間範圍、嚴重等級或規則 ID 的告警。
get_alerts(timeframe="last_24h", severity="high")
Agent 細節: 建立工具獲取單一 Agent 的詳細資訊（作業系統、版本、上次連線時間等）。
get_agent_details(agent_name="web-server-01")
健康狀態檢查: 建立工具檢查 Wazuh Manager 或 OpenSearch 叢集的健康狀態。
整合主動響應 (Active Response):

開發能觸發 Wazuh 主動響應的工具，例如隔離受感染主機、封鎖惡意 IP。
（高度注意） 這類工具權力極大，需設計嚴格的權限控管與二次確認機制。
自動化報告與通知:

結合排程任務（如 Cron Job），讓 LangChain Agent 定期生成每日/每週資安摘要報告。
將告警結果透過工具整合到 Slack、Microsoft Teams 或 Email，實現即時通知。
與其他系統連動:

票務系統整合: 建立工具，在偵測到嚴重告警時，自動到 Jira 或 Redmine 等系統中建立處理單。
威脅情資平台: 將告警中的 IP 或檔案雜湊值，透過工具送到 VirusTotal 等平台進行交叉比對。
後端服務擴展:

對於大規模部署，可以將 docker-compose.yml 中的 OpenSearch 從單節點模式擴展為多節點叢集，以提升效能與可靠性。
客製化前端介面:

使用 Streamlit 或 Flask 開發一個簡易的 Web UI，讓內部非技術人員也能透過一個聊天視窗，與背後的 Wazuh-LangChain 系統互動，查詢資安狀態。
