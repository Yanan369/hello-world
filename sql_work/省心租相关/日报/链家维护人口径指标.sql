--模板查询：链家维护人口径指标
--模板查询：链家维护人口径
SELECT  concat(funnel1.region_name,row_number() over(partition by funnel1.region_name ORDER BY funnel1.partname))
       ,funnel1.dabu
       ,funnel1.region_name
       ,funnel1.partname
       ,funnel1.partname                     AS team_name
       ,funnel1.nh_cnt
       ,funnel1.nh_to_tf
       ,funnel1.tf_in24h
       ,funnel1.tf_400_cnt
       ,funnel1.tf_op_cnt
       ,funnel1.tf_high_op
       ,funnel1.tf_prospecting_cnt
-- , funnel1.pro_tg_cnt
       -- ,nvl(7dsk.7d_prospecting_cnt,0)       AS 7d_prospecting_cnt
       -- ,nvl(7dsk.7d_prospecting_tg_cnt,0)    AS 7d_prospecting_tg_cnt
       ,nvl(7dsk.month_prospecting_cnt,0)    AS month_prospecting_cnt
       ,nvl(7dsk.month_prospecting_tg_cnt,0) AS month_prospecting_tg_cnt
       ,funnel1.nh_to_tg
	   ,7dsk.yesterday_prospecting_cnt       AS yesterday_prospecting_cnt
FROM
(
	SELECT  f1.dabu
	       ,f1.region_name
	       ,f1.partname
	       ,COUNT(distinct f1.housedel_id)                                                                                AS nh_cnt --新增房
	       ,COUNT(distinct f1.biz_code)                                                                                   AS nh_to_tf --新增房转推
	       ,COUNT(distinct CASE WHEN f1.tf_hours <= 24 THEN f1.biz_code else null end)                                    AS tf_in24h -- 24h内推房
	       ,COUNT(distinct CASE WHEN f1.is_call = 1 THEN f1.biz_code else null end)                                       AS tf_400_cnt
	       ,COUNT(distinct CASE WHEN f1.is_complete_opportunity_level = 1 THEN f1.biz_code else null end)                 AS tf_op_cnt
	       ,COUNT(distinct CASE WHEN f1.neg_opportunity_level_name = '高意向' THEN f1.biz_code else null end)                AS tf_high_op
	       ,COUNT(distinct CASE WHEN f1.is_complete_prospecting = 1 THEN f1.biz_code else null end)                       AS tf_prospecting_cnt
	       ,COUNT(distinct CASE WHEN f1.is_complete_prospecting = 1 AND f1.del_status = 2 THEN f1.biz_code else null end) AS pro_tg_cnt
	       ,COUNT(distinct CASE WHEN f1.del_status = 2 THEN f1.biz_code else null end)                                    AS nh_to_tg
	FROM
	(
		SELECT  emp.dabu
		       ,emp.region_name
		       ,emp.partname
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
				AND stat_function_code not IN ('110006005', '110006014', '110006007', '110006001','110006015') 
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
		ON emp.partname = ff1.holder_partname
	)f1
	GROUP BY  f1.dabu
	         ,f1.region_name
	         ,f1.partname
)funnel1
LEFT JOIN
(
	SELECT  f2.partname
	       ,f2.7d_prospecting_cnt
	       ,f2.7d_prospecting_tg_cnt
	       ,f2.month_prospecting_cnt
	       ,f2.month_prospecting_tg_cnt
  		   ,f2.yesterday_prospecting_cnt
	FROM
	(
		SELECT  b.manager_partname                                                                                                          AS partname
		       ,COUNT(distinct CASE WHEN to_date(b.neg_at_wxz_time) BETWEEN date_add(CURRENT_DATE,-7) AND date_add(CURRENT_DATE,-1) AND b.is_complete_prospecting = 1 THEN b.trusteeship_housedel_code else null end) AS 7d_prospecting_cnt
		       ,COUNT(distinct CASE WHEN to_date(b.neg_at_wxz_time) BETWEEN date_add(CURRENT_DATE,-7) AND date_add(CURRENT_DATE,-1) AND b.is_complete_prospecting = 1 AND b.del_status = 2 THEN b.trusteeship_housedel_code else null end) AS 7d_prospecting_tg_cnt
		       ,COUNT(distinct CASE WHEN b.is_complete_prospecting = 1 THEN b.trusteeship_housedel_code else null end)                      AS month_prospecting_cnt
		       ,COUNT(distinct CASE WHEN b.is_complete_prospecting = 1 AND b.del_status = 2 THEN b.trusteeship_housedel_code else null end) AS month_prospecting_tg_cnt
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
			       ,(unix_timestamp(del_create_time) - unix_timestamp(old_housedel_typing_time))/3600                                                       AS tf_hours
			       ,'惠居上海'                                                                                                                                  AS manager_corp_name
			       ,CASE WHEN agent.position_name IN ('租赁商圈经理','资管经理') THEN (CASE
			             WHEN agent.shop_name like '%豪宅%' THEN '链家豪宅事业部'  ELSE agent.shop_name END)  ELSE agent.region_name END                             AS manager_region_name
			       ,CASE WHEN agent.position_name IN ('租赁商圈经理','资管经理') THEN (CASE
			             WHEN agent.shop_name like '%豪宅%' THEN regexp_replace(agent.team_name,'大区','区')  ELSE agent.team_name END)  ELSE agent.partname END AS manager_partname
			       ,CASE WHEN agent.position_name = '租赁商圈经理' THEN '租赁商圈经理'
			             WHEN agent.position_name = '资管经理' THEN '资管经理'  ELSE '运营官' END                                                                      AS manager_type
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
				AND to_date(neg_at_wxz_time) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND date_add(CURRENT_DATE, -1) 
			)process
			LEFT JOIN
			(
				SELECT  distinct corp_name
				       ,CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
				             WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
				       ,region_name
				       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                 AS partname
				       ,shop_name
				       ,team_name
				       ,employee_no
				       ,employee_name
				       ,position_name
				FROM rpt.rpt_comm_employee_info_da
				WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000') 
			)agent
			ON process.manager_no = agent.employee_no
		)b
		GROUP BY  b.manager_partname
	)f2
)7dsk
ON funnel1.partname = 7dsk.partname