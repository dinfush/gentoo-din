# Copyright 2025-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop unpacker xdg systemd

DESCRIPTION="Clash Verge Rev - Continuation of Clash Meta GUI based on Tauri"
HOMEPAGE="https://github.com/clash-verge-rev/clash-verge-rev"

UPSTREAM_PV="2.5.2"

SRC_URI="
	amd64? (
		https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v${UPSTREAM_PV}/Clash.Verge_${UPSTREAM_PV}_amd64.deb -> ${P}_amd64.deb
	)
	arm64? (
		https://github.com/clash-verge-rev/clash-verge-rev/releases/download/v${UPSTREAM_PV}/Clash.Verge_${UPSTREAM_PV}_arm64.deb -> ${P}_arm64.deb
	)
"

S="${WORKDIR}"
LICENSE="GPL-3"
SLOT="0"
# 自用仓库直接设为稳定版关键字，无需再去手动写 package.accept_keywords
KEYWORDS="amd64 arm64"

# 默认启用独立的 SUID tun，默认关闭 systemd
IUSE="+tun systemd"

# 开启 systemd 时互斥禁用独立 SUID tun
REQUIRED_USE="systemd? ( !tun )"

DEPEND="
	dev-libs/libayatana-appindicator
	net-libs/webkit-gtk:4.1
	dev-libs/openssl:0/3
"

RDEPEND="
	${DEPEND}
	systemd? ( sys-apps/systemd )
"

RESTRICT="strip"
QA_PREBUILT="*"

src_install() {
	# 1. 安装二进制执行文件
	exeinto /opt/clash-verge/bin
	doexe "${S}"/usr/bin/*

	# 2. 安装 resources 运行时资源
	insinto /usr/lib/clash-verge
	doins -r "${S}"/usr/lib/Clash\ Verge/resources

	# 3. 桌面启动菜单与图标
	if [[ -f "${FILESDIR}/clash-verge.desktop" ]]; then
		domenu "${FILESDIR}/clash-verge.desktop"
	elif [[ -f "${S}/usr/share/applications/clash-verge.desktop" ]]; then
		domenu "${S}/usr/share/applications/clash-verge.desktop"
	fi

	for size in 32 128 256; do
		local icon_path="${S}/usr/share/icons/hicolor/${size}x${size}/apps/clash-verge.png"
		[[ ! -f "${icon_path}" ]] && icon_path="${S}/usr/share/icons/hicolor/${size}x${size}@2/apps/clash-verge.png"
		[[ -f "${icon_path}" ]] && doicon -s "${size}" "${icon_path}"
	done

	# 4. TUN 与 systemd 分流安装
	if use systemd; then
		# 【systemd 模式】：安装上游守护服务单元，不设 SUID
		if [[ -f "${S}/usr/lib/systemd/system/clash-verge-service.service" ]]; then
			systemd_dounit "${S}/usr/lib/systemd/system/clash-verge-service.service"
		fi
	else
		# 【-systemd 模式】：彻底清除 systemd 残留
		rm -rf "${ED}"/usr/lib/systemd "${ED}"/etc/systemd 2>/dev/null || true

		# 采用类似 mihomo-party-bin 的内核 SUID 方案
		if use tun; then
			local res_dir="${ED}/usr/lib/clash-verge/resources"
			if [[ -d "${res_dir}" ]]; then
				find "${res_dir}" -type f \( -name "clash*" -o -name "mihomo*" \) ! -name "*service*" -exec chmod 4755 {} + 2>/dev/null || true
			fi
		fi
	fi
}

pkg_postinst() {
	xdg_pkg_postinst

	if use systemd; then
		elog "已配置为原生 systemd 服务模式。"
		elog "如需启用 TUN 与系统代理支持，请启动守护服务："
		elog "  systemctl enable --now clash-verge-service"
	elif use tun; then
		elog "已配置免守护进程的内核 SUID TUN 模式（支持 OpenRC 等非 systemd 环境）。"
		elog "请确保内核已加载 tun 驱动: modprobe tun"
	fi
}
