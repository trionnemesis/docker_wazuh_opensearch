## 日誌分析與告警系統 (基於 Gemini 與 LangChain)
Wazuh-LangChain：AI 驅動的現代化安全監控平台
本專案旨在建立一個全容器化、易於管理，並具備 AI 互動能力的 Wazuh 安全監控平台。透過 Docker Compose 將 OpenSearch、Wazuh Manager 與 Wazuh Dashboard 整合為單一服務堆疊，並提供一個 Python/LangChain 介面，讓使用者能以自然語言對 Wazuh 系統進行查詢與操作。
```mermaid
graph TD
    subgraph A[主機 Host]
        subgraph B[Docker 環境]
            style B fill:#f9f9f9,stroke:#333,stroke-width:2px

            O[OpenSearch<br>(資料儲存)]
            WM[Wazuh Manager<br>(核心引擎 & API Server)]
            WD[Wazuh Dashboard<br>(Web UI)]

            WM -- 寫入索引/告警 --> O
            WD -- 查詢資料 --> O
            WD -- 呼叫 API --> WM
        end

        subgraph C[AI 代理層 (Python)]
            style C fill:#e6f7ff,stroke:#333,stroke-width:2px

            LC[LangChain Agent]
            SDK[Wazuh Python SDK]
            TOOL[自訂工具<br>(e.g., list_agents)]

            LC -- 使用 --> TOOL
            TOOL -- 呼叫 --> SDK
        end

        subgraph D[資料持久化]
            style D fill:#e6ffe6,stroke:#333,stroke-width:2px
            V[/home/Wazuh]
            O -- 掛載 --> V
            WM -- 掛載 --> V
        end
        
        SDK -- 透過 HTTPS/443 --> WM
    end

    U[使用者] -- 瀏覽器訪問 --> WD
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
