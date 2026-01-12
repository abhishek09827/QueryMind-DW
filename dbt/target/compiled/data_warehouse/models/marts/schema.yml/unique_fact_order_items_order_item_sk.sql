
    
    

select
    order_item_sk as unique_field,
    count(*) as n_records

from "warehouse"."public_gold"."fact_order_items"
where order_item_sk is not null
group by order_item_sk
having count(*) > 1


