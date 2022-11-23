--模板查询：9月链家分行收出房
--模板查询：百日奋战分行收房
SELECT  concat(funnel1.partname,row_number() over(partition by funnel1.partname ORDER BY funnel1.team_name))
       ,funnel1.dabu
       ,funnel1.region_name
       ,funnel1.partname
       ,funnel1.team_name
       ,funnel1.nh_cnt
       ,funnel1.nh_to_tf
       ,funnel1.tf_in24h
       ,funnel1.tf_400_cnt
       ,funnel1.tf_op_cnt
       ,funnel1.tf_high_op
       ,funnel1.tf_prospecting_cnt
-- , funnel1.pro_tg_cnt
       ,nvl(7dsk.7d_prospecting_cnt,0)        AS 7d_prospecting_cnt
       ,nvl(7dsk.7d_prospecting_tg_cnt,0)     AS prospecting_tg_cnt
       ,nvl(shouchu.shou_cnt,0)               AS shou_cnt --推荐人架构收房量
       ,nvl(shouchu.chu_cnt,0)                AS current_month_chu --本月出房量
       ,nvl(tf.tf_cnt,0)                      AS tf_cnt --推房人架构本月推房
       ,nvl(showcnt.qingtuo_cnt,0)            AS qingtuo_cnt --含轻托管带看量
       ,nvl(7dsk.month_prospecting_cnt,0)     AS month_prospecting_cnt -- 本月实地评估（推房人架构）
       ,nvl(7dsk.month_prospecting_tg_cnt,0)  AS month_prospecting_tg_cnt -- 本月实地评估收房
       ,nvl(7dsk.yesterday_prospecting_cnt,0) AS yesterday_prospecting_cnt --昨日实地评估量（推房人架构）
       ,nvl(shouchu.shou_period1_cnt,0)       AS `p1收房量`
       ,nvl(shouchu.shou_period2_cnt,0)       AS `p2收房量`
       ,nvl(shouchu.shou_period3_cnt,0)       AS `p3收房量`
       ,nvl(shouchu.shou_period4_cnt,0)       AS `p4收房量`
       ,nvl(shouchu.chu_period1_cnt,0)        AS `p1出房量`
       ,nvl(shouchu.chu_period2_cnt,0)        AS `p2出房量`
       ,nvl(shouchu.chu_period3_cnt,0)        AS `p3出房量`
       ,nvl(shouchu.chu_period4_cnt,0)        AS `p4出房量`
       ,nvl(shouchu.yesterday_shou,0)         AS `昨日收房量`
       ,nvl(shouchu.yesterday_chu,0)          AS `昨日出房量`
       ,nvl(funnel1.nh_to_tg,0)               AS `新增房转收`
FROM
(
	SELECT  f1.dabu
	       ,f1.region_name
	       ,f1.partname
	       ,f1.team_name
	       ,COUNT(distinct f1.housedel_id)                                                                                AS nh_cnt --新增房
	       ,COUNT(distinct f1.biz_code)                                                                                   AS nh_to_tf --新增房转推
	       ,COUNT(distinct CASE WHEN f1.del_status = 2 THEN f1.biz_code else null end)                                    AS nh_to_tg
	       ,COUNT(distinct CASE WHEN f1.tf_hours <= 24 THEN f1.biz_code else null end)                                    AS tf_in24h -- 24h内推房
	       ,COUNT(distinct CASE WHEN f1.is_call = 1 THEN f1.biz_code else null end)                                       AS tf_400_cnt
	       ,COUNT(distinct CASE WHEN f1.is_complete_opportunity_level = 1 THEN f1.biz_code else null end)                 AS tf_op_cnt
	       ,COUNT(distinct CASE WHEN f1.neg_opportunity_level_name = '高意向' THEN f1.biz_code else null end)                AS tf_high_op
	       ,COUNT(distinct CASE WHEN f1.is_complete_prospecting = 1 THEN f1.biz_code else null end)                       AS tf_prospecting_cnt
	       ,COUNT(distinct CASE WHEN f1.is_complete_prospecting = 1 AND f1.del_status = 2 THEN f1.biz_code else null end) AS pro_tg_cnt
	FROM
	(
		SELECT  emp.dabu
		       ,emp.region_name
		       ,emp.partname
		       ,emp.team_name
		       ,ff1.housedel_id
		       ,ff1.biz_code
		       ,ff1.typer_time
		       ,ff1.create_time
		       ,ff1.tf_hours
		       ,ff1.del_create_time
		       ,ff1.del_status
		       ,ff1.is_call
		       ,ff1.first_call_time
		       ,ff1.is_24h_call
		       ,ff1.is_30s_call
		       ,ff1.is_complete_opportunity_level
		       ,ff1.neg_at_skz_time
		       ,ff1.neg_opportunity_level
		       ,ff1.neg_opportunity_level_name
		       ,ff1.is_complete_prospecting
		       ,ff1.neg_at_wxz_time
		       ,ff1.estimate_time
		       ,ff1.is_estimate
		       ,ff1.is_estimate_approved
		       ,ff1.call_cnt
		       ,ff1.follow_cnt
		FROM
		( -- 架构
			SELECT  distinct corp_name
			       ,CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
			             WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
			       ,region_name
			       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                 AS partname
			       ,team_name
			FROM rpt.rpt_comm_employee_info_da
			WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
			AND corp_name = '上海链家' --限制上海链家
			AND (region_name LIKE'%沪%' OR region_name LIKE'%豪宅%')
			AND on_job_status_code = '170007002' --在职
			AND job_category_name like '%经纪人%' --限制经纪人
			AND team_name NOT like '%租赁业务%'
			AND team_name NOT like '%新房业务%'
			AND region_name not like '%新房%'
			AND team_name <> '' 
		)emp
		LEFT JOIN
		(
			SELECT  nh.housedel_id
			       ,nh.holder_agent_no
			       ,nh.holder_agent_name
			       ,nh.holder_region_name
			       ,nh.holder_partname
			       ,nh.holder_team_name
			       ,tf1.biz_code
			       ,nh.typer_time
			       ,tf1.create_time
			       ,(unix_timestamp(tf1.create_time) - unix_timestamp(nh.typer_time))/3600 AS tf_hours
			       ,tf2.del_create_time
			       ,tf2.del_status
			       ,tf2.is_call
			       ,tf2.first_call_time
			       ,tf2.is_24h_call
			       ,tf2.is_30s_call
			       ,tf2.is_complete_opportunity_level
			       ,tf2.neg_at_skz_time
			       ,tf2.neg_opportunity_level
			       ,tf2.neg_opportunity_level_name
			       ,tf2.is_complete_prospecting
			       ,tf2.neg_at_wxz_time
			       ,tf2.estimate_time
			       ,tf2.is_estimate
			       ,tf2.is_estimate_approved
			       ,tf2.call_cnt
			       ,tf2.follow_cnt
			FROM
			(
				SELECT  CASE WHEN typer_region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
				             WHEN typer_region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
				       ,typer_region_name                                                                                               AS region_name
				       ,CASE WHEN typer_region_name like '%豪宅%' THEN typer_area_name  ELSE typer_marketing_name END                     AS partname
				       ,housedel_id
				       ,resblock_id
				       ,resblock_name
				       ,to_date(typer_time)                                                                                             AS type_date
				       ,typer_time
				       ,typer_agent_no
				       ,typer_agent_name
				       ,typer_region_name
				       ,typer_marketing_name
				       ,typer_area_name
				       ,CASE WHEN typer_region_name like '%豪宅%' THEN typer_area_name  ELSE typer_marketing_name END                     AS typer_partname
				       ,typer_team_name
				       ,holder_agent_no
				       ,holder_agent_name
				       ,holder_region_name
				       ,holder_marketing_name
				       ,holder_area_name
				       ,CASE WHEN holder_region_name like '%豪宅%' THEN holder_area_name  ELSE holder_marketing_name END                  AS holder_partname
				       ,holder_team_name
				FROM rpt.rpt_coo_hdel_hdel_entrust_detail_da
				WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
				AND del_type_code = '990001002' -- 990001002 租赁
				AND city_name = '上海市'
				AND to_date(typer_time) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND date_add(CURRENT_DATE, -1)
				AND to_date(typer_time) <> to_date(cancel_time)
				AND (holder_region_name like '%沪%' or holder_region_name like '%豪宅%')
				AND stat_function_code not IN ('110006005', '110006014', '110006007', '110006001') 
			)nh
			LEFT JOIN
			(
				SELECT  housedel_id -- 原普租房源编号
				       ,luru_riqi
				       ,biz_code -- 房源编号
				       ,employee_no_1
				       ,employee_name_1
				       ,region_name_1
				       ,marketing_name_1
				       ,area_name_1
				       ,CASE WHEN region_name_1 like '%豪宅%' THEN area_name_1  ELSE marketing_name_1 END AS partname_1
				       ,employee_no_2
				       ,employee_name_2
				       ,region_name_2
				       ,marketing_name_2
				       ,area_name_2
				       ,contract_sign_time
				       ,create_time
				       ,status
				       ,neg_invalid_reason_remark
				FROM rpt.rpt_trusteeship_tuifang_data
				WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
				AND city_code = '310000'
				AND to_date(create_time) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND date_add(CURRENT_DATE, -1) 
			)tf1
			ON nh.housedel_id = tf1.housedel_id
			LEFT JOIN
			(
				SELECT  trusteeship_housedel_code
				       ,old_housedel_typing_time
				       ,del_create_time
				       ,del_status
				       ,neg_opportunity_invalid_reason
				       ,push_employee_name
				       ,push_employee_no
				       ,manager_name
				       ,manager_ucid
				       ,manager_no
				       ,manager_shop_name
				       ,manager_area_name
				       ,manager_marketing_name
				       ,manager_region_name
				       ,score
				       ,is_call
				       ,first_call_time
				       ,is_24h_call
				       ,is_30s_call
				       ,is_complete_opportunity_level
				       ,neg_at_skz_time
				       ,neg_opportunity_level
				       ,neg_opportunity_level_name
				       ,is_complete_prospecting
				       ,neg_at_wxz_time
				       ,estimate_time
				       ,is_estimate
				       ,is_estimate_approved
				       ,city_code
				       ,city_name
				       ,call_cnt
				       ,follow_cnt
				FROM olap.olap_trusteeship_hdel_follow_process_da
				WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
				AND city_code = '310000' 
			)tf2
			ON tf1.biz_code = tf2.trusteeship_housedel_code
		)ff1
		ON emp.team_name = ff1.holder_team_name
	)f1
	GROUP BY  f1.dabu
	         ,f1.region_name
	         ,f1.partname
	         ,f1.team_name
)funnel1
LEFT JOIN
(
	SELECT  DISTINCT f2.team_name
	       ,f2.7d_prospecting_cnt
	       ,f2.7d_prospecting_tg_cnt
	       ,f2.month_prospecting_cnt
	       ,f2.month_prospecting_tg_cnt
	       ,f2.yesterday_prospecting_cnt
	FROM
	(
		SELECT  emp.team_name
		       ,COUNT(distinct CASE WHEN to_date(b.neg_at_wxz_time) BETWEEN date_add(CURRENT_DATE,-7) AND date_add(CURRENT_DATE,-1) AND b.is_complete_prospecting = 1 THEN b.trusteeship_housedel_code else null end) AS 7d_prospecting_cnt
		       ,COUNT(distinct CASE WHEN to_date(b.neg_at_wxz_time) BETWEEN date_add(CURRENT_DATE,-7) AND date_add(CURRENT_DATE,-1) AND b.is_complete_prospecting = 1 AND b.del_status = 2 THEN b.trusteeship_housedel_code else null end) AS 7d_prospecting_tg_cnt
		       ,COUNT(distinct CASE WHEN to_date(b.neg_at_wxz_time) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(CURRENT_DATE,-1) AND b.is_complete_prospecting = 1 THEN b.trusteeship_housedel_code else null end) AS month_prospecting_cnt
		       ,COUNT(distinct CASE WHEN to_date(b.neg_at_wxz_time) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(CURRENT_DATE,-1) AND b.is_complete_prospecting = 1 AND b.del_status = 2 THEN b.trusteeship_housedel_code else null end) AS month_prospecting_tg_cnt
		       ,COUNT(distinct CASE WHEN to_date(b.neg_at_wxz_time) = date_add(CURRENT_DATE,-1) AND b.is_complete_prospecting = 1 THEN b.trusteeship_housedel_code else null end) AS yesterday_prospecting_cnt
		FROM
		(
			SELECT  trusteeship_housedel_code
			       ,old_housedel_typing_time
			       ,del_create_time
			       ,del_status
			       ,neg_opportunity_invalid_reason
			       ,push_employee_name
			       ,push_employee_no
			       ,manager_name
			       ,manager_ucid
			       ,manager_no
			       ,manager_shop_name
			       ,manager_area_name
			       ,manager_marketing_name
			       ,manager_region_name
			       ,score
			       ,is_call
			       ,first_call_time
			       ,is_24h_call
			       ,is_30s_call
			       ,is_complete_opportunity_level
			       ,neg_at_skz_time
			       ,neg_opportunity_level
			       ,neg_opportunity_level_name
			       ,is_complete_prospecting
			       ,neg_at_wxz_time
			       ,estimate_time
			       ,is_estimate
			       ,is_estimate_approved
			       ,city_code
			       ,city_name
			       ,call_cnt
			       ,follow_cnt
			       ,(unix_timestamp(del_create_time) - unix_timestamp(old_housedel_typing_time))/3600 AS tf_hours
			FROM olap.olap_trusteeship_hdel_follow_process_da
			WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
			AND city_code = '310000'
			AND to_date(neg_at_wxz_time) BETWEEN date_add(trunc(date_add(CURRENT_DATE, -1), 'MM'), -7) AND date_add(CURRENT_DATE, -1) 
		)b
		LEFT JOIN
		( -- 架构
			SELECT  distinct corp_name
			       ,CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
			             WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
			       ,region_name
			       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                 AS partname
			       ,team_name
			       ,employee_no
			FROM rpt.rpt_comm_employee_info_da
			WHERE pt BETWEEN concat(regexp_replace(date_add(trunc(date_add(CURRENT_DATE, -1), 'MM'), -7), '-', ''), '000000') AND concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000') 
		)emp
		ON b.push_employee_no = emp.employee_no
		GROUP BY  emp.team_name
	)f2
)7dsk
ON funnel1.team_name = 7dsk.team_name
LEFT JOIN
(
	SELECT  base.team_name
	       ,SUM(nvl(base.shou_cnt,0))                                                               AS shou_cnt
	       ,SUM(nvl(base.chu_cnt,0))                                                                AS chu_cnt
	       ,SUM(case WHEN base.shou_period = '1' THEN nvl(base.shou_cnt,0) else 0 end)              AS shou_period1_cnt
	       ,SUM(case WHEN base.shou_period = '2' THEN nvl(base.shou_cnt,0) else 0 end)              AS shou_period2_cnt
	       ,SUM(case WHEN base.shou_period = '3' THEN nvl(base.shou_cnt,0) else 0 end)              AS shou_period3_cnt
	       ,SUM(case WHEN base.shou_period = '4' THEN nvl(base.shou_cnt,0) else 0 end)              AS shou_period4_cnt
	       ,SUM(case WHEN base.chu_period = '1' THEN nvl(base.chu_cnt,0) else 0 end)                AS chu_period1_cnt
	       ,SUM(case WHEN base.chu_period = '2' THEN nvl(base.chu_cnt,0) else 0 end)                AS chu_period2_cnt
	       ,SUM(case WHEN base.chu_period = '3' THEN nvl(base.chu_cnt,0) else 0 end)                AS chu_period3_cnt
	       ,SUM(case WHEN base.chu_period = '4' THEN nvl(base.chu_cnt,0) else 0 end)                AS chu_period4_cnt
	       ,SUM(case WHEN base.shou_date = date_add(CURRENT_DATE,-1) THEN base.shou_cnt else 0 end) AS yesterday_shou
	       ,SUM(case WHEN base.chu_cdate = date_add(CURRENT_DATE,-1) THEN base.chu_cnt else 0 end)  AS yesterday_chu
	FROM
	(
		SELECT  DISTINCT CASE WHEN org.team_name is null THEN empnow.team_name ELSE emp.team_name END AS team_name
		       ,empnow.dabu                                                                           AS dabu_now
		       ,empnow.region_name                                                                    AS region_name_now
		       ,empnow.partname                                                                       AS partname_now
		       ,empnow.team_name                                                                      AS team_name_now
		       ,emp.employee_no
		       ,emp.employee_name
		       ,emp.job_name
		       ,empnow.job_name                                                                       AS job_name_now
			   ,shou.tuifang_date
		       ,shou.shou_date
		       ,chu.chu_cdate
		       ,CASE WHEN shou.shou_date BETWEEN '2022-09-01' AND '2022-09-12' THEN '1'
		             WHEN shou.shou_date BETWEEN '2022-09-13' AND '2022-09-18' THEN '2'
		             WHEN shou.shou_date BETWEEN '2022-09-19' AND '2022-09-26' THEN '3'
		             WHEN shou.shou_date BETWEEN '2022-09-27' AND '2022-09-30' THEN '4' END           AS shou_period
		       ,nvl(shou.shou_cnt,0)                                                                  AS shou_cnt
		       ,CASE WHEN chu.chu_cdate BETWEEN '2022-09-01' AND '2022-09-12' THEN '1'
		             WHEN chu.chu_cdate BETWEEN '2022-09-13' AND '2022-09-18' THEN '2'
		             WHEN chu.chu_cdate BETWEEN '2022-09-19' AND '2022-09-26' THEN '3'
		             WHEN chu.chu_cdate BETWEEN '2022-09-27' AND '2022-09-30' THEN '4' END            AS chu_period
		       ,nvl(chu.chu_cnt,0)                                                                    AS chu_cnt
		FROM
		(
			SELECT  CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
			             WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
			       ,region_name
			       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                 AS partname
			       ,org_name
			       ,employee_no
			       ,employee_ucid
			       ,employee_name
			       ,team_name
			       ,job_name
			       ,job_level_name
			       ,entry_date
			       ,concat_ws('-',substr(pt,1,4),substr(pt,5,2) ,substr(pt,7,2))                                              AS dt
			FROM rpt.rpt_comm_employee_info_da
			WHERE pt BETWEEN concat(REGEXP_replace(date_add(CURRENT_DATE, -90), '-', ''), '000000') AND concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
			AND corp_name = '上海链家'
			AND region_name RLIKE '^沪|链家'
			AND on_job_status_code = '170007002'
			AND job_category_name like '%经纪人%' -- AND job_name IN ( '租赁经纪人', '租赁店经理', '综合经纪人', '综合店经理')
			AND data_source <> 'uc' -- 剔除兼岗 
		) AS emp
		LEFT JOIN
		(
			SELECT  CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
			             WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
			       ,region_name
			       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                 AS partname
			       ,org_name
			       ,employee_no
			       ,employee_ucid
			       ,employee_name
			       ,team_name
			       ,job_name
			       ,job_level_name
			       ,entry_date
			       ,concat_ws('-',substr(pt,1,4),substr(pt,5,2) ,substr(pt,7,2))                                              AS dt
			FROM rpt.rpt_comm_employee_info_da
			WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
			AND corp_name = '上海链家'
			AND region_name RLIKE '^沪|链家'
			AND on_job_status_code = '170007002'
			AND job_category_name like '%经纪人%' -- AND job_name IN ( '租赁经纪人', '租赁店经理', '综合经纪人', '综合店经理')
			AND data_source <> 'uc' -- 剔除兼岗 
		) AS empnow
		ON emp.employee_no = empnow.employee_no
		LEFT JOIN
		(
			SELECT  distinct CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部' WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
			       ,region_name
			       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END AS partname
			       ,team_name
			FROM rpt.rpt_comm_employee_info_da
			WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
			AND corp_name = '上海链家'
			AND region_name RLIKE '^沪|链家'
			AND on_job_status_code = '170007002'
			AND job_category_name like '%经纪人%'
			AND data_source <> 'uc' -- 剔除兼岗 
		) AS org
		ON org.team_name = emp.team_name
		LEFT JOIN
		(
			SELECT  shou1.push_no
			       ,tf.tuifang_date
			       ,CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.contract_sign_date
			             WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN substr(chu.chu_cdate,1,10) END AS shou_date
			       ,COUNT(distinct CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code end) AS shou_cnt
			FROM
			(
				SELECT  trusteeship_housedel_code                                                                                                                   AS del_code
				       ,old_housedel_id
				       ,concat(trusteeship_housedel_code,'01')                                                                                                      AS housedel_dk
				       ,if(housedel_id = '-911','null',housedel_id)                                                                                                 AS housedel_code
				       ,house_id
				       ,contract_code
				       ,resblock_id
				       ,resblock_name
				       ,bizcircle_name
				       ,district_name
				       ,fitment_status
				       ,bedroom_num
				       ,physical_floor
				       ,overground_floor_cnt
				       ,CASE WHEN (physical_floor = 1 or physical_floor = overground_floor_cnt or (physical_floor >= 5 AND is_has_elevator = 0)) THEN 1  ELSE 0 END AS is_edge
				       ,is_has_elevator
				       ,is_vr
				       ,display_status_name
				       ,CASE WHEN rent_type = 0 THEN '不限'
				             WHEN rent_type = 1 THEN '整租'
				             WHEN rent_type = 2 THEN '合租' END                                                                                                       AS rent_type
				       ,CASE WHEN neg_housedel_source = 1 THEN '普租转录'
				             WHEN neg_housedel_source = 2 THEN '新增录入' END                                                                                           AS housedel_source
				       ,CASE WHEN sub_biz_type = 1 THEN '标准合同'
				             WHEN sub_biz_type = 2 THEN '续约合同' END                                                                                                  AS sub_biz_type_name
				       ,CASE WHEN rent_unit_status_name = '未知' THEN '装配中'  ELSE rent_unit_status_name END                                                           AS rent_unit_status_name
				       ,contract_status_name
				       ,contract_sign_time
				       ,to_date(contract_sign_time)                                                                                                                 AS contract_sign_date
				       ,CASE WHEN to_date(contract_sign_time) >= '2022-01-21' AND protocol_type = '普通' THEN '省心租'
				             WHEN to_date(contract_sign_time) >= '2022-07-20' AND protocol_type = '无忧' THEN '无忧'  ELSE '轻托管' END                                    AS service_type
				       ,effect_start_date
				       ,effect_end_date
				       ,sign_years
				       ,manager_ucid
				       ,manager_no
				       ,manager_name
				       ,manager_shop_name
				       ,push_employee_ucid
				       ,push_employee_name
				       ,push_employee_no                                                                                                                            AS push_no
				       ,sign_ucid
				       ,sign_no
				       ,sign_name
				       ,sign_marketing_name
				       ,sign_area_name
				       ,customer_code
				       ,revoke_back_date
				       ,is_follow
				       ,unit_guide_price
				       ,old_housedel_price
				       ,houseout_guide_price
				       ,expected_profits1
				       ,protocol_type
				       ,CASE WHEN expected_profits2 < expected_profits1 AND expected_profits2 is not null AND expected_profits2 <> '' THEN expected_profits2  ELSE expected_profits1 END AS valid_price
				       ,row_number() over(partition by trusteeship_housedel_code ORDER BY contract_sign_time desc)                                                  AS rn
				FROM olap.olap_trusteeship_hdel_housein_da
				WHERE pt = concat(regexp_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
				AND city_code = 310000
				AND contract_status_name = '已签约'
				AND sub_biz_type = 1
				AND protocol_type <> '豪宅'
				AND contract_code not IN ('TG0000492342') -- AND trusteeship_housedel_code IN ('107105749583', '107105727433') 
			) AS shou1
			LEFT JOIN
			(
				SELECT  *
				FROM
				(
					SELECT  biz_code -- 房源编号
					       ,employee_no_1
					       ,contract_sign_time
					       ,create_time
					       ,to_date(create_time)                                                                AS tuifang_date
					       ,row_number() over(partition by concat(biz_code,employee_no_1) ORDER BY create_time) AS rn
					FROM rpt.rpt_trusteeship_tuifang_data
					WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
					AND city_code = '310000'
					AND status = '已托管' 
				) AS adj
				WHERE adj.rn = 1 
			) AS tf
			ON shou1.del_code = tf.biz_code AND shou1.push_no = tf.employee_no_1
			LEFT JOIN
			(
				SELECT  trusteeship_housedel_code                                                                  AS del_code
				       ,contract_code
				       ,contract_status_name
				       ,sub_biz_type_name
				       ,agent_ucid
				       ,effect_start_date                                                                          AS chu_start_date
				       ,effect_end_date
				       ,revoke_type -- 1:到期解约 2:租客违约 3:惠居上海违约
				       ,back_date
				       ,CASE WHEN back_date is not null THEN back_date  ELSE effect_end_date END                   AS chu_end_date
				       ,housein_contract_code
				       ,housein_effect_start_date
				       ,housein_effect_end_date
				       ,to_date(contract_sign_time)                                                                AS chu_cdate
				       ,row_number() over(partition by trusteeship_housedel_code ORDER BY contract_sign_time desc) AS rn
				FROM olap.olap_trusteeship_hdel_houseout_da
				WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
				AND city_code = 310000
				AND contract_status_code = 2 
			) AS chu
			ON shou1.contract_code = chu.housein_contract_code
			GROUP BY  shou1.push_no
			         ,tf.tuifang_date
			         ,CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.contract_sign_date
			             WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN substr(chu.chu_cdate,1,10) END
		) AS shou
		ON emp.employee_no = shou.push_no AND emp.dt = shou.tuifang_date
		LEFT JOIN
		(
			SELECT  chu.agent_no
			       ,chu.chu_cdate
			       ,COUNT(distinct CASE WHEN substr(chu.chu_cdate,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(CURRENT_DATE,-1) AND chu.dt = date_add(CURRENT_DATE,-1) THEN chu.contract_code WHEN substr(chu.chu_cdate,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(CURRENT_DATE,-1) AND chu.dt < date_add(CURRENT_DATE,-1) AND deal.case_no is not null THEN chu.contract_code end) AS chu_cnt
			FROM
			(
				SELECT  trusteeship_housedel_code                                                                                                                   AS del_code
				       ,old_housedel_id
				       ,concat(trusteeship_housedel_code,'01')                                                                                                      AS housedel_dk
				       ,if(housedel_id = '-911','null',housedel_id)                                                                                                 AS housedel_code
				       ,house_id
				       ,contract_code
				       ,resblock_id
				       ,resblock_name
				       ,bizcircle_name
				       ,district_name
				       ,fitment_status
				       ,bedroom_num
				       ,physical_floor
				       ,overground_floor_cnt
				       ,CASE WHEN (physical_floor = 1 or physical_floor = overground_floor_cnt or (physical_floor >= 5 AND is_has_elevator = 0)) THEN 1  ELSE 0 END AS is_edge
				       ,is_has_elevator
				       ,is_vr
				       ,display_status_name
				       ,CASE WHEN rent_type = 0 THEN '不限'
				             WHEN rent_type = 1 THEN '整租'
				             WHEN rent_type = 2 THEN '合租' END                                                                                                       AS rent_type
				       ,CASE WHEN neg_housedel_source = 1 THEN '普租转录'
				             WHEN neg_housedel_source = 2 THEN '新增录入' END                                                                                           AS housedel_source
				       ,CASE WHEN sub_biz_type = 1 THEN '标准合同'
				             WHEN sub_biz_type = 2 THEN '续约合同' END                                                                                                  AS sub_biz_type_name
				       ,CASE WHEN rent_unit_status_name = '未知' THEN '装配中'  ELSE rent_unit_status_name END                                                           AS rent_unit_status_name
				       ,contract_status_name
				       ,contract_sign_time
				       ,to_date(contract_sign_time)                                                                                                                 AS contract_sign_date
				       ,CASE WHEN to_date(contract_sign_time) >= '2022-01-21' AND protocol_type = '普通' THEN '省心租'
				             WHEN to_date(contract_sign_time) >= '2022-07-20' AND protocol_type = '无忧' THEN '无忧'  ELSE '轻托管' END                                    AS service_type
				       ,effect_start_date
				       ,effect_end_date
				       ,sign_years
				       ,manager_ucid
				       ,manager_no
				       ,manager_name
				       ,manager_shop_name
				       ,push_employee_ucid
				       ,push_employee_name
				       ,push_employee_no                                                                                                                            AS push_no
				       ,sign_ucid
				       ,sign_no
				       ,sign_name
				       ,sign_marketing_name
				       ,sign_area_name
				       ,customer_code
				       ,revoke_back_date
				       ,is_follow
				       ,unit_guide_price
				       ,old_housedel_price
				       ,houseout_guide_price
				       ,expected_profits1
				       ,protocol_type
				       ,CASE WHEN expected_profits2 < expected_profits1 AND expected_profits2 is not null AND expected_profits2 <> '' THEN expected_profits2  ELSE expected_profits1 END AS valid_price
				       ,row_number() over(partition by trusteeship_housedel_code ORDER BY contract_sign_time desc)                                                  AS rn
				FROM olap.olap_trusteeship_hdel_housein_da
				WHERE pt = concat(regexp_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
				AND city_code = 310000
				AND contract_status_name = '已签约' -- AND sub_biz_type = 1
				AND protocol_type <> '豪宅' 
			) AS shou1
			JOIN
			(
				SELECT  *
				FROM
				(
					SELECT  trusteeship_housedel_code                                                AS del_code
					       ,contract_code
					       ,agent_no
					       ,customer_code
					       ,contract_status_name
					       ,sub_biz_type_name
					       ,agent_ucid
					       ,effect_start_date                                                        AS chu_start_date
					       ,effect_end_date
					       ,revoke_type -- 1:到期解约 2:租客违约 3:惠居上海违约
					       ,back_date
					       ,CASE WHEN back_date is not null THEN back_date  ELSE effect_end_date END AS chu_end_date
					       ,housein_contract_code
					       ,housein_effect_start_date
					       ,housein_effect_end_date
					       ,to_date(contract_sign_time)                                              AS chu_cdate
					       ,concat_ws('-',substr(pt,1,4),substr(pt,5,2) ,substr(pt,7,2))             AS dt
					       ,row_number() over(partition by contract_code ORDER BY pt desc)           AS rn
					FROM olap.olap_trusteeship_hdel_houseout_da
					WHERE pt BETWEEN concat(REGEXP_replace(trunc(date_add(CURRENT_DATE, -1), 'MM'), '-', ''), '000000') AND concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
					AND city_code = 310000
					AND to_date(contract_sign_time) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND date_add(CURRENT_DATE, -1)
					AND contract_status_code = 2
					AND sub_biz_type_name = '标准合同'
					AND contract_code not IN ('TGCF0000482666', 'TGCF0000493574') 
				) AS adj
				WHERE adj.rn = 1 
			) AS chu
			ON shou1.contract_code = chu.housein_contract_code
			LEFT JOIN
			(
				SELECT  CASE WHEN length(broker) <= 6 THEN 22000000 + broker  ELSE broker END AS broker
				       ,housedelcode
				       ,case_no
				       ,customer_no
				       ,COUNT(case_no) over(partition by concat(broker,housedelcode))         AS recept_cnt
				FROM olap.olap_sh_meacasedetail_ha
				WHERE pt = concat(REGEXP_replace(date_add(current_date(), -0), '-', ''), '000000')
				AND trading_type = '0101' -- 0101租赁
				AND signstatus = 3807
				AND corp_name = '上海链家'
				AND signedtypename = '轻托管出房 '
				AND receiptedcomplete = 1
				AND to_date(sign_date) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND date_add(CURRENT_DATE, -1) 
			) AS deal
			ON shou1.housedel_dk = deal.housedelcode AND chu.agent_no = deal.broker AND chu.customer_code = deal.customer_no
			GROUP BY  chu.agent_no
			         ,chu.chu_cdate
		) AS chu
		ON emp.employee_no = chu.agent_no AND emp.dt = chu.chu_cdate
		WHERE (shou.shou_cnt <> 0 or chu.chu_cnt <> 0) 
	)base
	GROUP BY  base.team_name
)shouchu
ON funnel1.team_name = shouchu.team_name
LEFT JOIN
(--分行本月推房量（推房人架构）
	SELECT  emp.team_name
	       ,COUNT(distinct t2.biz_code) AS tf_cnt --本月推房量
	FROM
	(
		SELECT  housedel_id -- 原普租房源编号
		       ,luru_riqi
		       ,biz_code -- 房源编号
		       ,employee_no_1
		       ,employee_name_1
		       ,region_name_1
		       ,marketing_name_1
		       ,area_name_1
		       ,contract_sign_time
		       ,create_time
		FROM rpt.rpt_trusteeship_tuifang_data
		WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
		AND city_code = '310000'
		AND to_date(create_time) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND date_add(CURRENT_DATE, -1) 
	)t2
	LEFT JOIN
	(
		SELECT  distinct corp_name
		       ,region_name
		       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END AS partname
		       ,team_name
		       ,employee_no
		       ,employee_name
		FROM rpt.rpt_comm_employee_info_da
		WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
		AND corp_name = '上海链家' --限制上海链家
		AND (region_name LIKE'%沪%' OR region_name LIKE'%豪宅%')
		AND on_job_status_code = '170007002' --在职
		AND job_category_name like '%经纪人%' --限制经纪人
		AND team_name NOT like '%租赁业务%'
		AND team_name NOT like '%新房业务%'
		AND region_name not like '%新房%'
		AND team_name <> '' 
	)emp
	ON t2.employee_no_1 = emp.employee_no
	GROUP BY  emp.team_name
)tf
ON funnel1.team_name = tf.team_name
LEFT JOIN
(--带看含省心租（带看人架构）
	SELECT  emp.team_name
	       ,COUNT(distinct show_detail.showing_code)                                                          AS show_cnt --带看量
	       ,COUNT(distinct CASE WHEN show_detail.house_num >= 3 THEN show_detail.showing_code end)            AS multishow_cnt --一带三看量
	       ,COUNT(distinct CASE WHEN show_detail.qingtuo_num >= 1 THEN show_detail.showing_code end)          AS qingtuo_cnt --含轻托管带看量
	       ,COUNT(distinct CASE WHEN show_detail.current_week_qingtuo >= 1 THEN show_detail.showing_code end) AS current_week_qingtuo_cnt
	FROM
	(
		SELECT  concat(showing_start_time,showing_agent_ucid,custdel_id)           AS showing_code
		       ,to_date(showing_start_time)                                        AS show_date
		       ,substr(showing_agent_ucid,9,8)                                     AS showing_agent_id
		       ,custdel_id
		       ,cust_ucid
		       ,COUNT(distinct housedel_id)                                        AS house_num
		       ,SUM(distinct CASE WHEN length(housedel_id) > 12 THEN 1 ELSE 0 END) AS qingtuo_num
		       ,SUM(distinct CASE WHEN (to_date(showing_start_time) BETWEEN date_add(next_day(date_add(current_date,-1),'MO'),-7) AND date_add(current_date,-1) AND length(housedel_id) > 12) THEN 1 ELSE 0 END) AS current_week_qingtuo
		FROM rpt.rpt_comm_show_showing_housedel_info_da
		WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
		AND city_code = 310000
		AND to_date(showing_start_time) <> to_date(invalid_time)
		AND to_date(showing_start_time) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND date_add(CURRENT_DATE, -1)
		AND is_valid = '1'
		AND del_type_sub_name IN ('求租', '商业求租')
		GROUP BY  concat(showing_start_time,showing_agent_ucid,custdel_id)
		         ,to_date(showing_start_time)
		         ,substr(showing_agent_ucid,9,8)
		         ,custdel_id
		         ,cust_ucid
	) AS show_detail
	LEFT JOIN
	(
		SELECT  distinct corp_name
		       ,region_name
		       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END AS partname
		       ,team_name
		       ,employee_no
		       ,employee_name
		FROM rpt.rpt_comm_employee_info_da
		WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
		AND corp_name = '上海链家' --限制上海链家
		AND (region_name LIKE'%沪%' OR region_name LIKE'%豪宅%')
		AND on_job_status_code = '170007002' --在职
		AND job_category_name like '%经纪人%' --限制经纪人
		AND team_name NOT like '%租赁业务%'
		AND team_name NOT like '%新房业务%'
		AND region_name not like '%新房%'
		AND team_name <> '' -- AND job_name like '租赁%' 
	)emp
	ON show_detail.showing_agent_id = emp.employee_no
	GROUP BY  emp.team_name
) AS showcnt
ON funnel1.team_name = showcnt.team_name