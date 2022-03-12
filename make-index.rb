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
    csv << %w[購入日 価格 タイトル URL]
    Dir::glob("screenshots/**/*.html").sort.each do |path|
      f = File.open path

      page = Nokogiri::XML f
      orders = page.css('.a-box-group.a-spacing-base.order.js-order-card')
      nums = orders.map {|order| order.css(".a-fixed-left-grid-col.a-col-right").size }
      nums += [0]
      titles =
        orders.css(".a-fixed-left-grid-col.a-col-right").map do |item|
          item.text.split(/\r\n|\r|\n/)
            .map{|x| x.gsub(/\A *\z/, '')}
            .select{|x| x.length> 0}[0].strip
        end.reverse

      orders.each_with_index do |order, idx| 
        vals = order.css(".value").map(&:text)[0..3]
        date = Date.strptime(vals[0].strip, "%Y年%m月%d日")
        price = price_to_int(vals[1].strip)
        url = "https://www.amazon.co.jp/gp/css/summary/print.html/ref=oh_aui_ajax_invoice?ie=UTF8&orderID=#{vals[3]}&print=1"
        # p "#{nums[idx + 1]}, #{nums[idx]}"
        # p  titles[(nums[idx + 1] - 1).. nums[idx]]
        item_titles = titles[nums[idx + 1] ... nums[idx]].join("\n")
        csv << [date, "#{format('%8d', price)}", item_titles, url]
      end
      f.close
    end
  end
  csv_string
end

puts generate_csv
