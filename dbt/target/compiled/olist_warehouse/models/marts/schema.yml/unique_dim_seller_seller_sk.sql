
    
    

select
    seller_sk as unique_field,
    count(*) as n_records

from "warehouse"."public_gold"."dim_seller"
where seller_sk is not null
group by seller_sk
having count(*) > 1


