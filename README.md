# 本机基础组件编排 (DevOps)

基于 Docker Compose 与 Makefile 构建的本地开发环境基础设施编排工具。支持**项目级组件组装**与**单组件原子运维**双模式，提供统一的生命周期管理与本地物理持久化。

---

## 包含组件

| 组件 | 容器名 | 默认端口 | 镜像 | 持久化路径 |
| :--- | :--- | :--- | :--- | :--- |
| **PostgreSQL** | `pg` | `5432` | `paradedb/paradedb:0.25.9-pg18` | `pg/data/` |
| **Redis** | `redis` | `6379` | `redis:7-alpine` | `redis/data/` |
| **LiveKit** | `livekit` | `7880, 7881, 7882/udp` | `livekit/livekit-server:latest` | `./livekit.yaml` 挂载 |

---

## 目录结构

```text
devops/
├── Makefile             # 全局组件与项目生命周期管理
├── projects.mk          # 业务项目组件依赖组装配置
├── .gitignore           # 忽略各组件的 */data/ 与 */backups/
├── pg/
│   ├── compose.yaml     # PostgreSQL 服务编排
│   ├── Makefile         # PostgreSQL 专属备份/恢复运维
│   ├── data/            # 本地物理数据存储目录
│   └── backups/         # 数据库导出备份目录
├── redis/
│   ├── compose.yaml     # Redis 服务编排
│   └── data/            # 本地物理数据存储目录
└── livekit/
    ├── compose.yaml     # LiveKit 服务编排
    └── livekit.yaml     # LiveKit 配置文件
```

---

## 快速使用

### 1. 项目级组装（业务开发推荐）

在 `projects.mk` 中定义项目依赖：
```makefile
PROJECT_aipica  := pg redis
PROJECT_meeting := pg redis livekit
```

通过项目名称批量联动管理依赖组件：
```bash
# 启动项目关联组件并等待就绪
make start aipica

# 查看项目依赖组件状态
make status aipica

# 停止项目关联组件
make stop aipica
```

### 2. 单组件运维（原子操作）

直接对指定组件进行独立操作：
```bash
# 单独启停
make start pg
make stop redis
make restart livekit

# 状态与排障
make status            # 查看全部组件状态
make logs pg           # 查看指定组件最近 100 行日志
```

---

## 数据持久化与备份

所有组件数据均通过 Bind Mount 挂载至宿主机本地物理目录（`pg/data/`、`redis/data/`）。

### PostgreSQL 备份与恢复

进入 `pg/` 目录执行数据库运维：

```bash
cd pg

# 1. 导出数据库 (自动 gzip 压缩，输出至 pg/backups/)
make dump              # 导出全部数据库
make dump aipica       # 导出指定数据库 (如 aipica)
```

**数据恢复**：
```bash
# 恢复全库
gunzip < pg/backups/pg_all_xxxx.sql.gz | docker compose -f pg/compose.yaml exec -T -e PGPASSWORD=postgres postgres psql -U postgres

# 恢复指定库
gunzip < pg/backups/pg_aipica_xxxx.sql.gz | docker compose -f pg/compose.yaml exec -T -e PGPASSWORD=postgres postgres psql -U postgres -d aipica
```

---

## 扩展机制

- **新增组件**：在项目下新建 `<组件名>/compose.yaml`，Makefile 会自动发现并纳入管理。
- **新增项目**：在 `projects.mk` 中追加 `PROJECT_<项目名> := <组件1> <组件2> ...` 即可。
