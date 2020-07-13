#!/usr/bin/env bash
########################################################################
main() {
    check_current_user_name_and_group
    check_dependencies
    case "$1" in
    up* | -u*)
        upgrade_tmoe_aria2_tool
        ;;
    h | -h | --help)
        cat <<-'EOF'
			-u       --更新(update aria2 tool)
		EOF
        ;;
    *)
        tmoe_aria2_manager
        ;;
    esac
}
################
check_current_user_name_and_group() {
    CURRENT_USER_NAME=$(cat /etc/passwd | grep "${HOME}" | awk -F ':' '{print $1}')
    CURRENT_USER_GROUP=$(cat /etc/passwd | grep "${HOME}" | awk -F ':' '{print $5}' | cut -d ',' -f 1)
    if [ -z "${CURRENT_USER_GROUP}" ]; then
        CURRENT_USER_GROUP=${CURRENT_USER_NAME}
    fi
}
##########
check_dependencies() {
    if [ ! $(command -v aria2c) ]; then
        echo '请先安装aria2'
    fi

    if [ ! $(command -v whiptail) ]; then
        echo '请安装whiptail'
    fi
    RED=$(printf '\033[31m')
    GREEN=$(printf '\033[32m')
    YELLOW=$(printf '\033[33m')
    BLUE=$(printf '\033[34m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[m')
}
################
##########################
do_you_want_to_continue() {
    echo "${YELLOW}Do you want to continue?[Y/n]${RESET}"
    echo "Press ${GREEN}enter${RESET} to ${BLUE}continue${RESET},type ${YELLOW}n${RESET} to ${BLUE}return.${RESET}"
    echo "按${GREEN}回车键${RESET}${BLUE}继续${RESET}，输${YELLOW}n${RESET}${BLUE}返回${RESET}"
    read opt
    case $opt in
    y* | Y* | "") ;;

    n* | N*)
        echo "skipped."
        ${RETURN_TO_WHERE}
        ;;
    *)
        echo "Invalid choice. skipped."
        ${RETURN_TO_WHERE}
        #beta_features
        ;;
    esac
}
##################
press_enter_to_return() {
    echo "Press ${GREEN}enter${RESET} to ${BLUE}return.${RESET}"
    echo "按${GREEN}回车键${RESET}${BLUE}返回${RESET}"
    read
}
################
upgrade_tmoe_aria2_tool() {
    cd /usr/local/bin
    curl -Lv -o aria2-i 'https://gitee.com/mo2/linux/raw/master/tool/aria2.sh'
    chmod +x aria2-i
}
################
tmoe_aria2_manager() {
    pgrep aria2 &>/dev/null
    if [ "$?" = "0" ]; then
        TMOE_ARIA2_STATUS='检测到aria2进程正在运行'
        TMOE_ARIA2_PROCESS='Restart重启'
    else
        TMOE_ARIA2_STATUS='检测到aria2进程未运行'
        TMOE_ARIA2_PROCESS='Start启动'
    fi
    if [ "${CURRENT_USER_NAME}" = 'root' ]; then
        TMOE_ARIA2_WARNING="检测到您以root权限运行,这可能会破坏您的系统"
    else
        if ! grep -q "${CURRENT_USER_NAME}" /etc/systemd/system/aria2.service; then
            TMOE_ARIA2_WARNING="请重新配置aria2,以使用${CURRENT_USER_NAME}身份运行aria2"
        else
            TMOE_ARIA2_WARNING="您将以${CURRENT_USER_NAME}身份运行aria2"
        fi
    fi

    TMOE_ARIA2_PATH='/usr/local/etc/tmoe-linux/aria2'
    TMOE_ARIA2_FILE="${TMOE_ARIA2_PATH}/aria2.conf"
    if [ -d "${TMOE_ARIA2_PATH}" ]; then
        mkdir -p ${TMOE_ARIA2_PATH}
    fi
    if (whiptail --title "你想要对这个小可爱做什么" --yes-button "${TMOE_ARIA2_PROCESS}" --no-button 'Configure配置' --yesno "本功能正在开发中,暂勿配置本服务。您是想要启动服务还是配置服务？\n${TMOE_ARIA2_STATUS}\n${TMOE_ARIA2_WARNING}" 0 50); then
        if [ ! -e "${TMOE_ARIA2_FILE}" ]; then
            echo "检测到配置文件不存在，1s后将为您自动配置服务。"
            sleep 1s
            tmoe_aria2_onekey
        fi
        aria2_restart
    else
        configure_aria2_rpc_server
    fi
}
#############
#############
tmoe_aria2_file() {
    TMOE_ARIA2_OPTION_01='true'
    TMOE_ARIA2_OPTION_02='false'
    RETURN_TO_WHERE='tmoe_aria2_file'
    TMOE_OPTION=$(whiptail --title "File allocation" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "dir 文件的下载目录(可使用绝对路径或相对路径)" \
        "02" "disk-cache 磁盘缓存大小" \
        "03" "file-allocation 文件预分配方式,降低磁盘碎片" \
        "04" "allow-overwrite 允许覆盖" \
        "05" "allow-piece-length-change 允许分片大小变化" \
        "06" "auto-file-renaming 文件自动重命名" \
        "07" "conditional-get 条件下载" \
        "08" "content-disposition-default-utf8 使用UTF-8处理disposition内容" \
        "09" "rlimit-nofile 最多打开的文件描述符" \
        "10" "enable-mmap 启用 MMap" \
        "11" "save-not-found 保存未找到的文件" \
        "12" "hash-check-only 文件校验——仅检查哈希值" \
        "13" "keep-unfinished-download-result 保留未完成的任务" \
        "14" "max-download-result 最多下载结果" \
        "15" "max-mmap-limit MMap 最大限制" \
        "16" "piece-length 文件分片大小" \
        "17" "no-file-allocation-limit 文件分配限制" \
        "18" "no-conf 禁用配置文件" \
        "19" "parameterized-uri 启用参数化 URI 支持" \
        "20" "realtime-chunk-checksum 实时数据块验证" \
        "21" "remove-control-file 删除控制文件" \
        "22" "socket-recv-buffer-size Socket 接收缓冲区大小" \
        "23" "check-integrity 检查完整性" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_GREP_NAME='dir'
        TMOE_ARIA2_TIPS='默认: 当前启动位置'
        ;;
    02)
        TMOE_ARIA2_GREP_NAME='disk-cache'
        TMOE_ARIA2_TIPS='启用磁盘缓存, 0为禁用缓存, 需1.16以上版本, 默认:16M\n此功能将下载的数据缓存在内存中, 最多占用此选项设置的字节数. 缓存存储由 aria2 实例创建并对所有下载共享. 由于数据以较大的单位写入并按文件的偏移重新排序, 所以磁盘缓存的一个优点是减少磁盘的 I/O. 如果调用哈希检查时并且数据缓存在内存中时, 将不需要从磁盘中读取. 大小可以包含 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    03)
        TMOE_ARIA2_GREP_NAME='file-allocation'
        TMOE_ARIA2_TIPS='默认:prealloc,预分配所需时间: none < falloc ? trunc < prealloc\nfalloc和trunc则需要文件系统和内核支持\n"none" 不会预先分配文件空间;"prealloc"会在下载开始前预先分配空间, 这将会根据文件的大小需要一定的时间。 如果您使用的是较新的文件系统, 例如 ext4 (带扩展支持)、 btrfs、 xfs 或 NTFS (仅 MinGW 构建), "falloc" 是最好的选择。其几乎可以瞬间分配大文件(数 GiB)。\n不要在旧的文件系统, 例如 ext3 和 FAT32 上使用 falloc, 因为该方式与 prealloc 花费的时间相同, 并且它还会在分配完成前阻塞 aria2。\n当您的系统不支持 posix_fallocate(3) 函数时, falloc 可能无法使用。 "trunc" 使用 ftruncate(2)  系统调用或平台特定的实现将文件截取到特定的长度。在多文件的 BitTorrent 下载中, 若某文件与其相邻的文件共享相同的分片时。 则相邻的文件也会被分配.\nwindows(非管理员运行)请勿将选项值改为falloc'
        ;;
    04)
        TMOE_ARIA2_GREP_NAME='allow-overwrite'
        TMOE_ARIA2_TIPS='如果相应的控制文件不存在时从头重新下载文件. 参见 --auto-file-renaming 选项.'
        ;;
    05)
        TMOE_ARIA2_GREP_NAME='allow-piece-length-change'
        TMOE_ARIA2_TIPS='如果设置为"false", 当分片长度与控制文件中的不同时, aria2 将会中止下载. 如果设置为"true", 您可以继续, 但部分下载进度将会丢失.'
        ;;
    06)
        TMOE_ARIA2_GREP_NAME='auto-file-renaming'
        TMOE_ARIA2_TIPS='重新命名已经存在的文件. 此选项仅对 HTTP(S)/FTP 下载有效. 新的文件名后会在文件名后、扩展名 (如果有) 前追加句点和数字(1..9999).'
        ;;
    07)
        TMOE_ARIA2_GREP_NAME='conditional-get'
        TMOE_ARIA2_TIPS='仅当本地文件比远程文件旧时才进行下载. 此功能仅适用于 HTTP(S) 下载. 如果在 Metalink 中文件大小已经被指定则功能无法生效. 同时此功能还将忽略 Content-Disposition 响应头. 如果存在控制文件, 此选项将被忽略. 此功能通过 If-Modified-Since 请求头获取较新的文件. 当获取到本地文件的修改时间时, 此功能将使用用户提供的文件名 (参见 --out 选项), 如果没有指定 --out 选项则使用 URI 中的文件名. 为了覆盖已经存在的文件, 需要使用 --allow-overwrite 参数.'
        ;;
    08)
        TMOE_ARIA2_GREP_NAME='content-disposition-default-utf8'
        TMOE_ARIA2_TIPS='处理 "Content-Disposition" 头中的字符串时使用 UTF-8 字符集来代替 ISO-8859-1, 例如, 文件名参数, 但不是扩展版本的文件名.'
        ;;
    09)
        TM OE_ARIA2_GREP_NAME='rlimit-nofile'
        TMOE_ARIA2_TIPS='设置打开的文件描述符的软限制 (soft limit). 此选项仅当满足如下条件时开放: a. 系统支持它 (posix). b. 限制没有超过硬限制 (hard limit). c. 指定的限制比当前的软限制高. 这相当于设置 ulimit, 除了其不能降低限制. 此选项仅当系统支持 rlimit API 时有效.'
        ;;
    10)
        TMOE_ARIA2_GREP_NAME='enable-mmap'
        TMOE_ARIA2_TIPS='内存中存放映射文件. 当文件空间没有预先分配至, 此选项无效. 参见 --file-allocation.'
        ;;
    11)
        TMOE_ARIA2_GREP_NAME='save-not-found'
        TMOE_ARIA2_TIPS='当使用 --save-session 选项时, 即使当任务中的文件不存在时也保存该下载任务. 此选项同时会将这种情况保存到控制文件中.'
        ;;
    12)
        TMOE_ARIA2_GREP_NAME='hash-check-only'
        TMOE_ARIA2_TIPS='如果设置为"true", 哈希检查完使用 --check-integrity 选项, 根据是否下载完成决定是否终止下载.'
        ;;
    13)
        TMOE_ARIA2_GREP_NAME='keep-unfinished-download-result'
        TMOE_ARIA2_TIPS='保留所有未完成的下载结果, 即使超过了 --max-download-result 选项设置的数量. 这将有助于在会话文件中保存所有的未完成的下载 (参考 --save-session 选项). 需要注意的是, 未完成任务的数量没有上限. 如果不希望这样, 请关闭此选项.'
        ;;
    14)
        TMOE_ARIA2_GREP_NAME='max-download-result'
        TMOE_ARIA2_TIPS='设置内存中存储最多的下载结果数量. 下载结果包括已完成/错误/已删除的下载. 下载结果存储在一个先进先出的队列中, 因此其可以存储最多指定的下载结果的数量. 当队列已满且有新的下载结果创建时, 最老的下载结果将从队列的最前部移除, 新的将放在最后. 此选项设置较大的值后如果经过几千次的下载将导致较高的内存消耗. 设置为 0 表示不存储下载结果. 注意, 未完成的下载将始终保存在内存中, 不考虑该选项的设置. 参考 --keep-unfinished-download-result 选项.'
        ;;
    15)
        TMOE_ARIA2_GREP_NAME='max-mmap-limit'
        TMOE_ARIA2_TIPS='设置启用 MMap (参见 --enable-mmap 选项) 最大的文件大小. 文件大小由一个下载任务中所有文件大小的和决定. 例如, 如果一个下载包含 5 个文件, 那么文件大小就是这些文件的总大小. 如果文件大小超过此选项设置的大小时, MMap 将会禁用.'
        ;;
    16)
        TMOE_ARIA2_GREP_NAME='piece-length'
        TMOE_ARIA2_TIPS='设置 HTTP/FTP 下载的分配大小. aria2 根据这个边界分割文件. 所有的分割都是这个长度的倍数. 此选项不适用于 BitTorrent 下载. 如果 Metalink 文件中包含分片哈希的结果此选项也不适用.'
        ;;
    17)
        TMOE_ARIA2_GREP_NAME='no-file-allocation-limit'
        TMOE_ARIA2_TIPS='不对比此参数设置大小小的分配文件. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    18)
        TMOE_ARIA2_GREP_NAME='no-conf'
        TMOE_ARIA2_TIPS='默认为false'
        ;;
    19)
        TMOE_ARIA2_GREP_NAME='parameterized-uri'
        TMOE_ARIA2_TIPS='启用参数化 URI 支持. 您可以指定部分的集合: http://{sv1,sv2,sv3}/foo.iso. 同时您也可以使用步进计数器指定数字化的序列: http://host/image[000-100:2].img. 步进计数器可以省略. 如果所有 URI 地址不指向同样的文件, 例如上述第二个示例, 需要使用 -Z 选项.'
        ;;
    20)
        TMOE_ARIA2_GREP_NAME='realtime-chunk-checksum'
        TMOE_ARIA2_TIPS='如果提供了数据块的校验和, 将在下载过程中通过校验和验证数据块.'
        ;;
    21)
        TMOE_ARIA2_GREP_NAME='remove-control-file'
        TMOE_ARIA2_TIPS='在下载前删除控制文件. 使用 --allow-overwrite=true 选项时, 总是从头开始下载文件. 此选项将有助于使用不支持断点续传代理服务器的用户.'
        ;;
    22)
        TMOE_ARIA2_GREP_NAME='socket-recv-buffer-size'
        TMOE_ARIA2_TIPS='设置 Socket 接收缓冲区最大的字节数. 指定为 0 时将禁用此选项. 当使用 SO_RCVBUF 选项调用 setsockopt() 时此选项的值将设置到 Socket 的文件描述符中.'
        ;;
    23)
        TMOE_ARIA2_GREP_NAME='check-integrity'
        TMOE_ARIA2_TIPS='通过对文件的每个分块或整个文件进行哈希验证来检查文件的完整性. 此选项仅对BT、Metalink及设置了 --checksum 选项的 HTTP(S)/FTP 链接生效.'
        ;;
    esac
    ##############################
    tmoe_aria2_settings_model_01
    press_enter_to_return
    tmoe_aria2_file
}
#############
check_tmoe_aria2_config_value() {
    TMOE_ARIA2_CONFIG_VALUE=$(cat ${TMOE_ARIA2_FILE} | grep ${TMOE_ARIA2_GREP_NAME} | cut -d '=' -f 2)
    if grep -q "^${TMOE_ARIA2_GREP_NAME}" ${TMOE_ARIA2_FILE}; then
        TMOE_ARIA2_CONFIG_STATUS="检测到${TMOE_ARIA2_GREP_NAME}的值为${TMOE_ARIA2_CONFIG_VALUE}"
        TMOOE_ARIA2_CONFIG_ENABLED='true'
    elif grep -q "^#${TMOE_ARIA2_GREP_NAME}" ${TMOE_ARIA2_FILE}; then
        TMOE_ARIA2_CONFIG_STATUS="检测到${TMOE_ARIA2_GREP_NAME}的值为默认"
        TMOOE_ARIA2_CONFIG_ENABLED='false'
    else
        TMOE_ARIA2_CONFIG_STATUS="检测到您未启用${TMOE_ARIA2_GREP_NAME}"
        TMOOE_ARIA2_CONFIG_ENABLED='no'
    fi
}
######################
tmoe_aria2_settings_model_01() {
    #此处不要设置RETURN_TO_WHERE的变量
    check_tmoe_aria2_config_value
    TMOE_OPTION=$(whiptail --title "您想要将参数${TMOE_ARIA2_GREP_NAME}修改为哪个值" --menu "${TMOE_ARIA2_CONFIG_STATUS}\n${TMOE_ARIA2_TIPS}" 0 50 0 \
        "0" "Return to previous menu 返回上级菜单" \
        "1" "${TMOE_ARIA2_OPTION_01}" \
        "2" "${TMOE_ARIA2_OPTION_02}" \
        "3" "custom手动输入" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") ${RETURN_TO_WHERE} ;;
    1) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_01} ;;
    2) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_02} ;;
    3) custom_aria2_config ;;
    esac
    ##############################
    modify_aria2_config_value
    press_enter_to_return
    tmoe_aria2_settings_model_01
}
#############
modify_aria2_config_value() {
    case "${TMOOE_ARIA2_CONFIG_ENABLED}" in
    true) sed -i "s@${TMOE_ARIA2_CONFIG_VALUE}@${TMOE_ARIA2_OPTION_TARGET}@g" ${TMOE_ARIA2_FILE} ;;
    false)
        sed -i "s@^#${TMOE_ARIA2_GREP_NAME}@${TMOE_ARIA2_GREP_NAME}@" ${TMOE_ARIA2_FILE}
        sed -i "s@${TMOE_ARIA2_CONFIG_VALUE}@${TMOE_ARIA2_OPTION_TARGET}@g" ${TMOE_ARIA2_FILE}
        ;;
    no) sed -i "$ a ${TMOE_ARIA2_GREP_NAME}=${TMOE_ARIA2_OPTION_TARGET}" ${TMOE_ARIA2_FILE} ;;
    esac
    check_tmoe_aria2_config_value
    echo "Your current ${TMOE_ARIA2_GREP_NAME} has been modified."
    echo "${TMOE_ARIA2_GREP_NAME}的值已修改为${TMOE_ARIA2_CONFIG_VALUE}"
}
###################
custom_aria2_config() {
    TMOE_ARIA2_OPTION_TARGET=$(whiptail --inputbox "请手动输入参数${TMOE_ARIA2_GREP_NAME}的值" 0 0 --title "${TMOE_ARIA2_GREP_NAME} conf" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        ${RETURN_TO_WHERE}
    elif [ -z "${TARGET}" ]; then
        echo "请输入有效的数值"
        echo "Please enter a valid value"
        echo "您输入了一个空数值，将自动切换为${TMOE_ARIA2_OPTION_02}"
        TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_02}
    fi
}
#############
#############
tmoe_aria2_download_protocol() {
    TMOE_OPTION=$(whiptail --title "RROTOCAL" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "1" "BT/PT" \
        "2" "HTTP" \
        "3" "FTP" \
        "4" "metalink" \
        "0" "Back 返回" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") configure_aria2_rpc_server ;;
    1) tmoe_aria2_bt_and_pt ;;
    2) tmoe_aria2_http ;;
    3) tmoe_aria2_ftp ;;
    4) tmoe_aria2_metalink ;;
    esac
    ##############################
    press_enter_to_return
    tmoe_aria2_download_protocol
}
########################
configure_aria2_rpc_server() {
    RETURN_TO_WHERE='configure_aria2_rpc_server'
    #进入aria2配置文件目录
    cd ${TMOE_ARIA2_PATH}
    TMOE_OPTION=$(whiptail --title "CONFIGURE ARIA2 RPC SERVER" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "1" "One-key conf 初始化一键配置" \
        "2" "process进程管理" \
        "3" "FAQ常见问题" \
        "4" "file allocation文件保存与分配" \
        "5" "edit manually手动编辑" \
        "6" "connection网络连接与下载限制" \
        "7" "port端口" \
        "8" "RPC服务器" \
        "9" "HTTP/BT/FTP:下载协议" \
        "10" "logs & info日志与输出信息" \
        "11" "TLS加密与安全" \
        "12" "事件HOOK" \
        "13" "proxy代理" \
        "14" "other其它选项" \
        "15" "update 更新" \
        "16" "DEL 删除配置文件" \
        "0" "exit 退出" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") exit 0 ;;
    1) tmoe_aria2_onekey ;;
    2) tmoe_aria2_systemd ;;
    3) tmoe_aria2_faq ;;
    4) tmoe_aria2_file ;;
    5) edit_tmoe_aria2_config_manually ;;
    6) tmoe_aria2_connection_threads ;;
    7) tmoe_aria2_port ;;
    8) tmoe_aria2_rpc_server ;;
    9) tmoe_aria2_download_protocol ;;
    10) tmoe_aria2_logs ;;
    11) tmoe_aria2_tls_crypt ;;
    12) tmoe_aria2_hook ;;
    13) tmoe_aria2_proxy ;;
    14) other_tmoe_aria2_conf ;;
    15) del_tmoe_aria2_conf ;;
    esac
    ##############################
    press_enter_to_return
    configure_aria2_rpc_server
}
##############
edit_tmoe_aria2_config_manually() {
    if [ $(command -v editor) ]; then
        editor ${TMOE_ARIA2_FILE}
    else
        nano ${TMOE_ARIA2_FILE}
    fi
}
##########
tmoe_aria2_systemd() {
    TMOE_DEPENDENCY_SYSTEMCTL='aria2'
    pgrep aria2 &>/dev/null
    if [ "$?" = "0" ]; then
        TMOE_ARIA2_STATUS='检测到aria2进程正在运行\nDetected that the aria2 process is running.'
    else
        TMOE_ARIA2_STATUS='检测到aria2进程未运行\nDetected that aria2 process is not running'
    fi
    ARIA2_SYSTEMD_OPTION=$(whiptail --title "你想要对这个小可爱做什么？" --menu \
        "${TMOE_ARIA2_STATUS}" 0 50 0 \
        "1" "start启动" \
        "2" "stop停止" \
        "3" "status状态" \
        "4" "systemctl enable开机自启" \
        "5" "systemctl disable禁用自启" \
        "0" "Return to previous menu 返回上级菜单" \
        3>&1 1>&2 2>&3)
    ##########################
    case "${ARIA2_SYSTEMD_OPTION}" in
    0 | "") configure_aria2_rpc_server ;;
    1)
        echo "您可以输${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} start${RESET}或${GREEN}systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}来启动"
        echo "${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} start${RESET}"
        echo "按回车键启动"
        do_you_want_to_continue
        systemctl daemon-reload 2>/dev/null
        service ${TMOE_DEPENDENCY_SYSTEMCTL} restart || systemctl start ${TMOE_DEPENDENCY_SYSTEMCTL}
        ;;
    2)
        echo "您可以输${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} stop${RESET}或${GREEN}systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}来停止"
        echo "${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} stop${RESET}"
        echo "按回车键停止"
        do_you_want_to_continue
        service ${TMOE_DEPENDENCY_SYSTEMCTL} stop || systemctl stop ${TMOE_DEPENDENCY_SYSTEMCTL}
        ;;
    3)
        echo "您可以输${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} status${RESET}或${GREEN}systemctl status ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}来查看进程状态"
        echo "${GREEN}service ${TMOE_DEPENDENCY_SYSTEMCTL} status${RESET}"
        #echo "按回车键查看"
        #do_you_want_to_continue
        service ${TMOE_DEPENDENCY_SYSTEMCTL} status || systemctl status ${TMOE_DEPENDENCY_SYSTEMCTL}
        ;;
    4)
        echo "您可以输${GREEN}rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}或${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}来添加开机自启任务"
        echo "${GREEN}systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
        systemctl enable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update add ${TMOE_DEPENDENCY_SYSTEMCTL}
        if [ "$?" = "0" ]; then
            echo "已添加至自启任务"
        else
            echo "添加自启任务失败"
        fi
        ;;
    5)
        echo "您可以输${GREEN}rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}或${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL}${RESET}来禁止开机自启"
        echo "${GREEN}systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} ${RESET}"
        systemctl disable ${TMOE_DEPENDENCY_SYSTEMCTL} || rc-update del ${TMOE_DEPENDENCY_SYSTEMCTL}
        if [ "$?" = "0" ]; then
            echo "已禁用开机自启"
        else
            echo "禁用自启任务失败"
        fi
        ;;
    esac
    ##########################
    press_enter_to_return
    tmoe_aria2_systemd
}
#######################
##############
del_tmoe_aria2_conf() {
    pkill aria2c
    echo "正在停止aria2c进程..."
    echo "Stopping aria2c..."
    service aria2 stop 2>/dev/null || systemctl stop aria2
    echo '正在停用aria2开机自启动任务...'
    systemctl disable aria2
    rm -fv ${TMOE_ARIA2_FILE} /etc/systemd/system/aria2.service
    echo "${YELLOW}已删除aria2配置文件${RESET}"
}
###################
tmoe_aria2_onekey() {
    cd ${TMOE_ARIA2_PATH}
    if [ ! -e "aria2.session" ]; then
        echo '' >aria2.session
    fi
    cp aria2.conf aria2.conf.bak 2>/dev/null
    #cp -pvf ${HOME}/gitee/linux-gitee/.config/aria2.conf ./
    aria2c --allow-overwrite=true -o aria2.conf 'https://gitee.com/mo2/linux/raw/master/.config/aria2.conf'
    if [ -e "/tmp/.Chroot-Container-Detection-File" ] || [ -e "/tmp/.Tmoe-Proot-Container-Detection-File" ]; then
        echo "检测到您处于${BLUE}chroot/proot容器${RESET}环境下"
        #echo "部分系统可能会出现failed，但仍能正常连接。"
        #CHROOT_STATUS='1'
    fi

    cd /etc/systemd/system
    cat >aria2.service <<-EndOFaria
[Unit]
Description= aria2
After=network.target

[Service]
PIDFile=/run/aria2.pid
ExecStart=su ${CURRENT_USER_NAME} -c  "cd /usr/local/etc/tmoe-linux/aria2 &&aria2c --conf-path=/usr/local/etc/tmoe-linux/aria2/aria2.conf"
ExecStop=/bin/kill \$MAINPID ;su ${CURRENT_USER_NAME} -c "pkill aria2c"
RestartSec=always

[Install]
WantedBy=multi-user.target
	EndOFaria
    #############
    #  aria2_restart
    ########################################
    press_enter_to_return
    configure_aria2_rpc_server
    #此处的返回步骤并非多余
}
############
main "$@"
###########################################
