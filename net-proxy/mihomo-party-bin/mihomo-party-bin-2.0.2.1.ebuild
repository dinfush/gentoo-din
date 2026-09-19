# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg unpacker

DESCRIPTION="Mihomo Party - Another Clash GUI client"
HOMEPAGE="
	https://mihomo.party
	https://github.com/mihomo-party-org/mihomo-party
"

UPSTREAM_PV="2.0.2"

SRC_URI="https://github.com/mihomo-party-org/mihomo-party/releases/download/v${UPSTREAM_PV}/mihomo-party-linux-${UPSTREAM_PV}-amd64.deb -> ${P}_amd64.deb"

S="${WORKDIR}"
LICENSE="GPL-3"
SLOT="0"
# 固化为稳定版 amd64，无需手动 unmask
KEYWORDS="amd64"
IUSE="+tun"

DEPEND="
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libxkbcommon
"

RDEPEND="${DEPEND}"

RESTRICT="strip"
QA_PREBUILT="*"

src_install() {
	domenu usr/share/applications/mihomo-party.desktop
	doicon -s 512 usr/share/icons/hicolor/512x512/apps/mihomo-party.png
	insinto /opt/
	doins -r opt/clash-party
	fperms +x /opt/clash-party/chrome-sandbox
	fperms +x /opt/clash-party/chrome_crashpad_handler
	fperms +x /opt/clash-party/mihomo-party
	fperms +x /opt/clash-party/resources/sidecar/mihomo
	fperms +x /opt/clash-party/resources/sidecar/mihomo-alpha
	fperms +x /opt/clash-party/resources/sidecar/mihomo-smart

	# TUN SUID 赋权
	if use tun; then
		fperms +s /opt/clash-party/resources/sidecar/mihomo
		fperms +s /opt/clash-party/resources/sidecar/mihomo-alpha
		fperms +s /opt/clash-party/resources/sidecar/mihomo-smart
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	if use tun; then
		elog "TUN 模式已启用（已为 sidecar 内核赋予 SUID 权限）。"
		elog "请确认系统已加载 tun 内核模块: modprobe tun"
	fi
}
