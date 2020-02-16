# frozen_string_literal: true

require 'open-uri'
require 'nokogiri'
require 'csv'

BASE_URL_AMAZON = 'http://www.amazon.co.jp'

def price_to_int(str)
  str[1..-1].gsub(/[ |,]/, '').to_i
end

# 購入物の一覧を csv 形式で得る。（購入日、価格、値引額、タイトル）
# @return csv 形式の文字列
def generate_csv
  csv_string = CSV.generate do |csv|
    Dir::glob("screenshots/**/*.html").sort.each do |path|
      f = File.open path

      page = Nokogiri::XML f
      orders = page.css('.order')
      orders.each do |order|
        info = order.css('.order-info')
        vals = info[0].css('.value')
        date = Date.strptime(vals[0].text.strip, "%Y年%m月%d日")
        price = price_to_int(vals[1].text.strip)
        titles = []
        urls = []
        links = order.css('.shipment .a-row .a-link-normal')
        if links.size > 0
          links.each do |link|
            title = link.text.chomp.strip
            if title && title != '' && title != '非表示にする'
              titles << title
              urls << BASE_URL_AMAZON + link.attribute('href')
            end
          end
        else
          if order.css('.a-box') && order.css('.a-box')[1]
            links = order.css('.a-box')[1].css('.a-link-normal')
            links.each do |link|
              title = link.text.chomp.strip
              if title && title != '' && title != '非表示にする'
                urls << BASE_URL_AMAZON + link.attribute('href')
                titles << title
              end
            end
          end
        end

        titles.each_with_index do |title, idx|
          next if title == '注文の詳細'
          next if title == 'こちら'
          next if title == '領収書／購入明細書'

          price = 0 if idx > 0
          csv << [date, "#{format('%8d', price)}", title, urls[idx]]
        end
      end
      f.close
    end
  end
  csv_string
end

puts generate_csv
