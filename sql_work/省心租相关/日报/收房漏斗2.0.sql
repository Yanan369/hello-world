--模板查询：收房漏斗2.0
SELECT  CASE WHEN t.dabu is null THEN '惠居上海'  ELSE t.dabu END                                                                           AS dabu
       ,CASE WHEN (t.region_name is null) AND (t.dabu is null) THEN '惠居上海'
             WHEN (t.region_name is null) AND (t.dabu is not null) THEN t.dabu  ELSE t.region_name END                                  AS region_name
       ,CASE WHEN (t.partname is null) AND (t.region_name is null) AND (t.dabu is null) THEN '惠居上海'
             WHEN (t.partname is null) AND (t.region_name is null) AND (t.dabu is not null) THEN t.dabu
             WHEN (t.partname is null) AND (t.region_name is not null) AND (t.dabu is not null) THEN t.region_name  ELSE t.partname END AS partname
       ,SUM(t.tf_cnt)                                                                                                                   AS `7日推房量`
       ,SUM(t.tg_cnt)                                                                                                                   AS `已托管`
       ,nvl(SUM(t.tg_cnt)/SUM(t.tf_cnt),0)                                                                                              AS `7日托管率`
       ,SUM(t.invalid_cnt)                                                                                                              AS `已无效`
       ,nvl(SUM(t.invalid_cnt)/SUM(t.tf_cnt),0)                                                                                         AS `推房无效率`
       ,nvl(SUM(t.invalid_2)/SUM(t.tf_cnt),0)                                                                                           AS `推房过期率`
       ,SUM(t.process_cnt)                                                                                                              AS `洽谈中`
       ,nvl(SUM(t.prospecting_cnt)/SUM(t.process_cnt),0)                                                                                AS `洽谈中实地评估率`
       ,nvl(SUM(t.pro_tg_cnt)/SUM(t.prospecting_cnt),0)                                                                                 AS `有实地评估收房率` --有实地评估收房率
       ,SUM(t.all_process)                                                                                                              AS `全部洽谈中房源`
       ,SUM(t.all_400)                                                                                                                  AS `400接通`
       ,SUM(t.all_op)                                                                                                                   AS `完成意向分级`
       ,SUM(t.all_pro)                                                                                                                  AS `完成实地评估`
       ,nvl(SUM(t.all_pro)/SUM(t.all_process),0)                                                                                        AS `完成实地评估率`
       ,SUM(t.all_es)                                                                                                                   AS `完成收房测算`
       ,SUM(t.nh_cnt)                                                                                                                   AS `7日新增房`
       ,nvl(SUM(t.nh_tf_cnt)/SUM(t.nh_cnt),0)                                                                                           AS `新增房转推率`
       ,nvl(SUM(t.tf_in24h)/SUM(t.nh_cnt),0)                                                                                            AS `新增房24小时转推率`
       ,nvl(SUM(t.nhtf_pro_cnt)/SUM(t.nh_tf_cnt),0)                                                                                     AS `新增房推荐转实地评估率`
       ,nvl(SUM(t.nh_tg_cnt)/SUM(t.nh_tf_cnt),0)                                                                                        AS `新增房推荐转收率`
       ,nvl(SUM(t.nhtf_pro_tg)/SUM(t.nhtf_pro_cnt),0)                                                                                   AS `新增房实地评估转收率`
FROM
(
	SELECT  emp.corp_name
	       ,emp.dabu
	       ,emp.region_name
	       ,emp.partname
	       ,nvl(funnel.tf_cnt,0)          AS tf_cnt
	       ,nvl(funnel.tg_cnt,0)          AS tg_cnt
	       ,nvl(funnel.invalid_cnt,0)     AS invalid_cnt
	       ,nvl(funnel.invalid_2,0)       AS invalid_2
	       ,nvl(funnel.process_cnt,0)     AS process_cnt
	       ,nvl(funnel.prospecting_cnt,0) AS prospecting_cnt
	       ,nvl(funnel.pro_tg_cnt,0)      AS pro_tg_cnt
	       ,nvl(funnel.all_process,0)     AS all_process
	       ,nvl(funnel.all_400,0)         AS all_400
	       ,nvl(funnel.all_op,0)          AS all_op
	       ,nvl(funnel.all_pro,0)         AS all_pro
	       ,nvl(funnel.all_es,0)          AS all_es
	       ,nvl(funnel.nh_cnt,0)          AS nh_cnt
	       ,nvl(funnel.nh_tf_cnt,0)       AS nh_tf_cnt
	       ,nvl(funnel.tf_in24h,0)        AS tf_in24h
	       ,nvl(funnel.nhtf_pro_cnt,0)    AS nhtf_pro_cnt
	       ,nvl(funnel.nh_tg_cnt,0)       AS nh_tg_cnt
	       ,nvl(funnel.nhtf_pro_tg,0)     AS nhtf_pro_tg
	FROM
	(
		SELECT  distinct team_name                                                                                             AS partname
			       ,team_code
			       ,employee_name
			       ,employee_no
			       ,employee_ucid
			       ,position_name                                                                                         AS job_name
			       ,shop_name                                                                                             AS region_name
			       ,CASE WHEN shop_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
			             WHEN shop_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
			FROM rpt.rpt_comm_employee_info_da
			WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
			AND on_job_status = '在职在岗'
			AND position_name IN ('资管区域经理', '资管经理')
			AND city_code = 310000
	)emp
	LEFT JOIN
	(
		SELECT  tb3.partname
		       ,tb1.tf_cnt
		       ,tb1.tg_cnt
		       ,tb1.invalid_cnt -- 推房无效 -- , tb1.invalid_1
		       ,tb1.invalid_2 -- 推房过期 -- , tb1.invalid_3 -- , tb1.invalid_4
		       ,tb1.process_cnt -- 洽谈中
		       ,tb1.prospecting_cnt -- 实地评估
		       ,tb1.pro_tg_cnt -- 有实地评估收房 --所有洽谈中房源状态
		       ,tb2.process_cnt           AS all_process --所有洽谈中房源
		       ,tb2.400_cnt               AS all_400
		       ,tb2.opportunity_level_cnt AS all_op
		       ,tb2.prospecting_cnt       AS all_pro
		       ,tb2.estimate_cnt          AS all_es --新增房转推
		       ,tb3.nh_cnt -- 新增房
		       ,tb3.nh_tf_cnt --新增房转推
		       ,tb3.tf_in24h
		       ,tb3.nhtf_pro_cnt
		       ,tb3.nh_tg_cnt
		       ,tb3.nhtf_pro_tg --有实地评估托管
		FROM
		(
			SELECT  a.manager_partname                                                                                                                  AS partname
			       ,COUNT(distinct a.trusteeship_housedel_code)                                                                                         AS tf_cnt
			       ,COUNT(distinct CASE WHEN a.tf_hours <= 24 THEN a.trusteeship_housedel_code else null end)                                           AS tf_in24h
			       ,COUNT(distinct CASE WHEN a.del_status = 2 THEN a.trusteeship_housedel_code else null end)                                           AS tg_cnt
			       ,COUNT(distinct CASE WHEN a.del_status = 14 THEN a.trusteeship_housedel_code else null end)                                          AS invalid_cnt
			       ,COUNT(distinct CASE WHEN a.del_status = 14 AND a.neg_opportunity_invalid_reason = 1 THEN a.trusteeship_housedel_code else null end) AS invalid_1
			       ,COUNT(distinct CASE WHEN a.del_status = 14 AND a.neg_opportunity_invalid_reason = 2 THEN a.trusteeship_housedel_code else null end) AS invalid_2
			       ,COUNT(distinct CASE WHEN a.del_status = 14 AND a.neg_opportunity_invalid_reason = 3 THEN a.trusteeship_housedel_code else null end) AS invalid_3
			       ,COUNT(distinct CASE WHEN a.del_status = 14 AND a.neg_opportunity_invalid_reason = 4 THEN a.trusteeship_housedel_code else null end) AS invalid_4
			       ,COUNT(distinct CASE WHEN a.del_status = -1 THEN a.trusteeship_housedel_code else null end)                                          AS cancel_cnt
			       ,COUNT(distinct CASE WHEN a.del_status = 1 THEN a.trusteeship_housedel_code else null end)                                           AS process_cnt
			       ,COUNT(distinct CASE WHEN a.del_status = 1 AND a.follow_cnt >= 1 THEN a.trusteeship_housedel_code else null end)                     AS follow_cnt
			       ,COUNT(distinct CASE WHEN a.del_status = 1 AND a.is_call = 1 THEN a.trusteeship_housedel_code else null end)                         AS 400_cnt
			       ,COUNT(distinct CASE WHEN a.del_status = 1 AND is_complete_opportunity_level = 1 THEN a.trusteeship_housedel_code else null end)     AS opportunity_level_cnt
			       ,COUNT(distinct CASE WHEN a.del_status = 1 AND is_complete_prospecting = 1 THEN a.trusteeship_housedel_code else null end)           AS prospecting_cnt
			       ,COUNT(distinct CASE WHEN a.del_status = 2 AND is_complete_prospecting = 1 THEN a.trusteeship_housedel_code else null end)           AS pro_tg_cnt
			       ,COUNT(distinct CASE WHEN a.del_status = 1 AND is_estimate = 1 THEN a.trusteeship_housedel_code else null end)                       AS estimate_cnt
			FROM
			(
				SELECT  *
				       ,(unix_timestamp(del_create_time) - unix_timestamp(old_housedel_typing_time))/3600 AS tf_hours -- just大区
				       ,CASE WHEN manager_region_name like '%豪宅%' THEN manager_area_name
				             WHEN agent.position_name in ('资管经理','资管区域经理') THEN (CASE
				             WHEN agent.shop_name = '豪宅事业部' THEN regexp_replace(agent.team_name,'大区','区')  ELSE agent.team_name END)  ELSE manager_marketing_name END AS manager_partname
				       ,CASE WHEN agent.position_name = '租赁商圈经理' THEN '租赁经理'
				             WHEN agent.position_name = '资管经理' THEN '资管经理'  ELSE '运营官' END                AS manager_type
				FROM
				(
					SELECT  *
					FROM olap.olap_trusteeship_hdel_follow_process_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND city_code = '310000'
					AND to_date(del_create_time) BETWEEN date_add(CURRENT_DATE, -7) AND date_add(CURRENT_DATE, -1) 
				)t1
				LEFT JOIN
				(
					SELECT  distinct corp_name
					       ,CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
					             WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
					       ,region_name
					       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                 AS partname
					       ,shop_name
					       ,team_name
					       ,employee_no
					       ,employee_name
					       ,position_name
					FROM rpt.rpt_comm_employee_info_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000') 
					AND position_name IN ('资管区域经理', '资管经理')
					AND city_code = 310000
				)agent
				ON t1.manager_no = agent.employee_no
			)a
			GROUP BY  a.manager_partname
		)tb1
		LEFT JOIN
		(
			SELECT  b.manager_partname                                                                                                                AS partname
			       ,COUNT(distinct b.trusteeship_housedel_code)                                                                                       AS process_cnt
			       ,COUNT(distinct CASE WHEN b.del_status = 1 AND b.follow_cnt >= 1 THEN b.trusteeship_housedel_code else null end)                   AS follow_cnt
			       ,COUNT(distinct CASE WHEN b.del_status = 1 AND b.is_call = 1 THEN b.trusteeship_housedel_code else null end)                       AS 400_cnt
			       ,COUNT(distinct CASE WHEN b.del_status = 1 AND b.is_complete_opportunity_level = 1 THEN b.trusteeship_housedel_code else null end) AS opportunity_level_cnt
			       ,COUNT(distinct CASE WHEN b.del_status = 1 AND b.is_complete_prospecting = 1 THEN b.trusteeship_housedel_code else null end)       AS prospecting_cnt
			       ,COUNT(distinct CASE WHEN b.del_status = 2 AND b.is_complete_prospecting = 1 THEN b.trusteeship_housedel_code else null end)       AS pro_tg_cnt
			       ,COUNT(distinct CASE WHEN b.del_status = 1 AND b.is_estimate = 1 THEN b.trusteeship_housedel_code else null end)                   AS estimate_cnt
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
				       ,'惠居上海'                                                                            AS manager_corp_name -- just大区
				       ,CASE WHEN manager_region_name like '%豪宅%' THEN manager_area_name
				             WHEN agent.position_name in ('资管经理','租赁商圈经理') THEN (CASE
				             WHEN agent.shop_name = '链家豪宅事业部' THEN regexp_replace(agent.team_name,'大区','区')  ELSE agent.team_name END)  ELSE manager_marketing_name END AS manager_partname
				       ,CASE WHEN agent.position_name = '租赁商圈经理' THEN '租赁经理'
				             WHEN agent.position_name = '资管经理' THEN '资管经理'  ELSE '运营官' END                AS manager_type
				FROM
				(
					SELECT  *
					FROM olap.olap_trusteeship_hdel_follow_process_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND city_code = '310000'
					AND del_status = 1 
				)t2
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
				ON t2.manager_no = agent.employee_no
			)b
			GROUP BY  b.manager_partname
		)tb2
		ON tb1.partname = tb2.partname
		RIGHT JOIN
		(-- 新增房转推
			SELECT  t3.partname
			       ,COUNT(distinct t3.housedel_id)                                                                                                 AS nh_cnt
			       ,COUNT(distinct t3.biz_code)                                                                                                    AS nh_tf_cnt
			       ,COUNT(distinct CASE WHEN t3.tf_hours <= 24 THEN t3.trusteeship_housedel_code else null end)                                    AS tf_in24h
			       ,COUNT(distinct CASE WHEN t3.is_complete_prospecting = 1 THEN t3.trusteeship_housedel_code else null end)                       AS nhtf_pro_cnt
			       ,COUNT(distinct CASE WHEN t3.del_status = 2 THEN t3.trusteeship_housedel_code else null end)                                    AS nh_tg_cnt
			       ,COUNT(distinct CASE WHEN t3.del_status = 2 AND t3.is_complete_prospecting = 1 THEN t3.trusteeship_housedel_code else null end) AS nhtf_pro_tg
			FROM
			(
				SELECT  nh.holder_partname AS partname
				       ,nh.housedel_id
				       ,nh.resblock_id
				       ,tuifang.biz_code
				       ,follow.trusteeship_housedel_code
				       ,follow.tf_hours
				       ,follow.del_status
				       ,follow.is_complete_prospecting
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
					AND to_date(typer_time) BETWEEN date_add(CURRENT_DATE, -7) AND date_add(CURRENT_DATE, -1)
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
				)tuifang
				ON nh.housedel_id = tuifang.housedel_id
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
					       ,(unix_timestamp(del_create_time) - unix_timestamp(old_housedel_typing_time))/3600 AS tf_hours
					FROM olap.olap_trusteeship_hdel_follow_process_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND city_code = '310000' 
				)follow
				ON tuifang.biz_code = follow.trusteeship_housedel_code
			)t3
			GROUP BY  t3.partname
		)tb3
		ON tb1.partname = tb3.partname
	)funnel
	ON emp.partname = funnel.partname
)t
GROUP BY  t.corp_name
         ,t.dabu
         ,t.region_name
         ,t.partname
GROUPING SETS ((t.corp_name, t.dabu, t.region_name, t.partname), (t.corp_name, t.dabu, t.region_name), (t.corp_name, t.dabu), (t.corp_name))