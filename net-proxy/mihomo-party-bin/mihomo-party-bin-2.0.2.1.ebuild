# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg-utils

DESCRIPTION="Mihomo Party GUI client with offline rulesets and auto-update launcher"
HOMEPAGE="https://github.com/mihomo-party-org/mihomo-party"

UPSTREAM_PV="2.0.2"

SRC_URI="
	amd64? (
		https://github.com/mihomo-party-org/mihomo-party/releases/download/v${UPSTREAM_PV}/mihomo-party-linux-${UPSTREAM_PV}-x86_64.rpm -> ${PN}-${UPSTREAM_PV}-x86_64.rpm
		https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/cn.yaml -> ${PN}-${UPSTREAM_PV}-cn_domain.yaml
		https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/cn.yaml -> ${PN}-${UPSTREAM_PV}-cn_ip.yaml
	)
"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="
	app-accessibility/at-spi2-core:2
	dev-libs/nss
	net-print/cups
	x11-libs/gtk+:3
	x11-libs/libnotify
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	net-misc/curl
"
BDEPEND="app-arch/rpm2tar"

S="${WORKDIR}"

src_unpack() {
	rpm2tar -O "${DISTDIR}/${PN}-${UPSTREAM_PV}-x86_64.rpm" | tar -xf -
}

src_install() {
	insinto /opt/clash-party
	doins -r opt/clash-party/*
	fperms +x /opt/clash-party/mihomo-party

	local sidecar_dir="/opt/clash-party/resources/sidecar"
	if [[ -d "${ED}/${sidecar_dir}" ]]; then
		fowners root:root "${sidecar_dir}"/*
		fperms 4755 "${sidecar_dir}"/*
	fi

	insinto /usr/share/mihomo-party/ruleset
	newins "${DISTDIR}/${PN}-${UPSTREAM_PV}-cn_domain.yaml" cn_domain.yaml
	newins "${DISTDIR}/${PN}-${UPSTREAM_PV}-cn_ip.yaml" cn_ip.yaml

	cat <<- 'LAUNCHER' > "${T}/mihomo-party"
		#!/usr/bin/env bash
		set -e

		USER_RULE_DIR="${HOME}/.config/mihomo-party/ruleset"
		SYS_RULE_DIR="/usr/share/mihomo-party/ruleset"
		mkdir -p "${USER_RULE_DIR}"

		[[ ! -f "${USER_RULE_DIR}/cn_domain.yaml" ]] && cp -n "${SYS_RULE_DIR}/cn_domain.yaml" "${USER_RULE_DIR}/" 2>/dev/null || true
		[[ ! -f "${USER_RULE_DIR}/cn_ip.yaml" ]] && cp -n "${SYS_RULE_DIR}/cn_ip.yaml" "${USER_RULE_DIR}/" 2>/dev/null || true

		CN_DOMAIN_URL="https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/cn.yaml"
		CN_IP_URL="https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/cn.yaml"

		update_rule() {
			local url="$1"
			local target="$2"
			local tmp_file="${target}.tmp"
			if curl -s -m 5 -L "${url}" -o "${tmp_file}" && [[ -s "${tmp_file}" ]]; then
				if [[ $(stat -c%s "${tmp_file}") -gt 1024 ]]; then
					mv "${tmp_file}" "${target}"
				else
					rm -f "${tmp_file}"
				fi
			else
				rm -f "${tmp_file}"
			fi
		}

		update_rule "${CN_DOMAIN_URL}" "${USER_RULE_DIR}/cn_domain.yaml" &
		update_rule "${CN_IP_URL}" "${USER_RULE_DIR}/cn_ip.yaml" &

		exec /opt/clash-party/mihomo-party \
			--ozone-platform-hint=auto \
			--enable-features=WaylandWindowDecorations \
			"$@"
	LAUNCHER

	newbin "${T}/mihomo-party" mihomo-party

	if [[ -d usr/share/icons ]]; then
		insinto /usr/share/icons
		doins -r usr/share/icons/*
	fi

	make_desktop_entry "mihomo-party" "Mihomo Party" "clash-party" "Network"
}

pkg_postinst() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}

pkg_postrm() {
	xdg_icon_cache_update
	xdg_desktop_database_update
}
