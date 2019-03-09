
    $ ruby amazon.rb foo.example.com password
    $ ruby make-index.rb > 1.csv
    $ cat head.csv 1.csv > amazon.csv

    電子領収書を１つの PDF ファイルにまとめる。
    $ convert -resize 575x823 -gravity north -background white -extent 595x842 screenshots/order*.png 1.pdf
    または
    % pdfjam --paper a4paper --outfile 1.pdf screenshots/order*.png

あるいは、pdf にしたい png を tmp/ 以下に置き
    $ ruby make_pdf.png
とすると 1 ページに２件で 10 ペー毎の PDFファイルが tmp/＊.pdf に作成される。
(コンビ二のプリンターで印刷するのにちょうど良い)
