select * from ecomm.categories c limit 50
-- Contains different possible categories for products. Includes a product_id to connect to products table

select * from ecomm.order_items oi limit 50
-- Contains revenues and ids for different orders made by customers

select * from ecomm.orders_part op limit 50
-- Conatins various facts about each order, inclduing address, payment method, order status, and other important data points

select * from ecomm.products p limit 50
-- Contains facts about each type of product and brands that are offered on the ecommerce site 

select * from  ecomm.reviews r limit 50
-- Contains reviews for each product. Includes a product id to connect to the products table



create or replace view ecomm.ecommerce_profit_report as -- Create a new view in the Ecomm schema to utilize when creating the dashboard
with brand_avg_review as ( -- A CTE that computes the average rating for each brand on the website along with a ranking 
select 
avg(r.rating) as brand_rating -- Average aggregation for rating
,count(r.rating) as ratings_count -- Ratings count for each brand
,rank() over (order by avg(r.rating) desc) as brand_rank -- Window fucntion to rank the brands by their average rating
,p.brand
from ecomm.products p 
left join ecomm.reviews r on p.product_id = r.product_id -- Join in the products table to include the brand in the query
group by p.brand -- Group the aggregations by Brand
)
select
c.category_id
,c.category_name
,c.parent_category
,oi.order_item_id
,oi.order_id
,oi.product_id
,oi.quantity 
,oi.unit_price
,oi.line_total
,oi.discount_amount
,cast(op.order_date as timestamp) as order_date -- Change the order date format into a timestamp
,op.status
,op.payment_method
,op.shipping_address
,left(right(op.shipping_address, 8),2) as state -- Extract the state abbreviation from the shipping address
,op.shipping_cost
,p.product_name
,p.brand
,p.price as product_price
,p.cost as product_cost
,case 
	when op.status in ('Cancelled', 'Refunded', 'Returned') 
		then 0
	else (oi.line_total - (oi.discount_amount + (oi.quantity*p.cost))) 
 end as profit -- Case statement to take out orders that were cancelled, refunded, or returned in order to correctly compute profit
,b.brand_rating
,b.brand_rank
from ecomm.order_items oi -- Select data from the order items table to get order totals
inner join ecomm.orders_part op on oi.order_id = op.order_id -- Join in orders part table to include fatcs about each order
left join ecomm.products p on oi.product_id = p.product_id -- Join in the products table to include facts about the product sold and the cost of the product to compute profit
left join ecomm.categories c on c.category_id = p.category_id -- Join in the category each product falls under
left join brand_avg_review b on p.brand = b.brand -- Join in brand average review CTE 
;


select * from ecomm.ecommerce_profit_report limit 100



