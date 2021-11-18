#!/usr/bin/env bash

if [ $# -lt 1 ]; then
  cat << EOS
Usage: bash trim.sh input_file
the input file example:
---
start front.MOV +00:00:00.03
end side.MOV -00:00:00.01
---
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

while read command mov_file offset
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
done < $trim_file

for base in "front" "side"; do
  duration=$(ffprobe -i "$dir/${base}.${MOV_EXT}" -show_entries format=duration -v quiet -of csv="p=0")
  if [ $base == "front" ];then
    f_ss=$(time2sec $front_start)
    b_ss=$(time2sec $front_end)
  else
    f_ss=$(time2sec $side_start)
    b_ss=$(time2sec $side_end)
  fi
  t=$(echo "scale=6; $duration - $f_ss - $b_ss" | bc)
  command="ffmpeg -ss $f_ss -i '$dir/${base}.${MOV_EXT}' -t $t -c copy '$dir/${base}_trimed.${MOV_EXT}'"
  echo $command
done
