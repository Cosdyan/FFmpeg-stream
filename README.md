1、# FFmpeg-stream

2、FFmpeg的循环推流脚本-LALA大神

3、一键运行：wget -N --no-check-certificate "https://raw.githubusercontent.com/Cosdyan/FFmpeg-stream/main/FFmpeg.sh" && chmod +x FFmpeg.sh && ./FFmpeg.sh

4、需要配合screen运行：yum install screen

5、screen -S name #新建一个运行空间，name可以随便写，例如：screen -S go-cq ,screen -S stream 这里的S一定要大写  

6、screen -D name #杀死命名为name的运行空间，杀死之后该运行空间就没了，里面运行的东西也就不会运行了,例如：screen -D stream

7、screen -r name #连接名字为name的运行空间，例如：screen -r stream

8、Ctrl + A + D #退出当前运行空间，但里面的运行的进程会一直运行，如果要对该进程进行操作，只需要运行上面的screen -r 即可进入

9、目前支持循环推流mp4格式的视频，注意视频文件的名字不能含有空格或其他特殊符号,脚本为LALA大神制作，我经常要用就自己维护一下

10、视频加水印，水印位置默认在右上角。

11、替换72行-74行（代码含义自己研究 -b:v 6000k视频码率；-b:a 128k音频码率）

  video=$(find ./ -type f | shuf -n 1)
  ffmpeg -re -i "$video" -preset ultrafast -vcodec libx264 -g 60 -b:v 6000k -c:a aac -b:a 128k -strict -2 -f flv ${rtmp}
  
12、LALA小站：https://lala.im/4816.html

