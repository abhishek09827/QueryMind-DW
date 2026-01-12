select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with child as (
    select order_sk as from_field
    from "warehouse"."public_gold"."fact_reviews"
    where order_sk is not null
),

parent as (
    select order_sk as to_field
    from "warehouse"."public_gold"."fact_orders"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



      
    ) dbt_internal_test