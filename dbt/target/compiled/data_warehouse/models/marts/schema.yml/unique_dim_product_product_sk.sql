
    
    

select
    product_sk as unique_field,
    count(*) as n_records

from "warehouse"."public_gold"."dim_product"
where product_sk is not null
group by product_sk
having count(*) > 1


