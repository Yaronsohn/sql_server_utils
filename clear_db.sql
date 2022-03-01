/*
 * MIT License
 * 
 * Copyright (c) 2022 Yaronsohn
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */
 
IF DB_NAME() = N'master'
BEGIN
    /*
     * WARNING!!! DO NOT MODIFY OR REMOVE THIS SAFETY BLOCK!
     */
    DECLARE @err nvarchar(max) =
        CHAR(13) + CHAR(10) +
        '********************************************************************************' + CHAR(13) + CHAR(10) +
        '** ERROR!' + CHAR(13) + CHAR(10) +
        '** Do NOT run this script on the master database!!!' + CHAR(13) + CHAR(10) +
        '********************************************************************************' + CHAR(13) + CHAR(10) +
        CHAR(13) + CHAR(10);

    IF ServerProperty('Edition') != 'SQL Azure'
        RAISERROR(@err, 20, 20) WITH LOG;
    ELSE
        RAISERROR(@err, 18, 18);
END
GO

IF ServerProperty('Edition') != 'SQL Azure'
BEGIN
    /* Drop all views */
    DECLARE @name VARCHAR(128)
    DECLARE @SQL VARCHAR(254)

    SELECT @name = (SELECT TOP 1 [name] FROM sysobjects WHERE [type] = 'V' AND category = 0 ORDER BY [name])

    WHILE @name IS NOT NULL
    BEGIN
        SELECT @SQL = 'DROP VIEW [dbo].[' + RTRIM(@name) +']'
        EXEC (@SQL)
        PRINT 'Dropped View: ' + @name
        SELECT @name = (SELECT TOP 1 [name] FROM sysobjects WHERE [type] = 'V' AND category = 0 AND [name] > @name ORDER BY [name])
    END
END
GO

/* Drop all Keys constraints */
DECLARE @table SYSNAME;
DECLARE @constraint VARCHAR(254) = '';
DECLARE @SQL VARCHAR(254);
DECLARE @schema SYSNAME;
DECLARE @type NVARCHAR(128);

WHILE 1 = 1
BEGIN
    SELECT TOP 1 @constraint = CONSTRAINT_NAME, @schema = CONSTRAINT_SCHEMA, @table = TABLE_NAME, @type = CONSTRAINT_TYPE
        FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
        WHERE constraint_catalog = DB_NAME()
            AND (CONSTRAINT_SCHEMA != N'sys' AND CONSTRAINT_SCHEMA != N'jobs' AND CONSTRAINT_SCHEMA != N'jobs_internal')
            AND (TABLE_NAME IS NOT NULL AND TABLE_NAME != '')
        ORDER BY CONSTRAINT_NAME;
    IF @constraint IS NULL OR @constraint = N''
        BREAK;

    SELECT @SQL = 'ALTER TABLE [' + @schema + '].[' + RTRIM(@table) +'] DROP CONSTRAINT [' + RTRIM(@constraint) +']'
    EXEC (@SQL)

    PRINT 'Dropped ' + @type + ' Constraint: ' + @constraint + ' on ' + @table
    SET @constraint = NULL;
END

SET @table = '';
WHILE 1 = 1
BEGIN
    SELECT TOP 1 @schema = TABLE_SCHEMA, @table = TABLE_NAME
        FROM INFORMATION_SCHEMA.TABLES
        WHERE TABLE_CATALOG = DB_NAME()
            AND (TABLE_SCHEMA != N'sys' AND TABLE_SCHEMA != N'jobs' AND TABLE_SCHEMA != N'jobs_internal')
        ORDER BY TABLE_NAME
    IF @table IS NULL OR @table = ''
        BREAK;

    SELECT @SQL = 'DROP TABLE [' + @schema + '].[' + RTRIM(@table) +']';
    EXEC (@SQL)

    PRINT 'Dropped Table: ' + @schema + '.' + @table
    SET @table = NULL;
END

DECLARE @routine SYSNAME = '';
DECLARE @routine_type NVARCHAR(20);
WHILE 1 = 1
BEGIN
    SELECT TOP 1 @schema = ROUTINE_SCHEMA, @routine = ROUTINE_NAME, @routine_type = ROUTINE_TYPE
        FROM INFORMATION_SCHEMA.ROUTINES
        WHERE ROUTINE_CATALOG = DB_NAME()
            AND (ROUTINE_SCHEMA != N'sys' AND ROUTINE_SCHEMA != N'jobs' AND ROUTINE_SCHEMA != N'jobs_internal')
        ORDER BY ROUTINE_NAME
   IF @routine IS NULL OR @routine = ''
        BREAK;

    SELECT @SQL = 'DROP ' + @routine_type + ' [' + @schema + '].[' + RTRIM(@routine) +']';
    EXEC (@SQL)

    PRINT 'Dropped Routine: ' + @schema + '.' + @routine
    SET @routine = NULL;
END

SET @type = '';
WHILE 1 = 1
BEGIN
    SELECT TOP 1 @schema = SCHEMA_NAME(schema_id), @type = name
        FROM sys.table_types
        WHERE (is_user_defined = 1
            AND (SCHEMA_NAME(schema_id) != N'sys' AND SCHEMA_NAME(schema_id) != N'jobs' AND SCHEMA_NAME(schema_id) != N'jobs_internal'))
        ORDER BY name
    IF @type IS NULL OR @type = ''
        BREAK;

    SELECT @SQL = 'DROP TYPE [' + @schema + '].[' + RTRIM(@type) +']';

    EXEC (@SQL)

    PRINT 'Dropped Table Type: ' + @schema + '.' + RTRIM(@type)
    SET @type = NULL;
END

SET @type = '';
WHILE 1 = 1
BEGIN
    SELECT TOP 1 @schema = SCHEMA_NAME(schema_id), @type = name
        FROM sys.types
        WHERE (is_user_defined = 1
            AND (SCHEMA_NAME(schema_id) != N'sys' AND SCHEMA_NAME(schema_id) != N'jobs' AND SCHEMA_NAME(schema_id) != N'jobs_internal'))
        ORDER BY name
    IF @type IS NULL OR @type = ''
        BREAK;

    SELECT @SQL = 'DROP TYPE [' + @schema + '].[' + RTRIM(@type) +']';

    EXEC (@SQL)

    PRINT 'Dropped Type: ' + @schema + '.' + RTRIM(@type)
    SET @type = NULL;
END
GO
