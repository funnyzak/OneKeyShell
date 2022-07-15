#!/bin/bash

#========================================================
#   System Required: CentOS 7+、Ubuntu、Debian、Bash 3.6+
#   Description: 系统维护脚本
#   Author: silenceace@gmail.com (Leon)
#========================================================

# version
SCRIPT_VERSION="0.1.0"

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
export PATH=$PATH:/usr/local/bin

# 脚本更新地址
SCRIPT_UPDATE_DOWNLINK="https://raw.githubusercontent.com/funnyzak/OneKeyShell/main/run.sh"

# 脚本运行时间
SH_RUN_START_TIME=$(date +%s)

# 临时路径
TMP_PATH="/tmp/${SH_RUN_START_TIME}"

# 脚本日志路径
SH_RUN_LOG_PATH="${TMP_PATH}/run.log"

# 主机名
HOST_NAME=$(hostname)

# 企业微信聊天机器人地址
qywx_bot_webhook_url="https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=your_qyweixin_key"

# 执行环境检查
pre_check() {
  mkdir -p ${TMP_PATH}

  echo "SCRIPT RUN TIME: $SH_RUN_START_TIME" > ${SH_RUN_LOG_PATH}

  command -v systemctl >> ${SH_RUN_LOG_PATH} 2>&1
  if [[ $? != 0 ]]; then
    echo -e "${red}不支持此系统：未找到 systemctl 命令${plain}"
    exit 1
  fi

  [[ $EUID -ne 0 ]] && echo -e "${red}请使用root用户运行此脚本！\n${plain}" && exit 1

  echo -e "\n本次运行日志请查看: ${yellow}tail -f -n 30 ${SH_RUN_LOG_PATH}${plain} \n"

}

# 获取时间差（毫秒级别）
# timediff $start $end
function timediff() {
  # time format:date +"%s.%N", such as 1502758855.907197692
  start_time=$1
  end_time=$2

  start_s=${start_time%.*}
  start_nanos=${start_time#*.}
  end_s=${end_time%.*}
  end_nanos=${end_time#*.}

  if [ "$end_nanos" -lt "$start_nanos" ];then
      end_s=$(( 10#$end_s - 1 ))
      end_nanos=$(( 10#$end_nanos + 10**9 ))
  fi

  time=$(( 10#$end_s - 10#$start_s )).`printf "%03d 秒" $(( (10#$end_nanos - 10#$start_nanos)/10**6 ))`
  echo $time
}

function calc_timediff_start() {
    start=$(date +"%s.%N")
}

function calc_timediff_result() {
  end=$(date +"%s.%N")
  echo -e "执行耗时：${yellow}$(timediff $start $end)${plain}"
}

# random string
# $1 length(1-32)
random_str() {
  random_str_length=$1
  if [[ $random_str_length == 0 || -z $random_str_length ]]; then
    random_str_length=16
  fi
  echo $(date +%s%N | md5_str | cut -c 1-$random_str_length)
}

# md5 string
# $1 md5 string
md5_str() {
  echo $(echo "$1" | md5sum | sed 's/ -//g')
}

# $1 下载URL
# $2 保存路径
# $3 保存文件名
# $4 文件名称（可选）
download_to_file() {
  download_to_file_downlink=$1
  download_to_file_path=$2
  download_to_file_name=$3
  download_to_file_title=$4

  if [[ -z "${download_to_file_downlink}" ]]; then
    read -ep "请输入下载地址: " download_to_file_downlink
  fi
  if [[ -z "${download_to_file_path}" ]]; then
    read -ep "请输入要保存的路径（如：/mnt/down，默认保存到：${TMP_PATH}）: " download_to_file_path
    if [[ -z "${download_to_file_path}" ]]; then
      download_to_file_path="$TMP_PATH"
    fi
  fi
  if [[ -z "${download_to_file_name}" ]]; then
    read -ep "请输入保存文件名（如：demo.txt）: " download_to_file_name
    if [[ -z "${download_to_file_name}" ]]; then
      download_to_file_name="$(date +%s).tmp"
    fi
  fi

  if [[ -z "${download_to_file_downlink}" || -z "${download_to_file_path}" || -z "${download_to_file_name}" ]]; then
    echo -e "${red}所有选项都不能为空${plain}"
    return 1
  fi

  echo -e "下载${green} ${download_to_file_title} ${plain}到 ${green}${download_to_file_path}/${download_to_file_name}${plain} (${download_to_file_downlink})"
  mkdir -p ${download_to_file_path}

  calc_timediff_start
  wget -t 2 -T 10 -O ${download_to_file_path}/${download_to_file_name} ${download_to_file_downlink} >> ${SH_RUN_LOG_PATH} 2>&1

  if [[ $? != 0 ]]; then
    calc_timediff_result
    echo -e "${red}${download_to_file_title}下载失败，请检查 ${download_to_file_downlink} 是否可访问。"
    if [[ $# == 0 ]]; then
      before_show_menu
    else
      return 1
    fi
  else
    calc_timediff_result
    if [[ $# == 0 ]]; then
      before_show_menu
    else
      return 0
    fi
  fi
}


# $1 downlink
# $2 down to Path
# $3 title (optional)
download_and_unzip() {
  tmp_zip_name="zip_$(date +%s).zip"

  download_and_unzip_downlink=$1
  download_and_unzip_path=$2
  download_and_unzip_title=$3

  if [[ -z "${download_and_unzip_downlink}" ]]; then
    read -ep "请输入压缩包下载地址: " download_and_unzip_downlink
  fi
  if [[ -z "${download_and_unzip_path}" ]]; then
    read -ep "请输入要保存的路径（如：/mnt/down，默认保存到：${TMP_PATH}）: " download_and_unzip_path
    if [[ -z "${download_and_unzip_path}" ]]; then
      download_and_unzip_path="$TMP_PATH"
    fi
  fi

  if [[ -z "${download_and_unzip_path}" || -z "${download_and_unzip_downlink}" ]]; then
    echo -e "${red}所有选项都不能为空${plain}"
    if [[ $# == 0 ]]; then
      before_show_menu
    else
      return 1
    fi
  fi

  download_to_file ${download_and_unzip_downlink} ${download_and_unzip_path} $tmp_zip_name ${download_and_unzip_title}

  if [[ $? != 0 ]]; then
    if [[ $# == 0 ]]; then
      before_show_menu
    else
      return 1
    fi
  else
    sleep 1

    echo -e "正解压到 ${green}${download_and_unzip_path}${plain}"

    unzip -o -q ${download_and_unzip_path}/${tmp_zip_name} -d ${download_and_unzip_path}/

    echo -e "${green}${download_and_unzip_title}${plain}下载解压完成"

    if [[ $# == 0 ]]; then
      before_show_menu
    else
      return 0
    fi
  fi
}

# 上传文件（勿上传敏感数据） $1: FilePath $2:name(optional)
file_transfer() {
  file_transfer_path=$1

  if [[ -z "${file_transfer_path}" ]]; then
    read -ep "请输入要上传的文件路径: " file_transfer_path
    if [[ -z "${file_transfer_path}" ]]; then
      echo -e "${red}你没有输入文件路径哦${plain}"
      before_show_menu
      return 1
    fi
  fi

  if [ ! -e $file_transfer_path ]; then
    echo -e "${red}${file_transfer_path} 文件不存在，请检查。"
  else
    echo -e "${green}文件：$file_transfer_path${plain} 正在上传"

    calc_timediff_start
    curl -i -s --upload-file $file_transfer_path https://transfer.sh/$2 -H "Max-Days: 7" -H "Max-Downloads: 999" >> ~/transfer.log

    if [[ $? != 0 ]]; then
      calc_timediff_result
      echo -e "${red}${file_transfer_path}${plain}上传失败，请检查文件。"
    else
      calc_timediff_result
      file_transfer_down_link=$(sed -n '$p' ~/transfer.log)
      echo -e "文件：${green}$file_transfer_path${plain} 上传完成。下载地址为：${green}${file_transfer_down_link}${plain} \n上传日志请查看: ${yellow}tail -f -n 30 ~/transfer.log${plain}"

      task_webhook_send "文件：$file_transfer_path 上传完成。上传信息：\n$(tail -n 10 ~/transfer.log)" >> ${SH_RUN_LOG_PATH} 2>&1
    fi
  fi

  if [[ $# == 0 ]]; then
    before_show_menu
  fi
}

# 企业微信机器人
webhook_qywx() {
  webhook_qywx_message=$*

  if [[ -z "${webhook_qywx_message}" ]]; then
    read -ep "使用前，请先设置机器人key。请输入要发送的消息: " webhook_qywx_message
  fi

  curl "${qywx_bot_webhook_url}" \
    -H "Content-Type: application/json" \
    -d "
   {
    	\"msgtype\": \"text\",
    	\"text\": {
        	\"content\": \"${webhook_qywx_message}\",
          \"mentioned_list\":[\"@all\"]
    	}
   }" >> ${SH_RUN_LOG_PATH} 2>&1

  if [[ $? == 0 ]]; then
    echo -e "${green}> 企业微信机器人 ${plain}发送成功"
  else
    echo -e "${red}> 企业微信机器人 ${plain}发送失败"
  fi

  if [[ $# == 0 ]]; then
    before_show_menu
  fi
}

# 显示硬件信息
show_system_info() {
  echo -e "> 显示硬件信息"

  (command -v yum >/dev/null 2>&1 && (command -v lshw || yum install -y lshw >> ${SH_RUN_LOG_PATH} 2>&1)) ||
  (command -v apt-get >/dev/null 2>&1 && (command -v lshw || apt-get install -y lshw >> ${SH_RUN_LOG_PATH} 2>&1))

  echo -e "${green}$(lshw -class disk -class storage)"

  if [[ $# == 0 ]]; then
    before_show_menu
  fi
}

clean_all() {
  return 0
}

# 升级脚本
update_script() {
  echo -e "> 更新脚本"

  curl -sL ${SCRIPT_UPDATE_DOWNLINK} -o /tmp/run.sh
  new_version=$(cat /tmp/run.sh | grep "SCRIPT_VERSION" | head -n 1 | awk -F "=" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
  if [ ! -n "$new_version" ]; then
    echo -e "脚本获取失败，请检查脚本更新链接 ${SCRIPT_UPDATE_DOWNLINK}"
    return 1
  fi
  echo -e "当前最新版本为: ${new_version}"
  mv -f /tmp/run.sh ./run.sh && chmod a+x ./run.sh

  echo -e "2s后执行新脚本"
  sleep 2s
  clear
  exec ./run.sh
  exit 0
}

before_show_menu() {
  echo && echo -n -e "${yellow}* 按回车返回主菜单 *${plain}" && read temp
  show_menu
}

show_usage() {
  echo "管理维护脚本使用方法: "
  echo "--------------------------------------------------------"
  echo "./run.sh                                - 显示管理菜单"
  echo "--------------------------------------------------------"
  echo "./run.sh show_system_info               - 显示系统信息"
  echo "./run.sh download_to_file               - 下载文件"
  echo "./run.sh download_and_unzip             - 下载并解压"
  echo "./run.sh file_transfer                  - 上传文件"
  echo "./run.sh webhook_qywx                   - 企业微信机器人"
  echo "--------------------------------------------------------"
  echo "./run.sh update_script                  - 更新脚本"
  echo "--------------------------------------------------------"
}

show_menu() {
  echo -e ">
    ${green}管理维护脚本${plain} ${red}${SCRIPT_VERSION}${plain}
    --- Author: Leon (silenceace@gmail.com) ---
    ————————————————-
    ${green}1.${plain} 显示系统信息
    ————————————————-
    ${green}2.${plain} 更新脚本
    ————————————————-
    ${green}3.${plain} 下载文件
    ${green}4.${plain} 下载并解压
    ${green}5.${plain} 上传文件
    ${green}6.${plain} 企业微信机器人
    ————————————————-
    ${green}0.${plain} 退出脚本
    "
  echo && read -ep "请输入操作序号 [0-6]: " select_num

  case "${select_num}" in
  0)
    exit 0
    ;;
  1)
    show_system_info
    ;;
  2)
    update_script
    ;;
  3)
    download_to_file
    ;;
  4)
    download_and_unzip
    ;;
  5)
    file_transfer
    ;;
  6)
    webhook_qywx
    ;;
  *)
    show_menu
    ;;
  esac
}

pre_check

if [[ $# > 0 ]]; then
  case $1 in
  "update_script")
    update_script 0
    ;;
  "file_transfer")
    shift
    if [ $# -ge 1 ]; then
      file_transfer "$@"
    else
      file_transfer
    fi
    ;;
  "download_to_file")
    shift
    if [ $# -ge 1 ]; then
      download_to_file "$@"
    else
      download_to_file
    fi
    ;;
  "download_and_unzip")
    shift
    if [ $# -ge 1 ]; then
      download_and_unzip "$@"
    else
      download_and_unzip
    fi
    ;;
  "webhook_qywx")
    shift
    if [ $# -ge 1 ]; then
      webhook_qywx "$@"
    else
      webhook_qywx
    fi
    ;;
  "show_system_info")
    show_system_info 0
    ;;
  *)
    $@ || show_usage
    ;;
  esac
else
  show_menu
fi
