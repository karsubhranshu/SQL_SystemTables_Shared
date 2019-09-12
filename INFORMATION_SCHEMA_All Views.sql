SELECT OBJECT_DEFINITION(OBJECT_ID('<View Name>'))


/*************************************Logic For INFORMATION_SCHEMA.CHECK_CONSTRAINTS********************************/
CREATE VIEW INFORMATION_SCHEMA.CHECK_CONSTRAINTS AS
SELECT DB_NAME() AS CONSTRAINT_CATALOG
	,SCHEMA_NAME(schema_id) AS CONSTRAINT_SCHEMA
	,name AS CONSTRAINT_NAME
	,CONVERT(NVARCHAR(4000), definition) AS CHECK_CLAUSE
FROM   sys.check_constraints  
/*************************************Logic For INFORMATION_SCHEMA.CHECK_CONSTRAINTS********************************/



/*************************************Logic For INFORMATION_SCHEMA.COLUMN_DOMAIN_USAGE********************************/
CREATE VIEW INFORMATION_SCHEMA.COLUMN_DOMAIN_USAGE AS
SELECT DB_NAME() AS DOMAIN_CATALOG
	,SCHEMA_NAME(t.schema_id) AS DOMAIN_SCHEMA
	,t.name AS DOMAIN_NAME
	,DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(o.schema_id) AS TABLE_SCHEMA
	,o.name AS TABLE_NAME
	,c.name AS COLUMN_NAME
FROM sys.objects o
JOIN sys.columns c ON c.object_id = o.object_id
JOIN sys.types t ON t.user_type_id = c.user_type_id
WHERE c.user_type_id > 256 -- UDT  
/*************************************Logic For INFORMATION_SCHEMA.COLUMN_DOMAIN_USAGE********************************/



/*************************************Logic For INFORMATION_SCHEMA.COLUMN_PRIVILEGES********************************/
CREATE VIEW INFORMATION_SCHEMA.COLUMN_PRIVILEGES AS
SELECT USER_NAME(p.grantor_principal_id) AS GRANTOR
	,USER_NAME(p.grantee_principal_id) AS GRANTEE
	,DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(o.schema_id) AS TABLE_SCHEMA
	,o.name AS TABLE_NAME
	,c.name AS COLUMN_NAME
	,convert(varchar(10), CASE p.type WHEN 'SL' THEN 'SELECT' WHEN 'UP' THEN 'UPDATE' WHEN 'RF' THEN 'REFERENCES' END) AS PRIVILEGE_TYPE
	,convert(varchar(3), CASE p.state WHEN 'G' THEN 'NO' WHEN 'W' THEN 'YES' END) AS IS_GRANTABLE 
FROM sys.database_permissions p
,sys.objects o
,sys.columns c
WHERE o.type IN ('U', 'V')
	AND o.object_id = c.object_id
	AND p.class = 1
	AND p.major_id = o.object_id
	AND p.minor_id = c.column_id
	AND p.type IN ('RF','SL','UP')
	AND p.state IN ('G', 'W')
	AND (
		p.grantee_principal_id = 0
		OR p.grantee_principal_id = DATABASE_PRINCIPAL_ID()
		OR p.grantor_principal_id = DATABASE_PRINCIPAL_ID()
		)
/*************************************Logic For INFORMATION_SCHEMA.COLUMN_PRIVILEGES********************************/



/*************************************Logic For INFORMATION_SCHEMA.COLUMNS********************************/
CREATE VIEW INFORMATION_SCHEMA.COLUMNS AS
SELECT DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(o.schema_id) AS TABLE_SCHEMA
	,o.name AS TABLE_NAME
	,c.name AS COLUMN_NAME
	,ColumnProperty(c.object_id, c.name, 'ordinal')  AS ORDINAL_POSITION
	,convert(nvarchar(4000)
	,object_definition(c.default_object_id)) AS COLUMN_DEFAULT
	,convert(varchar(3), CASE c.is_nullable WHEN 1 THEN 'YES' ELSE 'NO' END) AS IS_NULLABLE
	,ISNULL(type_name(c.system_type_id), t.name) AS DATA_TYPE
	,ColumnProperty(c.object_id, c.name, 'charmaxlen') AS CHARACTER_MAXIMUM_LENGTH
	,ColumnProperty(c.object_id, c.name, 'octetmaxlen') AS CHARACTER_OCTET_LENGTH
	,convert(tinyint, CASE --int/decimal/numeric/real/float/money 
					WHEN c.system_type_id IN (48, 52, 56, 59, 60, 62, 106, 108, 122, 127) THEN c.precision END) AS NUMERIC_PRECISION
	,convert(smallint, CASE -- int/money/decimal/numeric
					WHEN c.system_type_id IN (48, 52, 56, 60, 106, 108, 122, 127) THEN 10
					WHEN c.system_type_id IN (59, 62) THEN 2 END) AS NUMERIC_PRECISION_RADIX
	,-- real/float
	convert(int, CASE -- datetime/smalldatetime
				WHEN c.system_type_id IN (40, 41, 42, 43, 58, 61) THEN NULL	ELSE odbcscale(c.system_type_id, c.scale) END) AS NUMERIC_SCALE
	,convert(smallint, CASE -- datetime/smalldatetime
				WHEN c.system_type_id IN (40, 41, 42, 43, 58, 61) THEN odbcscale(c.system_type_id, c.scale) END) AS DATETIME_PRECISION
	,convert(sysname, null) AS CHARACTER_SET_CATALOG
	,convert(sysname, null) AS CHARACTER_SET_SCHEMA
	,convert(sysname, CASE WHEN c.system_type_id IN (35, 167, 175) -- char/varchar/text
						THEN CollationProperty(c.collation_name, 'sqlcharsetname')
					WHEN c.system_type_id IN (99, 231, 239) -- nchar/nvarchar/ntext
						THEN N'UNICODE' END) AS CHARACTER_SET_NAME
	,convert(sysname, null) AS COLLATION_CATALOG
	,convert(sysname, null) AS COLLATION_SCHEMA
	,c.collation_name AS COLLATION_NAME
	,convert(sysname, CASE WHEN c.user_type_id > 256 THEN DB_NAME() END) AS DOMAIN_CATALOG
	,convert(sysname, CASE WHEN c.user_type_id > 256 THEN SCHEMA_NAME(t.schema_id) END) AS DOMAIN_SCHEMA
	,   convert(sysname, CASE WHEN c.user_type_id > 256 THEN type_name(c.user_type_id) END) AS DOMAIN_NAME
FROM sys.objects o
JOIN sys.columns c ON c.object_id = o.object_id
LEFT JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE   o.type IN ('U', 'V')
/*************************************Logic For INFORMATION_SCHEMA.COLUMNS********************************/



/*************************************Logic For INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE********************************/
CREATE VIEW INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE AS
SELECT KCU.TABLE_CATALOG
	,KCU.TABLE_SCHEMA
	,KCU.TABLE_NAME
	,KCU.COLUMN_NAME
	,KCU.CONSTRAINT_CATALOG
	,KCU.CONSTRAINT_SCHEMA
	,KCU.CONSTRAINT_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE KCU
UNION ALL
SELECT DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(u.schema_id) AS TABLE_SCHEMA
	,u.name AS TABLE_NAME
	,col_name(d.referenced_major_id, d.referenced_minor_id) AS COLUMN_NAME
	,DB_NAME() AS CONSTRAINT_CATALOG
	,SCHEMA_NAME(k.schema_id) AS CONSTRAINT_SCHEMA
	,k.name AS CONSTRAINT_NAME
FROM sys.check_constraints k
JOIN sys.objects u ON u.object_id = k.parent_object_id
JOIN sys.sql_dependencies d ON d.class = 1
	AND d.object_id = k.object_id
	AND d.column_id = 0
	AND d.referenced_major_id = u.object_id
WHERE u.type <> 'TF' -- skip constraints in TVFs.
UNION ALL
SELECT DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(t.schema_id) AS TABLE_SCHEMA
	,t.name AS TABLE_NAME
	,col_name(f.object_id, f.column_id) AS COLUMN_NAME
	,DB_NAME() AS CONSTRAINT_CATALOG
	,SCHEMA_NAME(r.schema_id) AS CONSTRAINT_SCHEMA
	,r.name AS CONSTRAINT_NAME
FROM sys.objects t
JOIN sys.columns f ON f.object_id = t.object_id
JOIN sys.objects r ON r.object_id = f.rule_object_id
/*************************************Logic For INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE********************************/



/*************************************Logic For INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE********************************/
CREATE VIEW INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE AS
SELECT DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(t.schema_id) AS TABLE_SCHEMA
	,t.name AS TABLE_NAME
	,DB_NAME() AS CONSTRAINT_CATALOG
	,SCHEMA_NAME(c.schema_id) AS CONSTRAINT_SCHEMA
	,c.name AS CONSTRAINT_NAME
FROM sys.objects c
JOIN sys.tables t ON t.object_id = c.parent_object_id
WHERE c.type IN ('C' ,'UQ' ,'PK' ,'F')
/*************************************Logic For INFORMATION_SCHEMA.CONSTRAINT_TABLE_USAGE********************************/



/*************************************Logic For INFORMATION_SCHEMA.DOMAIN_CONSTRAINTS********************************/
CREATE VIEW INFORMATION_SCHEMA.DOMAIN_CONSTRAINTS AS
SELECT DB_NAME() AS CONSTRAINT_CATALOG
	,SCHEMA_NAME(o.schema_id) AS CONSTRAINT_SCHEMA
	,o.name AS CONSTRAINT_NAME
	,DB_NAME() AS DOMAIN_CATALOG
	,SCHEMA_NAME(t.schema_id) AS DOMAIN_SCHEMA
	,t.name AS DOMAIN_NAME
	,'NO' AS IS_DEFERRABLE
	,'NO' AS INITIALLY_DEFERRED
FROM sys.types t
JOIN sys.objects o ON o.object_id = t.rule_object_id
WHERE t.user_type_id > 256
/*************************************Logic For INFORMATION_SCHEMA.DOMAIN_CONSTRAINTS********************************/



/*************************************Logic For INFORMATION_SCHEMA.DOMAINS********************************/
CREATE VIEW INFORMATION_SCHEMA.DOMAINS AS
SELECT DB_NAME() AS DOMAIN_CATALOG
	,SCHEMA_NAME(schema_id) AS DOMAIN_SCHEMA
	,name AS DOMAIN_NAME
	,type_name(system_type_id) AS DATA_TYPE
	,convert(int, TypePropertyEx(user_type_id, 'charmaxlen')) AS CHARACTER_MAXIMUM_LENGTH
	,convert(int, TypePropertyEx(user_type_id, 'octetmaxlen')) AS CHARACTER_OCTET_LENGTH
	,convert(sysname, null) AS COLLATION_CATALOG
	,convert(sysname, null) AS COLLATION_SCHEMA
	,collation_name AS COLLATION_NAME
	,convert(sysname, null) AS CHARACTER_SET_CATALOG
	,convert(sysname, null) AS CHARACTER_SET_SCHEMA
	,convert(sysname, CASE WHEN system_type_id IN (35, 167, 175) THEN ServerProperty('sqlcharsetname') -- char/varchar/text
						   WHEN system_type_id IN (99, 231, 239) THEN N'UNICODE' END) AS CHARACTER_SET_NAME
	,-- nchar/nvarchar/ntext
	convert(tinyint, CASE -- int/decimal/numeric/real/float/money
		WHEN system_type_id IN (48, 52, 56, 59, 60, 62, 106, 108, 122, 127) THEN precision END) AS NUMERIC_PRECISION
	,convert(smallint, CASE -- int/money/decimal/numeric
		WHEN system_type_id IN (48, 52, 56, 60, 106, 108, 122, 127) THEN 10 
		WHEN system_type_id IN (59, 62) THEN 2 END) AS NUMERIC_PRECISION_RADIX
	,convert(int, CASE -- datetime/smalldatetime
		WHEN system_type_id IN (40, 41, 42, 43, 58, 61) THEN NULL 
		ELSE odbcscale(system_type_id, scale) END) AS NUMERIC_SCALE
	,convert(smallint, CASE -- datetime/smalldatetime
		WHEN system_type_id IN (40, 41, 42, 43, 58, 61) THEN  odbcscale(system_type_id, scale) END) AS DATETIME_PRECISION
	,convert(nvarchar(4000), object_definition(default_object_id)) AS DOMAIN_DEFAULT
FROM sys.types
WHERE user_type_id > 256 -- UDT
/*************************************Logic For INFORMATION_SCHEMA.DOMAINS********************************/



/*************************************Logic For INFORMATION_SCHEMA.KEY_COLUMN_USAGE********************************/
CREATE VIEW information_schema.key_column_usage AS
SELECT Db_name() AS CONSTRAINT_CATALOG
	,Schema_name(f.schema_id) AS CONSTRAINT_SCHEMA
	,f.NAME AS CONSTRAINT_NAME
	,Db_name() AS TABLE_CATALOG
	,Schema_name(p.schema_id) AS TABLE_SCHEMA
	,p.NAME AS TABLE_NAME
	,Col_name(k.parent_object_id, k.parent_column_id) AS COLUMN_NAME
	,k.constraint_column_id AS ORDINAL_POSITION 
FROM sys.foreign_keys f 
JOIN sys.foreign_key_columns k ON k.constraint_object_id = f.object_id 
JOIN sys.tables p ON p.object_id = f.parent_object_id 
UNION 
SELECT Db_name() AS CONSTRAINT_CATALOG
	,Schema_name(k.schema_id) AS CONSTRAINT_SCHEMA
	,k.NAME  AS CONSTRAINT_NAME
	,Db_name() AS TABLE_CATALOG
	,Schema_name(t.schema_id) AS TABLE_SCHEMA
	,t.NAME AS TABLE_NAME
	,Col_name(c.object_id, c.column_id) AS COLUMN_NAME
	,c.key_ordinal AS ORDINAL_POSITION 
FROM   sys.key_constraints k 
JOIN sys.index_columns c ON c.object_id = k.parent_object_id 
	AND c.index_id = k.unique_index_id 
JOIN sys.tables t ON t.object_id = k.parent_object_id 
/*************************************Logic For INFORMATION_SCHEMA.KEY_COLUMN_USAGE********************************/



/*************************************Logic For INFORMATION_SCHEMA.PARAMETERS********************************/
CREATE VIEW INFORMATION_SCHEMA.PARAMETERS AS
SELECT DB_NAME() AS SPECIFIC_CATALOG
	,SCHEMA_NAME(o.schema_id) AS SPECIFIC_SCHEMA
	,o.name AS SPECIFIC_NAME
	,c.parameter_id AS ORDINAL_POSITION
	,convert(nvarchar(10), CASE WHEN c.parameter_id = 0 THEN 'OUT' WHEN c.is_output = 1 THEN 'INOUT' ELSE 'IN' END) AS PARAMETER_MODE
	,convert(nvarchar(10), CASE WHEN c.parameter_id = 0 THEN 'YES' ELSE 'NO' END) AS IS_RESULT
	,convert(nvarchar(10), 'NO') AS AS_LOCATOR
	,c.name AS PARAMETER_NAME
	,ISNULL(type_name(c.system_type_id), u.name) AS DATA_TYPE
	,ColumnProperty(c.object_id, c.name, 'charmaxlen') AS CHARACTER_MAXIMUM_LENGTH
	,ColumnProperty(c.object_id, c.name, 'octetmaxlen') AS CHARACTER_OCTET_LENGTH
	,convert(sysname, null) AS COLLATION_CATALOG
	,convert(sysname, null) AS COLLATION_SCHEMA
	,convert(sysname, CASE WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239) -- [n]char/[n]varchar/[n]text    
							THEN ServerProperty('collation') END)  AS COLLATION_NAME
	,convert(sysname, null) AS CHARACTER_SET_CATALOG
	,convert(sysname, null) AS CHARACTER_SET_SCHEMA
	,convert(sysname, CASE WHEN c.system_type_id IN (35, 167, 175) THEN ServerProperty('sqlcharsetname') -- char/varchar/text
							WHEN c.system_type_id IN (99, 231, 239) THEN N'UNICODE' END) AS CHARACTER_SET_NAME -- nchar/nvarchar/ntext
	,convert(tinyint, CASE WHEN c.system_type_id IN (48, 52, 56, 59, 60, 62, 106, 108, 122, 127) -- int/decimal/numeric/real/float/money
							THEN c.precision END) AS NUMERIC_PRECISION
	,convert(smallint, CASE WHEN c.system_type_id IN (48, 52, 56, 60, 106, 108, 122, 127) THEN 10 -- int/money/decimal/numeric
							WHEN c.system_type_id IN (59, 62) THEN 2 END) AS NUMERIC_PRECISION_RADIX -- real/float
	,convert(int, CASE WHEN c.system_type_id IN (40, 41, 42, 43, 58, 61) THEN NULL -- datetime/smalldatetime
						ELSE odbcscale(c.system_type_id, c.scale) END) AS NUMERIC_SCALE
	,convert(smallint, CASE WHEN c.system_type_id IN (40, 41, 42, 43, 58, 61) -- datetime/smalldatetime
							THEN odbcscale(c.system_type_id, c.scale) END) AS DATETIME_PRECISION
	,convert(nvarchar(30), null) AS INTERVAL_TYPE
	,convert(smallint, null) AS INTERVAL_PRECISION
	,convert(sysname, CASE WHEN u.schema_id <> 4 THEN DB_NAME() END) AS USER_DEFINED_TYPE_CATALOG
	,convert(sysname, CASE WHEN u.schema_id <> 4 THEN SCHEMA_NAME(u.schema_id) END)  AS USER_DEFINED_TYPE_SCHEMA
	,convert(sysname, CASE WHEN u.schema_id <> 4 THEN u.name END) AS USER_DEFINED_TYPE_NAME
	,convert(sysname, null) AS SCOPE_CATALOG
	,convert(sysname, null) AS SCOPE_SCHEMA
	,convert(sysname, null) AS SCOPE_NAME
FROM sys.objects o
JOIN sys.parameters c ON c.object_id = o.object_id
JOIN sys.types u ON u.user_type_id = c.user_type_id
WHERE o.type IN ('P','FN','TF', 'IF', 'IS', 'AF','PC', 'FS', 'FT')
/*************************************Logic For INFORMATION_SCHEMA.PARAMETERS********************************/



/*************************************Logic For INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS********************************/
CREATE VIEW INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS AS
SELECT DB_NAME() AS CONSTRAINT_CATALOG
	,SCHEMA_NAME(f.schema_id) AS CONSTRAINT_SCHEMA
	,f.name AS CONSTRAINT_NAME
	,DB_NAME() AS UNIQUE_CONSTRAINT_CATALOG
	,SCHEMA_NAME(t.schema_id) AS UNIQUE_CONSTRAINT_SCHEMA
	,i.name AS UNIQUE_CONSTRAINT_NAME
	,convert(varchar(7), 'SIMPLE') AS MATCH_OPTION
	,convert(varchar(11), CASE f.update_referential_action
							WHEN 0 THEN 'NO ACTION'
							WHEN 1 THEN 'CASCADE'
							WHEN 2 THEN 'SET NULL'
							WHEN 3 THEN 'SET DEFAULT' END) AS UPDATE_RULE
	,convert(varchar(11), CASE f.delete_referential_action 
							WHEN 0 THEN 'NO ACTION'
							WHEN 1 THEN 'CASCADE'
							WHEN 2 THEN 'SET NULL'
							WHEN 3 THEN 'SET DEFAULT' END) AS DELETE_RULE
FROM sys.foreign_keys f
LEFT JOIN sys.indexes i ON i.object_id = f.referenced_object_id
	AND i.index_id = f.key_index_id
LEFT JOIN sys.tables t ON t.object_id = f.referenced_object_id
/*************************************Logic For INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS********************************/



/*************************************Logic For INFORMATION_SCHEMA.ROUTINE_COLUMNS********************************/
CREATE VIEW INFORMATION_SCHEMA.ROUTINE_COLUMNS AS
SELECT	DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(o.schema_id) AS TABLE_SCHEMA
	,o.name AS TABLE_NAME
	,c.name AS COLUMN_NAME
	,c.column_id AS ORDINAL_POSITION
	,convert(nvarchar(4000), object_definition(c.default_object_id)) AS COLUMN_DEFAULT
	,convert(varchar(3), CASE WHEN c.is_nullable = 1 THEN 'YES' ELSE 'NO' END) AS IS_NULLABLE
	,ISNULL(type_name(c.system_type_id), t.name) AS DATA_TYPE
	,ColumnProperty(c.object_id, c.name, 'charmaxlen') AS CHARACTER_MAXIMUM_LENGTH
	,ColumnProperty(c.object_id, c.name, 'octetmaxlen') AS CHARACTER_OCTET_LENGTH
	,convert(tinyint, CASE WHEN c.system_type_id IN (48, 52, 56, 59, 60, 62, 106, 108, 122, 127)-- int/decimal/numeric/real/float/money
							THEN c.precision END) AS NUMERIC_PRECISION
	,convert(smallint, CASE WHEN c.system_type_id IN (48, 52, 56, 60, 106, 108, 122, 127) THEN 10 -- int/money/decimal/numeric
							WHEN c.system_type_id IN (59, 62) THEN 2 END) AS NUMERIC_PRECISION_RADIX-- real/float
	,convert(int, CASE WHEN c.system_type_id IN (40, 41, 42, 43, 58, 61) THEN NULL -- datetime/smalldatetime
						ELSE odbcscale(c.system_type_id, c.scale) END) AS NUMERIC_SCALE
	,convert(smallint, CASE WHEN c.system_type_id IN (40, 41, 42, 43, 58, 61) -- datetime/smalldatetime
							THEN odbcscale(c.system_type_id, c.scale) END) AS DATETIME_PRECISION
	,convert( sysname, null) AS CHARACTER_SET_CATALOG
	,convert( sysname, null) AS CHARACTER_SET_SCHEMA
	,convert( sysname, CASE WHEN c.system_type_id IN (35, 167, 175) -- char/varchar/text
							THEN CollationProperty(c.collation_name, 'sqlcharsetname')
							WHEN c.system_type_id IN (99, 231, 239) -- nchar/nvarchar/ntext
							THEN N'UNICODE' END) AS CHARACTER_SET_NAME
	,convert(sysname, null) AS COLLATION_CATALOG
	,convert(sysname, null) AS COLLATION_SCHEMA
	,c.collation_name AS COLLATION_NAME
	,convert(sysname, CASE WHEN c.user_type_id > 256 THEN DB_NAME() END) AS DOMAIN_CATALOG
	,convert(sysname, CASE WHEN c.user_type_id > 256 THEN SCHEMA_NAME(t.schema_id) END) AS DOMAIN_SCHEMA
	,convert(sysname, CASE WHEN c.user_type_id > 256 THEN type_name(c.user_type_id) END) AS DOMAIN_NAME
FROM sys.objects o
JOIN sys.columns c ON c.object_id = o.object_id
LEFT JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE   o.type IN ('TF','IF', 'FT')
/*************************************Logic For INFORMATION_SCHEMA.ROUTINE_COLUMNS********************************/



/*************************************Logic For INFORMATION_SCHEMA.ROUTINES********************************/
CREATE VIEW INFORMATION_SCHEMA.ROUTINES AS
SELECT DB_NAME() AS SPECIFIC_CATALOG
	,SCHEMA_NAME(o.schema_id) AS SPECIFIC_SCHEMA
	,o.name AS SPECIFIC_NAME
	,DB_NAME() AS ROUTINE_CATALOG
	,SCHEMA_NAME(o.schema_id) AS ROUTINE_SCHEMA
	,o.name AS ROUTINE_NAME
	,convert(nvarchar(20), CASE WHEN o.type IN ('P','PC') THEN 'PROCEDURE' ELSE 'FUNCTION' END) AS ROUTINE_TYPE
	,convert(sysname, null) AS MODULE_CATALOG
	,convert(sysname, null) AS MODULE_SCHEMA
	,convert(sysname, null) AS MODULE_NAME
	,convert(sysname, null) AS UDT_CATALOG
	,convert(sysname, null) AS UDT_SCHEMA
	,convert(sysname, null) AS UDT_NAME
	,convert(sysname, CASE WHEN o.type IN ('TF', 'IF', 'FT') THEN N'TABLE'
							ELSE ISNULL(type_name(c.system_type_id), type_name(c.user_type_id)) END) AS DATA_TYPE
	,ColumnProperty(c.object_id, c.name, 'charmaxlen') AS CHARACTER_MAXIMUM_LENGTH
	,ColumnProperty(c.object_id, c.name, 'octetmaxlen') AS CHARACTER_OCTET_LENGTH
	,convert(sysname, null) AS COLLATION_CATALOG
	,convert(sysname, null) AS COLLATION_SCHEMA
	,convert(sysname, CASE WHEN c.system_type_id IN (35, 99, 167, 175, 231, 239) -- [n]char/[n]varchar/[n]text
							THEN CollationPropertyFromId(-1, 'name') END) AS COLLATION_NAME
	,convert(sysname, null) AS CHARACTER_SET_CATALOG
	,convert(sysname, null) AS CHARACTER_SET_SCHEMA
	,convert(sysname, CASE WHEN c.system_type_id IN (35, 167, 175) THEN ServerProperty('sqlcharsetname') -- char/varchar/text
							WHEN c.system_type_id IN (99, 231, 239) THEN N'UNICODE' END) AS CHARACTER_SET_NAME -- nchar/nvarchar/ntext
	,convert(tinyint, CASE WHEN c.system_type_id IN (48, 52, 56, 59, 60, 62, 106, 108, 122, 127) THEN c.precision END) AS NUMERIC_PRECISION-- int/decimal/numeric/real/float/money
	,convert(smallint, CASE WHEN c.system_type_id IN (48, 52, 56, 60, 106, 108, 122, 127) THEN 10-- int/money/decimal/numeric
							WHEN c.system_type_id IN (59, 62) THEN 2 END) AS NUMERIC_PRECISION_RADIX -- real/float
	,convert(int, CASE WHEN c.system_type_id IN (40, 41, 42, 43, 58, 61) THEN NULL -- datetime/smalldatetime
						ELSE odbcscale(c.system_type_id, c.scale) END) AS NUMERIC_SCALE
	,convert(smallint, CASE WHEN c.system_type_id IN (40, 41, 42, 43, 58, 61) -- datetime/smalldatetime
						THEN odbcscale(c.system_type_id, c.scale) END) AS DATETIME_PRECISION
	,convert(nvarchar(30), null) AS INTERVAL_TYPE
	,convert(smallint, null) AS INTERVAL_PRECISION
	,convert(sysname, null) AS TYPE_UDT_CATALOG
	,convert(sysname, null) AS TYPE_UDT_SCHEMA
	,convert(sysname, null) AS TYPE_UDT_NAME
	,convert(sysname, null) AS SCOPE_CATALOG
	,convert(sysname, null) AS SCOPE_SCHEMA
	,convert(sysname, null) AS SCOPE_NAME
	,convert(bigint, null) AS MAXIMUM_CARDINALITY
	,convert(sysname, null) AS DTD_IDENTIFIER
	,convert(nvarchar(30), CASE WHEN o.type IN ('P ', 'FN', 'TF', 'IF') THEN 'SQL' ELSE 'EXTERNAL' END) AS ROUTINE_BODY
	,convert(nvarchar(4000), object_definition(o.object_id)) AS ROUTINE_DEFINITION
	,convert(sysname, null) AS EXTERNAL_NAME
	,convert(nvarchar(30), null) AS EXTERNAL_LANGUAGE
	,convert(nvarchar(30), null) AS PARAMETER_STYLE
	,convert(nvarchar(10), CASE WHEN ObjectProperty(o.object_id, 'IsDeterministic') = 1  THEN 'YES' ELSE 'NO' END) AS IS_DETERMINISTIC
	,convert(nvarchar(30), CASE WHEN o.type IN ('P', 'PC') THEN 'MODIFIES' ELSE 'READS' END) AS SQL_DATA_ACCESS
	,convert(nvarchar(10), CASE WHEN o.type in ('P', 'PC') THEN null WHEN o.null_on_null_input = 1 THEN 'YES' ELSE 'NO' END) AS IS_NULL_CALL
	,convert(sysname, null) AS SQL_PATH
	,convert(nvarchar(10), 'YES') AS SCHEMA_LEVEL_ROUTINE
	,convert(smallint, CASE WHEN o.type IN ('P ', 'PC') THEN -1 ELSE 0 END) AS MAX_DYNAMIC_RESULT_SETS
	,convert(nvarchar(10), 'NO') AS IS_USER_DEFINED_CAST
	,convert(nvarchar(10), 'NO') AS IS_IMPLICITLY_INVOCABLE
	,o.create_date AS CREATED
	,o.modify_date AS LAST_ALTERED
FROM sys.objects o
LEFT JOIN sys.parameters c ON (c.object_id = o.object_id AND c.parameter_id = 0)
WHERE o.type IN ('P', 'FN', 'TF', 'IF', 'AF', 'FT', 'IS', 'PC', 'FS')
/*************************************Logic For INFORMATION_SCHEMA.ROUTINES********************************/



/*************************************Logic For INFORMATION_SCHEMA.SCHEMATA********************************/
CREATE VIEW information_schema.schemata AS 
SELECT Db_name() AS CATALOG_NAME
	,NAME AS SCHEMA_NAME
	,User_name(principal_id) AS SCHEMA_OWNER 
	,CONVERT(SYSNAME, NULL) AS DEFAULT_CHARACTER_SET_CATALOG
	,CONVERT(SYSNAME, NULL) AS DEFAULT_CHARACTER_SET_SCHEMA
	,CONVERT(SYSNAME, Collationpropertyfromid(-1, 'sqlcharsetname')) AS DEFAULT_CHARACTER_SET_NAME 
FROM sys.schemas
/*************************************Logic For INFORMATION_SCHEMA.SCHEMATA********************************/



/*************************************Logic For INFORMATION_SCHEMA.TABLE_CONSTRAINTS********************************/
CREATE VIEW INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS
SELECT DB_NAME() AS CONSTRAINT_CATALOG
	,SCHEMA_NAME(c.schema_id) AS CONSTRAINT_SCHEMA
	,c.name AS CONSTRAINT_NAME
	,DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(t.schema_id) AS TABLE_SCHEMA
	,t.name AS TABLE_NAME
	,CASE c.type WHEN 'C ' THEN 'CHECK'
				 WHEN 'UQ' THEN 'UNIQUE'
				 WHEN 'PK' THEN 'PRIMARY KEY'
				 WHEN 'F ' THEN 'FOREIGN KEY' END AS CONSTRAINT_TYPE
	,'NO' AS IS_DEFERRABLE
	,'NO' AS INITIALLY_DEFERRED
FROM sys.objects c
LEFT JOIN sys.tables t ON t.object_id = c.parent_object_id
WHERE c.type IN ('C' ,'UQ' ,'PK' ,'F')
/*************************************Logic For INFORMATION_SCHEMA.TABLE_CONSTRAINTS********************************/



/*************************************Logic For INFORMATION_SCHEMA.TABLE_PRIVILEGES********************************/
CREATE VIEW INFORMATION_SCHEMA.TABLE_PRIVILEGES AS
SELECT USER_NAME(p.grantor_principal_id) AS GRANTOR
	,USER_NAME(p.grantee_principal_id) AS GRANTEE
	,DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(o.schema_id) AS TABLE_SCHEMA
	,o.name AS TABLE_NAME
	,convert(varchar(10), CASE p.type WHEN 'RF' THEN 'REFERENCES'
									  WHEN 'SL' THEN 'SELECT'
									  WHEN 'IN' THEN 'INSERT'
									  WHEN 'DL' THEN 'DELETE'
									  WHEN 'UP' THEN 'UPDATE' END) AS PRIVILEGE_TYPE
	,convert(varchar(3), CASE p.state WHEN 'G' THEN 'NO' WHEN 'W' THEN 'YES' END) AS IS_GRANTABLE
FROM sys.objects o
,sys.database_permissions p
WHERE o.type IN ('U', 'V')
	AND p.class = 1
	AND p.major_id = o.object_id
	AND p.minor_id = 0 -- all columns
	AND p.type IN ('RF','IN','SL','UP','DL')
	AND p.state IN ('W','G')
	AND (
		p.grantee_principal_id = 0
		OR p.grantee_principal_id = DATABASE_PRINCIPAL_ID()
		OR p.grantor_principal_id = DATABASE_PRINCIPAL_ID()
		)
/*************************************Logic For INFORMATION_SCHEMA.TABLE_PRIVILEGES********************************/



/*************************************Logic For INFORMATION_SCHEMA.TABLES********************************/
CREATE VIEW INFORMATION_SCHEMA.TABLES AS
SELECT DB_NAME() AS TABLE_CATALOG
	,s.name AS TABLE_SCHEMA
	,o.name AS TABLE_NAME
	,CASE o.type WHEN 'U' THEN 'BASE TABLE' WHEN 'V' THEN 'VIEW' END AS TABLE_TYPE
FROM sys.objects o
LEFT JOIN sys.schemas s ON s.schema_id = o.schema_id
WHERE o.type IN ('U', 'V')  
/*************************************Logic For INFORMATION_SCHEMA.TABLES********************************/



/*************************************Logic For INFORMATION_SCHEMA.VIEW_COLUMN_USAGE********************************/
CREATE VIEW INFORMATION_SCHEMA.VIEW_COLUMN_USAGE AS
SELECT DB_NAME() AS VIEW_CATALOG
	,SCHEMA_NAME(v.schema_id) AS VIEW_SCHEMA
	,v.name AS VIEW_NAME
	,DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(t.schema_id) AS TABLE_SCHEMA
	,t.name AS TABLE_NAME
	,c.name AS COLUMN_NAME
FROM sys.views v
JOIN sys.sql_dependencies d ON d.object_id = v.object_id
JOIN sys.objects t ON t.object_id = d.referenced_major_id
JOIN sys.columns c ON c.object_id = d.referenced_major_id
	AND c.column_id = d.referenced_minor_id
WHERE d.class < 2
/*************************************Logic For INFORMATION_SCHEMA.VIEW_COLUMN_USAGE********************************/



/*************************************Logic For INFORMATION_SCHEMA.VIEW_TABLE_USAGE********************************/
CREATE VIEW INFORMATION_SCHEMA.VIEW_TABLE_USAGE AS
SELECT DISTINCT DB_NAME() AS VIEW_CATALOG
	,SCHEMA_NAME(v.schema_id) AS VIEW_SCHEMA
	,v.name AS VIEW_NAME
	,DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(t.schema_id) AS TABLE_SCHEMA
	,t.name AS TABLE_NAME
FROM sys.objects t
,sys.views v
,sys.sql_dependencies d
WHERE d.class < 2 
	AND d.object_id = v.object_id
	AND d.referenced_major_id = t.object_id  
/*************************************Logic For INFORMATION_SCHEMA.VIEW_TABLE_USAGE********************************/



/*************************************Logic For INFORMATION_SCHEMA.VIEWS********************************/
CREATE VIEW INFORMATION_SCHEMA.VIEWS AS
SELECT DB_NAME() AS TABLE_CATALOG
	,SCHEMA_NAME(schema_id) AS TABLE_SCHEMA
	,name AS TABLE_NAME
	,convert(nvarchar(4000), object_definition(object_id)) AS VIEW_DEFINITION
	,convert(varchar(7), CASE with_check_option WHEN 1 THEN 'CASCADE' ELSE 'NONE' END) AS CHECK_OPTION
	,'NO' AS IS_UPDATABLE
FROM sys.views
/*************************************Logic For INFORMATION_SCHEMA.VIEWS********************************/