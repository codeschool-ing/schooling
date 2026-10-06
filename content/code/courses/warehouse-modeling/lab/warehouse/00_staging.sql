-- The extract, loaded as it arrived: one table per CSV file, in a schema of
-- its own, so nothing downstream reads a file directly.
SET TimeZone = 'America/Sao_Paulo';
CREATE SCHEMA staging;
CREATE TABLE staging.shops            AS FROM read_csv('extract/shops.csv', sample_size = -1);
CREATE TABLE staging.categories       AS FROM read_csv('extract/categories.csv', sample_size = -1);
CREATE TABLE staging.publishers       AS FROM read_csv('extract/publishers.csv', sample_size = -1);
CREATE TABLE staging.authors          AS FROM read_csv('extract/authors.csv', sample_size = -1);
CREATE TABLE staging.books            AS FROM read_csv('extract/books.csv', sample_size = -1,
                                                    types = {'isbn': 'VARCHAR'});
CREATE TABLE staging.book_authors     AS FROM read_csv('extract/book_authors.csv', sample_size = -1);
CREATE TABLE staging.customers        AS FROM read_csv('extract/customers.csv', sample_size = -1);
CREATE TABLE staging.customer_changes AS FROM read_csv('extract/customer_changes.csv', sample_size = -1);
CREATE TABLE staging.promotions       AS FROM read_csv('extract/promotions.csv', sample_size = -1);
CREATE TABLE staging.orders           AS FROM read_csv('extract/orders.csv', sample_size = -1);
CREATE TABLE staging.order_lines      AS FROM read_csv('extract/order_lines.csv', sample_size = -1);
CREATE TABLE staging.payments         AS FROM read_csv('extract/payments.csv', sample_size = -1);
CREATE TABLE staging.stock_counts     AS FROM read_csv('extract/stock_counts.csv', sample_size = -1);
CREATE TABLE staging.events           AS FROM read_csv('extract/events.csv', sample_size = -1);
CREATE TABLE staging.event_attendance AS FROM read_csv('extract/event_attendance.csv', sample_size = -1);
