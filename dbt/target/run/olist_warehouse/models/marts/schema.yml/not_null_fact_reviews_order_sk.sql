select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select order_sk
from "warehouse"."public_gold"."fact_reviews"
where order_sk is null



      
    ) dbt_internal_test