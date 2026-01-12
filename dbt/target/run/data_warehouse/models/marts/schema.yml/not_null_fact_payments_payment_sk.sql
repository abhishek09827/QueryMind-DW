select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    



select payment_sk
from "warehouse"."public_gold"."fact_payments"
where payment_sk is null



      
    ) dbt_internal_test