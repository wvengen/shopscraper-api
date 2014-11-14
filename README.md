AH webshop API
==============

An API for the AH webshop. Uses HTTP basic auth for webshop acount.


Usage
-----

Having [Ruby](http://ruby-lang.org/) and [Bundler](http://bundler.io),
run `bundle install` to install the dependencies, then `rackup` to start
the server. By default, the server listens at port 9292, and you could
go to http://localhost:9292/api/v1/shop/ah/orders



Endpoints
---------

### `GET /api/v1/shop/ah/orders`

Returns orders for a user.

```json
{
  "orders": [
    {
      "id": "1234",
      "date": "dinsdag 11 november",
      "url": "https://www.ah.nl/producten/eerder-gekocht/bestelling?orderno=1234",
      "info": ""
    }
  ]
}
```

### `GET /api/v1/shop/ah/orders/:id`

Returns information about an order, most importantly its products.

```json
{
  "id": "1234",
  "date": "dinsdag 11 november",
  "products": [
    {
      "name": "Lekkere mandarijnen",
      "quantity": "3",
      "unit": "8 stuks",
      "category": "Aardappel, groente en fruit",
      "url": "https://www.ah.nl/producten/product/wi1234/lekkere-mandarijnen",
      "image_url": "http://beeldbank.ahold.com.kpnis.nl/getimage/AHI-abcdef?dRevLabel=1&Rendition=200x200.JPG"
    }
  ]
}
```

With a bit more effort, the barcode (ean) can be discovered. Add `ean=1` to the
parameters when doing the request, and this will be returned as a product
attribute when available. This does make the request quite a bit slower for
more than a couple of products.


Command-line example
--------------------

An example command-line application can be found in cli.rb. It expects
username, password and an optional orderid as parameters.

```
$ ./cli.rb me@example.com s3rect
+----------+----------------------+------+
| Orderid  | Date                 | Info |
+----------+----------------------+------+
| 12345678 | dinsdag 11 november  |      |
| 01234567 | dinsdag 4 november   |      |
+----------------------------------------+
$ ./cli.rb me@example.com s3rect 12345678
+---+-----------------------------------------+------------+
| x | Product                                 | Unit       |
+---+-----------------------------------------+------------+
| 1 | Avocado eetrijp                         | 3 stuks    |
| 5 | Biologische halfvolle melk              | 1 lt       |
| 3 | biologische pindakaas                   | 350 gr     |
+---+-----------------------------------------+------------+
```

