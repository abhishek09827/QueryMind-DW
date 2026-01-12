select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select seller_sk
from "warehouse"."public_gold"."dim_seller"
where seller_sk is null



      
    ) dbt_internal_test