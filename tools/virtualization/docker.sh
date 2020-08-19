#!/usr/bin/env bash
##########################
run_special_tag_docker_container() {
    service docker start 2>/dev/null || systemctl start docker
    docker stop ${CONTAINER_NAME} 2>/dev/null
    MOUNT_DOCKER_FOLDER=/media/docker
    if [ ! -d "${MOUNT_DOCKER_FOLDER}" ]; then
        mkdir -p ${MOUNT_DOCKER_FOLDER}
        chown -R ${CURRENT_USER_NAME}:${CURRENT_USER_GROUP} ${MOUNT_DOCKER_FOLDER}
    fi
    TMOE_LINUX_DOCKER_SHELL_FILE="${MOUNT_DOCKER_FOLDER}/.tmoe-linux-docker.sh"
    if [ ! -e "${TMOE_LINUX_DOCKER_SHELL_FILE}" ]; then
        aria2c --allow-overwrite=true -d ${MOUNT_DOCKER_FOLDER} -o ".tmoe-linux-docker.sh" https://gitee.com/mo2/linux/raw/master/debian.sh
        #aria2c --allow-overwrite=true -d ${MOUNT_DOCKER_FOLDER} -o ".tmoe-linux-tool.sh" https://gitee.com/mo2/linux/raw/master/tool.sh
        sed -i 's@###tmoe_locale_gen@tmoe_locale_gen@g' ${TMOE_LINUX_DOCKER_SHELL_FILE}
        sed -i 's@###tuna_mirror@tuna_mirror@g' ${TMOE_LINUX_DOCKER_SHELL_FILE}
    fi
    echo "${BLUE}docker run -itd --name ${CONTAINER_NAME} --env LANG=${TMOE_LANG} --restart on-failure -v ${MOUNT_DOCKER_FOLDER}:${MOUNT_DOCKER_FOLDER} ${DOCKER_NAME}:${DOCKER_TAG}${RESET}"
    docker run -itd --name ${CONTAINER_NAME} --env LANG=${TMOE_LANG} --restart on-failure -v ${MOUNT_DOCKER_FOLDER}:${MOUNT_DOCKER_FOLDER} ${DOCKER_NAME}:${DOCKER_TAG}
    echo "已将宿主机的${YELLOW}${MOUNT_DOCKER_FOLDER}${RESET}目录${RED}挂载至${RESET}容器内的${BLUE}${MOUNT_DOCKER_FOLDER}${RESET}"
    echo "You can type ${GREEN}sudo docker exec -it ${CONTAINER_NAME} sh${RESET} to connect ${CONTAINER_NAME} container."
    echo "您可以输${GREEN}docker attach ${CONTAINER_NAME}${RESET}来连接${CONTAINER_NAME}容器"
    echo "Do you want to start and configure this container?"
    echo "您是否想要启动并配置本容器？"
    do_you_want_to_continue
    docker start ${CONTAINER_NAME}
    docker exec -it ${CONTAINER_NAME} /bin/sh ${TMOE_LINUX_DOCKER_SHELL_FILE}
}
##############
only_delete_docker_container() {
    service docker start 2>/dev/null || systemctl start docker

    cat <<-EOF
		${RED}docker stop ${CONTAINER_NAME}
		docker rm ${CONTAINER_NAME}${RESET}
	EOF
    do_you_want_to_continue
    docker stop ${CONTAINER_NAME} 2>/dev/null
    docker rm ${CONTAINER_NAME} 2>/dev/null
}
##########
delete_docker_container_and_image() {
    only_delete_docker_container
    cat <<-EOF
		${RED}docker rmi ${DOCKER_NAME}:${DOCKER_TAG}
		docker rmi ${DOCKER_NAME}:${DOCKER_TAG_02}${RESET}
	EOF
    #docker rm ${CONTAINER_NAME} 2>/dev/null
    docker rmi ${DOCKER_NAME}:${DOCKER_TAG} 2>/dev/null
    if [ ! -z "${DOCKER_TAG_02}" ]; then
        docker rmi ${DOCKER_NAME}:${DOCKER_TAG_02} 2>/dev/null
    fi
    docker rmi ${DOCKER_NAME} 2>/dev/null
    if [ ! -z "${DOCKER_NAME_02}" ]; then
        docker rmi ${DOCKER_NAME_02}:${DOCKER_TAG} 2>/dev/null
        docker rmi ${DOCKER_NAME_02}:${DOCKER_TAG_02} 2>/dev/null
        docker rmi ${DOCKER_NAME_02} 2>/dev/null
    fi
}
##################
reset_docker_container() {
    delete_docker_container_and_image
    echo "${BLUE}docker pull ${DOCKER_NAME}:${DOCKER_TAG}${RESET}"
    docker pull ${DOCKER_NAME}:${DOCKER_TAG}
    run_special_tag_docker_container
}
###############
tmoe_docker_readme() {
    cat <<-ENDOFDOCKER
	${GREEN}service docker start || systemctl start docker${RESET}	${BLUE}启动docker${RESET}
	${GREEN}systemctl enable docker${RESET}	${BLUE}将docker设定为开机自启${RESET}
	---------------------------------
    ${GREEN}docker ps${RESET} 	${BLUE}列出当前正在运行的容器${RESET}
    ${GREEN}docker ps -a${RESET} 	${BLUE}列出所有容器${RESET}
    ${GREEN}docker start ${CONTAINER_NAME}${RESET}	${BLUE}启动${CONTAINER_NAME}容器${RESET}
    ${GREEN}docker stop ${CONTAINER_NAME}${RESET} 	${BLUE}停止${CONTAINER_NAME}容器${RESET}
    ${GREEN}docker attach ${CONTAINER_NAME}${RESET} 	${BLUE}连接${CONTAINER_NAME}容器${RESET}
    ${GREEN}docker exec -it ${CONTAINER_NAME} /bin/bash${RESET} 	${BLUE}对${CONTAINER_NAME}容器执行/bin/bash${RESET}
	${GREEN}docker exec -it ${CONTAINER_NAME} /bin/sh${RESET} 	${BLUE}对${CONTAINER_NAME}容器执行/bin/sh${RESET}
ENDOFDOCKER
}
#############
custom_docker_container_tag() {
    if [ "$(echo ${DOCKER_NAME} | grep '/')" ]; then
        #https://hub.docker.com/r/kalilinux/kali-rolling/tags
        DOCKER_URL="https://hub.docker.com/r/${DOCKER_NAME}/tags"
    else
        DOCKER_URL="https://hub.docker.com/_/${DOCKER_NAME}?tab=tags"
    fi
    TARGET=$(whiptail --inputbox "Please type the container tag,\nyou may be able to get more info via \n${DOCKER_URL}" 0 50 --title "DOCKER TAG" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ]; then
        ${RETURN_TO_WHERE}
    elif [ -z "${TARGET}" ]; then
        echo "请输入有效的值"
        echo "Please enter a valid value"
    else
        DOCKER_TAG=${TARGET}
        run_special_tag_docker_container
    fi
}
##########
tmoe_docker_management_menu_01() {
    RETURN_TO_WHERE='tmoe_docker_management_menu_01'
    DOCKER_TAG=${DOCKER_TAG_01}
    VIRTUAL_TECH=$(
        whiptail --title "${DOCKER_NAME} CONTAINER(docker容器)" --menu "Which container do you want to run?" 0 0 0 \
            "1" "${DOCKER_TAG_01}" \
            "2" "${DOCKER_TAG_02}" \
            "3" "custom tag(运行自定义标签的容器)" \
            "4" "readme of ${CONTAINER_NAME} 说明" \
            "5" "reset(重置容器数据并重拉${DOCKER_TAG}镜像)" \
            "6" "delete(删除${CONTAINER_NAME}容器)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    #############
    case ${VIRTUAL_TECH} in
    0 | "") choose_gnu_linux_docker_images ;;
    1)
        DOCKER_TAG=${DOCKER_TAG_01}
        run_special_tag_docker_container
        ;;
    2)
        DOCKER_TAG=${DOCKER_TAG_02}
        run_special_tag_docker_container
        ;;
    3) custom_docker_container_tag ;;
    4) tmoe_docker_readme ;;
    5) reset_docker_container ;;
    6) delete_docker_container ;;
    esac
    ###############
    press_enter_to_return
    tmoe_docker_management_menu_01
}
###########
delete_docker_container() {
    if (whiptail --title "Delete container" --yes-button 'container' --no-button 'container+image' --yesno "What do you want to delete?\n您是想要删除容器,还是删除容器+镜像？" 0 50); then
        only_delete_docker_container
    else
        delete_docker_container_and_image
    fi
}
############
tmoe_docker_management_menu_02() {
    RETURN_TO_WHERE='tmoe_docker_management_menu_02'
    DOCKER_TAG=${DOCKER_TAG_01}
    VIRTUAL_TECH=$(
        whiptail --title "${DOCKER_NAME} CONTAINER(docker容器)" --menu "Which container do you want to run?" 0 0 0 \
            "1" "${DOCKER_NAME}" \
            "2" "${DOCKER_NAME_02}" \
            "3" "custom tag(运行自定义标签的容器)" \
            "4" "readme of ${CONTAINER_NAME} 说明" \
            "5" "reset(重置容器数据并重拉${DOCKER_NAME}:${DOCKER_TAG_01}镜像)" \
            "6" "delete(删除${CONTAINER_NAME}容器)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    #############
    case ${VIRTUAL_TECH} in
    0 | "") choose_gnu_linux_docker_images ;;
    1) run_special_tag_docker_container ;;
    2)
        DOCKER_NAME=${DOCKER_NAME_02}
        run_special_tag_docker_container
        ;;
    3) custom_docker_container_tag ;;
    4) tmoe_docker_readme ;;
    5) reset_docker_container ;;
    6) delete_docker_container ;;
    esac
    ###############
    press_enter_to_return
    tmoe_docker_management_menu_02
}
###########
tmoe_docker_management_menu_03() {
    RETURN_TO_WHERE='tmoe_docker_management_menu_03'
    DOCKER_TAG=${DOCKER_TAG_01}
    VIRTUAL_TECH=$(
        whiptail --title "${DOCKER_NAME} CONTAINER(docker容器)" --menu "Which container do you want to run?" 0 0 0 \
            "1" "${DOCKER_TAG_01}" \
            "2" "custom tag(运行自定义标签的容器)" \
            "3" "readme of ${CONTAINER_NAME} 说明" \
            "4" "reset(重置容器数据并重拉${DOCKER_TAG_01}镜像)" \
            "5" "delete(删除${CONTAINER_NAME}容器)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    #############
    case ${VIRTUAL_TECH} in
    0 | "") choose_gnu_linux_docker_images ;;
    1) run_special_tag_docker_container ;;
    2) custom_docker_container_tag ;;
    3) tmoe_docker_readme ;;
    4) reset_docker_container ;;
    5) delete_docker_container ;;
    esac
    ###############
    press_enter_to_return
    tmoe_docker_management_menu_03
}
###########
choose_gnu_linux_docker_images() {
    check_docker_installation
    RETURN_TO_WHERE='choose_gnu_linux_docker_images'
    DOCKER_TAG_01='latest'
    CONTAINER_NAME=''
    DOCKER_MANAGEMENT_MENU='01'
    SELECTED_GNU_LINUX=$(whiptail --title "DOCKER IMAGES" --menu "Which distribution image do you want to pull? \n您想要拉取哪个GNU/Linux发行版的镜像?" 0 50 0 \
        "00" "Return to previous menu 返回上级菜单" \
        "01" "🏔️ alpine:非glibc的精简系统" \
        "02" "🍥 Debian:最早的发行版之一" \
        "03" "🍛 Ubuntu:我的存在是因為大家的存在" \
        "04" "🐉 Kali Rolling:设计用于数字取证和渗透测试" \
        "05" "arch:系统设计以KISS为总体指导原则" \
        "06" "👒 fedora:红帽社区版,新技术试验场" \
        "07" "centos(基于红帽的社区企业操作系统)" \
        "08" "opensuse tumbleweed(小蜥蜴风滚草)" \
        "09" "gentoo(追求极限配置和极高自由,stage3-amd64)" \
        "10" "clearlinux(intel发行的系统)" \
        "11" "Void(基于xbps包管理器的独立发行版)" \
        "12" "oracle(甲骨文基于红帽发行的系统)" \
        "13" "amazon(亚马逊云服务发行版)" \
        "14" "crux(lightweight轻量化)" \
        "15" "openwrt(常见于路由器)" \
        "16" "alt(起源于俄罗斯的发行版)" \
        "17" "photon(VMware专为ESXi定制的容器系统)" \
        3>&1 1>&2 2>&3)
    #############
    case ${SELECTED_GNU_LINUX} in
    00 | "") tmoe_docker_menu ;;
    01)
        DOCKER_TAG_02='edge'
        DOCKER_NAME='alpine'
        ;;
    02)
        DOCKER_TAG_01='unstable'
        DOCKER_TAG_02='stable'
        DOCKER_NAME='debian'
        ;;
    03)
        DOCKER_TAG_02='devel'
        DOCKER_NAME='ubuntu'
        ;;
    04)
        DOCKER_NAME='kalilinux/kali-rolling'
        DOCKER_NAME_02='kalilinux/kali'
        CONTAINER_NAME='kali'
        DOCKER_MANAGEMENT_MENU='02'
        ;;
    05)
        DOCKER_NAME='archlinux'
        CONTAINER_NAME='arch'
        DOCKER_MANAGEMENT_MENU='03'
        ;;
    06)
        DOCKER_TAG_02='rawhide'
        DOCKER_NAME='fedora'
        ;;
    07)
        DOCKER_TAG_01='latest'
        DOCKER_TAG_02='7'
        DOCKER_NAME='centos'
        CONTAINER_NAME='cent'
        ;;
    08)
        DOCKER_NAME='opensuse/tumbleweed'
        DOCKER_NAME_02='opensuse/leap'
        CONTAINER_NAME='suse'
        DOCKER_MANAGEMENT_MENU='02'
        ;;
    09)
        DOCKER_NAME='gentoo/stage3-amd64'
        DOCKER_NAME_02='gentoo/stage3-amd64-hardened-nomultilib'
        CONTAINER_NAME='gentoo'
        DOCKER_MANAGEMENT_MENU='02'
        ;;
    10)
        DOCKER_TAG_01='latest'
        DOCKER_TAG_02='base'
        DOCKER_NAME='clearlinux'
        CONTAINER_NAME='clear'
        ;;
    11)
        DOCKER_NAME='voidlinux/voidlinux'
        DOCKER_NAME_02='voidlinux/voidlinux-musl'
        CONTAINER_NAME='void'
        DOCKER_MANAGEMENT_MENU='02'
        ;;
    12)
        DOCKER_TAG_02='7'
        DOCKER_NAME='oraclelinux'
        CONTAINER_NAME='oracle'
        ;;
    13)
        DOCKER_TAG_02='with-sources'
        DOCKER_NAME='amazonlinux'
        CONTAINER_NAME='amazon'
        ;;
    14)
        DOCKER_TAG_02='3.4'
        DOCKER_NAME='crux'
        ;;
    15)
        DOCKER_NAME='openwrtorg/rootfs'
        CONTAINER_NAME='openwrt'
        DOCKER_MANAGEMENT_MENU='03'
        ;;
    16)
        DOCKER_TAG_02='sisyphus'
        DOCKER_NAME='alt'
        ;;
    17)
        DOCKER_TAG_02='2.0'
        DOCKER_NAME='photon'
        ;;
    esac
    ###############
    if [ -z "${CONTAINER_NAME}" ]; then
        CONTAINER_NAME=${DOCKER_NAME}
    fi
    case ${DOCKER_MANAGEMENT_MENU} in
    01) tmoe_docker_management_menu_01 ;;
    02) tmoe_docker_management_menu_02 ;;
    03) tmoe_docker_management_menu_03 ;;
    esac
    ###########
    press_enter_to_return
    choose_gnu_linux_docker_images
}
#############
install_docker_ce_or_io() {
    case "${TMOE_PROOT}" in
    true | no)
        echo "${RED}WARNING！${RESET}检测到您当前处于${GREEN}proot容器${RESET}环境下！"
        echo "若您处于容器环境下,且宿主机为${BOLD}Android${RESET}系统，则请在安装前${BLUE}确保${RESET}您的Linux内核支持docker"
        echo "否则请通过qemu-system来运行GNU/Linux虚拟机，再安装docker。"
        echo "If your host is android, it is recommended that you use the qemu-system virtual machine to run docker."
        do_you_want_to_continue
        ;;
    false) echo "检测到您当前处于chroot容器环境下" ;;
    esac
    if (whiptail --title "DOCKER本体" --yes-button 'docker-ce' --no-button 'docker.io' --yesno "Which software do you want to install?\n为避免冲突,请只选择其中一个" 0 50); then
        install_docker_ce
    else
        install_docker_io
    fi
    docker version
}
##############
add_current_user_to_docker_group() {
    echo "Do you want to add ${CURRENT_USER_NAME} to docker group?"
    echo "${YELLOW}gpasswd -a ${CURRENT_USER_NAME} docker${RESE}"
    do_you_want_to_continue
    if [ ! "$(groups | grep docker)" ]; then
        groupadd docker
    fi
    gpasswd -a ${CURRENT_USER_NAME} docker
    echo "您可以手动执行${GREEN}newgrp docker${RESET}来刷新docker用户组"
    echo "If you want to remove it,then type ${RED}gpasswd -d ${CURRENT_USER_NAME} docker${RESET}"
    echo "若您需要将当前用户移出docker用户组，则请输${RED}gpasswd -d ${CURRENT_USER_NAME} docker${RESET}"
}
##########
docker_163_mirror() {
    if [ ! -d /etc/docker ]; then
        mkdir -p /etc/docker
    fi
    cd /etc/docker
    if [ ! -e daemon.json ]; then
        echo '' >daemon.json
    fi
    if ! grep -q 'registry-mirrors' "daemon.json"; then
        cat >>daemon.json <<-'EOF'
		
			{
			"registry-mirrors": [
			"https://hub-mirror.c.163.com/"
			]
			}
		EOF
    else
        cat <<-'EOF'
			检测到您已经设定了registry-mirrors,请手动修改daemon.json为以下配置。
			{
			"registry-mirrors": [
			"https://hub-mirror.c.163.com/"
			]
			}
		EOF
    fi
}
##########
docker_mirror_source() {
    RETURN_TO_WHERE='docker_mirror_source'
    VIRTUAL_TECH=$(
        whiptail --title "DOCKER MIRROR" --menu "您想要修改哪些docker配置？" 0 0 0 \
            "1" "163镜像" \
            "2" "edit daemon.json" \
            "3" "edit software source软件本体源" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    #############
    case ${VIRTUAL_TECH} in
    0 | "") tmoe_docker_menu ;;
    1) docker_163_mirror ;;
    2) nano /etc/docker/daemon.json ;;
    3)
        non_debian_function
        nano /etc/apt/sources.list.d/docker.list
        ;;
    esac
    ###############
    press_enter_to_return
    docker_mirror_source
}
##########
tmoe_docker_menu() {
    RETURN_TO_WHERE='tmoe_docker_menu'
    VIRTUAL_TECH=$(
        whiptail --title "DOCKER容器" --menu "您想要对docker小可爱做什么?" 0 0 0 \
            "1" "🐋 install docker-ce(安装docker社区版引擎)" \
            "2" "🍭 pull distro images(拉取alpine,debian和ubuntu镜像)" \
            "3" "🌉 portainer(web端图形化docker容器管理)" \
            "4" "🍥 mirror source镜像源" \
            "5" "add ${CURRENT_USER_NAME} to docker group(添加当前用户至docker用户组)" \
            "0" "🌚 Return to previous menu 返回上级菜单" \
            3>&1 1>&2 2>&3
    )
    #############
    case ${VIRTUAL_TECH} in
    0 | "") install_container_and_virtual_machine ;;
    1) install_docker_ce_or_io ;;
    2) choose_gnu_linux_docker_images ;;
    3) install_docker_portainer ;;
    4) docker_mirror_source ;;
    5) add_current_user_to_docker_group ;;
    esac
    ###############
    press_enter_to_return
    tmoe_docker_menu
}
############
debian_add_docker_gpg() {
    if [ "${DEBIAN_DISTRO}" = 'ubuntu' ]; then
        DOCKER_RELEASE='ubuntu'
    else
        DOCKER_RELEASE='debian'
    fi
    cd /tmp
    curl -Lv -o '.docker-tuna.html' "https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/${DOCKER_RELEASE}/dists/"
    DOCKER_TUNA_FIRST_CODE=$(cat .docker-tuna.html | grep link | sed -n 2p | cut -d '=' -f 3 | cut -d '"' -f 2 | cut -d '/' -f 1)
    #curl -Lv https://download.docker.com/linux/${DOCKER_RELEASE}/gpg | apt-key add -
    if [ ! $(command -v lsb_release) ]; then
        apt update
        apt install lsb-release
    fi

    CURRENT_DOCKER_CODE=$(cat .docker-tuna.html | grep link | grep $(lsb_release -cs))
    if [ -z "${CURRENT_DOCKER_CODE}" ]; then
        DOCKER_CODE=${DOCKER_TUNA_FIRST_CODE}
    else
        DOCKER_CODE="$(lsb_release -cs)"
    fi
    rm .docker-tuna.html
    curl -Lv https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/${DOCKER_RELEASE}/gpg | apt-key add -
    cd /etc/apt/sources.list.d/
    sed -i 's/^deb/# &/g' docker.list 2>/dev/null
    #case "$(lsb_release -cs)" in
    #sid) DOCKER_CODE="buster" ;;
    #esac
    if (whiptail --title "请选择软件源" --yes-button "tuna" --no-button "docker.com" --yesno "Please select docker software source." 0 50); then
        echo "deb https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/${DOCKER_RELEASE} ${DOCKER_CODE} stable" >>docker.list
    else
        echo "deb https://download.docker.com/linux/${DOCKER_RELEASE} ${DOCKER_CODE} stable" >>docker.list
    fi
}
#################
check_docker_installation() {
    if [ ! "$(command -v docker)" ]; then
        echo "检测到您尚未安装docker，请先安装docker"
        install_docker_ce_or_io
    fi
}
############
install_docker_portainer() {
    check_docker_installation
    TARGET_PORT=$(whiptail --inputbox "请设定访问端口号,例如39080,默认内部端口为9000\n Please enter the port." 0 50 --title "PORT" 3>&1 1>&2 2>&3)
    if [ "$?" != "0" ] || [ -z "${TARGET_PORT}" ]; then
        echo "端口无效，请重新输入"
        press_enter_to_return
        tmoe_docker_menu
    fi
    service docker start 2>/dev/null || systemctl start docker
    docker stop portainer 2>/dev/null
    docker rm portainer 2>/dev/null
    #docker rmi portainer/portainer:latest 2>/dev/null
    docker pull portainer/portainer:latest
    docker run -d -p ${TARGET_PORT}:9000 --name portainer --restart always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer:latest
}
#####################
install_docker_io() {
    DEPENDENCY_01="docker.io"
    DEPENDENCY_02="docker"
    beta_features_quick_install
}
###########
install_docker_ce() {
    NON_DEBIAN='false'
    if [ ! $(command -v gpg) ]; then
        DEPENDENCY_01=""
        DEPENDENCY_02="gpg"
        beta_features_quick_install
    fi
    DEPENDENCY_02="docker-ce"
    DEPENDENCY_01="docker"
    #apt remove docker docker-engine docker.io
    if [ "${LINUX_DISTRO}" = 'debian' ]; then
        DEPENDENCY_01="docker-ce"
        DEPENDENCY_02="docker-ce-cli docker"
        debian_add_docker_gpg
    elif [ "${LINUX_DISTRO}" = 'redhat' ]; then
        curl -Lv -o /etc/yum.repos.d/docker-ce.repo "https://download.docker.com/linux/${REDHAT_DISTRO}/docker-ce.repo"
        sed -i 's@download.docker.com@mirrors.tuna.tsinghua.edu.cn/docker-ce@g' /etc/yum.repos.d/docker-ce.repo
    elif [ "${LINUX_DISTRO}" = 'arch' ]; then
        DEPENDENCY_01="docker"
    fi
    beta_features_quick_install
    if [ ! $(command -v docker) ]; then
        echo "安装失败，请执行${TMOE_INSTALLATON_COMMAND} docker.io"
    fi
}
#################
tmoe_docker_menu
