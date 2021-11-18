# ffmpeg_trim
Trim video files

# How to start
```
% bash trim.sh example/trim.txt
```

# The format of trim.txt
```
start front.MOV +00:00:00.03
end side.MOV -00:00:00.01
```

- 1行目: start 動画ファイル +hh:mm:ss.nnn
    - 動画ファイル: 開始位置を切り詰めるファイル名(trim.txtがあるディレクトリを基準としたパスを記載)
    - 開始位置を+hh:mm:ss.nnn 時:分:秒で記載したもの． (小数点以下はnnnのように記載)
- 2行目: end 動画ファイル -hh:mm:ss.nnn
    - 動画ファイル: 開始位置を切り詰めるファイル名(trim.txtがあるディレクトリを基準としたパスを記載)
    - 終了位置を動画の後ろを基準に，-hh:mm:ss.nnn 時:分:秒で記載したもの (小数点以下はnnnのように記載)
