
    $ ruby amazon.rb foo.example.com password
    $ ruby make-index.rb > 1.csv
    $ cat head.csv 1.csv > amazon.csv

    電子領収書を１つの PDF ファイルにまとめる。
    convert -resize 575x823 -gravity north -background white -extent 595x842 screenshots/order*.png 1.pdf
