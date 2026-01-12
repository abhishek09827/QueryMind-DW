
    
    

select
    review_sk as unique_field,
    count(*) as n_records

from "warehouse"."public_gold"."fact_reviews"
where review_sk is not null
group by review_sk
having count(*) > 1


