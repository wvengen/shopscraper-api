#!/usr/bin/env ruby
#
# Scrapes orders from AH webshop
#   pass username, password and optional orderid on command-line
#
require 'mechanize'
require 'ostruct'
require 'typhoeus'
require 'terminal-table'

require_relative 'ah_shop'


def main(user, pass, orderid=nil)
  shop = AHShop.new
  shop.login(user, pass)

  if orderid
    products = shop.order(orderid).products

    table = Terminal::Table.new
    table.headings = %w(x Product Unit)
    table.rows = products.map {|p| [p.quantity, p.name, p.unit]}
    puts table

  else
    orders = shop.orders

    table = Terminal::Table.new
    table.headings = %w(Orderid Date Info)
    table.rows = orders.map {|o| [o.id, o.date, o.info]}
    puts table
  end
end

main ARGV[0], ARGV[1], ARGV[2]
