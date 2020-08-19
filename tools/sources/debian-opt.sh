#!/usr/bin/env bash
##################
add_debian_opt_repo() {
    echo "检测到您未添加debian_opt软件源，是否添加？"
    echo "debian_opt_repo列表的所有软件均来自于开源项目"
    echo "感谢https://github.com/coslyk/debianopt-repo 仓库的维护者，以及各个项目的原开发者。"
    RETURN_TO_WHERE='software_center'
    do_you_want_to_continue
    add_debian_opt_gpg_key
}
##############
check_pic_go_sandbox() {
    if [ $(command -v picgo) ]; then
        sed -i 's+picgo %U+picgo --no-sandbox %U+' /usr/share/applications/picgo.desktop
    fi
}
##############
debian_install_electron() {
    if [ "${LINUX_DISTRO}" = "debian" ] && [ ! $(command -v electron) ]; then
        OPT_REPO='/etc/apt/sources.list.d/debianopt.list'
        if [ ! -e "${OPT_REPO}" ]; then
            add_debian_opt_gpg_key
        fi
        cat <<-EOF
			即将为您安装electron
			apt install -y electron
			如需卸载，请手动执行apt purge electron
		EOF
        apt install -y electron
    fi
}
##############
switch_debian_opt_repo_sources() {
    OPT_REPO='/etc/apt/sources.list.d/debianopt.list'
    if grep '^deb.*ustc' ${OPT_REPO}; then
        OPT_REPO_NAME='USTC'
    else
        OPT_REPO_NAME='bintray'
    fi
    if (whiptail --title "您想要对这个小可爱做什么呢 " --yes-button "USTC" --no-button "bintray" --yesno "检测到您当前的软件源为${OPT_REPO_NAME}\n您想要切换为哪个软件源?♪(^∇^*) " 0 0); then
        #sed -i 's@^#deb@deb@' ${OPT_REPO}
        #sed -i 's@^deb.*bintray@#&@' ${OPT_REPO}
        echo -e "deb https://bintray.proxy.ustclug.org/debianopt/debianopt/ buster main\n#deb https://dl.bintray.com/debianopt/debianopt buster main" >${OPT_REPO}
    else
        echo -e "#deb https://bintray.proxy.ustclug.org/debianopt/debianopt/ buster main\ndeb https://dl.bintray.com/debianopt/debianopt buster main" >${OPT_REPO}
    fi
    apt update
}
#######################
explore_debian_opt_repo() {
    if [ ! $(command -v gpg) ]; then
        DEPENDENCY_01=""
        DEPENDENCY_02="gpg"
        beta_features_quick_install
    fi
    DEPENDENCY_02=""

    if [ ! -e "/etc/apt/sources.list.d/debianopt.list" ]; then
        add_debian_opt_repo
    fi

    NON_DEBIAN='true'
    RETURN_TO_WHERE='explore_debian_opt_repo'
    cd /usr/share/applications/
    INSTALL_APP=$(whiptail --title "DEBIAN OPT REPO" --menu \
        "您想要安装哪个软件？按方向键选择，回车键确认！\n Which software do you want to install? " 16 50 7 \
        "1" "listen1(免费音乐聚合)" \
        "2" "electron-netease-cloud-music(云音乐客户端)" \
        "3" "lx-music-desktop(洛雪音乐助手)" \
        "4" "iease-music(界面华丽的云音乐客户端)" \
        "5" "cocomusic(第三方QQ音乐客户端)" \
        "6" "feeluown(x64,支持网易云、虾米)" \
        "7" "netease-cloud-music-gtk(x64,云音乐)" \
        "8" "picgo(图床上传工具)" \
        "9" "other:其他软件" \
        "10" "remove(移除本仓库)" \
        "11" "switch source repo:切换软件源仓库" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") tmoe_multimedia_menu ;;
    1) install_listen1 ;;
    2) install_electron_netease_cloud_music ;;
    3) install_lx_music_desktop ;;
    4) install_iease_music ;;
    5) install_coco_music ;;
    6) install_feeluown ;;
    7) install_netease_cloud_music_gtk ;;
    8) install_pic_go ;;
    9) apt_list_debian_opt ;;
    10) remove_debian_opt_repo ;;
    11) switch_debian_opt_repo_sources ;;
    esac
    ##########################
    press_enter_to_return
    explore_debian_opt_repo
}
################
debian_opt_quick_install() {
    beta_features_quick_install
    do_you_want_to_close_the_sandbox_mode
    RETURN_TO_WHERE='explore_debian_opt_repo'
    do_you_want_to_continue
}
############
with_no_sandbox_model_01() {
    sed -i "s+${DEPENDENCY_01} %U+${DEPENDENCY_01} --no-sandbox %U+" ${DEPENDENCY_01}.desktop
}
########
with_no_sandbox_model_02() {
    if ! grep 'sandbox' "${DEPENDENCY_01}.desktop"; then
        sed -i "s@/usr/bin/${DEPENDENCY_01}@& --no-sandbox@" ${DEPENDENCY_01}.desktop
    fi
}
##################
remove_debian_opt_repo() {
    rm -vf /etc/apt/sources.list.d/debianopt.list
    apt update
}
##########
apt_list_debian_opt() {
    apt list | grep '~buster'
    echo "请使用apt install 软件包名称 来安装"
}
#############
install_coco_music() {
    DEPENDENCY_01='cocomusic'
    echo "github url：https://github.com/xtuJSer/CoCoMusic"
    debian_opt_quick_install
    #sed -i 's+cocomusic %U+electron /opt/CocoMusic --no-sandbox "$@"+' /usr/share/applications/cocomusic.desktop
    with_no_sandbox_model_01
}
#####################
install_iease_music() {
    DEPENDENCY_01='iease-music'
    echo "github url：https://github.com/trazyn/ieaseMusic"
    debian_opt_quick_install
    with_no_sandbox_model_02
}
############
patch_electron_netease_cloud_music() {
    cd /tmp
    rm -rf /tmp/.electron-netease-cloud-music_TEMP_FOLDER
    git clone -b electron-netease-cloud-music --depth=1 https://gitee.com/mo2/patch ./.electron-netease-cloud-music_TEMP_FOLDER
    cd ./.electron-netease-cloud-music_TEMP_FOLDER
    tar -Jxvf app.asar.tar.xz
    mv -f app.asar /opt/electron-netease-cloud-music/
    cd ..
    rm -rf /tmp/.electron-netease-cloud-music_TEMP_FOLDER
}
######################
proot_warning() {
    case "${TMOE_PROOT}" in
    true | no)
        echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
        echo "在当前环境下，安装后可能无法正常运行。"
        RETURN_TO_WHERE='explore_debian_opt_repo'
        do_you_want_to_continue
        ;;
    esac
}
################
install_electron_netease_cloud_music() {
    DEPENDENCY_01='electron-netease-cloud-music'
    echo "github url：https://github.com/Rocket1184/electron-netease-cloud-music"
    beta_features_quick_install
    FILE_SIZE=$(du -s /opt/electron-netease-cloud-music/app.asar | awk '{print $1}')
    if ((${FILE_SIZE} < 3000)); then
        patch_electron_netease_cloud_music
    fi
    do_you_want_to_close_the_sandbox_mode
    do_you_want_to_continue
    #with_no_sandbox_model_02
    if ! grep -q 'sandbox' "$(command -v electron-netease-cloud-music)"; then
        sed -i 's@exec electron /opt/electron-netease-cloud-music/app.asar@& --no-sandbox@' $(command -v electron-netease-cloud-music)
    fi
}
########################
install_listen1() {
    DEPENDENCY_01='listen1'
    echo "github url：http://listen1.github.io/listen1/"
    debian_opt_quick_install
    #sed -i 's+listen1 %U+listen1 --no-sandbox %U+' listen1.desktop
    with_no_sandbox_model_01
}
################
install_lx_music_desktop() {
    DEPENDENCY_01='lx-music-desktop'
    echo "github url：https://github.com/lyswhut/lx-music-desktop"
    debian_opt_quick_install
    #sed -i 's+lx-music-desktop %U+lx-music-desktop --no-sandbox %U+' lx-music-desktop.desktop
    with_no_sandbox_model_01
}
####################
install_feeluown() {
    DEPENDENCY_01='feeluown'
    echo "url：https://feeluown.readthedocs.io/en/latest/"
    beta_features_quick_install
    if [ ! $(command -v feeluown-launcher) ]; then
        arch_does_not_support
    fi
}
###########
install_netease_cloud_music_gtk() {
    DEPENDENCY_01='netease-cloud-music-gtk'
    echo "github url：https://github.com/gmg137/netease-cloud-music-gtk"
    beta_features_quick_install
    if [ ! $(command -v netease-cloud-music-gtk) ]; then
        arch_does_not_support
    fi
}
###############
install_pic_go() {
    DEPENDENCY_01='picgo'
    echo "github url：https://github.com/Molunerfinn/PicGo"
    debian_opt_quick_install
    #sed -i 's+picgo %U+picgo --no-sandbox %U+' picgo.desktop
    with_no_sandbox_model_01
}
############################################
explore_debian_opt_repo
