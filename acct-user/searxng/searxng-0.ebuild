# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit acct-user

DESCRIPTION="System user for SearXNG"

ACCT_USER_ID=420
ACCT_USER_GROUPS=( "searxng" )
ACCT_USER_HOME=/var/lib/searxng

acct-user_add_deps
