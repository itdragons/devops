# DevOps 本机基础组件管理

本机开发环境基础服务编排工具，基于 Docker Compose 与 Makefile 构建，提供极简的生命周期管理与数据本地持久化。

---

## 包含组件

| 组件 | 容器名 | 默认端口 | 镜像 | 数据持久化路径 |
| :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL** | `pg` | `5432` | `paradedb/paradedb:0.25.9-pg18` | `pg/data/` |
| **Redis** | `redis` | `6379` | `redis:7-alpine` | `redis/data/` |
| **LiveKit** | `livekit` | `7880, 7881, 7882/udp` | `livekit/livekit-server:latest` | `./livekit.yaml` 挂载 |

---

## 目录结构

```text
devops/
├── Makefile             # 全局组件与项目生命周期管理
├── projects.mk          # 项目组合定义（如 PROJECT_dev）
├── .gitignore           # 忽略各组件的 */data/ 与 */backups/
├── pg/
│   ├── compose.yaml     # PostgreSQL 服务配置
│   ├── Makefile         # PostgreSQL 专属备份运维
│   ├── data/            # 数据库本地物理存储目录 (已 Git 忽略)
│   └── backups/         # 数据库备份导出目录 (已 Git 忽略)
├── redis/
│   ├── compose.yaml     # Redis 服务配置
│   └── data/            # Redis 本地物理存储目录 (已 Git 忽略)
└── livekit/
    ├── compose.yaml     # LiveKit 编排配置
    └── livekit.yaml     # LiveKit 配置文件
```

---

## 快速使用

### 1. 全局生命周期管理 (项目根目录)

```bash
# 查看所有可用命令和组件状态
make help

# 启动 dev 项目所需的全部组件（等待就绪/健康检查通过）
make start dev

# 查看全部或指定组件状态
make status
make status dev

# 停止全套组件
make stop dev
```

### 2. 单个组件管理

```bash
# 启动单独组件
make start pg
make start redis
make start livekit

# 查看最近 100 行日志
make logs pg
make logs redis

# 重启组件
make restart livekit

# 停止单独组件
make stop redis
```

---

## 数据持久化与备份（防重装系统数据丢失）

所有组件数据均通过 Bind Mount 挂载到宿主机本地物理目录（如 `pg/data/`、`redis/data/`），**不再依赖 Docker 隐藏的内部卷**。

### 重装系统注意事项
* **重装系统前**：只需将整个 `devops` 文件夹（或其中的 `pg/data`、`redis/data`）拷贝到外置移动硬盘或 U 盘。
* **重装系统后**：拷回原目录，执行 `make start dev` 即可无缝继承原有数据库与缓存。

### PostgreSQL 逻辑备份（双重保险）

进入 `pg/` 目录可使用专有的备份命令：

```bash
cd pg

# 1. 查看帮助
make help

# 2. 导出全部数据库 (自动 gzip 压缩)
make dump
# 产物: pg/backups/pg_all_<时间戳>.sql.gz

# 3. 导出指定数据库
make dump aipica
# 产物: pg/backups/pg_aipica_<时间戳>.sql.gz
```

#### 数据还原命令参考
```bash
# 还原全库
gunzip < pg/backups/pg_all_xxxx.sql.gz | docker compose -f pg/compose.yaml exec -T -e PGPASSWORD=postgres postgres psql -U postgres

# 还原指定数据库
gunzip < pg/backups/pg_aipica_xxxx.sql.gz | docker compose -f pg/compose.yaml exec -T -e PGPASSWORD=postgres postgres psql -U postgres -d aipica
```

---

## 扩展方式

1. **新增基础组件**：在项目下新建 `组件名/compose.yaml`，指定固定的 Compose 服务配置即可自动被 Makefile 发现。
2. **新增项目组合**：在 `projects.mk` 中添加 `PROJECT_项目名 := 组件1 组件2 ...` 即可通过 `make start <项目名>` 一键管理关联组件。
