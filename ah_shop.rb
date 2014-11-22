require 'mechanize'
require 'ostruct'
require 'typhoeus'

class AHShop
  BASEURL = 'http://www.ah.nl/'
  PRODUCT_URL = BASEURL+'producten/product'

  BASEURL_SECURE = 'https://www.ah.nl/'
  LOGIN_URL = BASEURL_SECURE+'mijn/inloggen/basis'
  LIST_ORDERS_URL = BASEURL_SECURE+'appie/producten/eerder-gekocht/bestellingen'
  ORDER_URL = BASEURL_SECURE+'appie/producten/eerder-gekocht/bestelling'

  def initialize(mech=Mechanize.new)
    @mech = mech
  end

  def login(user, pass)
    status = false
    @mech.get LOGIN_URL do |page|
      page = page.form_with(id: 'loginCommand') do |form|
        form.userName = user
        form.password = pass
      end.submit
      yield(page) if block_given?
      return true if page.search('title').text =~ /redirect/i
    end
    status
  end

  def orders(options={})
    orders = []
    @mech.get LIST_ORDERS_URL do |page|
      page.search('a.order_card').each do |page|
        order = OpenStruct.new
        order.date = page.search('.date').text.strip
        order.info = page.search('.info').text.strip
        order.url = page.attribute('href').value
        order.id = order.url.sub(/^.*orderno=/, '')
        orders << order
      end
    end
    orders
  end

  def product(id, options={})
    product = OpenStruct.new
    @mech.get "#{PRODUCT_URL}/#{id}" do |page|
      product.url = page.search('meta[property="og:url"]').first.attribute('content').value
      product.id = product_id_from_url(product.url)
      product.name = page.search('meta[property="og:title"]').attribute('content').value
      product.unit = page.search('#content .unit').inner_text.strip
      product.brand = page.search('meta[itemprop="brand"]').first.attribute('content').value
      product.image_url = page.search('meta[property="og:image"]').first.attribute('content').value
      product.description = page.search('.product-detail__content').inner_text.strip
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
            quantity: li.search('.quantity').inner_text.gsub(/\s*x\s*$/, ''),
            unit: li.search('.unit').inner_text.strip,
            category: category
          })
        end
      end
    end
    # gather extra info from non-printing page
    @mech.get "#{ORDER_URL}?orderno=#{order_id}" do |page|
      order.date = page.search('.header h2').text.gsub(/\A.*op\s+/m, '').strip
      page.search('#content .product').each do |p|
        cur_name = p.search('.image img').attribute('alt').value
        if i = order.products.index{|p| cur_name.strip.downcase.include? p.name.strip.downcase }
          product = order.products[i]
          product.url = BASEURL + p.search('.detail a').first.attribute('href').value
          product.image_url = p.search('.image img').first.attribute('data-original').value
          product.id = product_id_from_url(url)
        end
      end
    end

    # when request, load images in parallel to figure out ean ...
    if options[:ean]
      hydra = Typhoeus::Hydra.new
      order.products.each do |product|
        if product.image_url
          request = Typhoeus::Request.new(product.image_url, followlocation: true)
          request.on_complete do |response|
            if m=request.response.response_headers.match(/gtin([0-9]+)/)
              product.ean = m[1]
            end
          end
          hydra.queue(request)
        end
      end
      hydra.run
    end

    order
  end

  private

  def product_id_from_url(url)
    url.match /^#{PRODUCT_URL}\/+(.*?)(\/+.*)?$/ and $1
  end

end

