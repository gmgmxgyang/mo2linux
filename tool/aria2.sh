#!/usr/bin/env bash
########################################################################
main() {
    check_current_user_name_and_group
    check_dependencies
    case "$1" in
    up* | -u*)
        upgrade_tmoe_aria2_tool
        ;;
    bt | -bt)
        update_aria2_bt_tracker
        ;;
    h | -h | --help)
        cat <<-'EOF'
			-u       --更新aria2工具(update aria2 tool)
            bt       --更新BT-tracker服务器
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
    TMOE_ARIA2_SETTINGS_MODEL='01'
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
        TMOE_ARIA2_OPTION_01="${HOME}/Downloads"
        TMOE_ARIA2_OPTION_02="${HOME}/sd/Download"
        ;;
    02)
        TMOE_ARIA2_GREP_NAME='disk-cache'
        TMOE_ARIA2_TIPS='启用磁盘缓存, 0为禁用缓存, 需1.16以上版本, 默认:16M\n此功能将下载的数据缓存在内存中, 最多占用此选项设置的字节数. 缓存存储由 aria2 实例创建并对所有下载共享. 由于数据以较大的单位写入并按文件的偏移重新排序, 所以磁盘缓存的一个优点是减少磁盘的 I/O. 如果调用哈希检查时并且数据缓存在内存中时, 将不需要从磁盘中读取. 大小可以包含 K 或 M (1K = 1024, 1M = 1024K).'
        TMOE_ARIA2_OPTION_01="32M"
        TMOE_ARIA2_OPTION_02="16M"
        ;;
    03)
        TMOE_ARIA2_GREP_NAME='file-allocation'
        TMOE_ARIA2_TIPS='默认:prealloc,预分配所需时间: none < falloc ? trunc < prealloc\nfalloc和trunc则需要文件系统和内核支持\n"none" 不会预先分配文件空间;"prealloc"会在下载开始前预先分配空间, 这将会根据文件的大小需要一定的时间。 如果您使用的是较新的文件系统, 例如 ext4 (带扩展支持)、 btrfs、 xfs 或 NTFS (仅 MinGW 构建), "falloc" 是最好的选择。其几乎可以瞬间分配大文件(数 GiB)。\n不要在旧的文件系统, 例如 ext3 和 FAT32 上使用 falloc, 因为该方式与 prealloc 花费的时间相同, 并且它还会在分配完成前阻塞 aria2。\n当您的系统不支持 posix_fallocate(3) 函数时, falloc 可能无法使用。 "trunc" 使用 ftruncate(2)  系统调用或平台特定的实现将文件截取到特定的长度。在多文件的 BitTorrent 下载中, 若某文件与其相邻的文件共享相同的分片时。 则相邻的文件也会被分配.\nwindows(非管理员运行)请勿将选项值改为falloc'
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_OPTION_01='none'
        TMOE_ARIA2_OPTION_02='falloc'
        TMOE_ARIA2_OPTION_03='trunc'
        TMOE_ARIA2_OPTION_04='prealloc'
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
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="99"
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
        TMOE_ARIA2_OPTION_01="1000"
        TMOE_ARIA2_OPTION_02="1"
        TMOE_ARIA2_GREP_NAME='max-download-result'
        TMOE_ARIA2_TIPS='设置内存中存储最多的下载结果数量. 下载结果包括已完成/错误/已删除的下载. 下载结果存储在一个先进先出的队列中, 因此其可以存储最多指定的下载结果的数量. 当队列已满且有新的下载结果创建时, 最老的下载结果将从队列的最前部移除, 新的将放在最后. 此选项设置较大的值后如果经过几千次的下载将导致较高的内存消耗. 设置为 0 表示不存储下载结果. 注意, 未完成的下载将始终保存在内存中, 不考虑该选项的设置. 参考 --keep-unfinished-download-result 选项.'
        ;;
    15)
        TMOE_ARIA2_OPTION_01="9223372036854775807"
        TMOE_ARIA2_OPTION_02="99999999999999"
        TMOE_ARIA2_GREP_NAME='max-mmap-limit'
        TMOE_ARIA2_TIPS='设置启用 MMap (参见 --enable-mmap 选项) 最大的文件大小. 文件大小由一个下载任务中所有文件大小的和决定. 例如, 如果一个下载包含 5 个文件, 那么文件大小就是这些文件的总大小. 如果文件大小超过此选项设置的大小时, MMap 将会禁用.'
        ;;
    16)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="10M"
        TMOE_ARIA2_GREP_NAME='piece-length'
        TMOE_ARIA2_TIPS='设置 HTTP/FTP 下载的分配大小. aria2 根据这个边界分割文件. 所有的分割都是这个长度的倍数. 此选项不适用于 BitTorrent 下载. 如果 Metalink 文件中包含分片哈希的结果此选项也不适用.'
        ;;
    17)
        TMOE_ARIA2_OPTION_01="5M"
        TMOE_ARIA2_OPTION_02="10M"
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
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="99999"
        TMOE_ARIA2_GREP_NAME='socket-recv-buffer-size'
        TMOE_ARIA2_TIPS='设置 Socket 接收缓冲区最大的字节数. 指定为 0 时将禁用此选项. 当使用 SO_RCVBUF 选项调用 setsockopt() 时此选项的值将设置到 Socket 的文件描述符中.'
        ;;
    23)
        TMOE_ARIA2_GREP_NAME='check-integrity'
        TMOE_ARIA2_TIPS='通过对文件的每个分块或整个文件进行哈希验证来检查文件的完整性. 此选项仅对BT、Metalink及设置了 --checksum 选项的 HTTP(S)/FTP 链接生效.'
        ;;
    esac
    ##############################
    if [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "01" ]; then
        tmoe_aria2_settings_model_01
    elif [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "02" ]; then
        tmoe_aria2_settings_model_02
    fi
    press_enter_to_return
    tmoe_aria2_file
}
#############
tmoe_aria2_connection_threads() {
    TMOE_ARIA2_OPTION_01='true'
    TMOE_ARIA2_OPTION_02='false'
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_connection_threads'
    TMOE_OPTION=$(whiptail --title "网络连接" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "max-concurrent-downloads 最大同时下载任务数" \
        "02" "min-split-size  最小文件分片大小" \
        "03" "max-connection-per-server 同一服务器连接数" \
        "04" "split 单个任务最大连接数" \
        "05" "max-overall-download-limit 整体(全局)下载速度限制" \
        "06" "max-download-limit  单个任务下载速度限制, 默认:0" \
        "07" "max-overall-upload-limit  整体(全局)上传速度限制" \
        "08" "max-upload-limit  单个任务上传速度限制, 默认:0" \
        "09" "disable-ipv6  禁用IPv6" \
        "10" "timeout  连接超时时间" \
        "11" "max-tries  最大尝试（重试）次数" \
        "12" "retry-wait  设置重试等待的秒数, 默认:0" \
        "13" "max-resume-failure-tries 最大断点续传尝试次数" \
        "14" "continue  断点续传:继续下载部分完成的文件" \
        "15" "always-resume 始终断点续传" \
        "16" "async-dns 异步 DNS" \
        "17" "dscp 差分服务代码点" \
        "18" "optimize-concurrent-downloads 优化并发下载" \
        "19" "input-file 从会话文件中读取下载任务" \
        "20" "save-session 状态保存文件" \
        "21" "save-session-interval  保存状态间隔(定时保存会话)" \
        "22" "auto-save-interval 自动保存间隔" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_OPTION_01="10"
        TMOE_ARIA2_OPTION_02="5"
        TMOE_ARIA2_GREP_NAME='max-concurrent-downloads'
        TMOE_ARIA2_TIPS='运行时可修改, 默认:5'
        ;;
    02)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="20M"
        TMOE_ARIA2_GREP_NAME='min-split-size'
        TMOE_ARIA2_TIPS=' 添加时可指定, 取值范围1M -1024M, 默认:20M。\n简易说明：假定size=10M, 文件为20MiB 则使用两个来源下载; 文件为15MiB 则使用一个来源下载。\n完整说明：aria2 不会分割小于 2*SIZE 字节的文件。例如, 文件大小为 20MiB, 如果 SIZE 为 10M, aria2 会把文件分成 2 段 [0-10MiB) 和 [10MiB-20MiB) , 并且使用 2 个源进行下载 (如果 --split >= 2)。如果 SIZE 为 15M, 由于 2*15M > 20MB, 因此 aria2 不会分割文件并使用 1 个源进行下载。 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K)。'
        ;;
    03)
        TMOE_ARIA2_OPTION_01="16"
        TMOE_ARIA2_OPTION_02="1"
        TMOE_ARIA2_GREP_NAME='max-connection-per-server'
        TMOE_ARIA2_TIPS='添加时可指定, 默认:1。\n原版可取最大值为16，自行编译的版本可以解除此限制.若出现兼容性问题，请调整该参数的值。'
        ;;
    04)
        TMOE_ARIA2_OPTION_01="16"
        TMOE_ARIA2_OPTION_02="5"
        TMOE_ARIA2_GREP_NAME='split'
        TMOE_ARIA2_TIPS='默认:5,下载时使用 N 个连接。如果提供超过 N 个 URI 地址, 则使用前 N 个地址, 剩余的地址将作为备用。 如果提供的 URI 地址不足 N 个, 这些地址多次使用以保证同时建立 N 个连接。 同一服务器的连接数会被 --max-connection-per-server 选项限制。'
        ;;
    05)
        TMOE_ARIA2_OPTION_01="2M"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-overall-download-limit'
        TMOE_ARIA2_TIPS='运行时可修改, 默认:0\n设置全局最大下载速度 (字节/秒). 0 表示不限制. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    06)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-download-limit'
        TMOE_ARIA2_TIPS='设置每个任务的最大下载速度 (字节/秒). 0 表示不限制. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    07)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-overall-upload-limit'
        TMOE_ARIA2_TIPS='运行时可修改, 默认:0\n设置全局最大上传速度 (字节/秒). 0 表示不限制. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    08)
        TMOE_ARIA2_OPTION_01="1M"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-upload-limit'
        TMOE_ARIA2_TIPS='设置每个任务的最大上传速度 (字节/秒). 0 表示不限制. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    09)
        TMOE_ARIA2_GREP_NAME='disable-ipv6'
        TMOE_ARIA2_TIPS='默认:false'
        ;;
    10)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='timeout'
        TMOE_ARIA2_TIPS='默认:60。'
        ;;
    11)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="5"
        TMOE_ARIA2_GREP_NAME='max-tries'
        TMOE_ARIA2_TIPS='设置为0表示不限制重试次数, 默认:5'
        ;;
    12)
        TMOE_ARIA2_OPTION_01="1"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='retry-wait'
        TMOE_ARIA2_TIPS=' 当此选项的值大于 0 时, aria2 在 HTTP 服务器返回 503 响应时将会重试.'
        ;;
    13)
        TMOE_ARIA2_OPTION_01="1"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='max-resume-failure-tries'
        TMOE_ARIA2_TIPS='当 --always-resume 选项设置为"false"时, 如果 aria2 检测到有 N 个 URI 不支持断点续传时, 将从头开始下载文件. 如果 N 设置为 0, 当所有 URI 都不支持断点续传时才会从头下载文件. 参见 --always-resume 选项.'
        ;;
    14)
        TMOE_ARIA2_GREP_NAME='continue'
        TMOE_ARIA2_TIPS='启用此选项可以继续下载从浏览器或其他程序按顺序下载的文件. 此选项目前只支持 HTTP(S)/FTP 下载的文件。'
        ;;
    15)
        TMOE_ARIA2_GREP_NAME='always-resume'
        TMOE_ARIA2_TIPS='始终断点续传. 如果设置为"true", aria2 始终尝试断点续传, 如果无法恢复, 则中止下载. 如果设置为"false", 对于不支持断点续传的 URI 或 aria2 遇到 N 个不支持断点续传的 URI (N 为 --max-resume-failure-tries 选项设置的值), aria2 会从头下载文件. 参见 --max-resume-failure-tries 参数.'
        ;;
    16)
        TMOE_ARIA2_GREP_NAME='async-dns'
        TMOE_ARIA2_TIPS='默认为true'
        ;;
    17)
        TMOE_ARIA2_OPTION_01="63"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='dscp'
        TMOE_ARIA2_TIPS='为 QoS 设置 BT 上行 IP 包的 DSCP 值. 此参数仅设置 IP 包中 TOS 字段的 DSCP 位, 而不是整个字段. 如果您从 /usr/include/netinet/ip.h 得到的值, 需要除以 4 (否则值将不正确, 例如您的 CS1 类将会转为 CS4). 如果您从 RFC, 网络供应商的文档, 维基百科或其他来源采取常用的值, 可以直接使用.'
        ;;
    18)
        TMOE_ARIA2_GREP_NAME='optimize-concurrent-downloads'
        TMOE_ARIA2_TIPS='默认为false,根据可用带宽优化并发下载的数量. aria2 使用之前统计的下载速度通过规则 N = A + B Log10 (速度单位为 Mbps) 得到并发下载的数量. 其中系数 A 和 B 可以在参数中以冒号分隔自定义. 默认值 (A=5, B=25) 可以在 1Mbps 网络上使用通常 5 个并发下载, 在 100Mbps 网络上为 50 个. 并发下载的数量保持在 --max-concurrent-downloads 参数定义的最大之下.'
        ;;
    19)
        TMOE_ARIA2_OPTION_01="${HOME}/.aria2/aria2.session"
        TMOE_ARIA2_OPTION_02="./aria2.session"
        TMOE_ARIA2_GREP_NAME='input-file'
        TMOE_ARIA2_TIPS='默认为./aria2.session'
        ;;
    20)
        TMOE_ARIA2_GREP_NAME='save-session'
        TMOE_ARIA2_TIPS=' 在Aria2退出时保存"错误/未完成"的下载任务到会话文件.\n当退出时保存错误及未完成的任务到指定的文件中. 您可以在重启 aria2 时使用 --input-file 选项重新加载. 如果您希望输出的内容使用 GZip 压缩, 您可以在文件名后增加 .gz 扩展名. 请注意, 通过 aria2.addTorrent() 和 aria2.addMetalink() RPC 方法添加的下载, 其元数据没有保存到文件的将不会保存. 通过 aria2.remove() 和 aria2.forceRemove() 删除的下载将不会保存.'
        ;;
    21)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='save-session-interval'
        TMOE_ARIA2_TIPS=' 需1.16.1以上版本, 默认:0,每隔此选项设置的时间(秒)后会保存错误或未完成的任务到 --save-session 选项指定的文件中. 如果设置为 0, 仅当 aria2 退出时才会保存.'
        ;;
    22)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='auto-save-interval'
        TMOE_ARIA2_TIPS='每隔设置的秒数自动保存控制文件(*.aria2). 如果设置为 0, 下载期间控制文件不会自动保存. 不论设置的值为多少, aria2 会在任务结束时保存控制文件. 可以设置的值为 0 到 600.'
        ;;
    esac
    ##############################
    if [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "01" ]; then
        tmoe_aria2_settings_model_01
    elif [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "02" ]; then
        tmoe_aria2_settings_model_02
    fi
    press_enter_to_return
    tmoe_aria2_connection_threads
}
######################
tmoe_aria2_port() {
    TMOE_ARIA2_OPTION_01='true'
    TMOE_ARIA2_OPTION_02='false'
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_port'
    TMOE_OPTION=$(whiptail --title "端口" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "RPC监听端口" \
        "02" "BT监听端口" \
        "03" "DHT网络监听端口" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_OPTION_01="16800"
        TMOE_ARIA2_OPTION_02="6800"
        TMOE_ARIA2_OPTION_03="8443"
        TMOE_ARIA2_OPTION_04="18443"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='rpc-listen-port'
        TMOE_ARIA2_TIPS='RPC监听端口, 端口被占用时可以修改, 默认:6800'
        ;;
    02)
        TMOE_ARIA2_OPTION_01="36881-36999"
        TMOE_ARIA2_OPTION_02="6881-6999"
        TMOE_ARIA2_GREP_NAME='listen-port'
        TMOE_ARIA2_TIPS='BT监听端口, 当端口被屏蔽时使用, 默认:6881-6999'
        ;;
    03)
        TMOE_ARIA2_OPTION_01="56881-56999"
        TMOE_ARIA2_OPTION_02="6881-6999"
        TMOE_ARIA2_GREP_NAME='min-split-size'
        TMOE_ARIA2_TIPS='默认:6881-6999\n设置 BT 下载的 TCP 端口. 多个端口可以使用逗号 "," 分隔, 例如: 6881,6885. 您还可以使用短横线 "-" 表示范围: 6881-6999, 或可以一起使用: 6881-6889, 6999'
        ;;
    esac
    ##############################
    if [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "01" ]; then
        tmoe_aria2_settings_model_01
    elif [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "02" ]; then
        tmoe_aria2_settings_model_02
    fi
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
tmoe_aria2_http() {
    TMOE_ARIA2_OPTION_01='true'
    TMOE_ARIA2_OPTION_02='false'
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_port'
    TMOE_OPTION=$(whiptail --title "端口" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "RPC监听端口" \
        "02" "BT监听端口" \
        "03" "DHT网络监听端口" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_OPTION_01="16800"
        TMOE_ARIA2_OPTION_02="6800"
        TMOE_ARIA2_OPTION_03="8443"
        TMOE_ARIA2_OPTION_04="18443"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='rpc-listen-port'
        TMOE_ARIA2_TIPS='RPC监听端口, 端口被占用时可以修改, 默认:6800'
        ;;
    02)
        TMOE_ARIA2_OPTION_01="36881-36999"
        TMOE_ARIA2_OPTION_02="6881-6999"
        TMOE_ARIA2_GREP_NAME='listen-port'
        TMOE_ARIA2_TIPS='BT监听端口, 当端口被屏蔽时使用, 默认:6881-6999'
        ;;
    03)
        TMOE_ARIA2_OPTION_01="56881-56999"
        TMOE_ARIA2_OPTION_02="6881-6999"
        TMOE_ARIA2_GREP_NAME='min-split-size'
        TMOE_ARIA2_TIPS='默认:6881-6999\n设置 BT 下载的 TCP 端口. 多个端口可以使用逗号 "," 分隔, 例如: 6881,6885. 您还可以使用短横线 "-" 表示范围: 6881-6999, 或可以一起使用: 6881-6889, 6999'
        ;;
    esac
    ##############################
    if [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "01" ]; then
        tmoe_aria2_settings_model_01
    elif [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "02" ]; then
        tmoe_aria2_settings_model_02
    fi
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
tmoe_aria2_bt_and_pt() {
    TMOE_ARIA2_OPTION_01='true'
    TMOE_ARIA2_OPTION_02='false'
    TMOE_ARIA2_SETTINGS_MODEL='01'
    RETURN_TO_WHERE='tmoe_aria2_bt_and_pt'
    TMOE_OPTION=$(whiptail --title "端口" --menu "您想要修改哪项配置？\nWhich conf do you want to modify?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "更新BT-tracker服务器" \
        "02" "follow-torrent 当下载的是一个种子(以.torrent结尾)时, 自动开始BT任务" \
        "03" "bt-max-peers 单个种子最大连接节点数" \
        "04" "enable-dht  打开ipv4 DHT功能" \
        "05" "enable-dht6  打开IPv6 DHT功能" \
        "06" "bt-enable-lpd  本地节点查找(LPD)" \
        "07" "enable-peer-exchange  种子（节点）交换" \
        "08" "bt-request-peer-speed-limit  期望下载速度（每个种子限速, 对少种的PT很有用）" \
        "09" "peer-id-prefix  节点 ID 前缀(客户端伪装), PT需要。" \
        "10" "peer-agent 指定 BT 扩展握手期间用于节点客户端版本的字符串" \
        "11" "bt-require-crypto  需要加密" \
        "12" "seed-ratio  种子分享率" \
        "13" "seed-time  最小做种时间" \
        "14" "force-save  强制保存会话, 即使任务已经完成, 默认:false" \
        "15" "bt-hash-check-seed  BT校验相关" \
        "16" "bt-seed-unverified  继续之前的BT任务时, 无需再次校验" \
        "17" "bt-save-metadata  保存种子文件" \
        "18" "bt-detach-seed-only  分离仅做种任务" \
        "19" "bt-enable-hook-after-hash-check  启用哈希检查完成事件" \
        "20" "bt-exclude-tracker  BT排除服务器地址" \
        "21" "bt-external-ip  外部 IP 地址" \
        "22" "bt-force-encryption  强制加密" \
        "23" "bt-load-saved-metadata  加载已保存的元数据文件" \
        "24" "bt-max-open-files  最多打开文件数" \
        "25" "bt-metadata-only  仅下载种子文件" \
        "26" "bt-min-crypto-level  最低加密级别" \
        "27" "bt-prioritize-piece  优先下载" \
        "28" "bt-remove-unselected-file  删除未选择的文件" \
        "29" "bt-stop-timeout  无速度时自动停止时间" \
        "30" "bt-tracker-connect-timeout  BT 服务器连接超时时间" \
        "31" "bt-tracker-interval  BT 服务器连接间隔时间" \
        "32" "bt-tracker-timeout  BT 服务器超时时间" \
        "33" "dht-file-path  DHT (IPv4) 文件" \
        "34" "dht-file-path6  DHT (IPv6) 文件" \
        "35" "dht-message-timeout  DHT 消息超时时间" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    00 | "") configure_aria2_rpc_server ;;
    01)
        TMOE_ARIA2_GREP_NAME='bt-tracker'
        # TMOE_ARIA2_TIPS='如果服务器地址在 --bt-exclude-tracker 选项中, 其将不会生效.\nwiki: BitTorrent tracker（中文可称：BT服务器、tracker服务器等）是帮助BitTorrent协议在节点与节点之间做连接的服务器。\nBitTorrent客户端下载一开始就要连接到tracker，从tracker获得其他客户端IP地址后，才能连接到其他客户端下载。在传输过程中，也会一直与tracker通信，上传自己的信息，获取其它客户端的信息。\n一般BitTorrent客户端可以手动添加tracker。tracker也会提供很多端口。\n由于tracker对BT下载起到客户端协调和调控的重要作用，所以一旦被封锁会严重影响BT下载。'
        aria2_bt_tracker
        #此处需要写配置脚本
        ;;
    02)
        TMOE_ARIA2_OPTION_03="mem"
        TMOE_ARIA2_OPTION_04=""
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='follow-torrent'
        TMOE_ARIA2_TIPS='默认:true,如果设置为"true"或"mem", 当后缀为 .torrent 或内容类型为 application/x-bittorrent 的文件下载完成时, aria2 将按种子文件读取并下载该文件中提到的文件. 如果设置为"mem"(仅内存), 该种子文件将不会写入到磁盘中, 而仅会存储在内存中. 如果设置为"false"(否), 则 .torrent 文件会下载到磁盘中, 但不会按种子文件读取并且其中的文件不会进行下载.'
        ;;
    03)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="55"
        TMOE_ARIA2_GREP_NAME='bt-max-peers'
        TMOE_ARIA2_TIPS='默认:55，0为无限制。'
        ;;
    04)
        TMOE_ARIA2_GREP_NAME='enable-dht'
        TMOE_ARIA2_TIPS=' PT需要禁用, BT建议启用,默认:true\n启用 IPv4 DHT 功能. 此选项同时会启用 UDP 服务器支持. 如果种子设置为私有, 即使此选项设置为"true", aria2 也不会启用 DHT.'
        ;;
    05)
        TMOE_ARIA2_GREP_NAME='enable-dht6'
        TMOE_ARIA2_TIPS='PT需要禁用,默认:false\n启用 IPv6 DHT 功能. 如果种子设置为私有, 即使此选项设置为"true", aria2 也不会启用 DHT. 使用 --dht-listen-port 选项设置监听的端口.'
        ;;
    06)
        TMOE_ARIA2_GREP_NAME='bt-enable-lpd'
        TMOE_ARIA2_TIPS='PT需要禁用, 默认:false'
        ;;
    07)
        TMOE_ARIA2_GREP_NAME='enable-peer-exchange'
        TMOE_ARIA2_TIPS='PT需要禁用,BT建议启用,默认:true\n启用节点交换扩展. 如果种子设置为私有, 即使此选项设置为"true", aria2 也不会启用此功能.'
        ;;
    08)
        TMOE_ARIA2_OPTION_01="100K"
        TMOE_ARIA2_OPTION_02="50K"
        TMOE_ARIA2_GREP_NAME='bt-request-peer-speed-limit'
        TMOE_ARIA2_TIPS='默认:50K.如果一个 BT 下载的整体下载速度低于此选项设置的值, aria2 会临时提高连接数以提高下载速度. 在某些情况下, 设置期望下载速度可以提高您的下载速度. 您可以增加数值的单位 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    09)
        TMOE_ARIA2_OPTION_01="-TR2940-"
        TMOE_ARIA2_OPTION_02="A2-1-35-0-"
        TMOE_ARIA2_GREP_NAME='peer-id-prefix'
        TMOE_ARIA2_TIPS='Tmoe-linux下的aria2配置默认伪装成Transmission 2.94\n指定节点 ID 的前缀. BT 中节点 ID 长度为 20 字节. 如果超过 20 字节, 将仅使用前 20 字节. 如果少于 20 字节, 将在其后不足随机的数据保证为 20 字节,默认:A2-1-35-0-'
        ;;
    10)
        TMOE_ARIA2_OPTION_01="Transmission/2.94"
        TMOE_ARIA2_OPTION_02="aria2/1.35.0"
        TMOE_ARIA2_GREP_NAME='peer-agent'
        TMOE_ARIA2_TIPS='默认:aria2/1.35.0'
        ;;
    11)
        TMOE_ARIA2_GREP_NAME='bt-require-crypto'
        TMOE_ARIA2_TIPS='如果设置为"true", aria 将不会接受以前的 BitTorrent 握手协议(\\19BitTorrent 协议)并建立连接. 因此 aria2 总是模糊握手.'
        ;;
    12)
        TMOE_ARIA2_OPTION_01="0.0"
        TMOE_ARIA2_OPTION_02="1.0"
        TMOE_ARIA2_OPTION_03="1.5"
        TMOE_ARIA2_OPTION_04="2.0"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='seed-ratio'
        TMOE_ARIA2_TIPS='当种子的分享率达到这个数时, 自动停止做种, 0为一直做种, 默认:1.0\n如果您想不限制分享比率, 可以设置为 0.0 \n如果同时设置了 --seed-time 选项, 当任意一个条件满足时将停止做种.\n指定更高的分享率意味着您将为P2P网络（生态）作出更大的贡献。'
        ;;
    13)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="1"
        TMOE_ARIA2_OPTION_03="5"
        TMOE_ARIA2_OPTION_04="10"
        TMOE_ARIA2_SETTINGS_MODEL='02'
        TMOE_ARIA2_GREP_NAME='seed-time'
        TMOE_ARIA2_TIPS='此选项设置为 0 时, 将在 BT 任务下载完成后不进行做种.'
        ;;
    14)
        TMOE_ARIA2_GREP_NAME='force-save'
        TMOE_ARIA2_TIPS='较新的版本开启后会在任务完成后依然保留.aria2文件\n即使任务完成或删除时使用 --save-session 选项时也保存该任务. 此选项在这种情况下还会保存控制文件. 此选项可以保存被认为已经完成但正在做种的 BT 任务.'
        ;;
    15)
        TMOE_ARIA2_GREP_NAME='bt-hash-check-seed'
        TMOE_ARIA2_TIPS='默认:true，做种前检查文件哈希\n如果设置为"true", 当使用 --check-integrity 选项完成哈希检查及文件完成后才继续做种. 如果您希望仅当文件损坏或未完成时检查文件, 请设置为"false". 此选项仅对 BT 下载有效'
        ;;
    16)
        TMOE_ARIA2_GREP_NAME='bt-seed-unverified'
        TMOE_ARIA2_TIPS='默认:false,不检查之前下载文件中每个分片的哈希值.'
        ;;
    17)
        TMOE_ARIA2_GREP_NAME='bt-save-metadata'
        TMOE_ARIA2_TIPS='保存磁力链接元数据为种子文件(.torrent文件), 默认:false\n保存种子文件为 ".torrent" 文件. 此选项仅对磁链生效. 文件名为十六进制编码后的哈希值及 ".torrent"后缀. 保存的目录与下载文件的目录相同. 如果相同的文件已存在, 种子文件将不会保存.'
        ;;
    18)
        TMOE_ARIA2_GREP_NAME='bt-detach-seed-only'
        TMOE_ARIA2_TIPS='统计当前活动下载任务(参见 -j 选项) 时排除仅做种的任务. 这意味着, 如果参数设置为 -j3, 此选项打开并且当前有 3 个正在活动的任务, 并且其中有 1 个进入做种模式, 那么其会从正在下载的数量中排除(即数量会变为 2), 在队列中等待的下一个任务将会开始执行. 但要知道, 在 RPC 方法中, 做种的任务仍然被认为是活动的下载任务.'
        ;;
    19)
        TMOE_ARIA2_GREP_NAME='bt-enable-hook-after-hash-check'
        TMOE_ARIA2_TIPS='允许 BT 下载哈希检查(参见 -V 选项) 完成后调用命令. 默认情况下, 当哈希检查成功后, 通过 --on-bt-download-complete 设置的命令将会被执行. 如果要禁用此行为, 请设置为"false".'
        ;;
    20)
        TMOE_ARIA2_OPTION_01="*"
        TMOE_ARIA2_OPTION_02=""
        TMOE_ARIA2_GREP_NAME='bt-exclude-tracker'
        TMOE_ARIA2_TIPS='逗号分隔的 BT 排除服务器地址. 您可以使用 * 匹配所有地址, 因此将排除所有服务器地址. 当在 shell 命令行使用 * 时, 需要使用转义符或引号.'
        ;;
    21)
        TMOE_ARIA2_OPTION_01="*"
        TMOE_ARIA2_OPTION_02=""
        TMOE_ARIA2_GREP_NAME='bt-external-ip'
        TMOE_ARIA2_TIPS='指定用在 BitTorrent 下载和 DHT 中的外部 IP 地址. 它可能被发送到 BitTorrent 服务器. 对于 DHT, 此选项将会报告本地节点正在下载特定的种子. 这对于在私有网络中使用 DHT 非常关键. 虽然这个方法叫外部, 但其可以接受各种类型的 IP 地址.'
        ;;
    22)
        TMOE_ARIA2_GREP_NAME='bt-force-encryption'
        TMOE_ARIA2_TIPS='BT 消息中的内容需要使用 arc4 加密. 此选项是设置 --bt-require-crypto --bt-min-crypto-level=arc4 这两个选项的快捷方式. 此选项不会修改上述两个选项的内容. 如果设置为"true", 将拒绝以前的 BT 握手, 并仅使用模糊握手及加密消息.'
        ;;
    23)
        TMOE_ARIA2_GREP_NAME='bt-load-saved-metadata'
        TMOE_ARIA2_TIPS='当使用磁链下载时, 在从 DHT 获取种子元数据之前, 首先尝试加载使用 --bt-save-metadata 选项保存的文件. 如果文件加载成功, 则不会从 DHT 下载元数据.'
        ;;
    24)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="100"
        TMOE_ARIA2_GREP_NAME='bt-max-open-files'
        TMOE_ARIA2_TIPS='设置 BT/Metalink 下载全局打开的最大文件数.'
        ;;
    25)
        TMOE_ARIA2_GREP_NAME='bt-metadata-only'
        TMOE_ARIA2_TIPS='仅下载种子文件. 种子文件中描述的文件将不会下载. 此选项仅对磁链生效.'
        ;;
    26)
        TMOE_ARIA2_OPTION_01="arc4"
        TMOE_ARIA2_OPTION_02="plain"
        TMOE_ARIA2_GREP_NAME='bt-min-crypto-level'
        TMOE_ARIA2_TIPS='设置加密方法的最小级别. 如果节点提供多种加密方法, aria2 将选择满足给定级别的最低级别.'
        ;;
    27)
        TMOE_ARIA2_OPTION_01="100K"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='bt-prioritize-piece'
        TMOE_ARIA2_TIPS='尝试先下载每个文件开头或结尾的分片. 此选项有助于预览文件. 参数可以包括两个关键词: head 和 tail. 如果包含两个关键词, 需要使用逗号分隔. 每个关键词可以包含一个参数, SIZE. 例如, 如果指定 head=SIZE, 每个文件的最前 SIZE 数据将会获得更高的优先级. tail=SIZE 表示每个文件的最后 SIZE 数据. SIZE 可以包含 K 或 M (1K = 1024, 1M = 1024K).'
        ;;
    28)
        TMOE_ARIA2_GREP_NAME='bt-remove-unselected-file'
        TMOE_ARIA2_TIPS='当 BT 任务完成后删除未选择的文件. 要选择需要下载的文件, 请使用 --select-file 选项. 如果没有选择, 则所有文件都默认为需要下载. 此选项会从磁盘上直接删除文件, 请谨慎使用此选项.'
        ;;
    29)
        TMOE_ARIA2_OPTION_01="100"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='bt-stop-timeout'
        TMOE_ARIA2_TIPS='当 BT 任务F下载速度持续为 0, 达到此选项设置的时间后停止下载. 如果设置为 0, 此功能将禁用.'
        ;;
    30)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='bt-tracker-connect-timeout'
        TMOE_ARIA2_TIPS='设置 BT 服务器的连接超时时间 (秒). 当连接建立后, 此选项不再生效, 请使用 --bt-tracker-timeout 选项.'
        ;;
    31)
        TMOE_ARIA2_OPTION_01="60"
        TMOE_ARIA2_OPTION_02="0"
        TMOE_ARIA2_GREP_NAME='bt-tracker-interval'
        TMOE_ARIA2_TIPS='设置请求 BT 服务器的间隔时间 (秒). 此选项将完全覆盖服务器返回的最小间隔时间和间隔时间, aria2 仅使用此选项的值.如果设置为 0, aria2 将根据服务器的响应情况和下载进程决定时间间隔.'
        ;;
    32)
        TMOE_ARIA2_OPTION_01="0"
        TMOE_ARIA2_OPTION_02="60"
        TMOE_ARIA2_GREP_NAME='bt-tracker-timeout'
        TMOE_ARIA2_TIPS='默认为60'
        ;;
    33)
        TMOE_ARIA2_OPTION_01="${HOME}/.aria2/dht.dat"
        TMOE_ARIA2_OPTION_02="./dht.dat"
        TMOE_ARIA2_GREP_NAME='dht-file-path'
        TMOE_ARIA2_TIPS='修改 IPv4 DHT 路由表文件路径.'
        ;;
    34)
        TMOE_ARIA2_OPTION_01="${HOME}/.aria2/dht6.dat"
        TMOE_ARIA2_OPTION_02="./dht6.dat"
        TMOE_ARIA2_GREP_NAME='dht-file-path6'
        TMOE_ARIA2_TIPS='修改 IPv6 DHT 路由表文件路径.'
        ;;
    35)
        TMOE_ARIA2_OPTION_01="60"
        TMOE_ARIA2_OPTION_02="10"
        TMOE_ARIA2_GREP_NAME='dht-message-timeout'
        TMOE_ARIA2_TIPS='默认为10'
        ;;

    esac
    ##############################
    if [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "01" ]; then
        tmoe_aria2_settings_model_01
    elif [ "${TMOE_ARIA2_SETTINGS_MODEL}" = "02" ]; then
        tmoe_aria2_settings_model_02
    fi
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
######################
aria2_bt_tracker() {
    cat <<-'EOF'
     如果服务器地址在 --bt-exclude-tracker 选项中, 其将不会生效.
     wiki: BitTorrent tracker（中文可称：BT服务器、tracker服务器等）是帮助BitTorrent协议在节点与节点之间做连接的服务器。
     BitTorrent客户端下载一开始就要连接到tracker，从tracker获得其他客户端IP地址后，才能连接到其他客户端下载。在传输过程中，也会一直与tracker通信，上传自己的信息，获取其它客户端的信息。一般BitTorrent客户端可以手动添加tracker。tracker也会提供很多端口。
     由于tracker对BT下载起到客户端协调和调控的重要作用，所以一旦被封锁会严重影响BT下载。
EOF
    update_aria2_bt_tracker
    check_tmoe_aria2_config_value
    echo ${TMOE_ARIA2_CONFIG_STATUS}
    echo "更新完成，您可能需要重启aria2c进程才能生效"
    echo "如需自动更新，则请手动将${GREEN}aria2-i bt${RESET}添加至定时任务"
    press_enter_to_return
    ${RETURN_TO_WHERE}
}
################
update_aria2_bt_tracker() {
    #此处环境变量并非多余
    TMOE_ARIA2_FILE='/usr/local/etc/tmoe-linux/aria2/aria2.conf'
    BT_TRACKER_URL='https://raw.githubusercontent.com/ngosang/trackerslist/master/trackers_all.txt'
    echo ${BT_TRACKER_URL}
    list=$(curl -L ${BT_TRACKER_URL} | awk NF | sed ":a;N;s/\n/,/g;ta")
    if grep -q 'bt-tracker=' "${TMOE_ARIA2_FILE}"; then
        sed -i "s@bt-tracker.*@bt-tracker=$list@g" ${TMOE_ARIA2_FILE}
        echo 更新中......
    else
        sed -i '$a bt-tracker='${list} ${TMOE_ARIA2_FILE}
        echo 添加中......
    fi
    # pkill aria2c && systemctl start aria2
}
#######################
check_tmoe_aria2_config_value() {
    TMOE_ARIA2_CONFIG_VALUE=$(cat ${TMOE_ARIA2_FILE} | grep ${TMOE_ARIA2_GREP_NAME}= | head -n 1 | cut -d '=' -f 2)
    TMOE_ARIA2_CONFIG_LINE=$(cat ${TMOE_ARIA2_FILE} | grep -n ${TMOE_ARIA2_GREP_NAME}= | head -n 1 | awk '{print $1}' | cut -d ':' -f 1)
    if grep -q "^${TMOE_ARIA2_GREP_NAME}=" ${TMOE_ARIA2_FILE}; then
        TMOE_ARIA2_CONFIG_STATUS="检测到${TMOE_ARIA2_GREP_NAME}的值为${TMOE_ARIA2_CONFIG_VALUE}"
        TMOE_ARIA2_CONFIG_ENABLED='true'
    elif grep -q "^#${TMOE_ARIA2_GREP_NAME}=" ${TMOE_ARIA2_FILE}; then
        TMOE_ARIA2_CONFIG_STATUS="检测到${TMOE_ARIA2_GREP_NAME}的值为默认"
        TMOE_ARIA2_CONFIG_ENABLED='false'
    else
        TMOE_ARIA2_CONFIG_STATUS="检测到您未启用${TMOE_ARIA2_GREP_NAME}"
        TMOE_ARIA2_CONFIG_ENABLED='no'
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
        "4" "注释/隐藏${TMOE_ARIA2_GREP_NAME}(禁用该参数或使用默认值)" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") ${RETURN_TO_WHERE} ;;
    1) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_01} ;;
    2) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_02} ;;
    3) custom_aria2_config ;;
    4) TMOE_ARIA2_CONFIG_ENABLED='hide' ;;
    esac
    ##############################
    modify_aria2_config_value
    press_enter_to_return
    tmoe_aria2_settings_model_01
}
######################
tmoe_aria2_settings_model_02() {
    check_tmoe_aria2_config_value
    TMOE_OPTION=$(whiptail --title "您想要将参数${TMOE_ARIA2_GREP_NAME}修改为哪个值" --menu "${TMOE_ARIA2_CONFIG_STATUS}\n${TMOE_ARIA2_TIPS}" 0 50 0 \
        "0" "Return to previous menu 返回上级菜单" \
        "1" "${TMOE_ARIA2_OPTION_01}" \
        "2" "${TMOE_ARIA2_OPTION_02}" \
        "3" "${TMOE_ARIA2_OPTION_03}" \
        "4" "${TMOE_ARIA2_OPTION_04}" \
        "5" "custom手动输入" \
        "6" "注释/隐藏${TMOE_ARIA2_GREP_NAME}(禁用该参数或使用默认值)" \
        3>&1 1>&2 2>&3)
    ##############################
    case "${TMOE_OPTION}" in
    0 | "") ${RETURN_TO_WHERE} ;;
    1) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_01} ;;
    2) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_02} ;;
    3) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_03} ;;
    4) TMOE_ARIA2_OPTION_TARGET=${TMOE_ARIA2_OPTION_04} ;;
    5) custom_aria2_config ;;
    6) TMOE_ARIA2_CONFIG_ENABLED='hide' ;;
    esac
    ##############################
    modify_aria2_config_value
    press_enter_to_return
    tmoe_aria2_settings_model_02
}
#############
modify_aria2_config_value() {
    case "${TMOE_ARIA2_CONFIG_ENABLED}" in
    true | false) #sed -i "s@${TMOE_ARIA2_CONFIG_VALUE}@${TMOE_ARIA2_OPTION_TARGET}@g" ${TMOE_ARIA2_FILE}
        sed -i "${TMOE_ARIA2_CONFIG_LINE} c ${TMOE_ARIA2_GREP_NAME}=${TMOE_ARIA2_OPTION_TARGET}" ${TMOE_ARIA2_FILE}
        ;;
        #false)
        #   sed -i "s@^#${TMOE_ARIA2_GREP_NAME}@${TMOE_ARIA2_GREP_NAME}@" ${TMOE_ARIA2_FILE}
        #  sed -i "s@${TMOE_ARIA2_CONFIG_VALUE}@${TMOE_ARIA2_OPTION_TARGET}@g" ${TMOE_ARIA2_FILE}
        # ;;
    no) sed -i "$ a ${TMOE_ARIA2_GREP_NAME}=${TMOE_ARIA2_OPTION_TARGET}" ${TMOE_ARIA2_FILE} ;;
    hide) sed -i "s@^${TMOE_ARIA2_GREP_NAME}=@#&@" ${TMOE_ARIA2_FILE} ;;
    esac
    check_tmoe_aria2_config_value
    echo "${TMOE_ARIA2_GREP_NAME} has been modified."
    #echo "${TMOE_ARIA2_GREP_NAME}的值已修改为${TMOE_ARIA2_CONFIG_VALUE}"
    echo ${TMOE_ARIA2_CONFIG_STATUS}
}
###################
custom_aria2_config() {
    TMOE_ARIA2_OPTION_TARGET=$(whiptail --inputbox "请手动输入参数${TMOE_ARIA2_GREP_NAME}的值" 0 0 --title "${TMOE_ARIA2_GREP_NAME} conf" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        ${RETURN_TO_WHERE}
    elif [ -z "${TMOE_ARIA2_OPTION_TARGET}" ]; then
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
        "1" "BT/磁力+PT种子" \
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
    upgrade_tmoe_aria2_tool
    press_enter_to_return
    configure_aria2_rpc_server
    #此处的返回步骤并非多余
}
############
main "$@"
###########################################
