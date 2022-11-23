--模板查询：大区收房量
--模板查询：大区收房量
SELECT  CASE WHEN calc.partname is null AND calc.region_name is not null THEN calc.region_name
             WHEN calc.partname is null AND calc.region_name is null AND calc.dabu is not null THEN calc.dabu
             WHEN calc.partname is null AND calc.region_name is null AND calc.dabu is null THEN calc.corp_name  ELSE calc.partname END AS partname
       ,SUM(nvl(calc.shou_cnt,0))-SUM(nvl(calc.terminate_cnt,0))                                                                       AS shou_cnt
       ,SUM(nvl(calc.terminate_cnt,0))                                                                                                 AS terminate_cnt
       ,SUM(nvl(calc.chu_cnt1,0))+SUM(nvl(calc.chu_cnt2,0))*0.5                                                                        AS chu_cnt
       ,SUM(nvl(calc.shou_cnt_1,0))-SUM(nvl(calc.terminate_cnt_1,0))                                                                   AS shou_cnt_1
       ,SUM(nvl(calc.terminate_cnt_1,0))                                                                                               AS terminate_cnt_1
       ,SUM(nvl(calc.chu_cnt1_1,0))+SUM(nvl(calc.chu_cnt2_1,0))*0.5                                                                    AS chu_cnt_1
       ,SUM(nvl(calc.shou_cnt_2,0))-SUM(nvl(calc.terminate_cnt_2,0))                                                                   AS shou_cnt_2
       ,SUM(nvl(calc.terminate_cnt_2,0))                                                                                               AS terminate_cnt_2
       ,SUM(nvl(calc.chu_cnt1_2,0))+SUM(nvl(calc.chu_cnt2_2,0))*0.5                                                                    AS chu_cnt_2
       ,SUM(nvl(calc.shou_cnt_3,0))-SUM(nvl(calc.terminate_cnt_3,0))                                                                   AS shou_cnt_3
       ,SUM(nvl(calc.terminate_cnt_3,0))                                                                                               AS terminate_cnt_3
       ,SUM(nvl(calc.chu_cnt1_3,0))+SUM(nvl(calc.chu_cnt2_3,0))*0.5                                                                    AS chu_cnt_3
       ,SUM(nvl(calc.shou_cnt_4,0))-SUM(nvl(calc.terminate_cnt_4,0))                                                                   AS shou_cnt_4
       ,SUM(nvl(calc.terminate_cnt_4,0))                                                                                               AS terminate_cnt_4
       ,SUM(nvl(calc.chu_cnt1_4,0))+SUM(nvl(calc.chu_cnt2_4,0))*0.5                                                                    AS chu_cnt_4
FROM
(
	SELECT  '惠居上海'                           AS corp_name
	       ,holder.dabu
	       ,holder.region_name
	       ,holder.partname
	       ,holder.job_name
	       ,holder.employee_no
	       ,shouchu.manager_no
	       ,nvl(shouchu.shou_cnt,0)          AS shou_cnt
	       ,nvl(shouchu.chu_cnt1,0)          AS chu_cnt1
	       ,nvl(shouchu.chu_cnt2,0)          AS chu_cnt2
	       ,nvl(terminate.terminate_cnt,0)   AS terminate_cnt
	       ,nvl(shouchu.shou_cnt_1,0)        AS shou_cnt_1
	       ,nvl(shouchu.shou_cnt_2,0)        AS shou_cnt_2
	       ,nvl(shouchu.shou_cnt_3,0)        AS shou_cnt_3
	       ,nvl(shouchu.shou_cnt_4,0)        AS shou_cnt_4
	       ,nvl(shouchu.chu_cnt1_1,0)        AS chu_cnt1_1
	       ,nvl(shouchu.chu_cnt2_1,0)        AS chu_cnt2_1
	       ,nvl(shouchu.chu_cnt1_2,0)        AS chu_cnt1_2
	       ,nvl(shouchu.chu_cnt2_2,0)        AS chu_cnt2_2
	       ,nvl(shouchu.chu_cnt1_3,0)        AS chu_cnt1_3
	       ,nvl(shouchu.chu_cnt2_3,0)        AS chu_cnt2_3
	       ,nvl(shouchu.chu_cnt1_4,0)        AS chu_cnt1_4
	       ,nvl(shouchu.chu_cnt2_4,0)        AS chu_cnt2_4
	       ,nvl(terminate.terminate_cnt_1,0) AS terminate_cnt_1
	       ,nvl(terminate.terminate_cnt_2,0) AS terminate_cnt_2
	       ,nvl(terminate.terminate_cnt_3,0) AS terminate_cnt_3
	       ,nvl(terminate.terminate_cnt_4,0) AS terminate_cnt_4
	FROM
	(
		SELECT  a.dabu
		       ,a.region_name
		       ,a.partname
		       ,a.employee_name
		       ,a.employee_no
		       ,a.employee_ucid
		       ,a.job_name
		FROM
		(
			SELECT  team_name                                                                                             AS partname
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
		) AS a
	) holder
	LEFT JOIN
	(
		SELECT  shou1.manager_no
		       ,COUNT(distinct CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) >= '2022-09-01' AND substr(shou1.effect_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code end) AS shou_cnt
		       ,COUNT(distinct CASE WHEN (DATEDIFF(chu.chu_end_date,chu.chu_start_date) >= 180 or (DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) <= 0 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_start_date) >= 0 )) AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code end) AS chu_cnt1
		       ,COUNT(distinct CASE WHEN DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) > 0 AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code end) AS chu_cnt2
		       ,COUNT(distinct CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) >= '2022-09-01' AND substr(shou1.effect_start_date,1,10) BETWEEN '2022-09-01' AND '2022-09-12' THEN shou1.del_code WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-01' AND '2022-09-12' THEN shou1.del_code end) AS shou_cnt_1
		       ,COUNT(distinct CASE WHEN (DATEDIFF(chu.chu_end_date,chu.chu_start_date) >= 180 or (DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) <= 0 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_start_date) >= 0 )) AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-01' AND '2022-09-12' THEN shou1.del_code end) AS chu_cnt1_1
		       ,COUNT(distinct CASE WHEN DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) > 0 AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-01' AND '2022-09-12' THEN shou1.del_code end) AS chu_cnt2_1
		       ,COUNT(distinct CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) >= '2022-09-01' AND substr(shou1.effect_start_date,1,10) BETWEEN '2022-09-13' AND '2022-09-18' THEN shou1.del_code WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-13' AND '2022-09-18' THEN shou1.del_code end) AS shou_cnt_2
		       ,COUNT(distinct CASE WHEN (DATEDIFF(chu.chu_end_date,chu.chu_start_date) >= 180 or (DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) <= 0 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_start_date) >= 0 )) AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-13' AND '2022-09-18' THEN shou1.del_code end) AS chu_cnt1_2
		       ,COUNT(distinct CASE WHEN DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) > 0 AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-13' AND '2022-09-18' THEN shou1.del_code end) AS chu_cnt2_2
		       ,COUNT(distinct CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) >= '2022-09-01' AND substr(shou1.effect_start_date,1,10) BETWEEN '2022-09-19' AND '2022-09-26' THEN shou1.del_code WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-19' AND '2022-09-26' THEN shou1.del_code end) AS shou_cnt_3
		       ,COUNT(distinct CASE WHEN (DATEDIFF(chu.chu_end_date,chu.chu_start_date) >= 180 or (DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) <= 0 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_start_date) >= 0 )) AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-19' AND '2022-09-26' THEN shou1.del_code end) AS chu_cnt1_3
		       ,COUNT(distinct CASE WHEN DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) > 0 AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-19' AND '2022-09-26' THEN shou1.del_code end) AS chu_cnt2_3
		       ,COUNT(distinct CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) >= '2022-09-01' AND substr(shou1.effect_start_date,1,10) BETWEEN '2022-09-27' AND '2022-09-30' THEN shou1.del_code WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-27' AND '2022-09-30' THEN shou1.del_code end) AS shou_cnt_4
		       ,COUNT(distinct CASE WHEN (DATEDIFF(chu.chu_end_date,chu.chu_start_date) >= 180 or (DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) <= 0 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_start_date) >= 0 )) AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-27' AND '2022-09-30' THEN shou1.del_code end) AS chu_cnt1_4
		       ,COUNT(distinct CASE WHEN DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) > 0 AND substr(chu.chu_cdate,1,10) >= '2022-09-01' AND substr(chu.chu_start_date,1,10) BETWEEN '2022-09-27' AND '2022-09-30' THEN shou1.del_code end) AS chu_cnt2_4
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
		GROUP BY  shou1.manager_no
	) AS shouchu
	ON shouchu.manager_no = holder.employee_no
	LEFT JOIN
	(
		SELECT  a.manager_no
		       ,COUNT(distinct a.del_code)                                                                              AS terminate_cnt
		       ,COUNT(distinct CASE WHEN a.housein_back_date BETWEEN '2022-09-01' AND '2022-09-12' THEN a.del_code end) AS terminate_cnt_1
		       ,COUNT(distinct CASE WHEN a.housein_back_date BETWEEN '2022-09-13' AND '2022-09-18' THEN a.del_code end) AS terminate_cnt_2
		       ,COUNT(distinct CASE WHEN a.housein_back_date BETWEEN '2022-09-19' AND '2022-09-26' THEN a.del_code end) AS terminate_cnt_3
		       ,COUNT(distinct CASE WHEN a.housein_back_date BETWEEN '2022-09-27' AND '2022-09-30' THEN a.del_code end) AS terminate_cnt_4
		FROM
		(
			SELECT  a.*
			       ,b.chu_contract_code
			FROM
			(
				SELECT  trusteeship_housedel_code                                                                  AS del_code
				       ,old_housedel_id
				       ,concat(trusteeship_housedel_code,'01')                                                     AS housedel_dk
				       ,if(housedel_id = '-911','null',housedel_id)                                                AS housedel_code
				       ,house_id
				       ,contract_code
				       ,contract_status_name
				       ,contract_sign_time
				       ,to_date(contract_sign_time)                                                                AS contract_sign_date
				       ,effect_start_date
				       ,effect_end_date
				       ,sign_years
				       ,manager_no
				       ,manager_name
				       ,protocol_type
				       ,substr(terminate_time,1,10)                                                                AS terminate_date
				       ,housein_back_date
				       ,terminate_sign_date
				       ,CASE WHEN expected_profits2 < expected_profits1 AND expected_profits2 is not null AND expected_profits2 <> '' THEN expected_profits2  ELSE expected_profits1 END AS valid_price
				       ,row_number() over(partition by trusteeship_housedel_code ORDER BY contract_sign_time desc) AS rn
				FROM olap.olap_trusteeship_hdel_housein_da
				WHERE pt = concat(regexp_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
				AND city_code = 310000
				AND contract_status_name = '已解约'
				AND protocol_type <> '豪宅'
				AND substr(housein_back_date, 1, 10) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND last_day(date_add(CURRENT_DATE, -1))
				AND to_date(effect_start_date) < trunc(date_add(CURRENT_DATE, -1), 'MM')
				AND DATEDIFF(substr(housein_back_date, 1, 10), effect_start_date) <= 180 
			) AS a
			LEFT JOIN
			(
				SELECT  housein_contract_code
				       ,contract_code AS chu_contract_code
				FROM olap.olap_trusteeship_hdel_houseout_da
				WHERE pt = concat(regexp_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
				AND city_code = 310000
				AND to_date(effect_start_date) < trunc(date_add(CURRENT_DATE, -1), 'MM')
				AND contract_status_name IN ('已解约', '已完结', '解约中', '已签约') 
			) b
			ON a.contract_code = b.housein_contract_code
			WHERE (a.protocol_type != '无忧' or (a.protocol_type = '无忧' AND b.chu_contract_code is not null)) 
		)a
		GROUP BY  a.manager_no
	) AS terminate
	ON terminate.manager_no = holder.employee_no
) AS calc
GROUP BY  calc.corp_name
         ,calc.dabu
         ,calc.region_name
         ,calc.partname
GROUPING SETS ((calc.corp_name, calc.dabu, calc.region_name, calc.partname), (calc.corp_name, calc.dabu, calc.region_name), (calc.corp_name, calc.dabu), (calc.corp_name))