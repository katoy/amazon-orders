# frozen_string_literal: true

# 1. amazon の購入履歴を取得する。(screenshots/* に保存される)
#   $ ruby amazon.rb email password
#
# 2. 取得した情報から、明細書(*.png) を１つの PDF にまとめたものを作成する。
#    (imagemagic の convert コマンドを使う)
#   $ convert -resize 575x823 -gravity north -background white -extent 595x842 screenshots/ord*.png 1.pdf
#
# 3. 取得した情報から、csv 形式で購入物一覧表を作成する。
#   $ ruby make-index.rb > 1.csv

require 'rubygems'
require 'selenium-webdriver' # gem install selenium-webdriver
# brew install geckodriver
# brew install ChromeDriver
#
# https://qiita.com/apukasukabian/items/77832dd42e85ab7aa568
#  seleniumを使用しようとしたら、「"chromedriver"は開発元を検証できないため開けません。」と言われた
#

SCREENSHOTS_DIR = './screenshots'

module Amazon
  class Driver
    # 新しいタブで指定された URL を開き、制御をそのタブに移す。
    def open_new_window(wd, url)
      a = wd.execute_script("var d=document,a=d.createElement('a');a.target='_blank';a.href=arguments[0];a.innerHTML='.';d.body.appendChild(a);return a", url)
      a.click
      wd.switch_to.window(wd.window_handles.last)

      sleep(3)
      # ズームレベルを80%に設定
      wd.execute_script("document.body.style.zoom='80%'")
      wd.find_element(:link_text, '利用規約')
      yield
      wd.close
      wd.switch_to.window(wd.window_handles.last)
    end

    # 現在の画面からリンクが張られている購入明細を全て保存する。
    def save_order(wd)
      sleep 1
      wd.find_element(:link_text, '利用規約')
      order_ids = wd.find_elements(:class_name, 'value').map(&:text).select { |x| /\A\w+-\w+-\w+\z/.match(x) }
      order_ids.each do |ord|
        # invoice = "https://www.amazon.co.jp/gp/css/summary/print.html/ref=oh_aui_ajax_invoice?ie=UTF8&orderID=#{ord}&print=1"
        invoice_1 = "https://www.amazon.co.jp/gp/css/summary/print.html/ref=oh_aui_ajax_invoice?ie=UTF8&orderID=#{ord}"
        invoice_2 = "https://www.amazon.co.jp/gp/digital/your-account/order-summary.html?ie=UTF8&orderID=#{ord}&print=1&ref_=oh_aui_ajax_dpi"

        # 電子書籍とそれ以外では、領収書の URL 形式が異なる
        done = false
        open_new_window(wd, invoice_1) do
          page_content = wd.page_source # ページのHTMLソースを取得
          if page_content.include?("支払い情報") # "支払い情報" という文字列が含まれている場合のみスクリーンショットを撮る
            @order_seq += 1
            p invoice_1
            sleep(4)
            wd.save_screenshot("#{SCREENSHOTS_DIR}/order_#{format('%03d', @order_seq)}.png")
            done = true
          end
        end
        next if done

        open_new_window(wd, invoice_2) do
          page_content = wd.page_source # ページのHTMLソースを取得
          if page_content.include?("支払い情報") # "支払い情報" という文字列が含まれている場合のみスクリーンショットを撮る
            @order_seq += 1
            p invoice_2
            sleep(4)
            wd.save_screenshot("#{SCREENSHOTS_DIR}/order_#{format('%03d', @order_seq)}.png")
          end
        end
      end
    end

    def save_order_history(wd, auth)
      @page_seq = 0
      @order_seq = 0

      # 購入履歴ページへ
      wd.get 'https://www.amazon.co.jp/gp/css/order-history'

      # ログイン処理
      wd.find_element(:id, 'ap_email').click
      wd.find_element(:id, 'ap_email').clear
      wd.find_element(:id, 'ap_email').send_keys auth[:email]

      wd.find_element(:id, 'continue').click
      wd.find_element(:id, 'ap_password').click
      wd.find_element(:id, 'ap_password').clear
      wd.find_element(:id, 'ap_password').send_keys auth[:password]

      wd.find_element(:id, 'signInSubmit').click

      # unless wd.find_element(:xpath, "//form[@id='order-dropdown-form']/select//option[4]").selected?
      #   wd.find_element(:xpath, "//form[@id='order-dropdown-form']/select//option[4]").click  # 今年の注文
      # end
      # wd.find_element(:css, "#order-dropdown-form > span.in-amzn-btn.btn-prim-med > span > input[type=\"submit\"]").click

      # 去年１年分
      # wd.get "https://www.amazon.co.jp/gp/css/order-history?ie=UTF8&ref_=nav_gno_yam_yrdrs&"
      # sleep 1
      # unless wd.find_element(:id, "a-autoid-1-announce").selected?
      #  wd.find_element(:id, "a-autoid-1-announce").click
      #  wd.find_element(:id, "dropdown1_3").click
      #  sleep 2
      # end

      # 今年１年分(2018)
      # wd.get 'https://www.amazon.co.jp/gp/css/order-history?ie=UTF8&ref_=nav_gno_yam_yrdrs'
      # 2019
      # wd.get 'https://www.amazon.co.jp/gp/your-account/order-history?ie=UTF8&orderFilter=year-2019'
      # 2023
      wd.get 'https://www.amazon.co.jp/gp/your-account/order-history?ie=UTF8&orderFilter=year-2023'

      sleep 1
      # unless wd.find_element(:id, "a-autoid-1-announce").selected?
      #  wd.find_element(:id, "a-autoid-1-announce").click
      #  wd.find_element(:id, "dropdown1_2").click
      #  sleep 2
      # end
      # wd.find_element(:id, 'orderFilterEntry-year-2018').click
      # wd.find_element(:id, 'orderFilterEntry-year-2019').click
      # wd.find_element(:id, 'orderFilterEntry-year-2023').click
      # wd.get 'https://www.amazon.co.jp/gp/your-account/order-history?ie=UTF8&orderFilter=year-2023'

      sleep 2

      # [次] ページをめくっていく
      loop do
        wd.find_element(:link_text, '利用規約')
        @page_seq += 1
        wd.save_screenshot("#{SCREENSHOTS_DIR}/page_#{format('%03d', @page_seq)}.png")
        open("#{SCREENSHOTS_DIR}/page_#{format('%03d', @page_seq)}.html", 'w') do |f|
          f.write wd.page_source
        end

        # ページ中の個々の注文を閲覧する。
        save_order(wd)

        sleep 0.5
        elems = wd.find_elements(:link_text, '次へ→')
        break if elems.empty?

        elems[0].click
      end

      # サインアウト
      wd.get 'http://www.amazon.co.jp/gp/flex/sign-out.html/ref=gno_signout'
    end
  end
end

include Amazon

if ARGV.size != 2
  puts "usage: ruby #{$PROGRAM_NAME} account password"
  exit 1
end

wd = nil
begin
  ad = Amazon::Driver.new
  # wd = Selenium::WebDriver.for :firefox
  wd = Selenium::WebDriver.for :chrome
  wd.manage.timeouts.implicit_wait = 20 # 秒

  # wd.manage.window.resize_to(1200, 1280)

  # ウィンドウサイズの調整
  wd.manage.window.resize_to(900, 1280) # 横幅をズームレベルに合わせて調整

  ad.save_order_history(wd, email: ARGV[0], password: ARGV[1])
ensure
  wd.quit if wd
end
