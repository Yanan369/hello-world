SELECT  CASE WHEN org.team_name is null THEN empnow.team_name  ELSE emp.team_name END AS team_name
       ,empnow.dabu                                                                   AS dabu_now
       ,empnow.region_name                                                            AS region_name_now
       ,empnow.partname                                                               AS partname_now
       ,empnow.team_name                                                              AS team_name_now
       ,emp.employee_no
       ,emp.employee_name
       ,emp.job_name
       ,empnow.job_name                                                               AS job_name_now
       ,chu.*
FROM
(
	SELECT  chu.*
	       ,CASE WHEN substr(chu.chu_cdate,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(CURRENT_DATE,-1) AND chu.dt = date_add(CURRENT_DATE,-1) THEN 1
	             WHEN substr(chu.chu_cdate,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(CURRENT_DATE,-1) AND chu.dt < date_add(CURRENT_DATE,-1) AND deal.case_no is not null THEN 1  ELSE 0 END AS is_effective_cf
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
) AS chu
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
	WHERE pt BETWEEN concat(REGEXP_replace(date_add(CURRENT_DATE, -90), '-', ''), '000000') AND concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
	AND corp_name = '上海链家'
	AND region_name RLIKE '^沪|链家'
	AND on_job_status_code = '170007002'
	AND job_category_name like '%经纪人%' -- AND job_name IN ( '租赁经纪人', '租赁店经理', '综合经纪人', '综合店经理')
	AND data_source <> 'uc' -- 剔除兼岗 
) AS emp
ON emp.employee_no = chu.agent_no AND emp.dt = chu.chu_cdate
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