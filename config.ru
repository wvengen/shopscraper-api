require 'grape'
require 'rack-cache'
require 'rack/cache/key'
require 'rack/cors'

require_relative 'ah_shop'
require_relative 'jumbo_shop'


class API < Grape::API
  format :json
  prefix :api
  version :v1, using: :path

  SHOPS = {
    ah:    AHShop,
    jumbo: JumboShop
  }

  namespace :shop do

    route_param :shop do

      helpers do
        def shop
          unless @shop
            # @todo validate params.shop
            @shop = SHOPS[params.shop.to_sym].new
            if @credentials
              @shop.login(*@credentials) or error! 'Access denied', 401
              @crentials = nil
            end
          end
          @shop
        end
      end

      resources :orders do

        http_basic({realm: "Webshop login"}) do |username, password|
          # can't login right now as +params+ isn't set just yet
          @credentials = [username, password]
        end

        desc "Return a user's past orders"
        get do
          {orders: shop.orders.map(&:to_h)}
        end

        route_param :id, type: Integer, desc: "Order number" do
          desc "Return an order"
          get do
            order = shop.order(params.id)
            order.products.map!(&:to_h)
            {order: order.to_h}
          end
        end

      end

      resources :products do

        route_param :id, type: String, desc: "Product identifier" do
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

# Allow CORS, since we're an API
use Rack::Cors do
  allow do
    origins '*'
    resource '/api/*', headers: :any, methods: [:get, :post, :put, :delete, :options]
  end
end

# include authorization in cache key for urls with +/orders+ in it ...
class Rack::Cache::KeyWithAuth < Rack::Cache::Key
  def generate
    if @request.path =~ /\/orders/
      [super, @request.env['HTTP_AUTHORIZATION']].join
    else
      super
    end
  end
end

use Rack::Cache,
  verbose: false,
  private_headers: [],
  allow_revalidate: true,
  default_ttl: 15.minutes,
  cache_key: Rack::Cache::KeyWithAuth


run API
