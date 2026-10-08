# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="System user for the MCP Gateway"

ACCT_USER_ID=421
ACCT_USER_GROUPS=( "mcp-gateway" )
ACCT_USER_HOME=/var/lib/mcp-gateway
ACCT_USER_HOME_OWNER="mcp-gateway:mcp-gateway"
ACCT_USER_SHELL=/sbin/nologin
ACCT_USER_NO_MODIFY=1

acct-user_add_deps
