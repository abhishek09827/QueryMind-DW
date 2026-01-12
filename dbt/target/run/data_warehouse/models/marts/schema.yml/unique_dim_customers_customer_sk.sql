select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

select
    customer_sk as unique_field,
    count(*) as n_records

from "warehouse"."public_gold"."dim_customers"
where customer_sk is not null
group by customer_sk
having count(*) > 1



      
    ) dbt_internal_test