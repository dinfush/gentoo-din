# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg unpacker

DESCRIPTION="Mihomo Party - another Mihomo GUI with full TUN capability, offline rulesets, and auto-updater"
HOMEPAGE="
	https://mihomo.party
	https://github.com/mihomo-party-org/mihomo-party
"

UPSTREAM_PV="2.0.2"

SRC_URI="
	amd64? (
		https://github.com/mihomo-party-org/mihomo-party/releases/download/v${UPSTREAM_PV}/mihomo-party-linux-${UPSTREAM_PV}-amd64.deb -> ${PN}-${UPSTREAM_PV}-amd64.deb
		https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/cn.yaml -> ${PN}-${UPSTREAM_PV}-cn_domain.yaml
		https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/cn.yaml -> ${PN}-${UPSTREAM_PV}-cn_ip.yaml
	)
"

S="${WORKDIR}"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+tun"

RDEPEND="
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-misc/curl
	net-print/cups
	sys-apps/iproute2
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libxkbcommon
"

RESTRICT="strip"
QA_PREBUILT="*"

src_install() {
	if [[ -d usr/share/applications ]]; then
		domenu usr/share/applications/mihomo-party.desktop
	fi
	if [[ -d usr/share/icons ]]; then
		doicon -s 512 usr/share/icons/hicolor/512x512/apps/mihomo-party.png || true
	fi

	insinto /opt/
	doins -r opt/clash-party

	fperms 4755 /opt/clash-party/chrome-sandbox
	fperms +x /opt/clash-party/chrome_crashpad_handler
	fperms +x /opt/clash-party/mihomo-party
	fperms +x /opt/clash-party/resources/sidecar/mihomo
	fperms +x /opt/clash-party/resources/sidecar/mihomo-alpha
	fperms +x /opt/clash-party/resources/sidecar/mihomo-smart

	if use tun; then
		fperms +s /opt/clash-party/resources/sidecar/mihomo
		fperms +s /opt/clash-party/resources/sidecar/mihomo-alpha
		fperms +s /opt/clash-party/resources/sidecar/mihomo-smart
	fi

	# 1. 部署系统级离线规则底包
	insinto /usr/share/mihomo-party/ruleset
	newins "${DISTDIR}/${PN}-${UPSTREAM_PV}-cn_domain.yaml" cn_domain.yaml
	newins "${DISTDIR}/${PN}-${UPSTREAM_PV}-cn_ip.yaml" cn_ip.yaml

	# 2. 生成带规则分发与异步更新的 /usr/bin/mihomo-party 启动器
	cat <<- 'EOF' > "${T}/mihomo-party"
		#!/usr/bin/env bash
		set -e

		USER_RULE_DIR="${HOME}/.config/mihomo-party/ruleset"
		SYS_RULE_DIR="/usr/share/mihomo-party/ruleset"
		mkdir -p "${USER_RULE_DIR}"

		# 首次运行或规则缺失时，从系统底包拷贝
		[[ ! -f "${USER_RULE_DIR}/cn_domain.yaml" ]] && cp -n "${SYS_RULE_DIR}/cn_domain.yaml" "${USER_RULE_DIR}/" 2>/dev/null || true
		[[ ! -f "${USER_RULE_DIR}/cn_ip.yaml" ]] && cp -n "${SYS_RULE_DIR}/cn_ip.yaml" "${USER_RULE_DIR}/" 2>/dev/null || true

		CN_DOMAIN_URL="https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geosite/cn.yaml"
		CN_IP_URL="https://testingcf.jsdelivr.net/gh/MetaCubeX/meta-rules-dat@meta/geo/geoip/cn.yaml"

		# 后台异步静默拉取更新（5s超时），异常则保留本地已有版本
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
	EOF

	dobin "${T}/mihomo-party"
}

pkg_postinst() {
	xdg_pkg_postinst

	if use tun; then
		elog "TUN 支持已启用（已为 sidecar 内核赋予 SUID 权限）。"
		elog "请确保内核已加载 tun 模块（modprobe tun）。"
	else
		elog "未启用 TUN 支持。如需 TUN 功能，请将 USE=\"tun\" 加入配置并重新编译。"
	fi
}
