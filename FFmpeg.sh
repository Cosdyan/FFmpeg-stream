#!/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:~/bin
export PATH

# 获取脚本所在目录，设置日志路径
script_dir="$(cd "$(dirname "$0")" && pwd)"
log_file="${script_dir}/stream.log"

# 检查日志大小，超出 10MB 则清空
check_log_size() {
    if [ -f "$log_file" ]; then
        log_size=$(stat -c %s "$log_file")
        if [ "$log_size" -gt 10485760 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠ 日志文件超过 10MB，已清空并重新记录。" > "$log_file"
        fi
    fi
}

#=================================================================#
#   System Required: CentOS7 X86_64                               #
#   Description: FFmpeg Stream Media Server                       #
#   Author: LALA                                                  #
#   Modified by: ChatGPT                                          #
#   Website: https://www.lala.im                                  #
#=================================================================#

# 颜色选择
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
font="\033[0m"

ffmpeg_install(){
    read -p "你的机器内是否已经安装过FFmpeg4.x? 安装FFmpeg才能正常推流, 是否现在安装FFmpeg? (yes/no): " Choose
    if [ "$Choose" = "yes" ]; then
        yum -y install wget
        wget --no-check-certificate https://www.johnvansickle.com/ffmpeg/old-releases/ffmpeg-4.0.3-64bit-static.tar.xz
        tar -xJf ffmpeg-4.0.3-64bit-static.tar.xz
        cd ffmpeg-4.0.3-64bit-static
        mv ffmpeg /usr/bin && mv ffprobe /usr/bin && mv qt-faststart /usr/bin && mv ffmpeg-10bit /usr/bin
    elif [ "$Choose" = "no" ]; then
        echo -e "${yellow} 你选择不安装FFmpeg，请确保你的机器已安装，否则程序无法工作！ ${font}"
        sleep 2
    else
        echo -e "${red} 无效输入，请重新运行脚本。 ${font}"
        exit 1
    fi
}

stream_start(){
    read -p "输入你的推流地址和推流码 (例如 rtmp://xxx): " rtmp

    if [[ "$rtmp" =~ ^rtmp:// ]]; then
        echo -e "${green} 推流地址输入正确，程序将进行下一步操作。 ${font}"
        sleep 2
    else
        echo -e "${red} 推流地址不合法，请重新运行程序并输入！ ${font}"
        exit 1
    fi

    read -p "输入你的视频存放目录（格式仅支持mp4，使用绝对路径，例如 /opt/video）: " folder

    if ! cd "$folder"; then
        echo -e "${red} 无法进入目录: $folder，请检查路径是否正确。 ${font}"
        exit 1
    fi

    read -p "是否需要为视频添加水印？默认右上角，需较好CPU支持 (yes/no): " watermark

    if [ "$watermark" = "yes" ]; then
        read -p "输入水印图片的绝对路径，例如 /opt/image/watermark.jpg: " image
        echo -e "${yellow} 添加水印完成，程序开始推流... ${font}"

        while true; do
            cd "$folder" || { check_log_size; echo "目录不存在: $folder" | tee -a "$log_file"; exit 1; }

            find . -type f -name "*.mp4" | while read -r video; do
                check_log_size
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] 推流中: $video" | tee -a "$log_file"

                ffmpeg -re -i "$video" -i "$image" \
                    -filter_complex "overlay=W-w-5:5" \
                    -c:v libx264 -c:a aac -b:a 192k -f flv "$rtmp" \
                    >> "$log_file" 2>&1

                check_log_size
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] 播放完成: $video" | tee -a "$log_file"
                sleep 1
            done
        done

    elif [ "$watermark" = "no" ]; then
        echo -e "${yellow} 不添加水印，程序开始推流... ${font}"
        while true; do
            cd "$folder" || { check_log_size; echo "目录不存在: $folder" | tee -a "$log_file"; exit 1; }

            video=$(find . -type f -name "*.mp4" | shuf -n 1)

            check_log_size
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 推流中: $video" | tee -a "$log_file"

            ffmpeg -re -ss 0.01 -i "$video" \
                -preset ultrafast -vcodec libx264 -g 60 -b:v 6000k \
                -c:a aac -b:a 128k -f flv "$rtmp" \
                >> "$log_file" 2>&1

            check_log_size
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 播放完成: $video" | tee -a "$log_file"
            sleep 1
        done
    else
        echo -e "${red} 无效输入，请重新运行程序。 ${font}"
        exit 1
    fi
}

stream_stop(){
    screen -S stream -X quit
    killall ffmpeg
    echo -e "${green} 已尝试停止 screen 和 FFmpeg 进程。 ${font}"
}

start_menu(){
    while true; do
        echo -e "${yellow} CentOS7 X86_64 FFmpeg无人值守循环推流 For LALA.IM ${font}"
        echo -e "${red} 请确保脚本在 screen 窗口中运行！ ${font}"
        echo -e "${green} 1. 安装 FFmpeg（必须安装才能推流） ${font}"
        echo -e "${green} 2. 开始无人值守循环推流 ${font}"
        echo -e "${green} 3. 停止推流 ${font}"

        read -p "请输入数字 (1-3)，选择你要进行的操作: " num
        case "$num" in
            1)
                ffmpeg_install
                ;;
            2)
                stream_start
                ;;
            3)
                stream_stop
                ;;
            *)
                echo -e "${red} 输入错误，请输入 1 到 3 之间的数字。 ${font}"
                ;;
        esac
    done
}

# 启动主菜单
start_menu
