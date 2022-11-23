--模板查询：洽谈中房源明细
--模板查询：洽谈中房源明细
--模板查询：洽谈中房源明细
--模板查询：洽谈中房源明细
SELECT  follow.trusteeship_housedel_code                                                                AS `托管房源编码`
       -- ,hdel.resblock_id                                                                                AS `楼盘id`
       ,hdel.resblock_name                                                                              AS `楼盘名称`
       ,follow.old_housedel_typing_time                                                                 AS `普租录入时间`
       ,follow.del_create_time                                                                          AS `推房时间`
       ,follow.del_status                                                                               AS `房源状态：委托状态_1_洽谈中_2_已托管_14_无效_-1_已解约`
       -- ,follow.neg_opportunity_invalid_reason                                                           AS `房源无效原因_1_二手/普租已成交_2_洽谈已过期_3_业主无意向_4_手动无效-1_已解约`
       ,follow.push_employee_name                                                                       AS `推房经纪人姓名`
       ,follow.push_employee_no                                                                         AS `推房经纪人系统号`
       ,follow.manager_name                                                                             AS `管家姓名`
       ,follow.manager_ucid                                                                             AS `管家ucid`
       ,follow.manager_no                                                                               AS `管家系统号`
       ,follow.manager_shop_name                                                                        AS `门店`
       ,follow.manager_area_name                                                                        AS `业务区域/组`
       ,follow.manager_marketing_name                                                                   AS `营销大区/部门`
       ,follow.manager_region_name                                                                      AS `运营管理大区/中心`
       ,follow.score                                                                                    AS `推房时房源评分`
       ,follow.is_call                                                                                  AS `400电话联系是否接通`
       ,follow.first_call_time                                                                          AS `400电话首次接通时间点`
       ,follow.is_24h_call                                                                              AS `是否24小时内联系`
       ,follow.is_30s_call                                                                              AS `400电话是否有30S以上联系时长`
       ,follow.is_complete_opportunity_level                                                            AS `是否完成意向分级`
       ,follow.neg_at_skz_time                                                                          AS `完成意向分级时间点`
       ,follow.neg_opportunity_level                                                                    AS `意向分级分类`
       ,follow.neg_opportunity_level_name                                                               AS `意向分级分类`
       ,follow.is_complete_prospecting                                                                  AS `是否完成实地评估`
       ,follow.neg_at_wxz_time                                                                          AS `完成实地评估时间点`
       ,follow.estimate_time                                                                            AS `收房测算提交时间`
       ,follow.is_estimate                                                                              AS `是否完成收房测算`
       ,follow.is_estimate_approved                                                                     AS `收房测算是否审核通过`
       ,follow.pt                                                                                       AS `分区字段`
       ,follow.city_code                                                                                AS `城市编码`
       ,follow.city_name                                                                                AS `城市名称`
       ,follow.call_cnt                                                                                 AS `电话联系次数`
       ,follow.follow_cnt                                                                               AS `跟进次数`
       ,(unix_timestamp(follow.del_create_time) - unix_timestamp(follow.old_housedel_typing_time))/3600 AS tf_hours
       ,'惠居上海'                                                                                          AS manager_corp_name
       ,follow.manager_region_name_1                                                                      AS `管家事业部`
       ,follow.manager_partname                                                                         AS `管家大区`
       ,case WHEN follow.manager_region_name_1 IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
	             WHEN follow.manager_region_name_1 IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS `管家大部`
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
           ,pt
	       ,(unix_timestamp(del_create_time) - unix_timestamp(old_housedel_typing_time))/3600                                 AS tf_hours
	       ,'惠居上海'                                                                                                            AS manager_corp_name
	       ,CASE WHEN agent.position_name in ('资管经理','租赁商圈经理') THEN (case when agent.shop_name = '豪宅事业部' then '链家豪宅事业部' else agent.shop_name end) else agent.region_name end as manager_region_name_1
	       ,CASE WHEN manager_region_name like '%豪宅%' THEN manager_area_name
				             WHEN agent.position_name in ('资管经理','租赁商圈经理') THEN (CASE
				             WHEN agent.shop_name = '链家豪宅事业部' THEN regexp_replace(agent.team_name,'大区','区')  ELSE agent.team_name END)  ELSE manager_marketing_name END AS manager_partname
		   ,CASE WHEN agent.position_name = '租赁商圈经理' THEN '租赁经理'
				             WHEN agent.position_name = '资管经理' THEN '资管经理'  ELSE '运营官' END                AS manager_type
	       ,CASE WHEN agent.position_name in ('资管经理','租赁商圈经理') THEN regexp_replace(manager_area_name,'轻托管','租赁')
	             WHEN manager_region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
	             WHEN manager_region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS manager_dabu
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
               ,pt
		       ,(unix_timestamp(del_create_time) - unix_timestamp(old_housedel_typing_time))/3600 AS tf_hours
		FROM olap.olap_trusteeship_hdel_follow_process_da
		WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
		AND city_code = '310000' -- AND to_date(del_create_time) BETWEEN date_add(CURRENT_DATE, -7) AND date_add(CURRENT_DATE, -1)
		AND del_status = 1 
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
)follow
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
	       ,contract_sign_time
	       ,create_time
	FROM rpt.rpt_trusteeship_tuifang_data
	WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
	AND city_code = '310000'
	AND to_date(create_time) BETWEEN date_add(CURRENT_DATE, -7) AND date_add(CURRENT_DATE, -1) 
)tuifang
ON follow.trusteeship_housedel_code = tuifang.biz_code
LEFT JOIN
(
	SELECT  housedel_id
	       ,resblock_id
	       ,resblock_name
	       ,to_date(typer_time)                                                                            AS type_date
	       ,typer_time
	       ,typer_agent_no
	       ,typer_agent_name
	       ,typer_region_name
	       ,typer_marketing_name
	       ,typer_area_name
	       ,CASE WHEN typer_region_name like '%豪宅%' THEN typer_area_name  ELSE typer_marketing_name END    AS typer_partname
	       ,typer_team_name
	       ,holder_agent_no
	       ,holder_agent_name
	       ,holder_region_name
	       ,holder_marketing_name
	       ,holder_area_name
	       ,CASE WHEN holder_region_name like '%豪宅%' THEN holder_area_name  ELSE holder_marketing_name END AS holder_partname
	       ,holder_team_name
	FROM rpt.rpt_coo_hdel_hdel_entrust_detail_da
	WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
	AND del_type_code = '990001002' -- 990001002 租赁
	AND city_name = '上海市' 
)hdel
ON tuifang.housedel_id = hdel.housedel_id