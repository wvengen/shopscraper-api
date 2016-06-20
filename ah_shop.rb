require 'json'
require 'ostruct'
require 'typhoeus'
require_relative 'shop'

class AHShop < Shop
  BASEURL = 'http://www.ah.nl/'
  PRODUCT_URL = BASEURL+'producten/product/'

  BASEURL_SECURE = 'https://www.ah.nl/'
  LOGIN_URL = BASEURL_SECURE+'mijn/inloggen/basis'
  LIST_ORDERS_URL = BASEURL_SECURE+'service/rest/orders'
  ORDER_URL = BASEURL_SECURE+'producten/eerder-gekocht/bestelling'

  def name
    "Albert Heijn"
  end

  def login(user, pass)
    status = false
    @mech.get LOGIN_URL do |page|
      page = page.form_with(id: 'loginCommand') do |form|
        form.userName = user
        form.password = pass
      end.submit
      status = !!(page.search('title').text =~ /redirect/i)
      yield(page, status) if block_given?
    end
    status
  end

  def orders(options={})
    orders = []
    @mech.get LIST_ORDERS_URL do |page|
      JSON.parse(page.body)["orders"].each do |o|
        order = OpenStruct.new
        order.date = o["fulfillment"]["date"]
        order.id = o["id"]
        order.url = ORDER_URL+"?orderno="+order.id.to_s
        # @todo other fields like address, timeslot, type, state
        orders << order
      end
    end
    orders
  end

  def product(id, options={})
    product = OpenStruct.new
    @mech.get PRODUCT_URL+id do |page|
      product.url = search_first_attr(page, 'meta[property="og:url"]', 'content')
      product.id = product_id_from_url(product.url)
      product.name = search_first_attr(page, 'meta[property="og:title"]', 'content')
      product.unit = search_first_text(page, '#content .unit')
      product.brand_name = search_first_attr(page, 'meta[itemprop="brand"]', 'content')
      product.image_url = search_first_attr(page, 'meta[property="og:image"]', 'content')
      product.description = search_all_text(page, '.product-detail__content')
      product.price = search_first_attr(page, 'meta[itemprop="price"]', 'content')
    end
    product
  end

  def order(order_id, options={})
    # get list with quantities from print url
    order = OpenStruct.new
    @mech.get "#{ORDER_URL}/print?orderno=#{order_id}" do |page|
      order.id = order_id
      order.products = []
      category = nil
      page.search('section li').each do |li|
        if li.has_attribute?('class') && li.attribute('class').value.match(/\btitle\b/)
          category = li.text.gsub(/\s*\(\d+\)\s*$/, '')
        else
          order.products << OpenStruct.new({
            name: li.children.select{|e| e.is_a? Nokogiri::XML::Text}.map(&:text).join(''),
            quantity: search_first_text(li, '.quantity') {|t| t.gsub(/\s*x\s*$/, '') },
            unit: search_first_text(li, '.unit'),
            category: category
          })
        end
      end
    end
    # gather extra info from non-printing page
    @mech.get "#{ORDER_URL}?orderno=#{order_id}" do |page|
      order.date = search_first_text(page, '.header h2') {|t| t.gsub(/\A.*op\s+/m, '') }
      page.search('#content .product').each do |p|
        cur_name = search_first_attr(p, '.image img', 'alt')
        if i = order.products.index{|p| cur_name.strip.downcase.include? p.name.strip.downcase }
          product = order.products[i]
          product.url = search_first_attr(p, '.detail a', 'href') {|t| BASEURL+t}
          product.image_url = search_first_attr(p, '.image img', 'data-original')
          product.id = product_id_from_url(product.url)
        end
      end
    end

    order
  end

  private

  def product_id_from_url(url)
    url.gsub('//', '/').match(/^#{PRODUCT_URL.gsub('//','/')}(.*?)(\/+.*)?$/) and $1
  end

end

