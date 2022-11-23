--模板查询：运营官指标底表
SELECT  emp.corp_name                  AS `公司`
       ,emp.dabu                       AS `大部`
       ,emp.region_name                AS `事业部`
       ,emp.partname                   AS `大区`
       ,emp.employee_no                AS `工号`
       ,emp.employee_name              AS `姓名`
       ,nvl(t1.managed_house,0)        AS `在管房源`
       ,nvl(t2.shou_sign_price,0)      AS `平均收房价`
       ,nvl(t2.vacancy_days,0)         AS `平均免租期`
       ,nvl(t1.total_out,0)            AS `在管房源出房量`
       ,nvl(t1.one_price_rate,0)       AS `一口价率`
       ,nvl(t1.vacancy_house,0)        AS `空置量`
       ,nvl(t1.quhua,0)                AS `收房去化率`
       ,nvl(t1.over_15_vacancy,0)      AS `超15天空置房源量`
       ,nvl(t1.over_15_vacancy_rate,0) AS `超15天空置房源率`
       ,nvl(t1.over_30_vacancy,0)      AS `超30天空置房源量`
       ,nvl(t1.over_30_vacancy_rate,0) AS `超30天空置房源率`
       ,nvl(t1.remain_vacancy_days,0)  AS `平均剩余免租期`
       ,nvl(t1.vr_rate,0)              AS `VR率`
       ,nvl(t1.display_rate,0)         AS `外展率`
       ,nvl(t1.chu_cnt,0)              AS `出房量`
       ,nvl(t2.current_month_in,0)     AS `本月收房`
       ,nvl(t1.current_month_chu,0)    AS `本月出房`
       ,emp.position_alias             AS `职级`
       ,nvl(tf.tf_cnt,0)               AS `推房量`
       ,nvl(t2.shou_cnt,0)             AS `累计收房`
FROM
(-- 收房人
	SELECT  distinct corp_name
	       ,CASE WHEN region_name IN ('沪东事业部','沪东南事业部','沪南事业部','沪西南事业部','沪中事业部','沪中东事业部') THEN '租赁东大部'
	             WHEN region_name IN ('沪中西事业部','沪东北事业部','沪北事业部','沪西北事业部','沪中北事业部','链家豪宅事业部','沪西事业部') THEN '租赁西大部' END AS dabu
	       ,region_name
	       ,CASE WHEN region_name like '%豪宅%' THEN area_name  ELSE marketing_name END                                 AS partname
	       ,employee_no
	       ,employee_name
	       ,position_alias
	FROM rpt.rpt_comm_employee_info_da
	WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
	AND corp_name = '上海链家' --限制上海链家
	AND (region_name LIKE'%沪%' OR region_name LIKE'%豪宅%')
	AND on_job_status_code = '170007002' --在职 -- AND job_category_name like '%经纪人%' --限制经纪人
	AND team_name NOT like '%租赁业务%'
	AND team_name NOT like '%新房业务%'
	AND region_name not like '%新房%'
	AND employee_no IN ('26618406', '26617413', '26558411', '26506485', '29036320', '26622218', '28945104', '22246833', '26705733', '29194504', '26743218', '26608754', '29336606', '26798961', '29349132', '26582403', '29137813', '28784807', '22260778', '22278170', '26518707', '26727231', '26580293', '29299235', '26586109', '22222793', '26568921', '26744857', '29192448', '26505299', '22259192', '29237014', '29173863', '29138213', '26765089', '26556061', '22280538', '29304901', '20379406', '22279294', '29172430', '26792417', '22267507', '22274011', '28938470', '26514597', '26695909', '22259652', '29336506', '26713151', '26780648', '26520271', '26695837', '29169441', '22272669', '29125477', '29214549', '22277217', '29157637', '29030983', '22235029', '29113119', '29158751', '26691801', '26588547', '26709746', '22278268', '26667355', '26594964', '26682006', '29354234', '22271942', '22281965', '26801390', '29213370', '26731026', '26526105', '26721826', '26687745', '22281607', '29123775', '26714257', '26781050', '26612387', '26530781', '29267032', '22268831', '26748494', '26740543', '28944906', '26070360', '26510392', '22274221', '26543942', '26506579', '28818598', '22271521', '26648723', '22249136', '26742539', '26551288', '26568627', '22134237', '26631528', '22271748', '26520279', '22201109', '26658554', '26798119', '29222473', '22267597', '26566054', '29274177', '26668473', '26658247', '29179326', '26506446', '29214688', '26705299', '26739421', '28962655', '26505194', '26698286', '22230678', '22269093', '29158020', '28809173', '26707675', '29105259', '29341485', '26749516', '29288795', '22281163', '28998492', '29247776', '26683394', '22280574', '29350041', '26794848', '26718245', '29207993', '26740648', '26506510', '26724695', '26768406', '29341466', '26620281', '22280981', '26705814', '29285264', '26700675', '20321940', '29091986', '26679271', '29194443', '29157639', '26727009', '29248362', '29274113', '29250068', '26559584', '26526138', '26507225', '26595151', '26735978', '26568636', '28844478', '26749409', '22245208', '26791190', '26504638', '29030891', '26573784', '26714762', '26805382', '22228269', '26578962', '28854229', '26065103', '29153863', '26712108', '26734232', '26677084', '29291408', '26612368', '22279681', '29356404', '26679604', '26712101', '22242851', '26742514', '26680628', '26660468', '26734482', '26671018', '26747176', '26676390', '29251937', '26520490', '26749901', '26508017', '29003608', '26753416', '26514420', '26564215', '26782964', '26667362', '26528282', '26752557', '29198827', '28800501', '22264601', '28863089', '26781002', '26768559', '26798941', '22239031', '29157519', '29157645', '26713025', '26789106', '26752839', '29157523', '29153769', '26797701', '22252674', '29130577', '26672232', '26731070', '29293985', '26775094', '26541961', '26747080', '29161440', '22280595', '29349129', '26701596', '28851766', '26556049', '26708596', '22274090', '28851979', '26503216', '26746986', '26775036', '22213397', '29255980', '26768491', '26523716', '26517162', '29006729', '26787010', '22278266', '26751099', '29027226', '26033225', '26752064', '29031086', '29157455', '29195476', '29352016', '29179393', '29212984', '26696915', '29330587', '22241700', '29134894', '29146753', '26791276', '29027242', '29336393', '26718216', '26789952', '29027262', '29144127', '26780582', '29048511', '26717371', '26741963', '29019117', '28936573', '26752589', '29353013', '26559057', '26645957', '28872930', '26586087', '29225489', '29127773', '26765337', '26782212', '26637238', '26621244', '26631349', '22280015', '29351894', '26781257', '26747296', '29100598', '26565816', '26802523', '29182561', '26658806', '26741972', '26745699', '26585706', '26746264', '26514596', '26791156', '22278807', '26709929', '26599391', '22281221', '29248542', '26737334', '26737348', '28966940', '22269119', '26791091', '26612555', '26774983', '26588668', '26757068', '26805563', '26774445', '26802619', '26718963', '29248813', '29172550', '26747403', '26712967', '26799686', '26765341', '26799510', '26700194', '29146578', '29030976', '26682864', '26780570', '22277576', '26602807', '26759745', '26661388', '26673141', '22270917', '26775126', '26505164', '26719883', '28835928', '29086342', '26636301', '29029395', '28835594', '26761772', '22279175', '26546170', '26792735', '26507555', '29288914', '29157497', '26573175', '26766576', '26721472', '26701573', '28844283', '22256472', '26649735', '29358572', '29182708', '29328525', '20298644', '26756243', '29204443', '29291438', '29349120', '26608693', '22272401', '26620286', '29022580', '26751984', '26668754', '29135066', '29334466', '29030939', '26535029', '26504852', '28802050', '29048568', '29201569', '29112808', '29355951', '29026599', '22280130', '22280112', '29146456', '26506454', '26535062', '26719763', '28916828', '28918329', '26675821', '29239436', '26752556', '29134940', '29191331', '29158134', '26734043', '26752015', '26730112', '26591978', '29338970', '29209200', '26520502', '26777699', '26705285', '26748047', '26752564', '29273780', '28784700', '26782336', '29146565', '29030868', '26700572', '26754931', '29214699', '26758247', '22228354', '26641535', '26727119', '26768512', '26757762', '26741908', '29328476', '26660397', '26748251', '22257212', '26556723', '28801229', '26598888', '26757868', '26697125', '29113045', '26696948', '29344110', '26731567', '26730975', '26671839', '26575534', '26619221', '22210589', '26572916', '26697544', '28886924', '26513122', '29207987', '26749494', '29242067', '29153041', '26671837', '29216231', '29228845', '29358302', '26750163', '26517090', '22281755', '29272331', '26545645', '28932543', '29192576', '26705396', '26782278', '26682825', '28921425', '26778758', '26757077', '29358441', '26798849', '26667219', '26791106', '28945728', '26565976', '29108875', '26694406', '29351546', '26599140', '26634987', '26705727', '22254961', '26724347', '29307241', '26785803', '26621724', '29350690', '26516912', '26757090', '26797713', '26690375', '22260073', '26774936', '26510432', '26558419', '26776093', '29048230', '26512563', '26724335', '26624489', '22268041', '26518068', '26695860', '26803822', '29146756', '22268591', '26785671', '26759653', '26560412', '26700699', '22275387', '26605647', '28978470', '22273885', '29228628', '26782258', '28926763', '26684541', '29191002', '26724321', '29349130', '26704503', '26717398', '22244897', '26727234', '26568775', '29212919', '26507521', '26505548', '26730064', '26669277', '26506934', '26560393', '26659154', '29222716', '26517745', '26746947', '26623018', '29149840', '26501578', '26722705', '26798825', '22271673', '29317665', '26751008', '28854182', '26522761', '22271964', '26661649', '26679759', '26521921', '26519730', '26529625', '26802635', '26776504', '26675871', '29350986', '26763817', '26745042', '29119833', '26727225', '29209005', '26690316', '29198883', '28802165', '29352205', '26775043', '26607531', '26751976', '29219551', '28784666', '26709860', '22281800', '26529669', '26526183', '26598857', '26596349', '26797567', '26620272', '26776020', '26727134', '26727135', '22278157', '26569769', '26682876', '22193376', '26508773', '28971095', '26675411', '26718844', '26798150', '26758432', '22259320', '26591178', '22281835', '29349424', '29138655', '28938202', '26583317', '26513551', '23025477', '26746499', '29150344', '26649896', '22273614', '26649753', '26777803', '26692219', '29321986', '29199185', '26773453', '29030086', '26775202', '26520818', '29139074', '26532758', '28890003', '29261268', '26572920', '22281723', '28869524', '22270932', '26598877', '26776935', '29169410', '26712584', '26711342', '26512705', '26727794', '26598780', '26767885', '26507243', '22274122', '26675056', '26518158', '29105463', '29219661', '29383503', '26716142', '29044537', '26762630', '29166191', '26676993', '26510568', '26505917', '22126328', '26806833', '22248751', '26664906', '29377140', '22274514', '28975032', '26770183', '29363216', '26776216', '28801964', '26702991', '26747957', '29381336', '29258352', '26659262', '29362616', '29354599', '29343574', '26739499', '22257301', '26768407', '29364927', '29383871', '29127593', '29364169', '29356069', '29153184', '29294039', '26789864', '29377252', '26745613', '29134920', '29355532', '26626877', '26711926', '29349548', '28854185', '26518168', '26516051', '26633291', '29252030', '29337609', '26777708', '29198012', '29276904', '26774904', '29361940', '23110708', '29383535', '28922014', '29363274', '26775008', '26727906', '29376559', '26782322', '29157426', '26796080', '26782352', '29359399', '26782331', '29320805', '29390119', '29245374', '26687581', '28802007', '29214585', '27496416', '29285124', '29357016', '26798828', '26777768', '29310340', '29225536', '29175833', '27584802', '29376431', '29138533', '29378245', '29378772', '29361821', '29288829', '29171161', '26530355', '29044825', '29354093', '26798961', '22259292', '29125425', '26536846', '26773348', '29320707', '29201373', '29157567', '29130614', '26806092', '26701179', '22275865', '28987637', '26508788', '26583334', '26505193', '26740685', '26774912', '28971518', '28795333', '29233758', '26775054', '29353481', '26765376', '26694373', '26780557', '29379844', '22272712', '28813164', '26786635', '26620288', '26589980', '22281362', '26796079', '29119691', '29361792', '29386290', '29396041', '29187096', '29135363', '29384860', '26705823', '29146472', '29158208', '26635049', '29288848', '28859033', '28800658', '29165020', '26787225', '28921735', '26784366', '29003664', '29386350', '26764206', '29263645', '26798783', '26778612', '29341282', '29157115', '26758805', '28796329', '26783108', '26734507', '29328606', '29384002', '26780864', '29158449', '26505916', '28784711', '29157989', '29377322', '26776776' ) 
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
	       ,sum(sxz.standard_housein) + sum(sxz.delayed_housein)   as current_month_in
	       ,AVG(sxz.shou_sign_price)                  AS shou_sign_price -- 平均收房价
	       ,AVG(sxz.vacancy_days/(sxz.sign_days/365)) AS vacancy_days -- 平均免租期
	FROM
	(
		SELECT  DISTINCT table1.employee_no -- 合同创建人
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
			   ,table1.delayed_housein
			   ,table1.standard_housein
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
				   ,IF(substr(trunc(shou.contract_sign_time,'MM'),1,7) BETWEEN '2022-05' AND substr(trunc(add_months(date_sub(current_date,1),-1),"MM"),1,7) AND trunc(shou.effect_start_date,"MM") = trunc(add_months(date_sub(current_date,1),1),"MM") AND shou1.sub_biz_type = '续约合同' AND housein.protocol_type != '无忧',1,0) AS delayed_housein 
				   ,CASE WHEN housein.protocol_type != '无忧' AND to_date(shou.contract_sign_time) BETWEEN trunc(date_sub(current_date,1),"MM") AND date_sub(current_date,1) AND (shou.effect_start_date <= last_day(add_months(date_sub(current_date,1),1)) or shou1.sub_biz_type = '标准合同') THEN 1 WHEN housein.protocol_type = '无忧' AND (to_date(chu.chu_contract_sign_time) between trunc(date_sub(current_date,1),"MM") AND date_sub(current_date,1)) THEN 1 ELSE 0 END AS standard_housein
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
			LEFT JOIN
			(
				SELECT  trusteeship_housedel_code
					,protocol_type
				FROM olap.olap_trusteeship_hdel_housein_da
				WHERE pt = concat(regexp_replace(date_sub(current_date(), 1), '-', ''), '000000')
				AND city_code = '310000' 
			)housein
			ON shou.del_code = housein.trusteeship_housedel_code
			LEFT JOIN
			(-- 出房
				SELECT  del_code
					,broker_no -- 出房人
					,contract_code
					,contract_sign_time  as chu_contract_sign_time
					,contract_sign_date
					,effect_start_date   as chu_effect_start_date
				FROM
				(
					SELECT  del_code
						,substr(contract_created_uc_id,9,8)                                         AS broker_no
						,contract_code
						,row_number() over (partition by del_code ORDER BY contract_sign_time desc) AS num
						,contract_sign_time
						,to_date(contract_sign_time)                                                AS contract_sign_date
						,effect_start_date
					FROM olap.olap_trusteeship_house_out_dwd_da
					WHERE pt = concat(REGEXP_replace(date_sub(current_date(), 1), '-', ''), '000000')
					AND contract_status = 2
					AND contract_city_code = '310000'
					-- AND to_date(contract_sign_time) BETWEEN trunc(date_add(CURRENT_DATE, -1), 'MM') AND date_add(CURRENT_DATE, -1) 
				) tp2
				WHERE tp2.num = 1 
			) chu
			ON shou.del_code = chu.del_code
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
		   ,COUNT(distinct case when t.del_status = 2 THEN t.trusteeship_housedel_code else null end)                                         AS tg_cnt
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