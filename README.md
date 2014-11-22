AH & Jumbo webshop API
======================

An API for the AH and Jumbo webshop. Uses HTTP basic auth for webshop acount.


Usage
-----

Having [Ruby](http://ruby-lang.org/) and [Bundler](http://bundler.io),
run `bundle install` to install the dependencies, then `rackup` to start
the server. By default, the server listens at port 9292, and you could
go to [http://localhost:9292/api/v1/shop/ah/orders](http://localhost:9292/api/v1/shop/ah/orders).

Requests are cached for 15 minutes (each login separately, of course).


Endpoints
---------

### `GET /api/v1/shop/ah/products/:id`

Returns AH product information.

```json
{
  "product": {
    "id": "wi227237",
    "name": "AH Stoommaaltijd kip rozemarijn",
    "brand_name": "AH",
    "unit": "450 gr",
    "url": "http://www.ah.nl/producten/product/wi227237/ah-stoommaaltijd-kip-rozemarijn",
    "image_url": "http://beeldbank.ahold.com.kpnis.nl/getimage/AHI_434d50313631343639?dRevLabel=1&Rendition=200x200_JPG",
    "description": "Stoommaaltijd met gemarineerde kipfilet, haricots verts en gemarineerde aardappel in schil. Inhoud: haricots verts, gemarineerde aardappel in schil, gemarineerde kipfilet, spekreepjes, kruidenboter en rozemarijn.Lekkere kruidenboter maakt deze stoommaaltijd compleet.Met lekkere knapperige haricots vertsAllergenen: bevat lactose, melkeiwit, tarwegluten. Gemaakt in een bedrijf waar ook pinda's en noten worden verwerkt. De kwaliteit is tot 1 dag na afleveren gegarandeerd."
  }
}
```

### `GET /api/v1/shop/jumbo/products/:id`

Returns Jumbo product information.

```json
{
  "product": {
    "url": "http://www.jumbo.com:80/cool-product/1234AB/",
    "id": "1234AB",
    "name": "Cool Product",
    "unit": "250 g",
    "brand_url": "http://www.coolproducer.nl",
    "currency": "EUR",
    "price": 1.23,
    "storage": "Koel bewaren.",
    "preparation": "Coole gebruiksaanwijzing: eet mij.",
    "ingredients": [
      "Lekkers",
      "E9876543210"
    ],
    "nutrients": [
      {"name": "Energie", "value": "1000 kJ (880 kcal) / 100 g"},
      {"name": "Eiwitten", "value": "<0,5 g / 100 g"},
      {"name": "Natrium", "value": "0,55 g / 100 g"},
    ],
    "image_url": "http://www.jumbo.com/INTERSHOP/static/WFS/Jumbo-Grocery-Site/-/Jumbo-Grocery/nl_NL/product_images/1234AB-1_360x360.png",
    "description": "Dit is echt heel lekker, hoor. Blabla en bla."
  }
}
```

### `GET /api/v1/shop/ah/orders`

Returns orders for a user (auth required).

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

Returns information about an order, most importantly its products (auth required).

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
username, password and an optional orderid as arguments.

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

