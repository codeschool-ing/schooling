-- What every table and column of the model means, kept in the database
-- beside the data, where the dictionary is generated from.

COMMENT ON TABLE fact_sales IS 'One row per line of an order that was not cancelled, in a shop or online.';
COMMENT ON COLUMN fact_sales.date_key IS 'Day the order was placed, São Paulo time. Key of dim_date.';
COMMENT ON COLUMN fact_sales.shop_key IS 'Shop the order was placed in; the website is the shop Online. Key of dim_shop.';
COMMENT ON COLUMN fact_sales.book_key IS 'Book sold on this line. Key of dim_book.';
COMMENT ON COLUMN fact_sales.customer_key IS 'Customer as they were when ordering; 0 for a sale nobody identified. Key of dim_customer.';
COMMENT ON COLUMN fact_sales.promotion_key IS 'Promotion applied to the line; 0 when there was none. Key of dim_promotion.';
COMMENT ON COLUMN fact_sales.order_id IS 'Order number in the shop system. With line_no, identifies the row.';
COMMENT ON COLUMN fact_sales.line_no IS 'Position of the line within its order, from 1.';
COMMENT ON COLUMN fact_sales.quantity IS 'Copies sold on the line. Additive.';
COMMENT ON COLUMN fact_sales.gross_cents IS 'Quantity times the unit price charged, before any discount, in centavos. Additive.';
COMMENT ON COLUMN fact_sales.discount_cents IS 'Discount given on the line, in centavos. Additive.';
COMMENT ON COLUMN fact_sales.net_cents IS 'Net sales: gross_cents minus discount_cents, in centavos, without shipping. Additive.';

COMMENT ON TABLE fact_payments IS 'One row per payment; most orders have one, some two. Cancelled orders have none.';
COMMENT ON COLUMN fact_payments.date_key IS 'Day the order was placed, not the day of payment. Key of dim_date.';
COMMENT ON COLUMN fact_payments.shop_key IS 'Shop the order was placed in. Key of dim_shop.';
COMMENT ON COLUMN fact_payments.customer_key IS 'Customer as they were when ordering; 0 when not identified. Key of dim_customer.';
COMMENT ON COLUMN fact_payments.order_id IS 'Order the payment is for.';
COMMENT ON COLUMN fact_payments.payment_id IS 'Payment number in the shop system. Identifies the row.';
COMMENT ON COLUMN fact_payments.method IS 'card, cash, gift_card or pix.';
COMMENT ON COLUMN fact_payments.installments IS 'Number of monthly instalments on a card payment, 1 to 6; 1 for any other method.';
COMMENT ON COLUMN fact_payments.amount_cents IS 'Receipts: the amount paid, shipping included, in centavos. Additive.';

COMMENT ON TABLE fact_inventory IS 'One row per shop, per book it stocks, per month-end count. A periodic snapshot.';
COMMENT ON COLUMN fact_inventory.date_key IS 'Day of the count, the last day of a month. Key of dim_date.';
COMMENT ON COLUMN fact_inventory.shop_key IS 'Shop counted. Key of dim_shop.';
COMMENT ON COLUMN fact_inventory.book_key IS 'Book counted. Key of dim_book.';
COMMENT ON COLUMN fact_inventory.on_hand IS 'Copies on the shelf at the count. Semi-additive: add across shops and books, never across dates.';

COMMENT ON TABLE fact_fulfilment IS 'One row per online order not cancelled, updated as it moves. An accumulating snapshot.';
COMMENT ON COLUMN fact_fulfilment.order_id IS 'Order number in the shop system. Identifies the row.';
COMMENT ON COLUMN fact_fulfilment.customer_key IS 'Customer as they were when ordering. Key of dim_customer.';
COMMENT ON COLUMN fact_fulfilment.ordered_date_key IS 'Day the order was placed. Key of dim_date.';
COMMENT ON COLUMN fact_fulfilment.paid_date_key IS 'Day it was paid; 0, Not yet, until then. Key of dim_date.';
COMMENT ON COLUMN fact_fulfilment.shipped_date_key IS 'Day it was shipped; 0, Not yet, until then. Key of dim_date.';
COMMENT ON COLUMN fact_fulfilment.delivered_date_key IS 'Day it was delivered; 0, Not yet, until then. Key of dim_date.';
COMMENT ON COLUMN fact_fulfilment.status IS 'Latest status: paid, shipped, delivered or returned.';
COMMENT ON COLUMN fact_fulfilment.days_to_ship IS 'Calendar days from order to shipping; empty until shipped.';
COMMENT ON COLUMN fact_fulfilment.days_to_deliver IS 'Calendar days from order to delivery; empty until delivered.';

COMMENT ON TABLE fact_event_attendance IS 'One row per customer who came to an author''s event. Factless: the row is the fact.';
COMMENT ON COLUMN fact_event_attendance.date_key IS 'Day of the event. Key of dim_date.';
COMMENT ON COLUMN fact_event_attendance.shop_key IS 'Shop that held the event. Key of dim_shop.';
COMMENT ON COLUMN fact_event_attendance.author_key IS 'Author the event was for. Key of dim_author.';
COMMENT ON COLUMN fact_event_attendance.customer_key IS 'Customer who came, as they were at six in the evening that day. Key of dim_customer.';

COMMENT ON TABLE dim_date IS 'One row per day of 2024 and 2025, plus key 0, Not yet, for a milestone not reached.';
COMMENT ON COLUMN dim_date.date_key IS 'The date as a number, YYYYMMDD; 0 for Not yet.';
COMMENT ON COLUMN dim_date.date IS 'The calendar date; empty for Not yet.';
COMMENT ON COLUMN dim_date.year IS 'Calendar year.';
COMMENT ON COLUMN dim_date.quarter IS 'Calendar quarter, 1 to 4.';
COMMENT ON COLUMN dim_date.month IS 'Month number, 1 to 12.';
COMMENT ON COLUMN dim_date.month_name IS 'Month name in English.';
COMMENT ON COLUMN dim_date.day_of_month IS 'Day of the month, 1 to 31.';
COMMENT ON COLUMN dim_date.day_of_week IS 'ISO day of the week: 1 is Monday, 7 is Sunday.';
COMMENT ON COLUMN dim_date.day_name IS 'Day name in English.';
COMMENT ON COLUMN dim_date.is_weekend IS 'True on Saturday and Sunday.';
COMMENT ON COLUMN dim_date.is_holiday IS 'True on a Brazilian national holiday.';
COMMENT ON COLUMN dim_date.holiday IS 'Name of the national holiday, in English; empty on other days.';

COMMENT ON TABLE dim_shop IS 'One row per shop, the website included as the shop Online.';
COMMENT ON COLUMN dim_shop.shop_key IS 'Surrogate key, in order of opening.';
COMMENT ON COLUMN dim_shop.shop_id IS 'Shop number in the shop system.';
COMMENT ON COLUMN dim_shop.shop_name IS 'Name the shop is known by.';
COMMENT ON COLUMN dim_shop.city IS 'City the shop is in.';
COMMENT ON COLUMN dim_shop.state IS 'Two-letter state code.';
COMMENT ON COLUMN dim_shop.region IS 'Southeast, South, or Online for the website.';
COMMENT ON COLUMN dim_shop.channel IS 'store or online.';
COMMENT ON COLUMN dim_shop.opened_on IS 'Day the shop opened.';

COMMENT ON TABLE dim_book IS 'One row per book, with its category tree flattened to three levels.';
COMMENT ON COLUMN dim_book.book_key IS 'Surrogate key, in ISBN order.';
COMMENT ON COLUMN dim_book.book_id IS 'Book number in the shop system.';
COMMENT ON COLUMN dim_book.isbn IS 'ISBN-13, kept as text: an identifier, not a number.';
COMMENT ON COLUMN dim_book.title IS 'Title as printed.';
COMMENT ON COLUMN dim_book.authors IS 'Authors in credit order, separated by semicolons. For counting by author, use bridge_book_author.';
COMMENT ON COLUMN dim_book.format IS 'paperback, hardcover or ebook.';
COMMENT ON COLUMN dim_book.category IS 'Lowest level of the category tree.';
COMMENT ON COLUMN dim_book.subcategory IS 'Middle level; repeats category where the tree has only two levels.';
COMMENT ON COLUMN dim_book.department IS 'Top level: Fiction, Non-fiction, Children or Comics.';
COMMENT ON COLUMN dim_book.publisher IS 'Publisher name.';
COMMENT ON COLUMN dim_book.published_on IS 'Publication date.';

COMMENT ON TABLE dim_customer IS 'One row per version of a customer, type 2: a new row when tier, city or state changes.';
COMMENT ON COLUMN dim_customer.customer_key IS 'Surrogate key of this version; 0 for a customer not identified.';
COMMENT ON COLUMN dim_customer.customer_id IS 'Customer number in the shop system, the same in every version; empty for key 0.';
COMMENT ON COLUMN dim_customer.name IS 'Full name as registered, overwritten when corrected (type 1).';
COMMENT ON COLUMN dim_customer.tier IS 'Loyalty tier: none, reader, regular or patron.';
COMMENT ON COLUMN dim_customer.city IS 'City of the registered address.';
COMMENT ON COLUMN dim_customer.state IS 'Two-letter state code of the registered address.';
COMMENT ON COLUMN dim_customer.valid_from IS 'Moment this version took effect, inclusive.';
COMMENT ON COLUMN dim_customer.valid_to IS 'Moment the next version took effect, exclusive; 9999-12-31 for the current one.';
COMMENT ON COLUMN dim_customer.is_current IS 'True on the version in effect now.';

COMMENT ON TABLE dim_promotion IS 'One row per promotion, plus key 0, No promotion.';
COMMENT ON COLUMN dim_promotion.promotion_key IS 'Surrogate key; 0 for No promotion.';
COMMENT ON COLUMN dim_promotion.promotion_id IS 'Promotion number in the shop system; empty for key 0.';
COMMENT ON COLUMN dim_promotion.code IS 'Code a customer types or a cashier keys in.';
COMMENT ON COLUMN dim_promotion.promotion_name IS 'Name used in the shops'' material.';
COMMENT ON COLUMN dim_promotion.percent_off IS 'Discount it gives, in percent.';
COMMENT ON COLUMN dim_promotion.starts_on IS 'First day the promotion applied.';
COMMENT ON COLUMN dim_promotion.ends_on IS 'Last day the promotion applied, inclusive.';
COMMENT ON COLUMN dim_promotion.applies_to IS 'Department it applies to, or All departments.';

COMMENT ON TABLE dim_author IS 'One row per author.';
COMMENT ON COLUMN dim_author.author_key IS 'Surrogate key.';
COMMENT ON COLUMN dim_author.author_id IS 'Author number in the shop system.';
COMMENT ON COLUMN dim_author.author_name IS 'Name as credited on the books.';
COMMENT ON COLUMN dim_author.country IS 'Country of the author, as the publisher records it.';

COMMENT ON TABLE bridge_book_author IS 'One row per author of each book. Joins dim_book to dim_author.';
COMMENT ON COLUMN bridge_book_author.book_key IS 'Key of dim_book.';
COMMENT ON COLUMN bridge_book_author.author_key IS 'Key of dim_author.';
COMMENT ON COLUMN bridge_book_author.position IS 'Order of credit on the book, from 1.';
COMMENT ON COLUMN bridge_book_author.weight IS 'One divided by the number of authors; weights of one book add up to 1.';
