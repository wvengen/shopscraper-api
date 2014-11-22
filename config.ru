require 'grape'
require 'rack-cache'
require 'rack/cache/key'

require_relative 'ah_shop'
require_relative 'jumbo_shop'


class API < Grape::API
  format :json
  prefix :api
  version :v1, using: :path

  namespace :shop do

    namespace :ah do

      helpers do
        def shop
          @shop ||= AHShop.new
        end
      end

      resources :orders do

        http_basic({realm: 'AH webshop login'}) do |username, password|
          shop.login(username, password)
        end

        desc "Return a user's past orders"
        get do
          {orders: shop.orders.map(&:to_h)}
        end

        route_param :id do
          desc "Return an order"
          get do
            order = shop.order(params.id, ean: params.ean)
            order.products.map!(&:to_h)
            {order: order.to_h}
          end
        end

      end

      resources :products do

        route_param :id do
          desc "Return product information"
          get do
            product = shop.product(params.id)
            {product: product.to_h}
          end
        end
      end

    end

    namespace :jumbo do

      helpers do
        def shop
          @shop ||= JumboShop.new
        end
      end

      resources :products do
        route_param :id do
          desc "Return product information"
          get do
            product = shop.product(params.id)
            {product: product.to_h}
          end
        end
      end
    end

  end
end


# include authorization in cache key
class Rack::Cache::KeyWithAuth < Rack::Cache::Key
  def generate
    [super, @request.env['HTTP_AUTHORIZATION']].join
  end
end

use Rack::Cache,
  verbose: false,
  private_headers: [],
  allow_revalidate: true,
  default_ttl: 15.minutes,
  cache_key: Rack::Cache::KeyWithAuth


run API
