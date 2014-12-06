#!/usr/bin/env ruby
#
require 'ostruct'
require_relative 'shop'

class JumboShop < Shop
  BASEURL = 'http://www.jumbo.com/'
  PRODUCT_URL = BASEURL+'producten/'

  BASEURL_SECURE = 'https://www.jumbo.com/'
  SHOPURL_SECURE = BASEURL_SECURE+'INTERSHOP/web/WFS/Jumbo-Grocery-Site/nl_NL/-/EUR/'
  LOGIN_URL = SHOPURL_SECURE+'ViewUserAccount-ViewLoginStart'
  LIST_ORDERS_URL = SHOPURL_SECURE+'ViewOrders-View'

  def name
    "Jumbo"
  end

  def login(login, pass)
    status = false
    @mech.get LOGIN_URL do |page|
      m = page.body.match(/SYNCHRONIZER_TOKEN_VALUE\s*=\s*(['"])(.*?)\1/) or return false
      synctoken = m[2]
      page = page.form_with(id: 'login-user-form') do |form|
        form.ShopLoginForm_Login = login
        form.ShopLoginForm_Password = pass
        form.add_field! 'SynchronizerToken', synctoken
      end.submit
      status = !(page.search('title').text =~ /login/i)
      yield(page, status) if block_given?
    end
    status
  end

  def orders(options={})
    orders = []
    @mech.get LIST_ORDERS_URL do |page|
      page.search('.jum-order-list-table tbody tr').each do |page|
        order = OpenStruct.new
        order.date = search_first_text(page, '.jum-order-date')
        order.sum = search_first_text(page, '.jum-order-total')
        order.state = search_first_text(page, '.jum-order-status')
        order.id = search_first_text(page, '.jum-order-number')
        order.via = search_first_text(page, '.jum-order-via')
        #order.url = BASEURL+page.attribute('href').value
        orders << order
      end
    end
    orders
  end

  def order(order_id, options={})
    order = OpenStruct.new
    # @todo
  end

  def product(id)
    product = OpenStruct.new
    @mech.get PRODUCT_URL+id do |page|
      product.url = search_first_attr(page, 'link[rel=canonical]', 'href')
      product.id = id
      page.search('.jum-column-main').each do |page|
        product.name = search_first_text(page, 'h1')
        product.unit = search_first_text(page, '.jum-pack-size')
        product.brand_url = search_first_attr(page, '.jum-product-brand-info a', 'href')
        product.currency = 'EUR'
        product.price = search_first_text(page, '.jum-item-price .jum-price-format') {|t| t.to_i/100.0 }
        product.storage = search_all_text(page, '.jum-product-storage p')
        product.preparation = search_all_text(page, '.jum-product-preparation p')

        page.search('.jum-product-extra-info li').each do |el|
          el.text =~ /(regio|origin|herkomst)\s*:(.*)$/i and product.origin = $2.strip
        end

        product.ingredients = page.search('.jum-ingredients-info li').map{|el| el.inner_text.strip}
        product.ingredients.last =~ /E\s*=\s*door de E\.G\. goedgekeurde hulpstof/i and product.ingredients.pop

        nutrient_per = search_first_text(page, '.jum-nutritional-info table thead th:last-child') {|t| t.gsub!(/^\s*per\s*/i,'').gsub!(/\s*:\s*$/,'') }
        product.nutrients = page.search('.jum-nutritional-info table tbody').map do |el|
          {
            name: el.children.first.text.strip.gsub(/\s*:\s*$/,''),
            value: [el.children.last.text.strip, nutrient_per].compact.join(' / ')
          }
        end
        product.nutrients.last and product.nutrients.last[:name] =~ /Aanbevolen Dagelijkse Hoeveelheid/i and product.nutrients.pop

        product.image_url = search_first_attr(page, '[data-jum-role="mainImage"] img', 'data-jum-src') {|t| BASEURL+t}
        product.description = search_all_text(page, '#jum-summary-description')
        product.description =~ /^lees\s+meer$/i and product.description = nil
      end
    end
    product
  end

end

