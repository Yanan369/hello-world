--模板查询：资管经理底表
--模板查询：租赁经理&资管经理底表
--模板查询：资管经理底表（施工中）
--233333
SELECT  emp.corp_name                                         AS `公司`
       ,emp.dabu                                              AS `大部`
       ,emp.region_name                                       AS `事业部`
       ,emp.partname                                          AS `大区`
       ,emp.employee_no                                       AS `工号`
       ,emp.employee_name                                     AS `姓名`
       ,nvl(t1.managed_house,0)                               AS `在管房源`
       ,nvl(t1.shou_sign_price,0)                             AS `平均收房价`
       ,nvl(t1.vacancy_days,0)                                AS `平均免租期`
       ,nvl(t1.total_out,0)                                   AS `在管房源出房量`
       ,nvl(t1.one_price_rate,0)                              AS `一口价率`
       ,nvl(t1.vacancy_house,0)                               AS `空置量`
       ,nvl(t1.quhua,0)                                       AS `收房去化率`
       ,nvl(t1.over_15_vacancy,0)                             AS `超15天空置房源量`
       ,nvl(t1.over_15_vacancy_rate,0)                        AS `超15天空置房源率`
       ,nvl(t1.over_30_vacancy,0)                             AS `超30天空置房源量`
       ,nvl(t1.over_30_vacancy_rate,0)                        AS `超30天空置房源率`
       ,nvl(t1.remain_vacancy_days,0)                         AS `平均剩余免租期`
       ,nvl(t1.vr_rate,0)                                     AS `VR率`
       ,nvl(t1.display_rate,0)                                AS `外展率`
       ,nvl(t1.chu_cnt,0)                                     AS `出房量`
       ,nvl(shou.shou_cnt,0) - nvl(terminate.terminate_cnt,0) AS `本月收房`  --扣除解约
       ,nvl(chu.chu_cnt1+chu.chu_cnt2*0.5,0)                  AS `本月出房`
       ,emp.position_name                                     AS `职级`
       ,nvl(tf.tf_cnt,0)                                      AS `推房量`
       ,'-'                                                   AS `累计收房`
       ,nvl(tf.process_cnt,0)                                 AS `洽谈中总数`
       ,nvl(tf.30s_cnt/tf.process_cnt,0)                      AS `洽谈中400回访率`
       ,nvl(tf.op_cnt/tf.process_cnt,0)                       AS `洽谈中意向分级率`
       ,nvl(tf.pro_cnt/tf.process_cnt,0)                      AS `洽谈中实地评估率`
       ,nvl(tf.expire_cnt/tf.tf_cnt,0)                        AS `推房过期率`
       ,nvl(prospect.month_pro_cnt,0)                         AS `本月实地评估量`
       ,nvl(prospect.month_pro_in/prospect.month_pro_cnt,0)   AS `实地评估收房率`
       ,nvl(tf.tg_cnt/tf.tf_cnt,0)                            AS `推转收率`
       ,nvl(basic_info.flag,0)
       ,nvl(holder_detail.flag,0)
       ,nvl(CASE WHEN basic_info.flag = 1 AND holder_detail.flag = 1 THEN 1 WHEN basic_info.flag <> 1 AND holder_detail.flag = 1 THEN 0.5 ELSE holder_detail.flag END,0) AS flag
	   ,nvl(terminate.terminate_cnt,0)                        AS `本月解约`
FROM
(-- 收房人
	SELECT  distinct corp_name
	       ,CASE WHEN shop_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
	             WHEN shop_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
	       ,CASE WHEN shop_name = '豪宅事业部' THEN '链家豪宅事业部'  ELSE shop_name END                                      AS region_name
	       ,CASE WHEN shop_name = '豪宅事业部' THEN regexp_replace(team_name,'大区','区')  ELSE team_name END             AS partname
	       ,employee_no
	       ,employee_name
	       ,position_name
	FROM rpt.rpt_comm_employee_info_da
	WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
	AND corp_name = '惠居上海'
	AND on_job_status = '在职在岗'
	AND region_name = '轻托管运营中心'
	AND team_name rlike '大区$'
	AND position_name IN ('资管区域经理', '资管经理') 
)emp
LEFT JOIN
(-- 省心租在管房源部分
	SELECT  sxz.employee_no
	       ,COUNT(distinct sxz.del_code)                                                                                                          AS managed_house -- 在管房源
	       ,SUM(CASE WHEN sxz.rent_status = '已出租' THEN 1 ELSE 0 END)                                                                              AS total_out -- 出房量
	       ,SUM(CASE WHEN sxz.shou_sign_price = sxz.chu_sign_price AND sxz.chu_contract_status = 2 and to_date(sxz.contract_sign_time) >= '2022-02-01' THEN 1 else 0 end)/SUM(CASE WHEN sxz.chu_contract_status = 2 and to_date(sxz.contract_sign_time) >= '2022-02-01' THEN 1 else 0 end) AS one_price_rate -- 一口价率
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.protocol_type <> '无忧' AND to_date(sxz.effect_start_date) <= date_sub(current_date(),1) THEN 1 ELSE 0 END) AS vacancy_house -- 空置量
	       ,SUM(case WHEN sxz.rent_status = '已出租' AND to_date(sxz.effect_start_date) <= date_sub(current_date(),1) THEN 1 ELSE 0 END)/COUNT(distinct CASE WHEN to_date(sxz.effect_start_date) <= date_sub(current_date(),1) THEN sxz.del_code end) AS quhua -- 收房去化率
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.protocol_type <> '无忧' AND sxz.kongzhi >= 15 THEN 1 else 0 end)                         AS over_15_vacancy -- 火房量
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.protocol_type <> '无忧' AND sxz.kongzhi >= 15 THEN 1 else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' AND sxz.protocol_type <> '无忧' AND to_date(sxz.effect_start_date) <= date_sub(current_date(),1) THEN 1 ELSE 0 END) AS over_15_vacancy_rate
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.protocol_type <> '无忧' AND sxz.kongzhi >= 30 THEN 1 else 0 end)                         AS over_30_vacancy
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.protocol_type <> '无忧' AND sxz.kongzhi >= 30 THEN 1 else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' AND sxz.protocol_type <> '无忧' AND to_date(sxz.effect_start_date) <= date_sub(current_date(),1) THEN 1 ELSE 0 END) AS over_30_vacancy_rate
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.protocol_type <> '无忧' THEN sxz.vacancy_days1 - sxz.kongzhi else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' AND sxz.protocol_type <> '无忧' AND to_date(sxz.effect_start_date) <= date_sub(current_date(),1) THEN 1 else 0 end) AS remain_vacancy_days -- 平均剩余免租期
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.is_vr = 1 THEN 1 else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' THEN 1 ELSE 0 END) AS vr_rate
	       ,SUM(case WHEN sxz.rent_status != '已出租' AND sxz.display_status_name = '是' THEN 1 else 0 end)/SUM(case WHEN sxz.rent_status != '已出租' THEN 1 ELSE 0 END) AS display_rate
	       ,nvl(emp_chu.chu_cnt,0)                                                                                                                AS chu_cnt -- 运营官出房量
	       ,nvl(emp_chu.current_month_chu,0)                                                                                                      AS current_month_chu
	       ,AVG(sxz.shou_sign_price)                                                                                                              AS shou_sign_price
	       ,AVG(sxz.vacancy_days/(sxz.sign_days/365))                                                                                             AS vacancy_days
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
		       ,table1.protocol_type
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
				       ,vr.protocol_type
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
						AND contract_status = "已签约" 
					) tp
					WHERE tp.num = 1 
				) shou1
				ON shou.contract_code = shou1.contract_code
				LEFT JOIN
				(
					SELECT  *
					FROM
					(
						SELECT  contract_code
						       ,is_vr
						       ,display_status_name
						       ,protocol_type
						       ,row_number() over(partition by trusteeship_housedel_code ORDER BY contract_sign_time desc) AS rn
						FROM olap.olap_trusteeship_hdel_housein_da
						WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
						AND city_code = 310000
						AND contract_status_name = '已签约'
						AND to_date(effect_start_date) <= date_add(CURRENT_DATE, -1) 
					) AS adj
					WHERE adj.rn = 1 
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
								AND contract_city_code = 310000 -- AND contract_sign_time >= "2022-04-11" -- 运营官开始时间点
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
								AND city_code = 310000 -- AND contract_sign_time >= '2022-01-21' -- 省心租开始时间点
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
					AND contract_city_code = 310000 -- AND contract_sign_time >= "2022-01-21" -- 省心租开始时间点
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
				WHERE tp2.num = 1 -- AND tp2.contract_sign_date >= '2022-01-21' 
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
(-- 收房
	SELECT  shou1.sign_no
	       ,COUNT(distinct CASE WHEN shou1.protocol_type <> '无忧' AND substr(shou1.contract_sign_date,1,10) >= trunc(date_add(CURRENT_DATE,-1),'MM') AND substr(shou1.effect_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code WHEN shou1.protocol_type = '无忧' AND substr(chu.chu_cdate,1,10) >= trunc(date_add(CURRENT_DATE,-1),'MM') AND substr(chu.chu_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code end) AS shou_cnt
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
	GROUP BY  shou1.sign_no
) AS shou
ON emp.employee_no = shou.sign_no
LEFT JOIN
(
	SELECT  a.manager_no
	       ,COUNT(distinct a.del_code) AS terminate_cnt
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
		       ,terminate_sign_date
		       ,CASE WHEN expected_profits2 < expected_profits1 AND expected_profits2 is not null AND expected_profits2 <> '' THEN expected_profits2  ELSE expected_profits1 END AS valid_price
		       ,row_number() over(partition by trusteeship_housedel_code ORDER BY contract_sign_time desc) AS rn
		FROM olap.olap_trusteeship_hdel_housein_da
		WHERE pt = concat(regexp_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
		AND city_code = 310000
		AND contract_status_name = '已解约'
		AND protocol_type <> '豪宅'
		AND substr(housein_back_date, 1, 10) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE, -1), 1), 'MM'), -1)
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
	GROUP BY  a.manager_no
) AS terminate
ON emp.employee_no = terminate.manager_no
LEFT JOIN
(
	SELECT  shou1.manager_no
	       ,COUNT(distinct CASE WHEN (DATEDIFF(chu.chu_end_date,chu.chu_start_date) >= 180 or (DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) <= 0 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_start_date) >= 0 )) AND substr(chu.chu_cdate,1,10) >= trunc(date_add(CURRENT_DATE,-1),'MM') AND substr(chu.chu_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code end) AS chu_cnt1
	       ,COUNT(distinct CASE WHEN DATEDIFF(chu.chu_end_date,chu.chu_start_date) < 180 AND DATEDIFF(chu.housein_effect_end_date,chu.chu_end_date) > 0 AND substr(chu.chu_cdate,1,10) >= trunc(date_add(CURRENT_DATE,-1),'MM') AND substr(chu.chu_start_date,1,10) BETWEEN trunc(date_add(CURRENT_DATE,-1),'MM') AND date_add(trunc(add_months(date_add(CURRENT_DATE,-1),1),'MM'),-1) THEN shou1.del_code end) AS chu_cnt2
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
) AS chu
ON emp.employee_no = chu.manager_no
LEFT JOIN
(
	SELECT  t.manager_no
	       ,COUNT(distinct t.trusteeship_housedel_code)                                                                                       AS tf_cnt
	       ,COUNT(distinct CASE WHEN t.del_status = 1 THEN t.trusteeship_housedel_code else null end)                                         AS process_cnt
	       ,COUNT(distinct CASE WHEN t.del_status = 1 AND t.is_30s_call = 1 THEN t.trusteeship_housedel_code else null end)                   AS 30s_cnt
	       ,COUNT(distinct CASE WHEN t.del_status = 1 AND t.is_complete_opportunity_level = 1 THEN t.trusteeship_housedel_code else null end) AS op_cnt
	       ,COUNT(distinct CASE WHEN t.del_status = 1 AND t.is_complete_prospecting = 1 THEN t.trusteeship_housedel_code else null end)       AS pro_cnt -- 实地评估
	       ,COUNT(distinct CASE WHEN t.neg_opportunity_invalid_reason = 2 THEN t.trusteeship_housedel_code else null end)                     AS expire_cnt --洽谈过期
	       ,COUNT(distinct CASE WHEN t.del_status = 2 THEN t.trusteeship_housedel_code else null end)                                         AS tg_cnt
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
LEFT JOIN
(
	SELECT  emp.partname
	       ,CASE WHEN ( COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 15 AND 29 THEN trusteehouse_in1.del_code END)*0.5 + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi >= 30 THEN trusteehouse_in1.del_code END)) >= 2 AND (COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 15 AND 29 THEN trusteehouse_in1.del_code END)*0.5 + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi >= 30 THEN trusteehouse_in1.del_code END))/COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND trusteehouse_in1.effect_start_date <= date_add(CURRENT_DATE,-1) THEN trusteehouse_in1.del_code END) > 0.5 THEN 1
	             WHEN ( COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 7 AND 14 THEN trusteehouse_in1.del_code END) * 0.5 + (COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 15 AND 29 THEN trusteehouse_in1.del_code END) - COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 23 AND 29 THEN trusteehouse_in1.del_code END))*0.5 + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 23 AND 29 THEN trusteehouse_in1.del_code END) + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi >= 30 THEN trusteehouse_in1.del_code END) ) >= 2 AND ( COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 7 AND 14 THEN trusteehouse_in1.del_code END) * 0.5 + (COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 15 AND 29 THEN trusteehouse_in1.del_code END) - COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 23 AND 29 THEN trusteehouse_in1.del_code END))*0.5 + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 23 AND 29 THEN trusteehouse_in1.del_code END) + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi >= 30 THEN trusteehouse_in1.del_code END)) /COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND trusteehouse_in1.effect_start_date <= date_add(CURRENT_DATE,-1) THEN trusteehouse_in1.del_code END) > 0.5 THEN 0.5  ELSE 0 END AS flag
	FROM
	(
		SELECT  *
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
			       ,sign_name
			       ,sign_marketing_name
			       ,sign_area_name
			       ,customer_code
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
			AND to_date(effect_start_date) <= date_add(CURRENT_DATE, -1) 
		) AS adj
		WHERE adj.rn = 1 
	) AS trusteehouse_in1
	LEFT JOIN
	(
		SELECT  CASE WHEN shop_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
		             WHEN shop_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
		       ,CASE WHEN shop_name like '%豪宅%' THEN '链家豪宅事业部'  ELSE shop_name END                                    AS region_name
		       ,CASE WHEN shop_name like '%豪宅%' THEN regexp_replace(team_name,'大区','区')
		             WHEN team_name = '明珠大区' THEN '陆家嘴大区'
		             WHEN team_name = '普陀东大区' THEN '武宁大区'
		             WHEN team_name = '大华东大区' THEN '万华大区'  ELSE team_name END                                         AS partname
		       ,employee_name
		       ,employee_no
		       ,employee_ucid
		       ,position_name                                                                                         AS job_name
		FROM rpt.rpt_comm_employee_info_da
		WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
		AND on_job_status = '在职在岗'
		AND position_name IN ('资管区域经理', '资管经理')
		AND city_code = 310000 
		UNION ALL
		SELECT  CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
		             WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
		       ,region_name
		       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                               AS partname
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
	ON trusteehouse_in1.manager_no = holder.employee_no
	LEFT JOIN
	(
		SELECT  distinct corp_name
		       ,CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'  ELSE '租赁西大部' END AS dabu
		       ,region_name
		       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                    AS partname
		FROM rpt.rpt_comm_employee_info_da
		WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
		AND corp_name = '上海链家' --限制上海链家
		AND (region_name LIKE'%沪%' OR region_name LIKE'%豪宅%')
		AND on_job_status_code = '170007002' --在职
		AND job_category_name like '%经纪人%' --限制经纪人
		AND team_name NOT like '%租赁业务%'
		AND team_name NOT like '%新房业务%'
		AND region_name not like '%新房%'
		AND marketing_name not like '%新房%'
		AND marketing_name <> ''
		AND area_name <> ''
		AND data_source <> 'uc' -- 剔除兼岗 
	)emp
	ON holder.partname = emp.partname
	LEFT JOIN
	(
		SELECT  detail.del_code
		       ,detail.contract_code
		       ,detail.rent_unit_status_name
		       ,detail.is_effect
		       ,detail.contract_sign_date
		       ,detail.new_start
		       ,detail.new_end
		       ,detail.valid_price
		       ,detail.dt
		       ,CASE WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END AS last_kongzhi -- 如果有上一次去化，则去化结束时间-日期指示器，若无，则收房起租日-时间指示器+1
		       ,CASE WHEN detail.is_effect = 1 AND detail.is_chu = 1 AND detail.last_out_end is not null THEN DATEDIFF(detail.last_out_start,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 1 AND detail.last_out_end is null THEN DATEDIFF(detail.last_out_start,detail.new_start)+1 END AS last_quhua -- 如果有上一次去化，则去化结束时间-日期指示器，若无，则收房起租日-时间指示器+1
		       ,CASE WHEN (CASE
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END) <= 7 THEN '0-7天'
		             WHEN (CASE
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END) BETWEEN 8 AND 14 THEN '8-14天'
		             WHEN (CASE
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END) BETWEEN 15 AND 29 THEN '15-29天'
		             WHEN (CASE
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END) >= 30 THEN '30+天' END AS last_kongzhi_cat
		       ,detail.first_out_start
		       ,detail.last_out_start
		       ,detail.last_out_end
		       ,detail.chu_start_token
		       ,detail.chu_end_token
		       ,detail.is_chu1
		       ,detail.is_chu
		       ,detail.chuprice
		       ,detail.chu_cdate
		       ,detail.chu_end_date
		FROM
		(
			SELECT  deldaily.del_code
			       ,deldaily.contract_code
			       ,deldaily.rent_unit_status_name
			       ,deldaily.is_effect
			       ,deldaily.contract_sign_date
			       ,deldaily.new_start -- 现房源的最新收房起租日
			       ,deldaily.new_end -- 现房源的最新收房结束日
			       ,deldaily.valid_price
			       ,deldaily.dt -- 日期指示器
			       ,MIN(deldaily.chu_start_date)                                                                         AS first_out_start -- 房源编号下首次出房起租日
			       ,MAX(case WHEN deldaily.chu_start_date <= deldaily.dt THEN deldaily.chu_start_date end)               AS last_out_start --房源编号下最近一次出房起租日
			       ,MAX(case WHEN deldaily.chu_end_date <= deldaily.dt THEN deldaily.chu_end_date end)                   AS last_out_end -- 房源编号下最近一次出房结束日
			       ,COUNT(distinct CASE WHEN deldaily.chu_start_date <= deldaily.dt THEN deldaily.chu_contract_code end) AS chu_start_token -- 日期指示器前的出房起租次数
			       ,COUNT(distinct CASE WHEN deldaily.chu_end_date < deldaily.dt THEN deldaily.chu_contract_code end)    AS chu_end_token -- 日期指示器前的出房结束次数
			       ,if(COUNT(distinct CASE WHEN deldaily.chu_start_date <= deldaily.dt THEN deldaily.chu_contract_code end) > COUNT(distinct CASE WHEN deldaily.chu_end_date < deldaily.dt THEN deldaily.chu_contract_code end),'在租','不在租') AS is_chu1 --若结束次数小于起始次数，则说明在出租中
			       ,SUM(case WHEN deldaily.is_effect = 1 THEN nvl(deldaily.is_chu,0) else 0 end)                         AS is_chu -- 房源起租且任意一段出房的is_chu = 1则表明在出租中
			       ,SUM(case WHEN deldaily.is_effect = 1 AND deldaily.is_chu = 1 THEN deldaily.chu_price else 0 end)     AS chuprice -- 房源起租且任意一段出房的is_chu = 1则表明在出租中
			       ,MAX(case WHEN deldaily.is_effect = 1 AND deldaily.is_chu = 1 THEN deldaily.chu_cdate else 0 end)     AS chu_cdate
			       ,MAX(case WHEN deldaily.is_effect = 1 AND deldaily.is_chu = 1 THEN deldaily.chu_end_date else 0 end)  AS chu_end_date
			FROM
			(
				SELECT  base.del_code
				       ,base.contract_code
				       ,base.rent_unit_status_name
				       ,base.contract_sign_date
				       ,base.new_start
				       ,base.new_end
				       ,base.valid_price
				       ,base.dt
				       ,CASE WHEN base.dt BETWEEN base.new_start AND base.new_end THEN 1  ELSE 0 END         AS is_effect
				       ,chu.contract_status_name
				       ,chu.chu_start_date
				       ,chu.chu_end_date
				       ,chu.sign_price                                                                       AS chu_price
				       ,chu.contract_code                                                                    AS chu_contract_code
				       ,chu.chu_cdate
				       ,CASE WHEN base.dt BETWEEN chu.chu_start_date AND chu.chu_end_date THEN 1  ELSE 0 END AS is_chu
				FROM
				(
					SELECT  *
					FROM
					(
						SELECT  trusteeship_housedel_code                                                                                                            AS del_code
						       ,contract_code
						       ,effect_start_date
						       ,effect_end_date
						       ,CASE WHEN rent_unit_status_name = '未知' THEN '装配中'  ELSE rent_unit_status_name END                                                    AS rent_unit_status_name
						       ,to_date(contract_sign_time)                                                                                                          AS contract_sign_date
						       ,pt
						       ,concat_ws('-',substr(pt,1,4),substr(pt,5,2) ,substr(pt,7,2))                                                                         AS dt
						       ,first_value(effect_start_date) over (partition by trusteeship_housedel_code ORDER BY pt desc)                                        AS new_start
						       ,first_value(effect_end_date) over (partition by trusteeship_housedel_code ORDER BY pt desc)                                          AS new_end
						       ,CASE WHEN expected_profits2 is not null AND expected_profits2 < expected_profits1 THEN expected_profits1  ELSE expected_profits2 END AS valid_price
						       ,row_number() over(partition by trusteeship_housedel_code,pt ORDER BY contract_sign_time desc)                                        AS rn
						FROM olap.olap_trusteeship_hdel_housein_da
						WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
						AND city_code = 310000
						AND contract_status_name = '已签约'
						AND to_date(effect_start_date) <= date_add(CURRENT_DATE, -1) 
					) AS adj
					WHERE adj.rn = 1 
				) AS base
				LEFT JOIN
				(
					SELECT  trusteeship_housedel_code                                                AS del_code
					       ,contract_code
					       ,contract_status_name
					       ,to_date(contract_sign_time)                                              AS chu_cdate
					       ,agent_ucid
					       ,effect_start_date                                                        AS chu_start_date
					       ,effect_end_date
					       ,sign_price
					       ,revoke_type -- 1:到期解约 2:租客违约 3:公司违约
					       ,back_date
					       ,CASE WHEN back_date is not null THEN back_date  ELSE effect_end_date END AS chu_end_date
					       ,housein_contract_code
					       ,housein_effect_start_date
					       ,housein_effect_end_date
					FROM olap.olap_trusteeship_hdel_houseout_da
					WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
					AND city_code = 310000
					AND contract_status_code IN (2, 3, 4, 5) 
				) AS chu
				ON base.del_code = chu.del_code
			) AS deldaily
			WHERE deldaily.dt >= deldaily.new_start
			GROUP BY  deldaily.del_code
			         ,deldaily.contract_code
			         ,deldaily.rent_unit_status_name
			         ,deldaily.is_effect
			         ,deldaily.contract_sign_date
			         ,deldaily.new_start
			         ,deldaily.new_end
			         ,deldaily.valid_price
			         ,deldaily.dt
		) AS detail
	) AS dailystatus
	ON trusteehouse_in1.del_code = dailystatus.del_code
	GROUP BY  emp.partname
) AS basic_info
ON basic_info.partname = emp.partname
LEFT JOIN
(
	SELECT  holder.region_name
	       ,holder.partname
	       ,holder.employee_name
	       ,holder.employee_no
	       ,holder.job_name
	       ,CASE WHEN ( COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 15 AND 29 THEN trusteehouse_in1.del_code END)*0.5 + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi >= 30 THEN trusteehouse_in1.del_code END)) > 1 AND (COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 15 AND 29 THEN trusteehouse_in1.del_code END)*0.5 + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi >= 30 THEN trusteehouse_in1.del_code END))/COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND trusteehouse_in1.effect_start_date <= date_add(CURRENT_DATE,-1) THEN trusteehouse_in1.del_code END) >= 0.5 THEN 1
	             WHEN ( COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 7 AND 14 THEN trusteehouse_in1.del_code END) * 0.5 + (COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 15 AND 29 THEN trusteehouse_in1.del_code END) - COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 23 AND 29 THEN trusteehouse_in1.del_code END))*0.5 + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 23 AND 29 THEN trusteehouse_in1.del_code END) + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi >= 30 THEN trusteehouse_in1.del_code END) ) > 1 AND ( COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 7 AND 14 THEN trusteehouse_in1.del_code END) * 0.5 + (COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 15 AND 29 THEN trusteehouse_in1.del_code END) - COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 23 AND 29 THEN trusteehouse_in1.del_code END))*0.5 + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi BETWEEN 23 AND 29 THEN trusteehouse_in1.del_code END) + COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND dailystatus.last_kongzhi >= 30 THEN trusteehouse_in1.del_code END)) /COUNT(distinct CASE
	             WHEN trusteehouse_in1.protocol_type <> '无忧' AND trusteehouse_in1.rent_unit_status_name <> '已出租' AND trusteehouse_in1.effect_start_date <= date_add(CURRENT_DATE,-1) THEN trusteehouse_in1.del_code END) >= 0.5 THEN 0.5  ELSE 0 END AS flag
	FROM
	(
		SELECT  *
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
			       ,sign_name
			       ,sign_marketing_name
			       ,sign_area_name
			       ,customer_code
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
			AND to_date(effect_start_date) <= date_add(CURRENT_DATE, 14) 
		) AS adj
		WHERE adj.rn = 1 
	) AS trusteehouse_in1
	LEFT JOIN
	(
		SELECT  CASE WHEN shop_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
		             WHEN shop_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
		       ,CASE WHEN shop_name like '%豪宅%' THEN '链家豪宅事业部'  ELSE shop_name END                                      AS region_name
		       ,CASE WHEN shop_name like '%豪宅%' THEN regexp_replace(team_name,'大区','区')
		             WHEN team_name = '明珠大区' THEN '陆家嘴大区'
		             WHEN team_name = '普陀东大区' THEN '武宁大区'
		             WHEN team_name = '大华东大区' THEN '万华大区'  ELSE team_name END                                           AS partname
		       ,employee_name
		       ,employee_no
		       ,employee_ucid
		       ,position_name                                                                                           AS job_name
		FROM rpt.rpt_comm_employee_info_da
		WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
		AND on_job_status = '在职在岗'
		AND position_name IN ('资管区域经理', '资管经理')
		AND city_code = 310000 
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
	ON trusteehouse_in1.manager_no = holder.employee_no
	LEFT JOIN
	(
		SELECT  distinct corp_name
		       ,CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'  ELSE '租赁西大部' END AS dabu
		       ,region_name
		       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                    AS partname
		FROM rpt.rpt_comm_employee_info_da
		WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
		AND corp_name = '上海链家' --限制上海链家
		AND (region_name LIKE'%沪%' OR region_name LIKE'%豪宅%')
		AND on_job_status_code = '170007002' --在职
		AND job_category_name like '%经纪人%' --限制经纪人
		AND team_name NOT like '%租赁业务%'
		AND team_name NOT like '%新房业务%'
		AND region_name not like '%新房%'
		AND marketing_name not like '%新房%'
		AND marketing_name <> ''
		AND area_name <> ''
		AND data_source <> 'uc' -- 剔除兼岗 
	)emp
	ON holder.partname = emp.partname
	LEFT JOIN
	(
		SELECT  detail.del_code
		       ,detail.contract_code
		       ,detail.rent_unit_status_name
		       ,detail.is_effect
		       ,detail.contract_sign_date
		       ,detail.new_start
		       ,detail.new_end
		       ,detail.valid_price
		       ,detail.dt
		       ,CASE WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END AS last_kongzhi -- 如果有上一次去化，则去化结束时间-日期指示器，若无，则收房起租日-时间指示器+1
		       ,CASE WHEN detail.is_effect = 1 AND detail.is_chu = 1 AND detail.last_out_end is not null THEN DATEDIFF(detail.last_out_start,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 1 AND detail.last_out_end is null THEN DATEDIFF(detail.last_out_start,detail.new_start)+1 END AS last_quhua -- 如果有上一次去化，则去化结束时间-日期指示器，若无，则收房起租日-时间指示器+1
		       ,CASE WHEN (CASE
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END) <= 7 THEN '0-7天'
		             WHEN (CASE
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END) BETWEEN 8 AND 14 THEN '8-14天'
		             WHEN (CASE
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END) BETWEEN 15 AND 29 THEN '15-29天'
		             WHEN (CASE
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is not null THEN DATEDIFF(detail.dt,detail.last_out_end)
		             WHEN detail.is_effect = 1 AND detail.is_chu = 0 AND detail.last_out_end is null THEN DATEDIFF(detail.dt,detail.new_start)+1 END) >= 30 THEN '30+天' END AS last_kongzhi_cat
		       ,detail.first_out_start
		       ,detail.last_out_start
		       ,detail.last_out_end
		       ,detail.chu_start_token
		       ,detail.chu_end_token
		       ,detail.is_chu1
		       ,detail.is_chu
		       ,detail.chuprice
		       ,detail.chu_cdate
		       ,detail.chu_end_date
		FROM
		(
			SELECT  deldaily.del_code
			       ,deldaily.contract_code
			       ,deldaily.rent_unit_status_name
			       ,deldaily.is_effect
			       ,deldaily.contract_sign_date
			       ,deldaily.new_start -- 现房源的最新收房起租日
			       ,deldaily.new_end -- 现房源的最新收房结束日
			       ,deldaily.valid_price
			       ,deldaily.dt -- 日期指示器
			       ,MIN(deldaily.chu_start_date)                                                                         AS first_out_start -- 房源编号下首次出房起租日
			       ,MAX(case WHEN deldaily.chu_start_date <= deldaily.dt THEN deldaily.chu_start_date end)               AS last_out_start --房源编号下最近一次出房起租日
			       ,MAX(case WHEN deldaily.chu_end_date <= deldaily.dt THEN deldaily.chu_end_date end)                   AS last_out_end -- 房源编号下最近一次出房结束日
			       ,COUNT(distinct CASE WHEN deldaily.chu_start_date <= deldaily.dt THEN deldaily.chu_contract_code end) AS chu_start_token -- 日期指示器前的出房起租次数
			       ,COUNT(distinct CASE WHEN deldaily.chu_end_date < deldaily.dt THEN deldaily.chu_contract_code end)    AS chu_end_token -- 日期指示器前的出房结束次数
			       ,if(COUNT(distinct CASE WHEN deldaily.chu_start_date <= deldaily.dt THEN deldaily.chu_contract_code end) > COUNT(distinct CASE WHEN deldaily.chu_end_date < deldaily.dt THEN deldaily.chu_contract_code end),'在租','不在租') AS is_chu1 --若结束次数小于起始次数，则说明在出租中
			       ,SUM(case WHEN deldaily.is_effect = 1 THEN nvl(deldaily.is_chu,0) else 0 end)                         AS is_chu -- 房源起租且任意一段出房的is_chu = 1则表明在出租中
			       ,SUM(case WHEN deldaily.is_effect = 1 AND deldaily.is_chu = 1 THEN deldaily.chu_price else 0 end)     AS chuprice -- 房源起租且任意一段出房的is_chu = 1则表明在出租中
			       ,MAX(case WHEN deldaily.is_effect = 1 AND deldaily.is_chu = 1 THEN deldaily.chu_cdate else 0 end)     AS chu_cdate
			       ,MAX(case WHEN deldaily.is_effect = 1 AND deldaily.is_chu = 1 THEN deldaily.chu_end_date else 0 end)  AS chu_end_date
			FROM
			(
				SELECT  base.del_code
				       ,base.contract_code
				       ,base.rent_unit_status_name
				       ,base.contract_sign_date
				       ,base.new_start
				       ,base.new_end
				       ,base.valid_price
				       ,base.dt
				       ,CASE WHEN base.dt BETWEEN base.new_start AND base.new_end THEN 1  ELSE 0 END         AS is_effect
				       ,chu.contract_status_name
				       ,chu.chu_start_date
				       ,chu.chu_end_date
				       ,chu.sign_price                                                                       AS chu_price
				       ,chu.contract_code                                                                    AS chu_contract_code
				       ,chu.chu_cdate
				       ,CASE WHEN base.dt BETWEEN chu.chu_start_date AND chu.chu_end_date THEN 1  ELSE 0 END AS is_chu
				FROM
				(
					SELECT  *
					FROM
					(
						SELECT  trusteeship_housedel_code                                                                                                            AS del_code
						       ,contract_code
						       ,effect_start_date
						       ,effect_end_date
						       ,CASE WHEN rent_unit_status_name = '未知' THEN '装配中'  ELSE rent_unit_status_name END                                                    AS rent_unit_status_name
						       ,to_date(contract_sign_time)                                                                                                          AS contract_sign_date
						       ,pt
						       ,concat_ws('-',substr(pt,1,4),substr(pt,5,2) ,substr(pt,7,2))                                                                         AS dt
						       ,first_value(effect_start_date) over (partition by trusteeship_housedel_code ORDER BY pt desc)                                        AS new_start
						       ,first_value(effect_end_date) over (partition by trusteeship_housedel_code ORDER BY pt desc)                                          AS new_end
						       ,CASE WHEN expected_profits2 is not null AND expected_profits2 < expected_profits1 THEN expected_profits1  ELSE expected_profits2 END AS valid_price
						       ,row_number() over(partition by trusteeship_housedel_code,pt ORDER BY contract_sign_time desc)                                        AS rn
						FROM olap.olap_trusteeship_hdel_housein_da
						WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
						AND city_code = 310000
						AND contract_status_name = '已签约'
						AND to_date(effect_start_date) <= date_add(CURRENT_DATE, -1) 
					) AS adj
					WHERE adj.rn = 1 
				) AS base
				LEFT JOIN
				(
					SELECT  trusteeship_housedel_code                                                AS del_code
					       ,contract_code
					       ,contract_status_name
					       ,to_date(contract_sign_time)                                              AS chu_cdate
					       ,agent_ucid
					       ,effect_start_date                                                        AS chu_start_date
					       ,effect_end_date
					       ,sign_price
					       ,revoke_type -- 1:到期解约 2:租客违约 3:公司违约
					       ,back_date
					       ,CASE WHEN back_date is not null THEN back_date  ELSE effect_end_date END AS chu_end_date
					       ,housein_contract_code
					       ,housein_effect_start_date
					       ,housein_effect_end_date
					FROM olap.olap_trusteeship_hdel_houseout_da
					WHERE pt = concat(REGEXP_replace(date_add(CURRENT_DATE, -1), '-', ''), '000000')
					AND city_code = 310000
					AND contract_status_code IN (2, 3, 4, 5) 
				) AS chu
				ON base.del_code = chu.del_code
			) AS deldaily
			WHERE deldaily.dt >= deldaily.new_start
			GROUP BY  deldaily.del_code
			         ,deldaily.contract_code
			         ,deldaily.rent_unit_status_name
			         ,deldaily.is_effect
			         ,deldaily.contract_sign_date
			         ,deldaily.new_start
			         ,deldaily.new_end
			         ,deldaily.valid_price
			         ,deldaily.dt
		) AS detail
	) AS dailystatus
	ON trusteehouse_in1.del_code = dailystatus.del_code
	GROUP BY  holder.region_name
	         ,holder.partname
	         ,holder.employee_name
	         ,holder.employee_no
	         ,holder.job_name
) AS holder_detail
ON holder_detail.employee_no = emp.employee_no