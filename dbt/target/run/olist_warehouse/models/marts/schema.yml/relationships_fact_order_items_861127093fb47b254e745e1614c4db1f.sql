select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
    

with child as (
    select product_sk as from_field
    from "warehouse"."public_gold"."fact_order_items"
    where product_sk is not null
),

parent as (
    select product_sk as to_field
    from "warehouse"."public_gold"."dim_product"
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null



      
    ) dbt_internal_test