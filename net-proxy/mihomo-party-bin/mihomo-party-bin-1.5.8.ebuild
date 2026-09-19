# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit unpacker xdg fcaps

DESCRIPTION="Mihomo Party with TUN support"
HOMEPAGE="https://github.com/mihomo-party-org/mihomo-party"
SRC_URI="amd64? ( https://github.com/mihomo-party-org/mihomo-party/releases/download/v${PV}/mihomo-party-linux-${PV}-amd64.deb )"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="strip mirror"

RDEPEND="
    x11-libs/gtk+:3
    net-libs/webkit-gtk:4.1
    sys-apps/iproute2
"

S="${WORKDIR}"

FILECAPS=(
    cap_net_admin,cap_net_bind_service+ep opt/mihomo-party/resources/sidecar/mihomo
)

src_unpack() {
    unpack_deb "${A}"
}

src_install() {
    cp -a "${S}/opt" "${ED}/" || die
    cp -a "${S}/usr" "${ED}/" || die
    dodir /usr/bin
    dosym /opt/mihomo-party/mihomo-party /usr/bin/mihomo-party
    rm -rf "${ED}/usr/lib/systemd"
}

pkg_postinst() {
    xdg_pkg_postinst
    fcaps_pkg_postinst
    elog "Mihomo 内核已具备 cap_net_admin 权能，可直接在客户端界面开启 TUN。"
}
