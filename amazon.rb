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

SCREENSHOTS_DIR = './screenshots'

module Amazon
  class Driver
    # 新しいタブで指定された URL を開き、制御をそのタブに移す。
    def open_new_window(wd, url)
      a = wd.execute_script("var d=document,a=d.createElement('a');a.target='_blank';a.href=arguments[0];a.innerHTML='.';d.body.appendChild(a);return a", url)
      a.click
      wd.switch_to.window(wd.window_handles.last)

      wd.find_element(:link_text, '利用規約')
      yield
      wd.close
      wd.switch_to.window(wd.window_handles.last)
    end

    # 現在の画面からリンクが張られている購入明細を全て保存する。
    def save_order(wd)
      sleep 1
      wd.find_element(:link_text, '利用規約')
      orders = wd.find_elements(:link_text, '注文の詳細')
      orders.each do |ord|
        open_new_window(wd, ord.attribute('href')) do
          @order_seq += 1
          sleep(4)
          wd.save_screenshot("#{SCREENSHOTS_DIR}/order_#{format('%03d', @order_seq)}.png")
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

      # 今年１年分
      wd.get 'https://www.amazon.co.jp/gp/css/order-history?ie=UTF8&ref_=nav_gno_yam_yrdrs'

      sleep 1
      # unless wd.find_element(:id, "a-autoid-1-announce").selected?
      #  wd.find_element(:id, "a-autoid-1-announce").click
      #  wd.find_element(:id, "dropdown1_2").click
      #  sleep 2
      # end
      wd.find_element(:id, 'orderFilterEntry-year-2017').click
      sleep 2

      # [次] ページをめくっていく
      loop do
        wd.find_element(:link_text, '利用規約')
        @page_seq += 1
        wd.save_screenshot("#{SCREENSHOTS_DIR}/page_#{format('%03d', @page_seq)}.png")
        open("#{SCREENSHOTS_DIR}/page_#{format('%03d', @page_seq)}.html", 'w') {|f|
          f.write wd.page_source
        }

        # ページ中の個々の注文を閲覧する。
        save_order(wd)

        sleep 0.5
        elems = wd.find_elements(:link_text, "次へ→")
        break if elems.size == 0
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
  ad.save_order_history(wd, email: ARGV[0], password: ARGV[1])
ensure
  wd.quit if wd
end
