.DEFAULT_GOAL := help
DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TARGET_DB := $(word 2,$(MAKECMDGOALS))

.PHONY: help dump

help:
	@printf '%s\n' \
		'PostgreSQL 运维管理' \
		'' \
		'用法: make 命令 [参数]' \
		'' \
		'命令列表:' \
		'  make                   显示帮助' \
		'  make dump              备份全部数据库 (pg_dumpall -> backups/pg_all_*.sql.gz)' \
		'  make dump <库名>       备份指定数据库 (pg_dump -> backups/pg_<库名>_*.sql.gz)' \
		''

dump:
	@set -e; \
	if [ -z "$$(docker compose -f "$(DIR)compose.yaml" ps --status running -q postgres 2>/dev/null)" ]; then \
		printf '错误: PostgreSQL (pg) 容器未运行。请先在项目根目录执行 make start pg\n' >&2; \
		exit 1; \
	fi; \
	mkdir -p "$(DIR)backups"; \
	TIMESTAMP=$$(date +%Y%m%d_%H%M%S); \
	if [ -n "$(TARGET_DB)" ] && [ "$(TARGET_DB)" != "all" ]; then \
		FILE="$(DIR)backups/pg_$(TARGET_DB)_$${TIMESTAMP}.sql.gz"; \
		printf '== 正在导出数据库 [%s] 到 %s ==\n' "$(TARGET_DB)" "$$FILE"; \
		docker compose -f "$(DIR)compose.yaml" exec -T -e PGPASSWORD=postgres postgres pg_dump -U postgres -d "$(TARGET_DB)" | gzip > "$$FILE"; \
	else \
		FILE="$(DIR)backups/pg_all_$${TIMESTAMP}.sql.gz"; \
		printf '== 正在导出全部数据库到 %s ==\n' "$$FILE"; \
		docker compose -f "$(DIR)compose.yaml" exec -T -e PGPASSWORD=postgres postgres pg_dumpall -U postgres | gzip > "$$FILE"; \
	fi; \
	SIZE=$$(ls -lh "$$FILE" | awk '{print $$5}'); \
	printf '✓ 备份成功: %s (%s)\n' "$$FILE" "$$SIZE"

$(filter-out help dump,$(MAKECMDGOALS)):
	@:
