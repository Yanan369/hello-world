--模板查询：带看含省心租占比
--经纪人带看
SELECT  emp.dabu
       ,emp.region_name
           ,emp.partname
       ,SUM(showcnt.qingtuo_cnt)                                                   AS `带看含省心租量`
FROM
(
        SELECT  CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
                     WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
               ,region_name
               ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                 AS partname
               ,employee_no
               ,employee_ucid
               ,employee_name
               ,team_name
               ,job_name
               ,job_level_name
               ,entry_date
        FROM rpt.rpt_comm_employee_info_da
        WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
        AND corp_name = '上海链家'
        AND (region_name LIKE'%沪%' OR region_name LIKE'%豪宅%')
        AND on_job_status_code = '170007002'
        AND job_category_name like '%经纪人%'
        AND job_name IN ('租赁经纪人', '租赁店经理')
        AND data_source <> 'uc' -- 剔除兼岗 
)emp
LEFT JOIN
(
        SELECT  show_detail.showing_agent_ucid
               ,COUNT(distinct show_detail.showing_code)                                                 AS show_cnt --带看量
               ,COUNT(distinct CASE WHEN show_detail.house_num >= 3 THEN show_detail.showing_code end)   AS multishow_cnt --一带三看量
               ,COUNT(distinct CASE WHEN show_detail.qingtuo_num >= 1 THEN show_detail.showing_code end) AS qingtuo_cnt --含轻托管带看量
        FROM
        (
                SELECT  concat(showing_start_time,showing_agent_ucid,custdel_id)           AS showing_code
                       ,to_date(showing_start_time)                                        AS show_date
                       ,showing_agent_ucid
                       ,custdel_id
                       ,cust_ucid
                       ,COUNT(distinct housedel_id)                                        AS house_num
                       ,SUM(distinct CASE WHEN length(housedel_id) > 12 THEN 1 ELSE 0 END) AS qingtuo_num
                FROM rpt.rpt_comm_show_showing_housedel_info_da
                WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
                AND city_code = 310000
                AND to_date(showing_start_time) <> to_date(invalid_time)
                AND to_date(showing_start_time) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(CURRENT_DATE,-1)
                AND is_valid = '1'
                AND del_type_sub_name IN ('求租', '商业求租')
                GROUP BY  concat(showing_start_time,showing_agent_ucid,custdel_id)
                         ,to_date(showing_start_time)
                         ,showing_agent_ucid
                         ,custdel_id
                         ,cust_ucid
        ) AS show_detail
        GROUP BY  show_detail.showing_agent_ucid
) AS showcnt
ON emp.employee_ucid = showcnt.showing_agent_ucid
GROUP BY  emp.dabu
         ,emp.region_name
         ,emp.partname