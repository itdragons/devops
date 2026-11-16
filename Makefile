.DEFAULT_GOAL := help
ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
include $(ROOT)projects.mk

COMPONENTS := $(notdir $(patsubst %/,%,$(dir $(wildcard $(ROOT)*/compose.yaml))))
PROJECTS := $(patsubst PROJECT_%,%,$(filter PROJECT_%,$(.VARIABLES)))
ACTIONS := start stop restart status logs
ACTION := $(or $(firstword $(MAKECMDGOALS)),$(.DEFAULT_GOAL))
NAME := $(word 2,$(MAKECMDGOALS))
SELECTED := $(if $(NAME),$(if $(filter $(NAME),$(COMPONENTS)),$(NAME),$(PROJECT_$(NAME))),$(COMPONENTS))
COMPOSE_start := up -d --wait
COMPOSE_stop := stop
COMPOSE_restart := restart
COMPOSE_status := ps -a
COMPOSE_logs := logs --tail 100

ifneq ($(filter $(ACTIONS) help,$(COMPONENTS) $(PROJECTS)),)
$(error Component and project names must not match action names)
endif
ifneq ($(filter $(COMPONENTS),$(PROJECTS)),)
$(error Component and project names must be distinct)
endif
$(foreach project,$(PROJECTS),$(if $(strip $(PROJECT_$(project))),,$(error Empty project: $(project))))
$(foreach project,$(PROJECTS),$(if $(filter-out $(COMPONENTS),$(PROJECT_$(project))),$(error Unknown components in $(project): $(filter-out $(COMPONENTS),$(PROJECT_$(project))))))

ifeq ($(filter $(ACTION),$(ACTIONS) help),)
$(error Unknown action: $(ACTION). Run make help)
endif
ifneq ($(word 3,$(MAKECMDGOALS)),)
$(error Usage: make ACTION [COMPONENT|PROJECT])
endif
ifneq ($(NAME),)
ifeq ($(filter $(NAME),$(COMPONENTS) $(PROJECTS)),)
$(error Unknown component or project: $(NAME). Run make help)
endif
ifeq ($(ACTION),help)
$(error Usage: make help)
endif
else
ifeq ($(filter $(ACTION),status help),)
$(error Specify a component or project: make $(ACTION) <组件名或项目名>)
endif
endif

.PHONY: help $(ACTIONS) $(COMPONENTS) $(PROJECTS)

help:
	@printf '%s\n' \
		'本机基础组件管理' \
		'' \
		'用法: make 操作 [项目名或组件名]' \
		'' \
		'常用命令:' \
		'  make                   显示帮助' \
		'  make status            查看全部组件状态' \
		'  make status <项目名>    查看项目所需组件状态 (如 make status aipica)' \
		'' \
		'按项目操作 (仅管理该项目依赖的组件):' \
		'  make start <项目名>    启动该项目所需组件 (如 make start aipica)' \
		'  make stop <项目名>     停止该项目所需组件' \
		'' \
		'按单个组件操作:' \
		'  make start pg          启动 PostgreSQL' \
		'  make stop redis        停止 Redis' \
		'  make restart livekit   重启 LiveKit' \
		'  make logs redis        查看最近 100 行日志' \
		'' \
		'可用组件: $(COMPONENTS)' \
		'' \
		'可用项目:'
	@$(foreach project,$(sort $(PROJECTS)),printf '  %s: %s\n' '$(project)' '$(PROJECT_$(project))';)
	@printf '%s\n' \
		'' \
		'扩展方式:' \
		'  新增组件: 添加 组件名/compose.yaml，设置固定的 Compose 项目名' \
		'  新增项目: 在 projects.mk 添加 PROJECT_项目名 := 组件1 组件2' \
		'' \
		'注意: 停止或重启组件会影响所有使用它的项目。'

$(ACTIONS):
	@set -e; for component in $(SELECTED); do \
		printf '== %s ==\n' "$$component"; \
		COMPOSE_IGNORE_ORPHANS=1 docker compose -f "$(ROOT)$$component/compose.yaml" $(COMPOSE_$@); \
	done

$(COMPONENTS) $(PROJECTS):
	@:
