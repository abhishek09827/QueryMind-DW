select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    payment_sk as unique_field,
    count(*) as n_records

from "warehouse"."public_gold"."fact_payments"
where payment_sk is not null
group by payment_sk
having count(*) > 1



      
    ) dbt_internal_test