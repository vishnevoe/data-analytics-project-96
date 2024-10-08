/* Запрос, рассчитывающий основные метрики:
cpu, cpl, cppu, roi */

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
),

main as (
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
        t.utm_campaign asc
)

select
    utm_source,
    ROUND(SUM(total_cost) / SUM(visitors_count), 2) as cpu,
    ROUND(SUM(total_cost) / SUM(leads_count), 2) as cpl,
    ROUND(SUM(total_cost) / SUM(purchases_count), 2) as cppu,
    ROUND(
        (SUM(revenue) - SUM(total_cost)) / SUM(total_cost) * 100, 2
    ) as roi
from main
where utm_source in ('vk', 'yandex')
group by utm_source;

/* Запрос, с помощью которого
рассчитываются расходы на рекламу по дням */

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
),

main as (
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
        t.utm_campaign asc
)

select
    visit_date,
    utm_source as source,
    SUM(total_cost) as total_cost
from main
where utm_source in ('vk', 'yandex')
group by visit_date, utm_source
order by visit_date;

/* Запрос, с помощью которого
проводится расчет окупаемости рекламы */

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
),

main as (
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
        t.utm_campaign asc
)

select
    utm_source as source,
    SUM(total_cost) as total_cost,
    SUM(COALESCE(revenue, 0)) as revenue
from main
where utm_source in ('vk', 'yandex')
group by utm_source;

/* Каналы и визиты по дням */

select
    DATE_TRUNC('day', visit_date)::date as visit_date,
    source,
    medium,
    campaign,
    COUNT(visitor_id) as visitors_count
from sessions
group by DATE_TRUNC('day', visit_date)::date, source, medium, campaign
order by visit_date asc, visitors_count desc;

/* Каналы и визиты по неделям */

select
    DATE_TRUNC('week', visit_date)::date as visit_date,
    source,
    medium,
    campaign,
    COUNT(visitor_id) as visitors_count
from sessions
group by DATE_TRUNC('week', visit_date)::date, source, medium, campaign
order by visit_date asc, visitors_count desc;

/* Конверсия из визита (клика)
в лид */

select
    COUNT(lead_id) as count_leads,
    COUNT(visitor_id) as count_visitors,
    ROUND(COUNT(lead_id) * 100.0 / COUNT(visitor_id), 2) as conv
from last_paid_clicks_full;

/* Конверсия из лида
в оплату */

select
    COUNT(lead_id) as count_leads,
    COUNT(case when status_id = 142 then 1 end) as purchases_count,
    ROUND(
        COUNT(case when status_id = 142 then 1 end)
        * 100.0
        / COUNT(lead_id),
        2
    ) as conv
from last_paid_clicks_full;
