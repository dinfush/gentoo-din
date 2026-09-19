# Copyright 2024-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg unpacker

DESCRIPTION="Mihomo Party - another Mihomo GUI with full TUN capability"
HOMEPAGE="
	https://mihomo.party
	https://github.com/mihomo-party-org/mihomo-party
"
SRC_URI="amd64? ( https://github.com/mihomo-party-org/mihomo-party/releases/download/v${PV}/mihomo-party-linux-${PV}-amd64.deb )"

S="${WORKDIR}"
LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+tun"

RDEPEND="
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-print/cups
	x11-libs/gtk+:3
	x11-libs/libdrm
	x11-libs/libxkbcommon
	sys-apps/iproute2
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

	make_wrapper mihomo-party \
		"/opt/clash-party/mihomo-party --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations" \
		"/opt/clash-party"
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
