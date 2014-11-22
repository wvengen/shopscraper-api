#!/usr/bin/env ruby
#
require 'mechanize'
require 'ostruct'

class JumboShop
  BASEURL = 'http://www.jumbo.com/'
  PRODUCT_URL = BASEURL+'producten/'

  def initialize(mech=Mechanize.new)
    @mech = mech
  end

  def product(id)
    product = OpenStruct.new
    @mech.get PRODUCT_URL+id do |page|
      product.url = page.search('link[rel=canonical]').first.attribute('href').value
      product.id = id
      page.search('.jum-column-main').each do |page|
        product.name = page.search('h1').inner_text.strip
        product.unit = page.search('.jum-pack-size').inner_text.strip
        product.brand_url = page.search('.jum-product-brand-info a').first.attribute('href').value
        product.currency = 'EUR'
        product.price = page.search('.jum-item-price .jum-price-format').first.inner_text.strip.to_i/100.0
        product.storage = page.search('.jum-product-storage p').inner_text.strip
        product.preparation = page.search('.jum-product-preparation p').inner_text.strip

        page.search('.jum-product-extra-info li').each do |el|
          el.text =~ /(regio|origin|herkomst)\s*:(.*)$/i and product.origin = $2.strip
        end

        product.ingredients = page.search('.jum-ingredients-info li').map{|el| el.inner_text.strip}
        product.ingredients.last =~ /E\s*=\s*door de E\.G\. goedgekeurde hulpstof/i and product.ingredients.pop

        nutrient_per = page.search('.jum-nutritional-info table thead th:last-child').inner_text.strip.gsub(/^\s*per\s*/i,'')
        product.nutrients = page.search('.jum-nutritional-info table tbody').map do |el|
          {
            name: el.children.first.text.strip,
            value: el.children.last.text.strip + ' / ' + nutrient_per
          }
        end
        product.nutrients.last =~ /Aanbevolen Dagelijkse Hoeveelheid/i and product.nutrients.pop

        product.image_url = BASEURL + page.search('[data-jum-role="mainImage"] img').first.attribute('data-jum-src').value
        product.description = page.search('.jum-summary-description').inner_text.strip
      end
    end
    product
  end

end

