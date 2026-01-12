
    
    

with child as (
    select order_sk as from_field
    from "warehouse"."public_gold"."fact_payments"
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


