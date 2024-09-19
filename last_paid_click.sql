with last_paid_clicks as (
    select
        s.visitor_id,
        MAX(s.visit_date) as last_visit
    from sessions as s
    where s.medium != 'organic'
    group by s.visitor_id
)

select
    s.visitor_id,
    lpc.last_visit as visit_date,
    s.source as utm_source,
    s.medium as utm_medium,
    s.campaign as utm_campaign,
    l.lead_id,
    l.created_at,
    l.amount,
    l.closing_reason,
    l.status_id
from sessions as s
inner join last_paid_clicks as lpc
    on
        s.visitor_id = lpc.visitor_id
        and s.visit_date = lpc.last_visit
left join leads as l
    on
        s.visitor_id = l.visitor_id
        and l.created_at >= visit_date
order by
    l.amount desc nulls last, visit_date asc,
    utm_source asc, utm_medium asc, utm_campaign asc;
