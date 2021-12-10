#!/usr/bin/env bash
cd `dirname $0`

if [ $# -lt 1 ]; then
  cat << EOS
Usage: bash trim.sh input_file
the input file example:
---
start front.MOV +00:00:00.03
end side.MOV -00:00:00.01
1 -1
---
1st column: trim the first frames (length 0.03sec) from front.MOV
2nd column: trim the last frames (length 0.01sec) from side.MOV
3rd column: rotate front.MOV 90 deg. (in clockwise direction) and side.MOV 180 deg. (1:90d 2:-90d -1:180d)
EOS
  exit 1
fi

MOV_EXT="MOV"

#echo $1
trim_file=$1
dir=$(dirname $trim_file)

#echo dir=$dir filename=$filename ext=$extension
temp_str="date +%Y%m%d-%H%M%S"

front_start="00:00:00.000"
front_end="00:00:00.000"
side_start="00:00:00.000"
side_end="00:00:00.000"

set -f

function trim_sign(){
  str=$1
  if [ ${str:0:1}=="+" ];then
    echo ${str:1}
  elif [ ${str:0:1}=="-" ];then
    echo ${str:1}
  fi
  echo $str
}
function add_zero(){
  str=$1
  if [ ${str:0:1}=="\." ];then
    str="0$str"
  fi
  echo $str
}

function time2sec(){
  time_str=$(trim_sign $1)
  nums=(${time_str//:/ })
  sec=0
  unit=3600
  sec=$(echo "scale=3; ${nums[0]} * 3600 + ${nums[1]} * 60 + ${nums[2]} " | bc )
  echo $(add_zero $sec)
}


function command_error(){
  command=$1
  cat << EOF
Unknown command: $command
It must be 'start' or 'end'.
EOF
}

head -n 2 $trim_file | while read command mov_file offset
do
  base=$(basename -- "$mov_file")
  base="${base%.*}"
  #MOV_EXT="${base##*.}"
  if [ $base == "front" ]; then
    if [ $command == "start" ]; then
      front_start=$offset
    elif [ $command == "end" ]; then
      front_end=$offset
    else
      command_error $command
      exit 1
    fi
  elif [ $base == "side" ]; then
    if [ $command == "start" ]; then
      side_start=$offset
    elif [ $command == "end" ]; then
      side_end=$offset
    else
      command_error $command
      exit 1
    fi
  else
    cat << EOF
Unknown movie file name: $base
It must be 'front' or 'side'
EOF
    exit 1
  fi
done

# read rotation
rotation_commands=($(head -n 3 $trim_file | tail -n 1)) # get the 3rd row

function create_rot_option(){
  command=$1
  if [ $command -eq -1 ]; then
    echo "hflip,vflip,scale=640:-2"
  elif [ $command -eq 0 ]; then
    #echo "-c copy " # only when not re-encode.
    echo "scale=640:-2"
  else
    echo "transpose=$command,scale=640:-2"
  fi
}
front_rot_option=$(create_rot_option ${rotation_commands[0]})
side_rot_option=$(create_rot_option ${rotation_commands[1]})

for base in "front" "side"; do
  duration=$(ffprobe -i "$dir/${base}.${MOV_EXT}" -show_entries format=duration -v quiet -of csv="p=0")
  if [ $base == "front" ];then
    f_ss=$(time2sec $front_start)
    b_ss=$(time2sec $front_end)
    rot_option=$front_rot_option
  else
    f_ss=$(time2sec $side_start)
    b_ss=$(time2sec $side_end)
    rot_option=$side_rot_option
  fi
  t=$(echo "scale=6; $duration - $f_ss - $b_ss" | bc)
  command="ffmpeg -y -ss $f_ss -i '$dir/${base}.${MOV_EXT}' -vf '$rot_option' -t $t -vcodec libx265 '$dir/${base}_compressed_h265_w640.mp4' > '$dir/${base}_compressed_h265_w640.log' 2>&1"
  echo $command
  ffmpeg -y -ss $f_ss -i "$dir/${base}.${MOV_EXT}" -vf "$rot_option" -t $t -vcodec libx265 "$dir/${base}_compressed_h265_w640.mp4" > "$dir/${base}_compressed_h265_w640.log" 2>&1

done
