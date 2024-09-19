with last_paid_clicks as (
    select
        s.visitor_id,
        MAX(s.visit_date) as last_visit
    from sessions as s
    where s.medium != 'organic'
    group by s.visitor_id
),

tab as (
    select
        lpc.last_visit::date as visit_date,
        s.source as utm_source,
        s.medium as utm_medium,
        s.campaign as utm_campaign,
        COUNT(s.visitor_id) as visitors_count,
        COUNT(l.lead_id) as leads_count,
        COUNT(case when l.status_id = 142 then 1 end) as purchases_count,
        SUM(l.amount) as revenue
    from sessions as s
    inner join last_paid_clicks as lpc
        on
            s.visitor_id = lpc.visitor_id
            and s.visit_date = lpc.last_visit
    left join leads as l
        on
            s.visitor_id = l.visitor_id
            and l.created_at >= visit_date
    group by lpc.last_visit::date, utm_source, utm_medium, utm_campaign
),

costs as (
    select
        SUM(daily_spent) as daily_spent,
        utm_source,
        utm_medium,
        utm_campaign,
        campaign_date
    from vk_ads
    group by utm_source, utm_medium, utm_campaign, campaign_date
    union all
    select
        SUM(daily_spent) as daily_spent,
        utm_source,
        utm_medium,
        utm_campaign,
        campaign_date
    from ya_ads
    group by utm_source, utm_medium, utm_campaign, campaign_date
)

select
    t.visit_date,
    t.utm_source,
    t.utm_medium,
    t.utm_campaign,
    t.visitors_count,
    c.daily_spent as total_cost,
    t.leads_count,
    t.purchases_count,
    t.revenue
from tab as t
left join costs as c
    on
        t.utm_source = c.utm_source
        and t.utm_medium = c.utm_medium
        and t.utm_campaign = c.utm_campaign
        and t.visit_date = c.campaign_date
order by
    t.revenue desc nulls last,
    t.visit_date asc,
    t.visitors_count desc,
    t.utm_source asc,
    t.utm_medium asc,
    t.utm_campaign asc;
