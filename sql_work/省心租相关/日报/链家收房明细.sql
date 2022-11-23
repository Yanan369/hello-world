SELECT  CASE WHEN org.team_name is null THEN empnow.team_name  ELSE emp.team_name END AS team_name
       ,empnow.dabu                                                                   AS dabu_now
       ,empnow.region_name                                                            AS region_name_now
       ,empnow.partname                                                               AS partname_now
       ,empnow.team_name                                                              AS team_name_now
       ,emp.employee_no
       ,emp.employee_name
       ,emp.job_name
       ,empnow.job_name                                                               AS job_name_now
       ,shou.*
FROM
(
	SELECT  distinct shou1.push_no
	       ,shou1.push_employee_name
	       ,tf.tuifang_date
	       ,shou1.del_code          AS shou_del_code
	       ,shou1.contract_code     AS shou_contract_code
	       ,shou1.resblock_name
	       ,shou1.sub_biz_type_name AS shou_biz_type -- 收房合同类型
	       ,shou1.service_type
	       ,shou1.effect_start_date AS shou_start_date
	       ,shou1.effect_end_date   AS shou_end_date
	       ,shou1.manager_no
	       ,shou1.manager_name
	       ,shou1.protocol_type
	       ,chu.del_code            AS chu_del_code
	       ,chu.contract_code       AS chu_contract_code
	       ,chu.sub_biz_type_name   AS chu_biz_type -- 出房合同类型
	       ,chu.chu_cdate
	       ,chu.chu_start_date
	       ,CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.contract_sign_date
	             WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN substr(chu.chu_cdate,1,10) END AS shou_date
	       ,CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN 1
	             WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN 1  ELSE 0 END AS is_effective_sf
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
		SELECT  biz_code
		       ,employee_no_1
		       ,tuifang_date
		FROM
		(
			SELECT  biz_code -- 房源编号
			       ,employee_no_1
			       ,contract_sign_time
			       ,create_time
			       ,to_date(create_time)                                                                AS tuifang_date
			       ,row_number() over(partition by concat(biz_code,employee_no_1) ORDER BY create_time) AS rn
			FROM rpt.rpt_trusteeship_tuifang_data
			WHERE pt = concat(regexp_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
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
) AS shou
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
ON emp.employee_no = shou.push_no AND emp.dt = shou.tuifang_date
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