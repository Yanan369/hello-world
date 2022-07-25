--模板查询：资管经理底表（施工中）
SELECT  emp.corp_name                                       AS `公司`
       ,emp.dabu                                            AS `大部`
       ,emp.region_name                                     AS `事业部`
       ,emp.partname                                        AS `大区`
       ,emp.employee_no                                     AS `工号`
       ,emp.employee_name                                   AS `姓名`
       ,nvl(t1.managed_house,0)                             AS `在管房源`
       ,nvl(t2.shou_sign_price,0)                           AS `平均收房价`
       ,nvl(t2.vacancy_days,0)                              AS `平均免租期`
       ,nvl(t1.total_out,0)                                 AS `在管房源出房量`
       ,nvl(t1.one_price_rate,0)                            AS `一口价率`
       ,nvl(t1.vacancy_house,0)                             AS `空置量`
       ,nvl(t1.quhua,0)                                     AS `收房去化率`
       ,nvl(t1.over_15_vacancy,0)                           AS `超15天空置房源量`
       ,nvl(t1.over_15_vacancy_rate,0)                      AS `超15天空置房源率`
       ,nvl(t1.over_30_vacancy,0)                           AS `超30天空置房源量`
       ,nvl(t1.over_30_vacancy_rate,0)                      AS `超30天空置房源率`
       ,nvl(t1.remain_vacancy_days,0)                       AS `平均剩余免租期`
       ,nvl(t1.vr_rate,0)                                   AS `VR率`
       ,nvl(t1.display_rate,0)                              AS `外展率`
       ,nvl(t1.chu_cnt,0)                                   AS `出房量`
       ,nvl(t2.current_month_in,0)                          AS `本月收房`
       ,nvl(t1.current_month_chu,0)                         AS `本月出房`
       ,emp.position_name                                   AS `职级`
       ,nvl(tf.tf_cnt,0)                                    AS `推房量`
       ,nvl(t2.shou_cnt,0)                                  AS `累计收房`
       ,nvl(tf.process_cnt,0)                               AS `洽谈中总数`
       ,nvl(tf.30s_cnt/tf.process_cnt,0)                    AS `洽谈中400回访率`
       ,nvl(tf.op_cnt/tf.process_cnt,0)                     AS `洽谈中意向分级率`
       ,nvl(tf.pro_cnt/tf.process_cnt,0)                    AS `洽谈中实地评估率`
       ,nvl(tf.expire_cnt/tf.tf_cnt,0)                      AS `推房过期率`
       ,nvl(prospect.month_pro_cnt,0)                       AS `本月实地评估量`
       ,nvl(prospect.month_pro_in/prospect.month_pro_cnt,0) AS `实地评估收房率`
FROM
(-- 收房人
	SELECT  distinct corp_name
	       ,CASE WHEN shop_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
	             WHEN shop_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
	       ,shop_name                                                                                               AS region_name
	       ,CASE WHEN shop_name = '链家豪宅事业部' THEN regexp_replace(team_name,'大区','区')  ELSE team_name END             AS partname
	       ,employee_no
	       ,employee_name
	       ,position_name
	FROM rpt.rpt_comm_employee_info_da
	WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
	AND corp_name = '惠居上海'
	AND region_name = '轻托管运营中心'
	AND team_name rlike '大区$'
	AND position_name = '资管经理' 
)emp
LEFT JOIN
(-- 省心租在管房源部分
	SELECT  sxz.employee_no
	       ,COUNT(sxz.del_code)                                                                                                                       AS managed_house -- 在管房源
	       ,SUM(CASE WHEN sxz.rent_status = '已出租' THEN 1 ELSE 0 END)                                                                                  AS total_out -- 出房量
	       ,SUM(CASE WHEN sxz.shou_sign_price = sxz.chu_sign_price AND sxz.chu_contract_status = 2 THEN 1 else 0 end)/SUM(CASE WHEN sxz.chu_contract_status = 2 THEN 1 else 0 end) AS one_price_rate -- 一口价率
	       ,SUM(case WHEN sxz.rent_status != '已出租' THEN 1 ELSE 0 END)                                                                                 AS vacancy_house -- 空置量
	       ,SUM(case WHEN sxz.rent_status = '已出租' THEN 1 ELSE 0 END)/COUNT(sxz.del_code)                                                              AS quhua -- 收房去化率
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.kongzhi >= 15 THEN 1 else 0 end)                                                           AS over_15_vacancy -- 火房量
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.kongzhi >= 15 THEN 1 else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' THEN 1 ELSE 0 END) AS over_15_vacancy_rate
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.kongzhi >= 30 THEN 1 else 0 end)                                                           AS over_30_vacancy
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.kongzhi >= 30 THEN 1 else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' THEN 1 ELSE 0 END) AS over_30_vacancy_rate
	       ,SUM(case WHEN sxz.rent_status != '已出租' THEN sxz.vacancy_days1 - sxz.kongzhi else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' THEN 1 else 0 end) AS remain_vacancy_days -- 平均剩余免租期
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.is_vr = 1 THEN 1 else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' THEN 1 ELSE 0 END)     AS vr_rate
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.display_status_name = '是' THEN 1 else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' THEN 1 ELSE 0 END) AS display_rate
	       ,nvl(emp_chu.chu_cnt,0)                                                                                                                    AS chu_cnt -- 运营官出房量
	       ,nvl(emp_chu.current_month_chu,0)                                                                                                          AS current_month_chu
	FROM
	(
		SELECT  table1.employee_no -- 房管人
		       ,table1.del_code
		       ,table1.contract_code
		       ,table1.shou_sign_price
		       ,table1.sub_biz_type
		       ,table1.layout
		       ,table1.sign_date
		       ,table1.effect_start_date
		       ,table1.effect_end_date
		       ,table1.delivery_date
		       ,table1.sign_days
		       ,table1.vacancy_days
		       ,table1.vacancy_days1 -- 第一年免租期
		       ,table1.extend_days
		       ,table1.contract_sign_time
		       ,table1.rent_status
		       ,table1.case_no
		       ,table1.total_kongzhi
		       ,table1.kongzhi
		       ,table1.is_vr
		       ,table1.display_status_name
		       ,chu.del_code                                                                                                  AS chu_del_code
		       ,chu.biz_type
		       ,chu.chu_sign_price
		       ,chu.cinfo_contract_start_date
		       ,chu.cinfo_contract_end_date
		       ,chu.contract_sign_time                                                                                        AS chu_contract_sign_time
		       ,chu.contract_status                                                                                           AS chu_contract_status
		       ,CASE WHEN table1.effect_start_date > nvl(chu.end_date,0) THEN table1.effect_start_date  ELSE chu.end_date END AS last_end_date
		       ,chu1.selling_days
		       ,chu1.broker_area_name
		FROM
		(
			SELECT  *
			FROM
			(
				SELECT  shou.del_code
				       ,shou.contract_code
				       ,shou.sign_price                                                         AS shou_sign_price
				       ,shou1.sub_biz_type
				       ,shou.employee_no -- 收房人
				       ,shou1.layout
				       ,shou.sign_date
				       ,shou.effect_start_date
				       ,shou.effect_end_date
				       ,shou.delivery_date
				       ,shou.sign_days
				       ,shou.vacancy_days
				       ,shou.vacancy_days1
				       ,shou.vacancy_days2
				       ,shou.vacancy_days3
				       ,shou.vacancy_days4
				       ,shou.vacancy_days5
				       ,shou.extend_days
				       ,shou.deposit
				       ,shou.service_charge
				       ,shou.contract_sign_time
				       ,shou1.rent_status
				       ,ROW_NUMBER() OVER (PARTITION BY shou.del_code ORDER BY ay.case_no DESC) AS num
				       ,ay.case_no --出租率指标
				       ,czl.total_kongzhi --空置
				       ,last_kz.kongzhi
				       ,vr.is_vr
				       ,vr.display_status_name
				FROM -- 响叮当续约量
				(
					SELECT  *
					FROM
					(
						SELECT  del_code
						       ,alliance_house_code
						       ,contract_code
						       ,sign_date
						       ,sign_price
						       ,effect_start_date
						       ,effect_end_date
						       ,delivery_date
						       ,sign_days
						       ,vacancy_days
						       ,vacancy_days1
						       ,vacancy_days2
						       ,vacancy_days3
						       ,vacancy_days4
						       ,vacancy_days5
						       ,extend_days
						       ,deposit
						       ,service_charge
						       ,contract_sign_time
						       ,substr(house_manager_uc_id,9,8)                                            AS employee_no
						       ,row_number() over (partition by del_code ORDER BY contract_sign_time desc) AS num
						FROM olap.olap_trusteeship_house_in_dwd_da
						WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
						AND contract_city_code = 310000
						AND contract_sign_time >= "2022-04-11" -- 运营官开始时间点
						AND contract_status = 2 -- AND del_status = 2 -- 1:洽谈中, 2:已托管, 14:无效 
					) tp1
					WHERE tp1.num = 1 
				) shou
				LEFT JOIN
				(
					SELECT  *
					FROM
					(
						SELECT  sub_biz_type
						       ,contract_code
						       ,rent_status
						       ,layout
						       ,ROW_NUMBER() OVER (PARTITION BY contract_code ORDER BY contract_sign_time DESC) AS num
						FROM rpt.rpt_trusteeship_house_in_da
						WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
						AND city_code = 310000
						AND contract_sign_time >= "2022-04-11" -- 运营官开始时间点
						AND contract_status = "已签约" 
					) tp
					WHERE tp.num = 1 
				) shou1
				ON shou.contract_code = shou1.contract_code
				LEFT JOIN
				(
					SELECT  contract_code
					       ,is_vr
					       ,display_status_name
					FROM olap.olap_trusteeship_hdel_housein_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND city_code = 310000 
				) vr
				ON shou.contract_code = vr.contract_code
				LEFT JOIN
				(
					SELECT  housedel_id
					       ,house_id
					FROM rpt.rpt_coo_hdel_hdel_entrust_detail_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND del_type_code = '990001002' -- 990001002 租赁
					AND city_code = 310000
					AND typer_brand_code not IN ('990004003') --- 自如
					AND to_date(typer_time) <> to_date(cancel_time)
					AND (holder_region_name LIKE '%沪%' or holder_region_name = '链家豪宅事业部') 
				) house1
				ON house1.housedel_id = shou.alliance_house_code
				LEFT JOIN
				(
					SELECT  housedel_id
					       ,house_id
					FROM rpt.rpt_coo_hdel_hdel_entrust_detail_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND del_type_code = '990001002' -- 990001002 租赁
					AND city_code = 310000
					AND typer_brand_code not IN ('990004003') --- 自如
					AND to_date(typer_time) <> to_date(cancel_time)
					AND (holder_region_name LIKE '%沪%' or holder_region_name = '链家豪宅事业部') 
				) house2
				ON house1.house_id = house2.house_id
				LEFT JOIN
				(
					SELECT  case_no
					       ,housedelcode
					FROM olap.olap_sh_meacasedetail_ha
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND trading_type = '0101' -- 0101租赁
					AND signstatus = 3807
					AND corp_name = '上海链家' -- AND signedtypename <> '普通租赁'
					AND signedtypename not like '轻托管%'
					AND to_date(sign_date) BETWEEN '2021-03-01' AND '2021-08-31' 
				) ay
				ON ay.housedelcode = house2.housedel_id -- 出租率
				LEFT JOIN
				(
					SELECT  t5.del_code
					       ,SUM(CASE WHEN DATEDIFF(t5.effect_start_date,t5.cinfo_contract_start_date) > 0 THEN 0 ELSE (CASE WHEN ( CASE WHEN rn = 1 AND t5.contract_code IS NULL THEN DATEDIFF(CURRENT_DATE(),t5.effect_start_date) WHEN rn = 1 AND t5.contract_code IS NOT NULL THEN DATEDIFF(t5.cinfo_contract_start_date,t5.effect_start_date) ELSE DATEDIFF(t5.cinfo_contract_start_date,t5.end_date)-1 END ) < 0 THEN 0 ELSE ( CASE WHEN rn = 1 AND t5.contract_code IS NULL THEN DATEDIFF(CURRENT_DATE(),t5.effect_start_date) WHEN rn = 1 AND t5.contract_code IS NOT NULL THEN DATEDIFF(t5.cinfo_contract_start_date,t5.effect_start_date) ELSE DATEDIFF(t5.cinfo_contract_start_date,t5.end_date)-1 END ) END) END) AS total_kongzhi
					FROM
					(
						SELECT  t4.del_code
						       ,t4.effect_start_date
						       ,t4.effect_end_date
						       ,t1.contract_code
						       ,t2.cinfo_contract_start_date
						       ,CASE WHEN t3.end_date IS NULL THEN t2.end_date  ELSE t3.end_date END                   AS END_date
						       ,ROW_NUMBER() OVER (PARTITION BY t4.del_code ORDER BY t2.cinfo_contract_start_date ASC) AS rn
						FROM
						(
							SELECT  *
							FROM
							(
								SELECT  del_code
								       ,effect_start_date
								       ,effect_end_date
								       ,row_number() over (partition by del_code ORDER BY contract_sign_time desc) AS num
								FROM olap.olap_trusteeship_house_in_dwd_da
								WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
								AND contract_city_code = 310000
								AND contract_sign_time >= "2022-04-11" -- 运营官开始时间点
								AND contract_status = 2 -- AND del_status = 2 -- 1:洽谈中, 2:已托管, 14:无效 
							) aa
							WHERE aa.num = 1 
						) t4
						LEFT JOIN
						(
							SELECT  *
							FROM
							(
								SELECT  del_code
								       ,contract_code
								       ,cinfo_contract_start_date
								       ,cinfo_contract_end_date
								       ,contract_sign_time
								       ,contract_status
								       ,ROW_NUMBER() OVER (PARTITION BY del_code ORDER BY contract_sign_time DESC) AS num
								FROM olap.olap_trusteeship_house_out_dwd_da
								WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
								AND contract_city_code = 310000
								AND contract_status IN (2, 3) -- AND contract_sign_time >= "2022-01-21" 
							) temp
							WHERE temp.num = 1 
						) t1
						ON t4.del_code = t1.del_code
						LEFT JOIN
						(
							SELECT  del_code
							       ,contract_code
							       ,cinfo_contract_start_date
							       ,CASE WHEN nvl(back_date,"null") = "null" THEN cinfo_contract_end_date  ELSE back_date END         AS END_date
							       ,CONCAT(del_code,ROW_NUMBER() OVER (PARTITION BY del_code ORDER BY cinfo_contract_start_date ASC)) AS num
							FROM olap.olap_trusteeship_house_out_dwd_da
							WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
							AND contract_city_code = 310000
							AND contract_status IN (2, 3, 4, 5) -- AND contract_sign_time >= "2022-01-21" 
						) t2
						ON t1.del_code = t2.del_code
						LEFT JOIN
						(
							SELECT  del_code
							       ,contract_code
							       ,cinfo_contract_start_date
							       ,CASE WHEN nvl(back_date,"null") = "null" THEN cinfo_contract_end_date  ELSE back_date END           AS END_date
							       ,CONCAT(del_code,ROW_NUMBER() OVER (PARTITION BY del_code ORDER BY cinfo_contract_start_date ASC)+1) AS num
							FROM olap.olap_trusteeship_house_out_dwd_da
							WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
							AND contract_city_code = 310000
							AND contract_status IN (2, 3, 4, 5) -- AND contract_sign_time >= "2022-01-21" 
						) t3
						ON t2.num = t3.num
					) t5
					GROUP BY  t5.del_code
				) czl
				ON shou.del_code = czl.del_code --最后一次空置
				LEFT JOIN
				(
					SELECT  kz.del_code
					       ,CASE WHEN kz.is_effective_sf = 0 THEN null
					             WHEN kz.is_history_cf = 0 THEN DATEDIFF(CURRENT_DATE,kz.effect_start_date)  ELSE DATEDIFF(CURRENT_DATE,last_cf_end_date) - 1 END AS kongzhi
					FROM
					(
						SELECT  sf.del_code
						       ,sf.effect_start_date
						       ,cf.last_cf_end_date
						       ,CASE WHEN DATEDIFF(CURRENT_DATE,sf.effect_start_date) >= 0 THEN 1  ELSE 0 END AS is_effective_sf
						       ,CASE WHEN cf.cf_contract_code IS NULL THEN 0  ELSE 1 END                      AS is_history_cf
						FROM
						(
							SELECT  *
							FROM
							(
								SELECT  del_code
								       ,effect_start_date
								       ,ROW_NUMBER() OVER (PARTITION BY del_code ORDER BY contract_sign_time DESC) AS num
								FROM rpt.rpt_trusteeship_house_in_da
								WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
								AND city_code = 310000
								AND contract_sign_time >= '2022-01-21' -- 省心租开始时间点
								AND contract_status = '已签约'
								AND rent_status != '已出租' 
							) t1
							WHERE t1.num = 1 
						) sf
						LEFT JOIN
						(
							SELECT  *
							FROM
							(
								SELECT  del_code
								       ,contract_code                                                                             AS cf_contract_code
								       ,cinfo_contract_start_date
								       ,CASE WHEN nvl(back_date,"null") = "null" THEN cinfo_contract_end_date  ELSE back_date END AS last_cf_end_date
								       ,ROW_NUMBER() OVER (PARTITION BY del_code ORDER BY contract_sign_time DESC)                AS num
								FROM olap.olap_trusteeship_house_out_dwd_da
								WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
								AND contract_city_code = 310000
								AND contract_status IN (2, 3, 4, 5) 
							) t2
							WHERE t2.num = 1
							AND DATEDIFF(last_cf_end_date, cinfo_contract_start_date) >= 15 
						) cf
						ON sf.del_code = cf.del_code
					) kz
				) last_kz
				ON shou.del_code = last_kz.del_code
			)temp1
			WHERE temp1.num = 1 
		) table1
		LEFT JOIN
		(-- 出房(在管房源)
			SELECT  *
			FROM
			(
				SELECT  contract_code                                                                                       AS contract_code_out
				       ,del_code
				       ,biz_type
				       ,sign_date
				       ,sign_price                                                                                          AS chu_sign_price
				       ,contract_period_updated_time
				       ,contract_termination_sign_date
				       ,back_date
				       ,cinfo_pay_cycle
				       ,cinfo_contract_start_date
				       ,cinfo_contract_end_date
				       ,contract_sign_time
				       ,contract_status
				       ,CASE WHEN nvl(terminate_time,"null") = "null" THEN cinfo_contract_end_date  ELSE terminate_time END AS END_date
				       ,row_number() over (partition by del_code ORDER BY contract_sign_time desc)                          AS num
				FROM olap.olap_trusteeship_house_out_dwd_da
				WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
				AND contract_city_code = 310000
				AND contract_status IN (2, 3) -- contract_status： 1:盖章, 2:已签约, 3:解约中, 4:已解约, 5:已完结, 6:起草中, 7:已无效 -- AND contract_sign_time >= "2022-02-01" 
			) tp2
			WHERE tp2.num = 1 
		) chu
		ON table1.del_code = chu.del_code
		LEFT JOIN
		(
			SELECT  contract_code
			       ,selling_days
			       ,broker_area_name
			FROM olap.olap_trusteeship_house_out_da
			WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
			AND city_code = 310000 
		) chu1
		ON chu.contract_code_out = chu1.contract_code
	)sxz
	LEFT JOIN
	(-- 运营官出房量（非在管房源出房）
		SELECT  broker_no
		       ,COUNT(empchu_del_code) AS chu_cnt
		       ,COUNT(CASE WHEN contract_sign_date BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(CURRENT_DATE,-1) THEN empchu_del_code else null END) AS current_month_chu
		FROM
		(
			SELECT  chu.del_code AS empchu_del_code
			       ,chu.broker_no
			       ,chu.contract_sign_date
			FROM
			(
				SELECT  *
				FROM
				(
					SELECT  del_code
					       ,alliance_house_code
					       ,contract_code
					       ,sign_date
					       ,sign_price
					       ,effect_start_date
					       ,effect_end_date
					       ,delivery_date
					       ,sign_days
					       ,extend_days
					       ,deposit
					       ,service_charge
					       ,contract_sign_time
					       ,substr(house_manager_uc_id,9,8)                                            AS employee_no
					       ,row_number() over (partition by del_code ORDER BY contract_sign_time desc) AS num
					FROM olap.olap_trusteeship_house_in_dwd_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND contract_city_code = 310000
					AND contract_sign_time >= "2022-01-21" -- 省心租开始时间点
					AND contract_status = 2 -- AND del_status = 2 -- 1:洽谈中, 2:已托管, 14:无效 
				) tp1
				WHERE tp1.num = 1 
			) shou
			INNER JOIN
			(-- 出房
				SELECT  *
				FROM
				(
					SELECT  del_code
					       ,substr(contract_created_uc_id,9,8)                                         AS broker_no
					       ,contract_code
					       ,row_number() over (partition by del_code ORDER BY contract_sign_time desc) AS num
					       ,to_date(contract_sign_time)                                                AS contract_sign_date
					FROM olap.olap_trusteeship_house_out_dwd_da
					WHERE pt = concat(REGEXP_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND contract_status = 2
					AND contract_city_code = 310000 
				) tp2
				WHERE tp2.num = 1
				AND tp2.contract_sign_date >= '2022-01-21' 
			) chu
			ON shou.del_code = chu.del_code
		)temp2
		GROUP BY  broker_no
	)emp_chu
	ON sxz.employee_no = emp_chu.broker_no
	GROUP BY  sxz.employee_no
	         ,nvl(emp_chu.chu_cnt,0)
	         ,nvl(emp_chu.current_month_chu,0)
)t1
ON emp.employee_no = t1.employee_no
LEFT JOIN
(-- 省心租收房部分（合同创建人口径）
	SELECT  sxz.employee_no -- 合同创建人
	       ,COUNT(sxz.del_code)                       AS shou_cnt -- 收房量
	       ,SUM(CASE WHEN to_date(sxz.contract_sign_time) BETWEEN trunc(date_sub(current_date(),1),"MM") AND date_sub(current_date(),1) AND (sxz.effect_start_date <= last_day(add_months(date_add(current_date,-1),1)) OR sxz.sub_biz_type = '标准合同') THEN 1 else 0 end) + SUM(CASE WHEN substr(trunc(sxz.contract_sign_time,'MM'),1,7) BETWEEN '2022-05' AND substr(trunc(add_months(date_add(current_date,-1),-1),'MM'),1,7) AND trunc(sxz.effect_start_date,'MM') = trunc(add_months(date_add(current_date,-1),1),'MM') AND sxz.sub_biz_type = '续约合同' THEN 1 else 0 end) AS current_month_in
	       ,AVG(sxz.shou_sign_price)                  AS shou_sign_price -- 平均收房价
	       ,AVG(sxz.vacancy_days/(sxz.sign_days/365)) AS vacancy_days -- 平均免租期
	FROM
	(
		SELECT  table1.employee_no -- 合同创建人
		       ,table1.del_code
		       ,table1.contract_code
		       ,table1.shou_sign_price
		       ,table1.sub_biz_type
		       ,table1.layout
		       ,table1.sign_date
		       ,table1.effect_start_date
		       ,table1.effect_end_date
		       ,table1.delivery_date
		       ,table1.sign_days
		       ,table1.vacancy_days
		       ,table1.vacancy_days1 -- 第一年免租期
		       ,table1.extend_days
		       ,table1.contract_sign_time
		FROM
		(
			SELECT  shou.del_code
			       ,shou.contract_code
			       ,shou.sign_price AS shou_sign_price
			       ,shou1.sub_biz_type
			       ,shou.employee_no -- 合同创建人
			       ,shou1.layout
			       ,shou.sign_date
			       ,shou.effect_start_date
			       ,shou.effect_end_date
			       ,shou.delivery_date
			       ,shou.sign_days
			       ,shou.vacancy_days
			       ,shou.vacancy_days1
			       ,shou.vacancy_days2
			       ,shou.vacancy_days3
			       ,shou.vacancy_days4
			       ,shou.vacancy_days5
			       ,shou.extend_days
			       ,shou.deposit
			       ,shou.service_charge
			       ,shou.contract_sign_time
			       ,shou1.rent_status
			FROM -- 响叮当续约量
			(
				SELECT  *
				FROM
				(
					SELECT  del_code
					       ,alliance_house_code
					       ,contract_code
					       ,sign_date
					       ,sign_price
					       ,effect_start_date
					       ,effect_end_date
					       ,delivery_date
					       ,sign_days
					       ,vacancy_days
					       ,vacancy_days1
					       ,vacancy_days2
					       ,vacancy_days3
					       ,vacancy_days4
					       ,vacancy_days5
					       ,extend_days
					       ,deposit
					       ,service_charge
					       ,contract_sign_time
					       ,substr(contract_house_created_uc_id,9,8)                                   AS employee_no
					       ,row_number() over (partition by del_code ORDER BY contract_sign_time desc) AS num
					FROM olap.olap_trusteeship_house_in_dwd_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND contract_city_code = 310000
					AND contract_sign_time >= "2022-04-11" -- 运营官开始时间点
					AND contract_status = 2 -- AND del_status = 2 -- 1:洽谈中, 2:已托管, 14:无效 
				) tp1
				WHERE tp1.num = 1 
			) shou
			LEFT JOIN
			(
				SELECT  *
				FROM
				(
					SELECT  sub_biz_type
					       ,contract_code
					       ,rent_status
					       ,layout
					       ,ROW_NUMBER() OVER (PARTITION BY contract_code ORDER BY contract_sign_time DESC) AS num
					FROM rpt.rpt_trusteeship_house_in_da
					WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND city_code = 310000
					AND contract_sign_time >= "2022-04-11" -- 运营官开始时间点
					AND contract_status = "已签约" 
				) tp
				WHERE tp.num = 1 
			) shou1
			ON shou.contract_code = shou1.contract_code
		) table1
	)sxz
	GROUP BY  sxz.employee_no
)t2
ON emp.employee_no = t2.employee_no
LEFT JOIN
(
	SELECT  t.manager_no
	       ,COUNT(distinct t.trusteeship_housedel_code)                                                                                       AS tf_cnt
	       ,COUNT(distinct CASE WHEN t.del_status = 1 THEN t.trusteeship_housedel_code else null end)                                         AS process_cnt
	       ,COUNT(distinct CASE WHEN t.del_status = 1 AND t.is_30s_call = 1 THEN t.trusteeship_housedel_code else null end)                   AS 30s_cnt
	       ,COUNT(distinct CASE WHEN t.del_status = 1 AND t.is_complete_opportunity_level = 1 THEN t.trusteeship_housedel_code else null end) AS op_cnt
	       ,COUNT(distinct CASE WHEN t.del_status = 1 AND t.is_complete_prospecting = 1 THEN t.trusteeship_housedel_code else null end)       AS pro_cnt -- 实地评估
	       ,COUNT(distinct CASE WHEN t.neg_opportunity_invalid_reason = 2 THEN t.trusteeship_housedel_code else null end)                     AS expire_cnt --洽谈过期
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
		FROM olap.olap_trusteeship_hdel_follow_process_da
		WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
		AND city_code = '310000'
		AND to_date(del_create_time) >= trunc(date_sub(current_date(), 1), 'MM') 
	)t
	GROUP BY  t.manager_no
)tf
ON emp.employee_no = tf.manager_no
LEFT JOIN
(
	SELECT  p.manager_no
	       ,COUNT(distinct CASE WHEN p.is_complete_prospecting = 1 THEN p.trusteeship_housedel_code else null end)                      AS month_pro_cnt --本月实地评估
	       ,COUNT(distinct CASE WHEN p.del_status = 2 AND p.is_complete_prospecting = 1 THEN p.trusteeship_housedel_code else null end) AS month_pro_in --实地评估收房
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
		FROM olap.olap_trusteeship_hdel_follow_process_da
		WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
		AND city_code = '310000'
		AND to_date(neg_at_wxz_time) >= trunc(date_sub(current_date(), 1), 'MM') 
	)p
	GROUP BY  p.manager_no
)prospect
ON emp.employee_no = prospect.manager_no