SELECT  DISTINCT holder.dabu        AS `大部`
       ,holder.region_name          AS `事业部`
       ,holder.partname             AS `大区`
       ,holder.employee_name        AS `管家姓名`
       ,holder.employee_no          AS `管家工号`
       ,holder.employee_ucid        AS `管家ucid`
       ,holder.job_name             AS `管家职位`
       ,shou1.manager_no            AS `管家工号`
       ,shou1.del_code              AS `托管房源编号`
       ,shou1.old_housedel_id       AS `原普租房源编号`
       ,shou1.house_id              AS `房屋编号`
       ,shou1.contract_code         AS `收房合同号`
       ,shou1.resblock_id           AS `楼盘id`
       ,shou1.resblock_name         AS `楼盘名称`
       ,shou1.bizcircle_name        AS `商圈名称`
       ,shou1.district_name         AS `行政区`
       ,shou1.fitment_status        AS `装修情况`
       ,shou1.is_vr                 AS `是否vr`
       ,shou1.display_status_name   AS `外展状态`
       ,shou1.rent_type             AS `租赁方式`
       ,shou1.housedel_source       AS `房源来源`
       ,shou1.sub_biz_type_name     AS `合同类型`
       ,shou1.rent_unit_status_name AS `租赁状态`
       ,shou1.contract_status_name  AS `合同状态`
       ,shou1.contract_sign_time    AS `合同签约时间`
       ,shou1.contract_sign_date    AS `合同签约日期`
       ,shou1.service_type          AS `产品类型`
       ,shou1.effect_start_date     AS `收房起租日`
       ,shou1.effect_end_date       AS `收房结束日`
       ,shou1.sign_years            AS `签约年限`
       ,shou1.manager_ucid          AS `管家ucid`
       ,shou1.manager_no            AS `管家工号`
       ,shou1.manager_name          AS `管家姓名`
       ,shou1.manager_shop_name     AS `管家事业部`
       ,shou1.push_employee_no      AS `推房人工号`
       ,shou1.push_employee_ucid    AS `推房人ucid`
       ,shou1.push_employee_name    AS `推房人姓名`
       ,shou1.sign_ucid             AS `收房合同创建人ucid`
       ,shou1.sign_no               AS `收房合同创建人工号`
       ,shou1.sign_name             AS `收房合同创建人姓名`
       ,shou1.sign_marketing_name   AS `收房合同创建人营销大区`
       ,shou1.sign_area_name        AS `收房合同创建人业务区域`
       ,shou1.customer_code         AS `客源编码`
       ,shou1.revoke_back_date      AS `房屋返还日期`
       ,shou1.is_follow             AS `是否跟进`
       ,shou1.unit_guide_price      AS `挂牌价`
       ,shou1.old_housedel_price    AS `原普租房源价格`
       ,shou1.houseout_guide_price  AS `委托里出房指导价`
       ,shou1.expected_profits1     AS `第一年收房价格`
       ,shou1.protocol_type         AS `产品名称`
-- , shou1.valid_price
       ,chu.del_code                AS `托管房源编号`
       ,chu.contract_code           AS `出房合同号`
       ,chu.contract_status_name    AS `出房合同状态`
       ,chu.sub_biz_type_name       AS `出房合同类型`
       ,chu.agent_ucid              AS `出房人ucid`
       ,chu.chu_start_date          AS `出房起租日`
       ,chu.effect_end_date         AS `出房结束日`
       ,chu.revoke_type             AS `违约类型`
       ,chu.back_date               AS `房屋交还日期`
       ,chu.chu_end_date            AS `出房实际结束日`
       ,chu.chu_cdate               AS `出房合同签约日期`
       ,CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) >= trunc(date_add(CURRENT_DATE,-1),'MM') AND substr(shou1.effect_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN 1
             WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) >= trunc(date_add(CURRENT_DATE,-1),'MM') AND substr(chu.chu_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN 1  ELSE 0 END AS `是否本月收房`
       ,CASE WHEN (DATEDIFF(chu.chu_end_date,chu.chu_start_date) >= 180 or (DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) <= 0 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_start_date) >= 0 )) AND substr(chu.chu_cdate,1,10) >= trunc(date_add(CURRENT_DATE,-1),'MM') AND substr(chu.chu_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN 1
             WHEN DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) > 0 AND substr(chu.chu_cdate,1,10) >= trunc(date_add(CURRENT_DATE,-1),'MM') AND substr(chu.chu_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN 0.5  ELSE 0 END AS `是否本月出房`
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
	       ,push_employee_no
	       ,push_employee_ucid
	       ,push_employee_name
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
	AND protocol_type <> '豪宅' 
) AS shou1
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
LEFT JOIN
(
	SELECT  a.dabu
	       ,a.region_name
	       ,a.team_name AS partname
	       ,a.employee_name
	       ,a.employee_no
	       ,a.employee_ucid
	       ,a.job_name
	FROM
	(
		SELECT  team_name
		       ,team_code
		       ,CASE WHEN shop_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
		             WHEN shop_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
		       ,CASE WHEN shop_name = '豪宅事业部' THEN '链家豪宅事业部'  ELSE shop_name END                                      AS region_name
		       ,employee_name
		       ,employee_no
		       ,employee_ucid
		       ,position_name                                                                                         AS job_name
		FROM rpt.rpt_comm_employee_info_da
		WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
		AND on_job_status = '在职在岗'
		AND position_name IN ('资管区域经理', '资管经理')
		AND city_code = 310000 
	) AS a
	UNION ALL
	SELECT  CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
	             WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
	       ,region_name
	       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                 AS partname
	       ,employee_name
	       ,employee_no
	       ,employee_ucid
	       ,job_name
	FROM rpt.rpt_comm_employee_info_da
	WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
	AND corp_name = '上海链家'
	AND region_name RLIKE '^沪|链家'
	AND on_job_status_code = '170007002'
	AND job_category_name like '%经纪人%' -- AND job_name IN ('租赁经纪人', '租赁店经理')
	AND data_source <> 'uc' -- 剔除兼岗 
) holder
ON shou1.manager_no = holder.employee_no