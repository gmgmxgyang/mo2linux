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
    non_debian_function
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
    debian_opt_menu
}
#################
debian_opt_menu() {
    NON_DEBIAN='true'
    RETURN_TO_WHERE='debian_opt_menu'
    RETURN_TO_MENU='debian_opt_menu'
    DEPENDENCY_02=""
    cd /usr/share/applications/
    #16 50 7
    INSTALL_APP=$(whiptail --title "DEBIAN OPT REPO" --menu \
        "您想要安装哪个软件？按方向键选择，回车键确认！\n Which software do you want to install? " 0 0 0 \
        "1" "🎶 Music:云音乐,虾米,QQ音乐" \
        "2" "📝 notes笔记:记录灵感,撰写文档,整理材料,回顾日记" \
        "3" "pictures图像:bing壁纸,流程图绘制" \
        "4" "videos视频:无损切割视频,全网影视搜索" \
        "5" "games游戏:Minecraft启动器" \
        "6" "reader:悦享生活,品味阅读" \
        "7" "development程序开发:神经网络,深度学习,GUI设计" \
        "8" "other:其他软件" \
        "9" "remove(移除本仓库)" \
        "10" "switch source repo:切换软件源仓库" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") tmoe_multimedia_menu ;;
    1) debian_opt_music_app ;;
    2) debian_opt_note_app ;;
    3) debian_opt_picture_app ;;
    4) debian_opt_video_app ;;
    5) debian_opt_game_app ;;
    6) debian_opt_reader_app ;;
    7) debian_opt_development_app ;;
    8) debian_opt_other_apps ;;
    9) remove_debian_opt_repo ;;
    10) switch_debian_opt_repo_sources ;;
    esac
    ##########################
    press_enter_to_return
    debian_opt_menu
}
################
debian_opt_install_or_remove_01() {
    RETURN_TO_WHERE='debian_opt_install_or_remove_01'
    INSTALL_APP=$(whiptail --title "DEBIAN OPT REPO" --menu \
        "您想要对该软件执行哪项操作?" 0 0 0 \
        "1" "install 安装" \
        "2" "upgrade 更新" \
        "3" "fix 修复" \
        "4" "remove 卸载" \
        "0" "🌚 Back 返回" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") ${RETURN_TO_MENU} ;;
    1) install_opt_app_01 ;;
    2) upgrade_opt_app_01 ;;
    3) fix_opt_app_01 ;;
    4) remove_opt_app_01 ;;
    esac
    ##########################
    press_enter_to_return
    ${RETURN_TO_MENU}
}
################
check_debian_opt_app_version() {
    DEBIAN_OPT_REPO_POOL_URL='https://bintray.proxy.ustclug.org/debianopt/debianopt/pool/main/'
    #https://bintray.proxy.ustclug.org/debianopt/debianopt/pool/main/b/bookworm/:bookworm_1.1.2-1~buster_amd64.deb
    APP_NAME_PREFIX="$(echo ${DEPENDENCY_01} | cut -c 1)"
    DEBIAN_OPT_APP_PATH_URL="${DEBIAN_OPT_REPO_POOL_URL}${APP_NAME_PREFIX}/${DEPENDENCY_01}"
    THE_LATEST_DEB_FILE=$(curl -Lv "${DEBIAN_OPT_APP_PATH_URL}" | grep '.deb' | grep -v '.asc' | grep "${ARCH_TYPE}" | tail -n 1 | cut -d '"' -f 4)
    DEBIAN_OPT_APP_URL="${DEBIAN_OPT_APP_PATH_URL}/${THE_LATEST_DEB_FILE}"
    DOWNLOAD_PATH='/tmp'
    THE_LATEST_ISO_LINK="${DEBIAN_OPT_APP_URL}"
    aria2c_download_file
    extract_deb_file_01
}
###############
install_opt_app_01() {
    case "${LINUX_DISTRO}" in
    debian) beta_features_quick_install ;;
    *) check_debian_opt_app_version ;;
    esac
}
################
debian_opt_music_app() {
    #16 50 7
    RETURN_TO_WHERE='debian_opt_music_app'
    RETURN_TO_MENU='debian_opt_music_app'
    INSTALL_APP=$(whiptail --title "manage ${DEPENDENCY_01}" --menu \
        "您想要安装哪个软件?\n Which software do you want to install? " 0 0 0 \
        "1" "listen1(免费音乐聚合)" \
        "2" "electron-netease-cloud-music(云音乐客户端)" \
        "3" "lx-music-desktop(洛雪音乐助手)" \
        "4" "cocomusic(第三方QQ音乐+白屏修复补丁)" \
        "5" "netease-cloud-music-gtk(云音乐)" \
        "6" "iease-music(界面华丽的云音乐客户端)" \
        "7 " "petal:第三方豆瓣FM客户端" \
        "8 " "chord:支持虾米,云音乐,qq音乐多平台" \
        "9 " "lossless-cut:无损剪切视频音频工具" \
        "10" "#vocal:强大美观的播客app" \
        "11" "#flacon:支持从专辑中提取音频文件" \
        "0" "🌚 Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##############
    case "${INSTALL_APP}" in
    0 | "") debian_opt_menu ;;
    1) install_listen1 ;;
    2) install_electron_netease_cloud_music ;;
    3) install_lx_music_desktop ;;
    4) install_coco_music ;;
    5) install_netease_cloud_music_gtk ;;
    6) install_iease_music ;;
    7) install_electron_petal ;;
    8) install_electron_chord ;;
    9) install_electron_lossless_cut ;;
    10)
        non_debian_function
        install_opt_vocal
        ;;
    11)
        non_debian_function
        install_opt_flacon
        ;;
    esac
    ##########################
    #"7" "feeluown(x64,支持网易云、虾米)" \
    copy_opt_startup_script_to_bin
    press_enter_to_return
    debian_opt_music_app
}
################
debian_opt_quick_install() {
    beta_features_quick_install
    do_you_want_to_close_the_sandbox_mode
    RETURN_TO_WHERE='explore_debian_opt_repo'
    do_you_want_to_continue
}
############
remove_debian_opt_repo() {
    non_debian_function
    rm -vf /etc/apt/sources.list.d/debianopt.list
    apt update
}
##########
debian_opt_other_apps() {
    if (whiptail --title "Would you want to manage electron or view the software list?" --yes-button "electron" --no-button "list列表" --yesno "您想要管理electron还是查看软件列表?♪(^∇^*)" 0 0); then
        electron_manager
    else
        apt_list_debian_opt
    fi
}
##############
apt_list_debian_opt() {
    non_debian_function
    apt list | grep '~buster' | sed 's@~buster@@g'
    echo "请使用${YELLOW}apt install${RESET}软件包名称 来安装"
}
#############
install_electron_chord() {
    DEPENDENCY_01="chord"
    echo "github url：${YELLOW}https://github.com/PeterDing/chord${RESET}"
    debian_opt_quick_install
}
##############
install_electron_petal() {
    DEPENDENCY_01="petal"
    echo "github url：${YELLOW}https://ilime.github.io/Petal${RESET}"
    debian_opt_quick_install
}
############
install_coco_music() {
    DEPENDENCY_01='cocomusic'
    echo "github url：${YELLOW}https://github.com/xtuJSer/CoCoMusic${RESET}"
    debian_opt_quick_install
}
#####################
install_iease_music() {
    DEPENDENCY_01='iease-music'
    echo "github url：${YELLOW}https://github.com/trazyn/ieaseMusic${RESET}"
    debian_opt_quick_install
    case "${LINUX_DISTRO}" in
    1) ;;
    esac
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
install_electron_netease_cloud_music() {
    DEPENDENCY_01='electron-netease-cloud-music'
    echo "github url：${YELLOW}https://github.com/Rocket1184/electron-netease-cloud-music${RESET}"
    beta_features_quick_install
    FILE_SIZE=$(du -s /opt/electron-netease-cloud-music/app.asar | awk '{print $1}')
    if ((${FILE_SIZE} < 3000)); then
        patch_electron_netease_cloud_music
    fi
}
########################
install_listen1() {
    DEPENDENCY_01='listen1'
    echo "github url：${YELLOW}http://listen1.github.io/listen1${RESET}"
    debian_opt_quick_install
}
################
install_lx_music_desktop() {
    DEPENDENCY_01='lx-music-desktop'
    echo "github url：${YELLOW}https://github.com/lyswhut/lx-music-desktop${RESET}"
    debian_opt_quick_install
}
####################
install_feeluown() {
    DEPENDENCY_01='feeluown'
    echo "url：${YELLOW}https://feeluown.readthedocs.io/en/latest${RESET}"
    beta_features_quick_install
    if [ ! $(command -v feeluown-launcher) ]; then
        arch_does_not_support
    fi
}
###########
install_netease_cloud_music_gtk() {
    DEPENDENCY_01='netease-cloud-music-gtk'
    echo "github url：${YELLOW}https://github.com/gmg137/netease-cloud-music-gtk${RESET}"
    beta_features_quick_install
    if [ ! $(command -v netease-cloud-music-gtk) ]; then
        arch_does_not_support
    fi
}
###############
install_pic_go() {
    DEPENDENCY_01='picgo'
    echo "github url：${YELLOW}https://github.com/Molunerfinn/PicGo${RESET}"
    debian_opt_quick_install
}
############################################
explore_debian_opt_repo
