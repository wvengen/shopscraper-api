#!/usr/bin/env ruby
#
require 'ostruct'
require_relative 'shop'

class JumboShop < Shop
  BASEURL = 'http://www.jumbo.com/'
  PRODUCT_URL = BASEURL+'producten/'

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
        product.description = search_all_text(page, '.jum-summary-description')
        product.description =~ /lees\s+meer/i and product.description = nil
      end
    end
    product
  end

end

