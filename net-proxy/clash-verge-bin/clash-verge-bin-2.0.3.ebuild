# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg fcaps

DESCRIPTION="Clash Verge Rev with OpenRC & TUN support"
HOMEPAGE="https://github.com/clash-verge-rev/clash-verge-rev"
SRC_URI="amd64? ( https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v${PV}/clash-verge_${PV}_amd64.deb )"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip mirror"

RDEPEND="
    x11-libs/gtk+:3
    net-libs/webkit-gtk:4.1
    x11-libs/libnotify
    dev-libs/libayatana-appindicator
    sys-apps/iproute2
"

S="${WORKDIR}"

FILECAPS=(
    cap_net_admin,cap_net_bind_service+ep usr/bin/clash-verge-service
)

src_unpack() {
    unpack_deb "${A}"
}

src_install() {
    cp -a "${S}/usr" "${ED}/" || die
    newinitd "${FILESDIR}/clash-verge-service.initd" clash-verge-service
    rm -rf "${ED}/usr/lib/systemd"
}

pkg_postinst() {
    xdg_pkg_postinst
    fcaps_pkg_postinst

    elog "若使用 TUN 模式："
    elog "1. 确保内核已启用 CONFIG_TUN=y 或 CONFIG_TUN=m"
    elog "2. 启动 OpenRC 服务："
    elog "   # rc-service clash-verge-service start"
    elog "   # rc-update add clash-verge-service default"
}
