USE [SHAPLTEST]
GO
/****** Object:  StoredProcedure [dbo].[SBO_SP_TransactionNotification]    Script Date: 07/07/2023 8:11:07 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER proc [dbo].[SBO_SP_TransactionNotification] 

@object_type nvarchar(30), 				-- SBO Object Type
@transaction_type nchar(1),			-- [A]dd, [U]pdate, [D]elete, [C]ancel, C[L]ose
@num_of_cols_in_key int,
@list_of_key_cols_tab_del nvarchar(255),
@list_of_cols_val_tab_del nvarchar(255)

AS

begin

-- Return values
declare @error  int				-- Result (0 for no error)
declare @error_message nvarchar (200) 		-- Error string to be displayed
select @error = 0
select @error_message = N'Ok'

 -------------------------------------------------------------------------------------------------------------------
declare @AItemCode1 nvarchar
declare @orignItemCode nvarchar
declare @Icount int
declare @cCount int 
declare @aCount int
declare @BoMCount int
Declare @ProdCount int
declare @AlternateItem nvarchar(30)
declare @OriginalItem nvarchar(30)
declare @AltItem nvarchar(30)
declare @Code nvarchar(30)
declare @WItemCode nvarchar(30)
declare @AItem nvarchar(30)
declare @OItem nvarchar(30)
declare @ChildNum int
declare @LineNum int
declare @RemoveItem nvarchar (30)
                                    ---ADD YOUR CODE---

 --------------------------------------------------------------------------------------------------------------------

                 --------BP MASTER : OBJECT TYPE-2 : TABLE-OCRD VALIDATION--------

 --------------------------ADDED 2022_V1.0--------------------------------------------------------------------------------


IF (@object_type = N'2' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN 
    IF EXISTS (
        SELECT CRD1.GSTRegnNo
        FROM CRD1
        INNER JOIN ocst ON ocst.code = crd1.[State]
        WHERE CRD1.GSTRegnNo IS NOT NULL 
        AND CRD1.CARDCODE = @list_of_cols_val_tab_del
        AND CRD1.Country = 'IN'
        AND CRD1.GSTRegnNo <> OCST.GSTCode + '' + SUBSTRING(GSTRegnNo, 3, 20)
    )
    BEGIN 
        SELECT @Error = 201
        SELECT @error_message = 'GSTTIN FIRST TWO DIGITS SHOULD BE THE STATE CODE'
    END
END

---------------------------ADDED 2022_V1.0-------------------------------------------------------------------

IF (@object_type = N'2' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN
    IF EXISTS (
        SELECT CRD1.GSTRegnNo
        FROM CRD1
        INNER JOIN OCST ON OCST.Code = CRD1.[State]
        WHERE CRD1.GSTRegnNo IS NOT NULL
            AND CRD1.CardCode = @list_of_cols_val_tab_del
            AND CRD1.GSTRegnNo <> OCST.GSTCode + '' + SUBSTRING(GSTRegnNo, 3, 20)
    )
    BEGIN
        SELECT @Error = 202
        SELECT @error_message = 'FIRST TWO DIGITS SHOULD BE STATE CODE'
    END
END;

--------------------------ADDED 2022_V1.0-------------------------------------------------------------------------

IF (@object_type = N'2' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN
    IF EXISTS (
        SELECT CRD1.GSTRegnNo
        FROM CRD1
        INNER JOIN OCST ON OCST.Code = CRD1.[State]
        WHERE CRD1.GSTRegnNo IS NULL
            AND CRD1.CardCode = @list_of_cols_val_tab_del
            AND CRD1.Country = 'IN'
    )
    BEGIN
        SELECT @Error = 203
        SELECT @error_message = 'GSTIN CANNOT BE BLANK'
    END
END;

-----------------------------ADDED 2022_V1.0--------------------------------------------------------------------
IF (@object_type = N'2' AND (@transaction_type = N'A' OR @transaction_type = N'U'))

BEGIN
    IF EXISTS (
        SELECT T0.CardCode
        FROM OCRD T0
        WHERE ISNULL(T0.CardName, '') = '' AND T0.CardCode = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @Error = 204
        SELECT @error_message = 'CARD NAME CANNOT BE BLANK'
    END
END

----------------------------ADDED 2022_V1.0--------------------------------------------	
IF (@object_type = N'2' AND @transaction_type = N'A')

BEGIN
    IF EXISTS (
        SELECT T0.CardCode
        FROM OCPR T0
        WHERE (LEN(T0.Cellolar) > 10 AND T0.CARDCODE = @list_of_cols_val_tab_del)
    )
    BEGIN
        SELECT @error = 205
        SELECT @error_message = 'PLEASE ENTER ONLY 10-DIGIT MOBILE NUMBER'
    END
END
---------------------------------ADDED 2022_V1.0----------------------------------------------------------

IF (@object_type = N'2' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN
    IF EXISTS (
        SELECT OCPR.Cellolar
        FROM OCPR
        WHERE OCPR.Cellolar IS NOT NULL AND LEN(ISNULL(OCPR.Cellolar, '')) <> 10
            AND OCPR.CardCode = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @Error = 206
        SELECT @error_message = 'MOBILE NUMBER EXCEEDED 10 DIGITS LIMIT'
    END
END;


---------------------------ADDED 2022_V1.0-----------------------------------------------------------------------

IF (@object_type = N'2' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN 
    IF EXISTS (
        SELECT T1.[Cellolar]
        FROM OCRD T0
        INNER JOIN OCPR T1 ON T0.[CardCode] = T1.[CardCode]
        WHERE T0.[CardType] IN ('C', 'L')
          AND T1.CardCode = @list_of_cols_val_tab_del
          AND T1.Cellolar IS NULL
    )
    BEGIN                        
        SELECT @Error = 207                                                          
        SELECT @error_message = 'PLEASE ENTER MOBILE NUMBER FOR CONTACT PERSON'
    END
END


---------------------ITEM MASTER : OBJECT TYPE-4 : TABLE-OITM VALIDATION---------------------

----------------------------------DUPLICATE ITEM NAME -------ADDED 2022_V1.0-----------------------

IF @object_type = '4' And (@transaction_type = 'A' or @transaction_type = 'U')
 BEGIN
	DECLARE @ItemCode AS VARCHAR (100)
	DECLARE @ItemName as varchar (100)
	IF (@object_type = '4')
	 BEGIN
	   SELECT  @ItemCode = ItemCode,@ItemName = ItemName FROM OITM T0 WHERE T0.ItemCode = @list_of_cols_Val_tab_del
	  BEGIN
	    IF (@ItemName IS NOT NULL)
	     BEGIN
	     IF 1!= (SELECT COUNT (ItemCode) FROM OITM WITH (NOLOCK)WHERE (ItemName = @ItemName) )
	     BEGIN
	       SELECT @error = 401
	       SELECT @error_message = 'DUPLICATE ITEM NAME --> '+@ItemName+' , FOR ITEM CODE -->'+@ItemCode+' !'
	      END
	   END
	 END
  END
END
------------------------------Item Description Mandatory-----------ADDED 2022_V1.0----------------------------------------

IF (@object_type = N'4' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM OITM A
        WHERE A.ItemCode = @list_of_cols_val_tab_del 
        AND (A.ItemName IS NULL OR A.ItemName = '')
    )
    BEGIN
        SELECT @error = 402
        SELECT @error_message = 'ITEM DESCRIPTION SHOULD NOT BE BLANK !!'
    END
END


--------------------------------HSN Code Mandatory--------ADDED 2022_V1.0-------------------------------------------

IF (@object_type = N'4' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM OITM A
        INNER JOIN OITB T1 ON A.[ItmsGrpCod] = T1.[ItmsGrpCod]
        WHERE A.ItemCode = @list_of_cols_val_tab_del AND T1.[ItemClass] = '2' AND A.GSTRelevnt = 'Y'
        AND (A.ChapterID = -1 OR A.ChapterID IS NULL)
    )
    BEGIN
        SELECT @error = 403
        SELECT @error_message = 'HSN CODE CANNOT BE BLANK !!'
    END
END

----------HSN USER BASE
	
IF (@object_type = N'4' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
		BEGIN IF Exists				
						(SELECT T0.itemcode FROM OITM T0 
						WHERE T0.ItemCode = @list_of_cols_val_tab_del AND (T0.ChapterID <= 0 OR T0.ChapterID IS NULL) 
						--AND (T0.UserSign in ('1') OR t0.UserSign2 in ('1'))
						)
					BEGIN	
				SET @error = 404		
			SET @error_message = 'PLEASE PUT HSN/SAC CODE'			
		END				
	END		


--------------------Item Master GST or Excisable option should be checked on MATERIAL Class-------ADDED 2022_V1.0------------

IF (@object_type = N'4' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM OITM A
        WHERE A.ItemCode = @list_of_cols_val_tab_del
        AND A.ItemClass = '2'
        AND A.GSTRelevnt = 'N'
        AND A.Excisable = 'N'
    )
    BEGIN
        SELECT @error = 405
        SELECT @error_message = 'PLEASE TICK GST OR EXCISABLE CHECKBOX EITHER !!'
    END
END

IF (@object_type = N'4' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM OITM A
        INNER JOIN OITB T1 ON A.[ItmsGrpCod] = T1.[ItmsGrpCod]
        WHERE A.ItemCode = @list_of_cols_val_tab_del AND T1.ItmsGrpCod=103
       AND A.ChapterID <> 134 AND A.UserSign in (71, 72) and A.UserSign2 in (71, 72) 
    
    )
    BEGIN
        SELECT @error = 411
        SELECT @error_message = 'HSN CODE FOR FG ITEM NOT CORRECT '
    END
END

----------------In Item Master GST or Excisable option should be checked on service Class------ADDED 2022_V1.0-------------

IF (@object_type = N'4' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM OITM A
        WHERE A.ItemCode = @list_of_cols_val_tab_del
        AND A.ItemClass = '1'
        AND A.GSTRelevnt = 'N'
    )
    BEGIN
        SELECT @error = 406
        SELECT @error_message = 'PLEASE TICK GST CHECKBOX !!'
    END
END

---------------------------- Inventory UOM Mandatory----------------ADDED 2022_V1.0---------------------------------------

IF (@object_type = N'4' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF EXISTS (
        SELECT *
        FROM OITM a
        WHERE A.InvntItem = 'Y' AND (ISNULL(A.InvntryUom, '') = '') 
        AND a.ItemCode = @list_of_cols_val_tab_del AND a.objtype = '4'
    )
    BEGIN
        SELECT @error = 407
        SELECT @error_message = 'INVENTORY UOM CANNOT BE BLANK ON INVENTORY DATA TAB'
    END
END

-----------------------------Sales UOM Mandatory------------------ADDED 2022_V1.0--------------------------------------

--IF (@object_type = N'4' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
--BEGIN
--    IF EXISTS (
--        SELECT *
--        FROM OITM a
--        WHERE A.SellItem = 'Y' AND (ISNULL(A.SalUnitMsr, '') = '') 
--        AND a.ItemCode = @list_of_cols_val_tab_del AND a.objtype = '4'
--          --AND (a.UserSign in ('1') OR a.UserSign2 in ('1'))
--    )
--    BEGIN
--        SELECT @error = 408
--        SELECT @error_message = 'SALE UOM CANNOT BE BLANK ON SALES DATA TAB'
--    END
--END
						
------------------------------Purchasing UOM Mandatory------------ADDED 2022_V1.0---------------------------------------

IF (@object_type = N'4' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF EXISTS (
        SELECT *
        FROM OITM a
        WHERE A.PrchseItem = 'Y' AND (ISNULL(A.BuyUnitMsr, '') = '') 
        AND a.ItemCode = @list_of_cols_val_tab_del AND a.objtype = '4'
    )
    BEGIN
        SELECT @error ='409'
		SELECT @error_message = 'PURCHASING UOM CANNOT BE BLANK ON PURCHASING DATA TAB'

    END
END;


---------------------A/R INVOICE : OBJECT TYPE-13 : TABLE-OINV VALIDATION---------ADDED 2022_V1.0------------

-----------------------------------------UDF2-------------------------------------

IF @object_type = '13' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM OINV T0, OCRD H
        WHERE T0.DocEntry = @list_of_cols_val_tab_del
        AND (T0.DocTotal + ISNULL(U_UDF1, 0) - 5000000) < 0
        AND ISNULL(U_UDF2, 0) <> 0
        AND T0.CardCode = H.CardCode
        --AND H.groupcode NOT IN (117)--------Kindly fill interbranch group code
        AND T0.Docdate >= '20201001'
        AND T0.DocCur = 'INR'
        AND T0.DocType = 'I'
    )
    BEGIN
        SELECT @Error = '1301', @error_message = 'KINDLY REFRESH TCS APPLICABLE AMOUNT'
    END
END

-----------------------ADDED 2022_V1.0---------------------------------------

IF ((@transaction_type = 'C') AND @object_type = '13')
BEGIN
       IF EXISTS 
       (
          SELECT COUNT(T0.DocEntry) FROM INV1 T0 
		  INNER JOIN [@UTL_GE_GPS1] T1 ON T0.DocEntry= T1.U_UTL_BASEKEY  AND T0.LineNum= T1.U_UTL_BASELINE
          WHERE T0.DocEntry=@list_of_cols_val_tab_del
       )
       
       
       BEGIN
        Set  @error ='1302';
        Set  @error_message ='GATE PASS FOUND BASED FOR THIS AR INVOICE.';
       END ;
END ;

---------------------------Currency for A/R INvoice---------ADDED 2022_V1.0--------

IF @transaction_type in ('A','U') AND @object_type = '13'
BEGIN
IF EXISTS (SELECT T0.DOCENTRY from dbo.OINV T0 INNER JOIN INV1 T1 on T0.DocEntry=t1.DocEntry
WHERE  T1.AcctCode='411001001' AND T0.CurSource <> 'C' AND t0.DocCur <> 'USD'
AND T0.DocEntry=@list_of_cols_val_tab_del)
BEGIN
SELECT @error = 1303, @error_message = 'CHECK CURRENCY OF CUSTOMER IT IS ALWAYS BP CURRENCY IN USD'
END
END


--------------------------------------------------G/L for export Customer for A/R INvoice--------ADDED 2022_V1.0---------

IF @transaction_type in ('A','U') AND @object_type = '13'
BEGIN
IF exists (select T0.CardName,T2.GroupCode ,T0.DocEntry from dbo.OINV T0 
inner join INV1 T1 on T0.DocEntry=t1.DocEntry
LEFT join OCRD T2 ON T0.CardCode=T2.CardCode
WHERE T2.GroupCode='105' AND T1.AcctCode <> '411001001'
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 1304, @error_message = 'SELECT EXPORT G/L ACCOUNT FOR THIS CUSTOMER'
End
END

---------------------A/R Invoice Document Series- EXPORT---------------ADDED 2022_V1.0-----------------------


IF @transaction_type in ('A','U') AND @object_type = '13'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.OINV T0 inner join OCRD T1 on t0.CardCode=t1.CardCode
Where  T0.Series='865' AND T1.GroupCode NOT IN ('105')
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 1305, @error_message = 'WRONG SERIES FOR EXPORT INVOICE'
End
END


----- Domestic-----

IF @transaction_type in ('A','U') AND @object_type = '13'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.OINV T0 inner join OCRD T1 on t0.CardCode=t1.CardCode
Where  T0.Series='354' AND T1.GroupCode = 105
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 1306, @error_message = 'WRONG SERIES FOR DOMESTIC INVOICE'
End
END



-------------------------G/L for Domestic Customer for A/R Invoice------ADDED 2022_V1.0------------------------

IF @transaction_type in ('A','U') AND @object_type = '13'
BEGIN
IF exists (select T0.CardName,T2.GroupCode ,T0.DocEntry from dbo.OINV T0 
inner join INV1 T1 on T0.DocEntry=t1.DocEntry
LEFT join OCRD T2 ON T0.CardCode=T2.CardCode
WHERE T2.GroupCode in ('107','106','100') AND T1.AcctCode <> '411001003'
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 1307, @error_message = 'SELECT DOMESTIC G/L ACCOUNT FOR THIS CUSTOMER'
End
END
------------------HSN CODE 8 DIGIT IN A/R INVOICE------------ADDED 2022_V1.0---------------------

IF @transaction_type IN (N'A', N'U') AND (@Object_type = N'13')      
BEGIN            
   IF EXISTS (
      SELECT '*' 
      FROM INV1 A, OCHP C 
      WHERE A.DocEntry = @list_of_cols_val_tab_del AND A.HsnEntry = C.AbsEntry 
      AND LEN(REPLACE(C.ChapterID, '.', '')) < 8
   )
   BEGIN   
      SET @error = 1308   
      SET @error_message = 'HSN LENGTH SHOULD NOT BE LESS THAN 8'   
      
   END      
END

--------------------UOM IN INVOICE----------------



IF @transaction_type IN (N'A', N'U') AND (@Object_type = N'13')      
BEGIN            
   IF EXISTS (
      SELECT '*' 
      FROM INV1 A 
      WHERE A.DocEntry = @list_of_cols_val_tab_del 
	  AND (A.UomCode = 'Manual' OR A.unitMsr is null)

      
   )
   BEGIN   
      SET @error = 1308   
      SET @error_message = 'UOM IS REQUIRED FOR IRN UPDATE ITEM MASTER '   
      
   END      
END



IF @transaction_type IN (N'A', N'U') AND (@Object_type = N'15')      
BEGIN            
   IF EXISTS (
      SELECT '*' 
      FROM DLN1 A 
      WHERE A.DocEntry = @list_of_cols_val_tab_del 
	  AND (A.UomCode = 'Manual' OR A.unitMsr is null)

      
   )
   BEGIN   
      SET @error = 1508   
      SET @error_message = 'UOM IS REQUIRED FOR IRN UPDATE ITEM MASTER'   
      
   END      
END



---------------------A/R CREDIT MEMO : OBJECT TYPE-14 : TABLE-ORIN VALIDATION------------ADDED 2022_V1.0---------

IF ((@transaction_type = 'A') AND @object_type = '14')
BEGIN
declare @check2 nvarchar
SELECT @check2=U_UTL_CHKVAL FROM "@UTL_GE_OGST" WHERE U_UTL_PROCS='GE' AND U_UTL_DOCTY='AR' AND U_UTL_CHKVAL='Y';
IF(@check2='Y')
BEGIN
       IF EXISTS 
       (
		SELECT ISNULL("U_UTL_GE_DENT",'-1') AS "U_UTL_GE_DENT" FROM ORIN
			WHERE DocEntry=@list_of_cols_val_tab_del and ("U_UTL_GE_DENT"<=0 OR "U_UTL_GE_DENT" IS NULL)
       )
       
       BEGIN
       Set @error =1401;
       Set @error_message ='GATE INWORD DOCUMENT MUST BE TAG ON THIS DOCUMENT.';
       END ;

END;
END ;

------------------------------------------------------------------------------------

IF ((@transaction_type = 'A') AND @object_type = '14')
BEGIN
declare @check3 nvarchar
SELECT @check3=U_UTL_CHKVAL FROM "@UTL_GE_OGST" WHERE U_UTL_PROCS='GE' AND U_UTL_DOCTY='AR' AND U_UTL_CHKVAL='Y';
IF(@check3='Y')
BEGIN
       IF EXISTS 
       (
        SELECT T2.ItemCode FROM [@UTL_GE_GIN1] T1
 INNER JOIN [@UTL_GE_OGIN] T0 on T1.DocEntry=T0.DocEntry 
INNER JOIN RIN1 T2 ON T1.DocEntry=T2.U_UTL_GE_DocE and T1.LineId=T2.U_UTL_GE_Line AND T1.U_UTL_ITCD=T2.ItemCode 
 where T2.DocEntry=@list_of_cols_val_tab_del and (ISNULL(T1.U_UTL_QTY,0) != ISNULL(T2.Quantity,0))
       )
       
       BEGIN
       Set @error =1402;
       Set @error_message ='QUANTITY SHOULD BE EQUAL TO GATE ENTRY QUANTITY';
       END ;
END;
END ;

-------------------------------------------------------------------------------------

IF ((@transaction_type = 'C') AND @object_type = '14')
BEGIN
       IF EXISTS 
       (
          SELECT COUNT(T0.DocEntry) FROM RIN1 T0 INNER JOIN [@UTL_GE_GIN1] T1 ON T0.DocEntry= T1.U_UTL_BASENTR  AND T0.LineNum= T1.U_UTL_BASELINE
          WHERE T0.DocEntry=@list_of_cols_val_tab_del
       )

       BEGIN
        Set  @error ='1403';
        Set  @error_message ='GATE ENTRY FOUND BASED FOR THIS AR CREDIT NOTE.';
       END ;
END ;


---------------------DELIVERY : OBJECT TYPE-15 : TABLE-ODLN VALIDATION---------------------

----------------------------------------------------------------------

IF ((@transaction_type = 'C') AND @object_type = '15')
BEGIN
       IF EXISTS 
       (
          SELECT COUNT(T0.DocEntry) FROM DLN1 T0 INNER JOIN [@UTL_GE_GPS1] T1 ON T0.DocEntry= T1.U_UTL_BASEKEY  AND T0.LineNum= T1.U_UTL_BASELINE
          WHERE T0.DocEntry=@list_of_cols_val_tab_del
       )
       
       BEGIN
        Set @error ='1501';
        Set @error_message ='GATE PASS FOUND BASED FOR THIS DELIVERY.';
       END ;
END ;

---------------------------------------------------Series for Delivery-------------------------------------------
------Export----
IF @transaction_type in ('A','U') AND @object_type = '15'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.ODLN T0 inner join OCRD T1 on t0.CardCode=t1.CardCode
Where  T0.Series='875' AND T1.GroupCode not in ('105')
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 1502, @error_message = 'WRONG SERIES FOR EXPORT DELIVERY'
End
END


----- Domestic-----

IF @transaction_type in ('A','U') AND @object_type = '15'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.ODLN T0 inner join OCRD T1 on t0.CardCode=t1.CardCode
Where  T0.Series='874' AND T1.GroupCode = 105
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 1503, @error_message = 'WRONG SERIES FOR DOMESTIC DELIVERY'
End
END

---------------------RETURNS : OBJECT TYPE-16 : TABLE-ORDN VALIDATION---------------------


---------------------SALES ORDER : OBJECT TYPE-17 : TABLE-ORDR VALIDATION---------------------

---------Customer Ref. No. Should be not duplicate for the same customer---------------------------------------

IF @object_type = N'17' AND (@transaction_type = N'A' OR @transaction_type = N'U')
Begin
IF EXISTS
(
  SELECT T0.DocEntry
  FROM ORDR T0
   INNER JOIN ORDR T1 ON T0.CardCode=T1.CardCode AND ISNULL(T0.NumAtCard,'')=ISNULL(T1.NumAtCard,'') 
AND T1.DocEntry<>@list_of_cols_val_tab_del
  WHERE T0.DocEntry=@list_of_cols_val_tab_del 
 )
    BEGIN                  
        SELECT @Error = 1701                                                             
        SELECT @error_message = 'CUSTOMER REF. NO. ALREADY ADDED FOR THIS CUSTOMER.'
    END  
END

----------------------------BOM NOT AVAILABLE--------------------------------- 

IF @object_type = '17' AND (@transaction_type IN ('U', 'A'))
BEGIN
    IF EXISTS (
        SELECT Itemcode
        FROM RDR1
        WHERE ItemCode NOT IN (SELECT Code FROM OITT)
        AND DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SET @error = '1702';
        SET @error_message = 'PLEASE CHECK BOM NOT AVAILABLE FOR THE SELECTED ITEM';
    END
END;

---------------------A/P INVOICE : OBJECT TYPE-18 : TABLE-OPCH VALIDATION---------------------

------------------------------------------------------------------------
IF (@object_type = '18') AND (@transaction_type IN ('A', 'U'))
BEGIN
    IF EXISTS (
        SELECT * FROM PCH1 T0
        INNER JOIN OPCH T1 ON T1.DocEntry = T0.DocEntry
        WHERE T0.DocEntry = @list_of_cols_val_tab_del AND T1.DocType = 'I' AND T1.GSTTranTyp = 'GA'
        AND (ISNULL(T0.BaseEntry, '') = '' OR ISNULL(T0.BaseEntry, '') IS NULL)
    )
    BEGIN
        SELECT @Error = 1801 
        SELECT @error_message = 'A/P INVOICE" CAN NOT ADD WITHOUT GOODS RECEIPT PO.'
    END
END
----------------------------------------------------------------------------------
IF (@object_type = '18') AND (@transaction_type IN ('A', 'U'))
BEGIN
    IF EXISTS (
        SELECT T0.DocEntry FROM PCH1 T0
        INNER JOIN OPCH T1 ON T1.DocEntry = T0.DocEntry
        INNER JOIN OPDN T2 ON T2.DocEntry = T0.BaseEntry
        WHERE T1.DocType = 'I' AND T1.GSTTranTyp = 'GA' AND T1.TaxDate <> T2.TaxDate AND T0.DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @Error = 1802
        SELECT @error_message = 'A/P INVOICE BILL DATE NOT MATCH WITH GOODS RECEIPT PO. BILL DATE'
    END
END

----------------------------------------------------------------------------------
IF (@object_type = '18') AND (@transaction_type IN ('A', 'U'))
BEGIN
    IF EXISTS (
        SELECT * FROM OPCH t1
        INNER JOIN PCH12 ON t1.DocEntry = PCH12.DocEntry
        WHERE PCH12.LocStatCod <> 'RJ' AND T1.DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @Error = 1803
        SELECT @error_message = 'YOU MUST SELECT BHIWADI LOCATION OR WAREHOUSE'
    END
END


---------------------------------------------------------------------------------------

IF @transaction_type IN ('A', 'U') AND @object_type = '18'
BEGIN
    IF EXISTS (
        SELECT COUNT(*) FROM OPCH T0
        INNER JOIN PCH1 T1 ON T1.DocEntry = T0.DocEntry
        INNER JOIN dbo.[@SACD] T2 ON T1.SacEntry = T2.U_SCID
        WHERE T0.DocType = 's' AND T0.DocEntry = @list_of_cols_val_tab_del
        HAVING COUNT(T2.name) < '6'
    )
    BEGIN
        SELECT @error = 1804, @error_message = 'SAC CODE MUST BE 6 DIGIT.'
    END
END


------------------------------------------------------------------------

IF (@object_type = '18') AND (@transaction_type IN ('A','U'))
BEGIN
    IF EXISTS (
        SELECT T0.DocEntry FROM OPCH T0
        INNER JOIN PCH5 ON T0.DocEntry = PCH5.AbsEntry
        INNER JOIN OWHT ON PCH5.WTCode = OWHT.WTCode
        WHERE T0.DocEntry = @list_of_cols_val_tab_del AND T0.DocType = 'S' AND OWHT.OffclCode = '194Q'
    )
    BEGIN
        SELECT @Error = 1805 
        SELECT @error_message = 'IN SERVICE TYPE AP 194Q CANNOT BE SELECTED'
    END
END

----------------------------------------------TDS ON APINVOICE(194Q)-----------------------------------------

 IF ((@transaction_type = 'A' OR @transaction_type = 'U') AND @object_type = '18')										
		BEGIN	
		
Declare @Vendor12 nvarchar(200)
set @Vendor12=(Select CardCode From OPCH where Docentry=@list_of_cols_val_tab_del)

Declare @TDSY nvarchar(200)
set @TDSY=isnull((Select OCRD.U_TDS From OPCH,OCRD where OPCH.Docentry=@list_of_cols_val_tab_del and OPCH.CardCode=OCRD.CardCode),'')

Declare @AP_DATE Date
set @AP_DATE=(Select convert(nvarchar(100),docdate,112) From OPCH where Docentry=@list_of_cols_val_tab_del)

Declare @Item_Material integer
set @Item_Material=isnull((Select distinct ItemClass From PCH1 D,OITM H where D.ItemCode=h.ItemCode and h.ItemClass='2'
							and d.Docentry=@list_of_cols_val_tab_del),0)


Declare @AP_Value21 numeric(19,3)
set @AP_Value21=(Select isnull(sum(aa.tt),0)
From (
(select isnull((select sum(a.vv)tt from (Select (isnull((Select (Case when DocCur='INR' 
then sum(PCH1.Linetotal) else sum(PCH1.TotalFrgn) END )  From PCH1,OITM 
 where PCH1.DocEntry=OPCH.DocEntry and OITM.ItemCode=PCH1.ItemCode and OITM.InvntItem='Y'  )
,0) +
       isnull((Select sum(PCH4.TaxSum) From PCH4 where OPCH.DocEntry=PCH4.docentry ),0.0) +
       isnull((Select sum(PCH3.LineTotal) From PCH3 where OPCH.DocEntry=PCH3.docentry),0.0) -
       isnull((Case when DocCur='INR' then OPCH.DiscSum else OPCH.DiscSumFC END ),0.0))'VV'
From OPCH,OCRD,OITM
where OPCH.DocType='I' 
and OPCH.Docdate >'20210331'
and OPCH.CardCode=@Vendor12 AND OCRD.CardCode=OPCH.CardCode  
 and OPCH.DocCur='INR' and OPCH.Canceled='N' 
group by DocCur,DiscSum,DiscSumFC,OPCH.DocEntry)a),0)tt)
union all
(Select isnull(-sum(b.vv),0)tt From(Select (isnull((Select (Case when DocCur='INR' 
then sum(RPC1.Linetotal) else sum(RPC1.TotalFrgn) END )  From RPC1,OITM 
 where RPC1.DocEntry=ORPC.DocEntry and OITM.ItemCode=RPC1.ItemCode and OITM.InvntItem='Y'   )
,0) +
       isnull((Select sum(RPC4.TaxSum) From RPC4 where ORPC.DocEntry=RPC4.docentry ),0.0) +
       isnull((Select sum(RPC3.LineTotal) From RPC3 where ORPC.DocEntry=RPC3.docentry),0.0) -
       isnull((Case when DocCur='INR' then ORPC.DiscSum else ORPC.DiscSumFC END ),0.0))'VV'
From ORPC,OCRD
where ORPC.DocType='I'
and ORPC.Docdate >'20210331'
and ORPC.CardCode=@Vendor12 AND OCRD.CardCode=ORPC.CardCode  
 and ORPC.DocCur='INR' and ORPC.Canceled='N' 
group by DocCur,DiscSum,DiscSumFC,ORPC.DocEntry)b)
)AA)


If(@AP_Value21>=5000000 and @AP_DATE>'20210630' and @Item_Material=2 and @TDSY in ('Y','N') )
BEGIN
		       IF not EXISTS 										
		       (										
				Select '*'	
				From OPCH T0,PCH5 T1,OWHT H
				where T0.DocEntry=@list_of_cols_val_tab_del				
				and t0.DocEntry=t1.AbsEntry 
				and T0.DocType='I' and T1.WTCode=H.WTCode and H.OffclCode='194Q' 
				
		       ) 										
		       BEGIN										
		        Set  @error ='1806';										
		        Set  @error_message ='KINDLY FILL TDS ..';	
				END
END ;										
END ;	

---------------------------------

IF @object_type = N'18' AND (@transaction_type = N'A' OR @transaction_type = N'U')
Begin
	IF EXISTS
	(

		SELECT T0.DocEntry
		FROM OPCH T0
			INNER JOIN OPCH T1 ON T0.CardCode=T1.CardCode AND ISNULL(T0.NumAtCard,'')=ISNULL(T1.NumAtCard,'') AND 
			T1.DocEntry<>@list_of_cols_val_tab_del
		WHERE T0.DocEntry=@list_of_cols_val_tab_del  
		and CONVERT(NVARCHAR,T0.DocDate,112) between  CONVERT(NVARCHAR,(CASE WHEN (MONTH(GETDATE()))  <=3 THEN 
		convert(varchar(4),YEAR(GETDATE())-1) + '-04-01'  ELSE convert(varchar(4),YEAR(GETDATE()))+ '-04-01' END),112)
		and CONVERT(NVARCHAR,(CASE WHEN (MONTH(GETDATE()))  <=3 THEN convert(varchar(4),YEAR(GETDATE())) + '-03-31' ELSE 
		convert(varchar(4),YEAR(GETDATE())+1)+ '-03-31' END),112)



		and CONVERT(NVARCHAR,T1.DocDate,112) between  CONVERT(NVARCHAR,(CASE WHEN (MONTH(GETDATE()))  <=3 THEN 
		convert(varchar(4),YEAR(GETDATE())-1) + '-04-01'  ELSE convert(varchar(4),YEAR(GETDATE()))+ '-04-01' END),112)
		and CONVERT(NVARCHAR,(CASE WHEN (MONTH(GETDATE()))  <=3 THEN convert(varchar(4),YEAR(GETDATE())) + '-03-31' ELSE 
		convert(varchar(4),YEAR(GETDATE())+1)+ '-03-31' END),112)
	)
    BEGIN                  
        SELECT @Error = 1807                                                             
        SELECT @error_message = 'DUPLICATE VENDOR REF NO IN AP INVOICES. !'
    END  
END

--------------------------------------------------Bill Number on AP INvoice----------------------------------------------------

IF (@object_type = '18' AND ( @transaction_type = N'A'  OR @transaction_type = N'U' ))
BEGIN 
if exists (Select NumAtCard,* from OPCH where NumAtCard is null 
		and DocEntry =@list_of_cols_val_tab_del )
 		BEGIN                        
					SELECT @Error = 1808                                                             
					SELECT @error_message = 'ENTER BILL NUMBER'

END
END

-----------------------------------------TDS Calculation-------------------------------------------------------------------
IF (@object_type = '18' AND ( @transaction_type = N'A'  OR @transaction_type = N'U' ))
BEGIN 
declare @value01 int ,@vlaue02 int , @value03 int , @value04 char
set @vlaue02=(select TaxbleAmnt from PCH5 where AbsEntry=@list_of_cols_val_tab_del)
set @value04=(select top 1 WtLiable from PCH1 where DocEntry=@list_of_cols_val_tab_del and WtLiable is not null)
set  @value03=(select sum(U_QTY*U_UPRC) from PCH1 where DocEntry=@list_of_cols_val_tab_del)
set @value01=(select iif(((select TaxbleAmnt from PCH5 where AbsEntry=@list_of_cols_val_tab_del)=(select sum(U_QTY*U_UPRC) from PCH1 where DocEntry=@list_of_cols_val_tab_del)),0,1))
if((@value01>0) and  @value03!=0 and @value04='Y')
--((select iif(TaxbleAmnt=(select sum(U_QTY*U_UPRC) from PCH1 where DocEntry=@list_of_cols_val_tab_del),0,1)
--from PCH5 where AbsEntry=@list_of_cols_val_tab_del)>0)
 		BEGIN                        
					SELECT @Error = 1809                                                             
					SELECT @error_message = Cast (@value03 as nvarchar(30))+'   CHECK WTAX TAXABLE VALUE      '+cast(@vlaue02 as nvarchar(20))

END
END
-------------------------------------------------------------------------------------
IF @Object_type = N'18' and (@transaction_type = 'A' or @transaction_type = 'U')
BEGIN
IF EXISTS 
(SELECT PCH1.DOCENTRY FROM PCH1

INNER JOIN OPOR ON PCH1.BaseEntry=OPOR.DocEntry


where OPOR.U_POTY='CLOSE' AND OPOR.U_LEVEL2 <>'Y'
 
 AND PCH1.DocEntry = @list_of_cols_val_tab_del)
   
begin
  SELECT @error = 1810,
  @error_message = 'PO NOT APPROVED'


end
END
---------------------A/P CREDIT MEMO : OBJECT TYPE-19 : TABLE-ORPC VALIDATION---------------------

----------------Gate pass found based for this AP Credit Memo----------------------


IF ((@transaction_type = 'C') AND @object_type = '19')
BEGIN
       IF EXISTS 
       (
          SELECT COUNT(T0.DocEntry) FROM RPC1 T0 INNER JOIN [@UTL_GE_GPS1] T1 ON T0.DocEntry= T1.U_UTL_BASEKEY  AND T0.LineNum= T1.U_UTL_BASELINE
          WHERE T0.DocEntry=@list_of_cols_val_tab_del
       )
       
       
       BEGIN
        Set  @error ='1901';
        Set  @error_message ='GATE PASS FOUND BASED FOR THIS AP CREDIT MEMO.';
       END ;
END ;



---------------------GOODS RECEIPT PO : OBJECT TYPE-20 : TABLE-OPDN VALIDATION---------------------

---------------------------------Conversion Qty Should be match with Item Master------------------------

IF (@object_type = N'20' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN
    IF EXISTS (
        SELECT T1.NumPerMsr
        FROM PDN1 T1
        INNER JOIN OITM T2 ON T2.ITEMCODE = T1.ITEMCODE
        WHERE T1.DocEntry = @list_of_cols_val_tab_del
        AND T1.NumPerMsr <> T2.NumInBuy
        AND T1.ItemCode IN ('37200140000', '37200030000')
    )
    BEGIN
        SELECT @Error = 2001
        SELECT @error_message = 'CONVERSION QTY SHOULD BE MATCH WITH ITEM MASTER.'
    END
END

----------------CAN NOT CHANGE THE DELIVERY DATE IN PO-----------------------------------------------                              
                                                          
 IF @transaction_type IN (N'A') AND (@Object_type = N'20')
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM pdn1 w
        INNER JOIN por1 d ON d.docentry = w.baseentry
                          AND d.ObjType = w.BaseType
                          AND d.linenum = w.BaseLine
        WHERE w.DocEntry = @list_of_cols_val_tab_del
          AND CONVERT(nvarchar, d.shipdate, 103) <> CONVERT(nvarchar, w.shipdate, 103)
    )
    BEGIN
        SET @error = '2002'
        SET @error_message = 'YOU CANNOT CHANGE THE DELIVERY DATE'
    END
END

--------------------DUPLICATE BILL NO IN GRPO FOR SAME CARDCODE-----------------------------------

IF @object_type = '20' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT T0.NumAtCard
        FROM OPDN AS T0 
        WHERE T0.CardCode IN (
            SELECT T1.CardCode 
            FROM OPDN AS T1 
            WHERE T1.DocEntry = @list_of_cols_val_tab_del
        ) 
        AND T0.NumAtCard IN (
            SELECT T2.NumAtCard 
            FROM OPDN AS T2 
            WHERE T2.DocEntry = @list_of_cols_val_tab_del
        ) 
        GROUP BY T0.NumAtCard
        HAVING COUNT(*) > 1
    )
    BEGIN
        SET @Error = '2003';
        SET @error_message = 'DUPLICATED REF. NO. FOUND FOR THIS BUSINESS PARTNER';
    END
END;

-----------MATERIAL RECEIVED BEFORE DELIVERY DATE-----------------------------------------------------------

IF @transaction_type = 'A' AND @Object_type = '20'
BEGIN
    IF EXISTS (
        SELECT T0.DocDate
        FROM opdn T0
        INNER JOIN PDN1 T1 ON T0.DocEntry = T1.DocEntry
        INNER JOIN POR1 T2 ON T1.BaseEntry = T2.DocEntry AND T1.BaseType = T2.ObjType
        INNER JOIN OPOR T3 ON T2.DocEntry = T3.DocEntry
        INNER JOIN POR1 T4 ON T4.DocEntry = T2.DocEntry
        WHERE T0.Docdate > (T4.ShipDate - 10) AND T0.DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @Error = 2004;
        SELECT @error_message = 'GRPO DOCDATE IS GREATER THAN PO SHIPPING DATE';
    END
END;
	
	----------------------------------------------------------------------------------------------------------------------

IF (@object_type = N'20' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN                                             
    IF EXISTS (
        SELECT T1.VisOrder  
        FROM OPDN T0 
        INNER JOIN PDN1 T1 ON T0.DocEntry = T1.DocEntry 
        INNER JOIN POR1 T2 ON T1.BaseEntry = T2.DocEntry AND T1.BaseLine = T2.LineNum
        WHERE T0.DocEntry = @list_of_cols_val_tab_del AND ISNULL(T2.Price, 0) <> ISNULL(T1.Price, 0)
        --AND T1.LineNum = T2.BaseLine
        GROUP BY T1.VisOrder
        ---HAVING SUM(T1.BaseOpnQty) <> SUM(T1.Quantity)
    )
    BEGIN                        
        SELECT @Error = 2005                                                             
        SELECT @error_message = 'PRICE IN GRPO SHOULD BE SAME AS PER THE PURCHASE ORDER.'                        
    END                           
END 

----------------------------------duplicate vendor reference number in grpo-------------------------------

IF @object_type = '20' AND @transaction_type = 'A'
BEGIN
    DECLARE @venno AS VARCHAR(100)
    DECLARE @vennam AS VARCHAR(100)
    
    IF @object_type = '20'
    BEGIN
        SELECT @venno = NumAtCard, @vennam = CardCode FROM OPDN T0 WHERE DocEntry = @list_of_cols_Val_tab_del
        
        BEGIN
            IF @venno IS NOT NULL
            BEGIN
                IF 1 != (
                    SELECT COUNT(DocEntry) 
                    FROM OPDN WITH (NOLOCK) 
                    WHERE (NumatCard = @venno) AND (CardCode = @vennam)
                )
                BEGIN
                    SELECT @error = 2006
                    SELECT @error_message = 'DUPLICATE VENDOR REF NUMBER!'
                END
            END
        END
    END
END

-------------------------------------------------------------------------------------------------------------------------------------

IF @object_type = '20' AND @transaction_type = 'A'
BEGIN
    IF EXISTS (
        SELECT T0.DocEntry
        FROM [dbo].[OPDN] T0
        INNER JOIN PDN1 T1 ON T0.DocEntry = T1.DocEntry
        INNER JOIN POR1 T2 ON T2.DocEntry = T1.BaseEntry AND T1.BaseLine = T2.LineNum
        INNER JOIN OPOR T3 ON T3.DocEntry = T2.DocEntry
        WHERE T0.DocEntry = @list_of_cols_val_tab_del AND T1.Price <> T2.Price AND T0.DocType = 'I'
    )
    BEGIN
        SELECT @error = 2007,
               @error_message = 'YOU CANNOT ADD GRPO AS GRPO PRICE MUST BE THE SAME AS PO PRICE'
    END
END

------------------------------------------------------------------------------------------------------------------

IF (@object_type = N'20' AND ( @transaction_type = N'A' OR @transaction_type = N'U' ))
BEGIN 
    IF EXISTS (
        SELECT NumAtCard
        FROM OPOR
        WHERE NumAtCard IS NOT NULL AND LEN(ISNULL(NumAtCard, '')) <> 16
        AND DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN                        
        SELECT @Error = 2008                                                             
        SELECT @error_message = 'ENTER A VALID BILL NUMBER OF LENGTH 16 NUMERIC CHARACTERS ONLY!!!!!'  
    END
END
----------------------------QR Code in GRPO -------------------------------------------------------------------------

IF (@object_type = N'20' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN
    IF EXISTS (
        SELECT QRCodeSrc
        FROM OPDN
        WHERE (QRCodeSrc IS NULL OR QRCodeSrc NOT LIKE 'MRR%')
        AND DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @Error = 2009,
               @error_message = 'PLEASE PUT THE BATCH NUMBER IN THE QR CODE FIELD.'
    END
END


-----------------------------------------------------------Gate Entry by Tushar 

IF (@object_type = N'20' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN
    IF EXISTS (
        SELECT T0.DocEntry
        FROM OPDN T0
        WHERE DocEntry = @list_of_cols_val_tab_del AND ISNULL(U_UTL_GE_DENT, '') = ''
    )
    BEGIN
        SELECT @Error = 2010,
               @error_message = 'GATE ENTRY NO. CANNOT BE BLANK.'
    END
END
---------------------------------------------------------------------------------------------------------------------------

IF (@object_type = N'20' AND (@transaction_type = N'A' OR @transaction_type = N'U'))	
BEGIN
    DECLARE @BPCode VARCHAR(20)
    DECLARE @InvNo VARCHAR(20)

    SET @BPCode = (SELECT T0.U_UTL_CardCode FROM [@UTL_GE_OGIN] T0 WHERE DocEntry = @list_of_cols_val_tab_del)
    SET @InvNo = (SELECT T0.U_UTL_InvoiceNo FROM [@UTL_GE_OGIN] T0 WHERE DocEntry = @list_of_cols_val_tab_del)

    IF EXISTS (SELECT DocEntry FROM [@UTL_GE_OGIN] WHERE U_UTL_CardCode = @BPCode AND U_UTL_InvoiceNo = @InvNo)
    BEGIN                        
        SELECT @Error = 2011
        SELECT @error_message = 'INVOICE NO CAN NOT BE DUPLICATE WITH RESPECT TO VENDOR CODE'
    END
END

----------------------------------------------------------------------------------------------------------------------
IF (@object_type = N'20' AND (@transaction_type = N'A' OR @transaction_type = N'U'))	
BEGIN
    IF EXISTS (SELECT U_GEDT FROM OPDN WHERE U_GEDT IS NULL AND DocEntry = @list_of_cols_val_tab_del)
    BEGIN                        
        SELECT @Error = 2012                                                           
        SELECT @error_message = 'GATE ENTRY DATE CANNOT BE BLANK'
    END
END


-----------------------------------------------------------------------------------------------------------------------------------------------------------
IF (@object_type = N'20' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN 
    IF EXISTS (
        SELECT NumAtCard
        FROM OPOR
        WHERE NumAtCard IS NULL AND NumAtCard = '' --and len(isnull(NumAtCard,0))<>16
          AND DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN                        
        SELECT @Error = 2014                                                             
        SELECT @error_message = 'ENTER BILL NUMBER'
    END
END

---------------Gate Entry transaction notification (add-on standard) start ----------------------------------------------------

IF ((@transaction_type = 'A') AND @object_type = '20')
BEGIN
    DECLARE @check nvarchar
    SELECT @check = U_UTL_CHKVAL FROM "@UTL_GE_OGST" WHERE U_UTL_PROCS = 'GE' AND U_UTL_DOCTY = 'PO' AND U_UTL_CHKVAL = 'Y';
    
    IF (@check = 'Y')
    BEGIN
        IF EXISTS (
            SELECT ISNULL("U_UTL_GE_DENT", '-1') AS "U_UTL_GE_DENT"
            FROM OPDN
            INNER JOIN PDN1 T1 ON T1.DocEntry = OPDN.DocEntry
            LEFT JOIN PDN1 T2 ON T2.DocEntry = T1.BaseEntry AND T2.LineNum = T1.BaseLine AND T2.TrgetEntry = T1.DocEntry
            WHERE OPDN.DocEntry = @list_of_cols_val_tab_del AND ("U_UTL_GE_DENT" <= 0 OR "U_UTL_GE_DENT" IS NULL) AND (T1.BaseType <> -1)
              AND OPDN.DocType = 'I' AND OPDN.DocStatus = 'O'
        )
        BEGIN
            SET @error = 2015;
            SET @error_message = 'GATE INWARD DOCUMENT MUST BE TAGGED TO THIS DOCUMENT.';
        END;
    END;
END;

---------------------Quantity should be equal to Gate Entry quantity------------------------------------------------------

IF ((@transaction_type = 'A') AND @object_type = '20')
BEGIN
declare @check1 nvarchar
SELECT @check1=U_UTL_CHKVAL FROM "@UTL_GE_OGST" WHERE U_UTL_PROCS='GE' AND U_UTL_DOCTY='PO' AND U_UTL_CHKVAL='Y';
IF(@check1='Y')
BEGIN
       IF EXISTS 
       (
        SELECT T2.ItemCode FROM [@UTL_GE_GIN1] T1
		 INNER JOIN [@UTL_GE_OGIN] T0 on T1.DocEntry=T0.DocEntry 
		INNER JOIN PDN1 T2 ON T1.DocEntry=T2.U_UTL_GE_DocE and T1.LineId=T2.U_UTL_GE_Line AND T1.U_UTL_ITCD=T2.ItemCode 
		 where T2.DocEntry=@list_of_cols_val_tab_del and (ISNULL(T1.U_UTL_QTY,0) != ISNULL(T2.Quantity,0)) 

	      )
       
       BEGIN
       Set @error = 2016;
       Set @error_message ='QUANTITY SHOULD BE EQUAL TO GATE ENTRY QUANTITY';
       END ;
END;
END ;

-------------------------------------------------------------------------------------------------------------------------------

IF ((@transaction_type = 'A') AND @object_type = '20')
BEGIN

SELECT @check=U_UTL_CHKVAL FROM "@UTL_GE_OGST" WHERE U_UTL_PROCS='GE' AND U_UTL_DOCTY='PO' AND U_UTL_CHKVAL='Y';
IF(@check='Y')
BEGIN
       IF EXISTS 
       (
		SELECT ISNULL("U_UTL_GE_DNUM",'-1') AS "U_UTL_GE_DNUM" 
		FROM OPDN
		INNER JOIN PDN1 T1 ON T1.DocEntry=OPDN.DocEntry	
		LEFT JOIN PDN1 T2 ON T2.DocEntry=T1.BaseEntry AND T2.LineNum=T1.BaseLine AND T2.TrgetEntry=T1.DocEntry
			WHERE OPDN.DocEntry=@list_of_cols_val_tab_del and ("U_UTL_GE_DNUM"<=0 OR "U_UTL_GE_DNUM" IS NULL) AND (T1.BaseType<>-1) 
			and OPDN.DocStatus='O' and OPDN.DocType='I'
       )
       
       BEGIN
       Set @error = 2017;
       Set @error_message ='GATE INWARD DOCUMENT NUMBER CAN NOT BE BLANK.';
       END ;

END;
END ;

-------------------------------GRPO CANNOT ADD WITH GREATER QUANTITY IN PO-------------------------------

IF @Object_type = N'20' and @transaction_type = N'A'
BEGIN
 declare  @line int
SELECT @line = (LineNum + 1)
 From PDN1
 Where PDN1.DocEntry = @list_of_cols_val_tab_del
   and (Quantity > BaseOpnQty)
 Order by LineNum
If (not ISNULL(@line, 0) = 0)
begin
  Set @error = 2018
  Set @error_message = N'LINE QUANTITY' + CONVERT(nvarchar(4), @line) + N' IS MORE THEN ORDERED !'
end
END
------------------ GRPO CAN'T ADD WITHOUT APPROVAL ----------------------

IF @Object_type = N'20' and (@transaction_type = 'A' or @transaction_type = 'U')
BEGIN
IF EXISTS 
(SELECT PDN1.DOCENTRY FROM PDN1

INNER JOIN OPOR ON PDN1.BaseEntry=OPOR.DocEntry


where OPOR.U_POTY='CLOSE' AND OPOR.U_LEVEL2 <>'Y'
 
 AND PDN1.DocEntry = @list_of_cols_val_tab_del)
   
begin
  SELECT @error = 2019,
  @error_message = 'PO NOT APPROVED'


end
END

-----------------------------------------GRPO CAN NOT ADD WITHOUT PURCHASE ORDER-----------------------

IF (@object_type='20')
 IF (@transaction_type='A')
 BEGIN
 IF (SELECT max(ISNULL(T0.BaseEntry,-1))  FROM PDN1 T0 WHERE T0.DocEntry = @list_of_cols_val_tab_del) != -1
 BEGIN
  set @error = 0
  set @error_message = N'Ok'
 END
 ELSE
 BEGIN
    set @error_message='GOODS RECEIPT PO CANNOT BE CREATED DIRECTLY. COPY FROM PO'
    set @error=2020  
 END
 END

 --------------------------------------------GRPO QC MAND------------------------------------------

IF @transaction_type in ('A') AND @object_type = '20'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.PDN1 T0 INNER JOIN OITM T1 ON T1.ITEMCODE=T0.ITEMCODE
Where   T1.U_UTL_QCCHK='Y' AND T0.WHSCODE <>'IQC'
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 2021, @error_message = 'WRONG WAREHOUSE SELECTED FOR QC ITEMS'
End
END
--------------------------------------------------NON QC ITEM MST1-----------------
IF @transaction_type in ('A') AND @object_type = '20'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.PDN1 T0 INNER JOIN OITM T1 ON T1.ITEMCODE=T0.ITEMCODE
Where  T1.U_UTL_QCCHK='N' AND T0.WHSCODE <>'MST'
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 2022, @error_message = 'WRONG WAREHOUSE SELECTED FOR NON QC ITEMS'
End
END

---------------------------------

IF @Object_type = N'20' and (@transaction_type = 'A' or @transaction_type = 'U')
BEGIN
IF EXISTS 
(SELECT PDN1.DOCENTRY FROM PDN1

INNER JOIN OPOR ON PDN1.BaseEntry=OPOR.DocEntry


where OPOR.U_POTY='SCHEDULE' AND OPOR.U_LEVEL1 ='N'
 
 AND PDN1.DocEntry = @list_of_cols_val_tab_del)
   
begin
  SELECT @error = 2024,
  @error_message = 'PO NOT APPROVED'
end
END

---------------------------------

IF (@object_type = N'20' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN
   IF EXISTS (
      SELECT T1.VisOrder  
      FROM OPDN T0 
      INNER JOIN PDN1 T1 ON T0.DocEntry = T1.DocEntry 
      INNER JOIN POR1 T2 ON T1.BaseEntry = T2.DocEntry AND T1.BaseLine = T2.LineNum
      WHERE T0.DocEntry = @list_of_cols_val_tab_del AND ISNULL(T2.Price, 0) <> ISNULL(T1.Price, 0)
      --AND T1.LineNum = T2.BaseLine
      GROUP BY T1.VisOrder  
      ---HAVING SUM(T1.BaseOpnQty) <> SUM(T1.Quantity)
   )
   BEGIN
      SELECT @Error = 2025
      SELECT @error_message = 'PRICE IN GRPO SHOULD BE THE SAME AS PER THE PURCHASE ORDER.'
   END
END

--------------------------------------------------------------------------------

--		IF @transaction_type in ('A','U') or  @object_type = '20'
--begin
--		If Exists (Select DocEntry From OPDN Where 
--		DocDate < DATEADD(d,-3,DocDate)) 
		
--		Begin
				
--		        Set  @error ='2026';										
--		        Set  @error_message ='POSTING DATE SHOULD NOT BE LESS THAN 3 DAYS ';		
--		End

--		end

------------------------------------------------------------------------------------------------------------------------

IF (@object_type = N'20' AND ( @transaction_type = N'A'  OR @transaction_type = N'U' ))	
Begin
Declare @GRPONumatcrad varchar(20)
Declare @GEEntry varchar(20)
Declare @GRPODate Date
Declare @GEInvNo varchar(20)
Declare @GEInvDate Date

Set @GRPONumatcrad=(SELECT T0.NumAtCard  from OPDN T0 where  DocEntry =@list_of_cols_val_tab_del )
Set @GRPODate=(SELECT T0.TaxDate  from OPDN T0 where  DocEntry =@list_of_cols_val_tab_del )
Set @GEInvNo=(SELECT T0.U_UTL_InvoiceNo  from [@UTL_GE_OGIN] T0 where  DocEntry =@list_of_cols_val_tab_del )
Set @GEInvDate=(SELECT T0.U_UTL_InvDate  from [@UTL_GE_OGIN] T0 where  DocEntry =@list_of_cols_val_tab_del )

if(isnull(@GRPONumatcrad,'')<>isnull(@GEInvNo,''))
         
		   
		   BEGIN                        
                                  SELECT @Error = 4000                                                             
                                  SELECT @error_message = 'GRPO NUMATCARD SHOULD BE MATCH WITH GATEENTRY INVOICE NO.'

END

if(isnull(@GRPODate,'')<>isnull(@GEInvDate,''))
         
		   
		   BEGIN                        
                                  SELECT @Error = 2027                                                             
                                  SELECT @error_message = 'GRPO TAXDATE SHOULD BE MATCH WITH GATEENTRY INVOICE DATE.'

END

End

--------------------------------Good Issue/Good Receipt Not Today-------------------------------------------
--IF @transaction_type in ('A','U') or  @object_type = '20'

--		BEGIN											
--		IF EXISTS (SELECT DocDate,TaxDate FROM OPDN 										
--		WHERE DocEntry  = @list_of_cols_val_tab_del											
								
--		and Taxdate < docdate)
--		BEGIN

--		        Set  @error ='2028';										
--		        Set  @error_message ='DOCUMENT/REF DATE SHOULD BE LESS THEN POSTING DATE';		
--		End

--		END

---------------------GOODS RETURN : OBJECT TYPE-21 : TABLE-OPPD VALIDATION---------------------

-----------------------------------------------------------------gate pass---------------------------

IF ((@transaction_type = 'C') AND @object_type = '21')
BEGIN
       IF EXISTS 
       (
          SELECT COUNT(T0.DocEntry) FROM RPD1 T0 INNER JOIN [@UTL_GE_GPS1] T1 ON T0.DocEntry= T1.U_UTL_BASEKEY  AND T0.LineNum= T1.U_UTL_BASELINE
          WHERE T0.DocEntry=@list_of_cols_val_tab_del
       )      
       
       BEGIN
        Set  @error ='2029';
        Set  @error_message ='GATE PASS FOUND BASED FOR THIS GOODS RETURN.';
       END ;
END ;
---------------------PURCHASE ORDER : OBJECT TYPE-22 : TABLE-OPOR VALIDATION---------------------

-------------------PR IS  MANDATORY FOR PO--------------------
          
IF (@object_type = '22') AND (@transaction_type IN ('U', 'A'))
BEGIN
    IF EXISTS(
        SELECT '*'
        FROM OPOR o, por1 h
        WHERE o.docentry = @list_of_cols_val_tab_del
        AND o.DocType = 'i'
        AND o.docentry = h.docentry
        AND h.baseentry IS NULL
    )
    BEGIN
        SELECT @error = 2201
        SELECT @error_message = 'DIRECT PO NOT ALLOWED ADD PURCHASE REQUEST AS PER SOP '
    END
END        

--------------------------Cannot Add Purchase Order Without Purchase Request-------------------------------------------------

IF @object_type = '22' AND (@transaction_type IN ('U','A'))
BEGIN
    IF EXISTS (
        SELECT *
        FROM OPOR A
        INNER JOIN POR1 B ON A.DocEntry = B.DocEntry
        WHERE A.DocEntry = @list_of_cols_val_tab_del
        AND A.DocType = 'i'
        AND LEN(B.ItemCode) = '11'
        AND B.BaseType <> '1470000113'
    )
    BEGIN
        SET @error = '2202';
        SET @error_message = 'YOU CANNOT ADD PURCHASE ORDER WITHOUT PURCHASE REQUEST';
    END

	
-------------------------------Location Must Be Bhiwadi For Purchase Order-----------------------------------------

    IF EXISTS (
        SELECT *
        FROM OPOR A
        INNER JOIN POR1 B ON A.DocEntry = B.DocEntry
        WHERE A.DocEntry = @list_of_cols_val_tab_del
        AND B.LocCode <> 2
    )
    BEGIN
        SET @error = '2203';
        SET @error_message = 'LOCATION MUST BE BHIWADI FOR PURCHASE ORDER';
    END

--------------------------------HSN/SAC Code Is Not Blank-----------------------------------------------------------

    IF EXISTS (
        SELECT *
        FROM OPOR A
        INNER JOIN POR1 B ON A.DocEntry = B.DocEntry
        WHERE A.DocEntry = @list_of_cols_val_tab_del
        AND ISNULL(B.HsnEntry,'') = ''
        AND ISNULL(B.SacEntry,'') = ''
    )
    BEGIN
        SET @error = '2204';
        SET @error_message = 'HSN/SAC CODE IS NOT BLANK';
    END

----------------------------------ItemCode Should Match With Purchase Request--------------------------------------------------------------------

    IF EXISTS (
        SELECT *
        FROM OPOR A
        INNER JOIN POR1 B ON A.DocEntry = B.DocEntry
        INNER JOIN PRQ1 C ON B.BaseEntry = C.DocEntry AND B.BaseLine = C.LineNum
        WHERE A.DocEntry = @list_of_cols_val_tab_del
        AND B.ItemCode <> C.ItemCode
    )
    BEGIN
        SET @error = '2205';
        SET @error_message = 'ITEMCODE SHOULD MATCH WITH PURCHASE REQUEST';
    END

---------------------------------------------------------------------------------------------------

    IF EXISTS (
        SELECT *
        FROM OPOR A
        INNER JOIN POR1 B ON A.DocEntry = B.DocEntry
        INNER JOIN PRQ1 C ON B.BaseEntry = C.DocEntry AND B.BaseLine = C.LineNum
        WHERE A.DocEntry = @list_of_cols_val_tab_del
        AND B.Quantity > C.Quantity + (C.Quantity * 10 / 100)
    )
    BEGIN
        SET @error = '2206';
        SET @error_message = 'ITEMCODE QUANTITY SHOULD NOT BE GREATER THAN PURCHASE REQUEST';
    END
END;


--------------------------------------------------------------------------------------------------------

IF (@object_type = '22' AND @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT *
        FROM OPOR
        WHERE DocEntry = @list_of_cols_val_tab_del
        AND U_POTY = 'CLOSE'
        AND CardCode NOT IN ('V000643', 'V000451', 'V000199')
        AND UserSign2 <> 31
        AND U_LEVEL2 = 'Y'
    )
    BEGIN
        SET @error = '2207';
        SET @error_message = 'PO CANNOT BE UPDATED WHEN PO TYPE IS CLOSE AND APPROVAL 2 IS YES';
    END
END;


---------------------------------------------------------------------------------------------------

IF (@object_type = '22' AND @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT *
        FROM OPOR
        WHERE DocEntry = @list_of_cols_val_tab_del
        AND U_POTY = 'CLOSE'
        AND CardCode NOT IN ('V000451', 'V000199')
        AND UserSign2 <> 32
        AND U_LEVEL1 = 'Y'
    )
    BEGIN
        SET @error = '2208';
        SET @error_message = 'PO CANNOT BE UPDATED WHEN PO TYPE IS CLOSE AND APPROVAL 1 IS YES';
    END
END;


-------------------------------------------------------------------------------------------------

IF (@object_type = '22' AND @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT *
        FROM OPOR
        WHERE DocEntry = @list_of_cols_val_tab_del
        AND U_POTY = 'SCHEDULE'
        AND CardCode NOT IN ('V000451', 'V000199')
        AND UserSign2 <> 32
        AND UserSign <> 32
        AND U_LEVEL1 = 'Y'
    )
    BEGIN
        SET @error = '2209';
        SET @error_message = 'SCHEDULE CANNOT BE UPDATED WHEN APPROVAL 1 IS YES';
    END
END;


----------------------------------------------------------------------------------------

IF (@object_type = '22' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF EXISTS (
        SELECT OPOR.DocEntry
        FROM OPOR
        INNER JOIN POR1 ON OPOR.DocEntry = POR1.DocEntry
        INNER JOIN OPRQ ON POR1.BaseRef = OPRQ.DocNum
        WHERE OPOR.DocEntry = @list_of_cols_val_tab_del
        AND OPOR.U_PRLEVEL0 <> 'Y'
    )
    BEGIN
        SET @error = '2210';
        SET @error_message = 'INDENT NOT APPROVED FROM LEVEL 2';
    END
END;

--------------------------------------------------------------------------------------------------------------

IF ((@transaction_type = 'C') AND @object_type = '22')
BEGIN
       IF EXISTS 
       (
          SELECT COUNT(T0.DocEntry) FROM POR1 T0 INNER JOIN [@UTL_GE_GIN1] T1 ON T0.DocEntry= T1.U_UTL_BASENTR  
		  AND T0.LineNum= T1.U_UTL_BASELINE
          WHERE T0.DocEntry=@list_of_cols_val_tab_del
       )
 
       BEGIN
        Set  @error ='2211';
        Set  @error_message ='GATE ENTRY FOUND BASED FOR THIS PURCHASE ORDER';
       END ;
END ;

---------------------------------------------------------------------------------------------------

IF (@object_type = N'22' AND ( @transaction_type = N'A'  OR @transaction_type = N'U' ))
BEGIN 
if exists (SELECT NumAtCard  from OPOR where NumAtCard  is not null --and len(isnull(NumAtCard,0))<>16
		and DocEntry =@list_of_cols_val_tab_del  and NumAtCard like '% %')
 		BEGIN                        
					SELECT @Error = 2212                                                             
					SELECT @error_message = 'NO SPACE ALLOWED'

END
END

------------------------------------------------------------------------------------------------------------------------------------
If @object_type='22' and @transaction_type='A'

BEGIN

If Exists (

SELECT T0.DocEntry from OPOR T0
inner join POR1 T1 ON T1.DocEntry=T0.DocEntry
INNER JOIN OITM T2 ON T1.ItemCode=T2.ItemCode
Where T0.DocEntry = @list_of_cols_val_tab_del and T1.TaxCode IN ('',NULL))

BEGIN

Select @error = 2213,
@error_message = 'YOU CAN NOT ADD PO WITHOUT TAX CODE'

End
END



--------------------------------------PO AND SCHEDULE-------------------------
IF @object_type=N'22' AND (@transaction_type = 'A' or @transaction_type = 'U')
       BEGIN
IF  exists (Select T0.DOCENTRY from dbo.OPOR T0 INNER JOIN POR1 T1 ON T1.DocEntry=T0.DocEntry
Where  T0.U_POTY='SCHEDULE' AND T1.AgrNo is null
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 2214, @error_message = 'BLANKET AGREEMENT NOT AVAILABLE'
End
END


---------------------------------------------PROTO TYP PO --------------------------------------------------------------
IF @transaction_type IN ('A', 'U') AND @object_type = '22'
BEGIN
   IF EXISTS (
      SELECT T0.DocEntry
      FROM dbo.POR1 T0
      WHERE T0.ItemCode LIKE '%PR%' AND T0.Quantity >= '55'
      AND T0.DocEntry = @list_of_cols_val_tab_del
   )
   BEGIN
      SELECT @error = 2215, @error_message = 'QUANTITY IS GREATER THAN PROTO ITEM'
   END
END
---------------------------------------------------------------------------------------------------------------------
IF @transaction_type IN ('A', 'U') AND @object_type = '22'
BEGIN
   IF EXISTS (
      SELECT T0. DOCENTRY,T1.SacEntry,T2.Name
      FROM OPOR T0
      INNER JOIN POR1 T1 ON T1.DocEntry = T0.DocEntry
      LEFT JOIN dbo.[@SACD] T2 ON T1.SacEntry = T2.U_SCID
      WHERE T0.DocEntry = @list_of_cols_val_tab_del AND T0.DocType = 'S' AND LEN(T2.name) < 6
	     )
   BEGIN
      SELECT @error = 2216, @error_message = 'SAC CODE MUST BE 6 DIGIT.'
   END
END

------------------------------------------------------------------------------------------------------------------
If @object_type='22' and @transaction_type='A'

BEGIN

If Exists (

SELECT T0.DocEntry from OPOR T0
inner join POR1 T1 ON T1.DocEntry=T0.DocEntry
INNER JOIN OITM T2 ON T1.ItemCode=T2.ItemCode
Where T0.DocEntry = @list_of_cols_val_tab_del and T2.ChapterID IS NULL AND T2.ChapterID=63)

BEGIN

Select @error = 2217,
@error_message = 'YOU CAN NOT ADD PO WITHOUT HSN NUMBER'

End
END
----------------------------------------------
IF (@object_type = '22') AND (@transaction_type IN ('A'))
BEGIN
    IF EXISTS (SELECT A.U_LEVEL1 FROM OPOR A WHERE A.U_LEVEL1 = 'Y' AND A.DocEntry = @list_of_cols_val_tab_del)
    BEGIN
        SELECT @Error = 2218
        SELECT @error_message = 'PLEASE SELECT APPROVAL 1 IN PENDING STAGE!!!'
    END
END


--------------------------------------

IF (@object_type = '22') AND (@transaction_type IN ('A'))
BEGIN
    IF EXISTS (SELECT A.U_LEVEL2 FROM OPOR A WHERE A.U_LEVEL2 = 'Y' AND A.DocEntry = @list_of_cols_val_tab_del)
    BEGIN
        SELECT @Error = 2219
        SELECT @error_message = 'PLEASE SELECT APPROVAL 2 IN PENDING STAGE!!!'
    END
END
--------------------------------------------------------------------------------------------------------------------------------
IF ((@transaction_type = 'C') AND @object_type = '22')
BEGIN
       IF EXISTS 
       (
          SELECT COUNT(T0.DocEntry) FROM POR1 T0 
		  INNER JOIN [@UTL_GE_GIN1] T1 ON T0.DocEntry= T1.U_UTL_BASENTR  AND T0.LineNum= T1.U_UTL_BASELINE
          WHERE T0.DocEntry=@list_of_cols_val_tab_del
       )
 
       BEGIN
        Set  @error ='2220';
        Set  @error_message ='GATE ENTRY FOUND BASED FOR THIS PURCHASE ORDER';
       END ;
END ;

---------------------SALES QUOTATION : OBJECT TYPE-23 : TABLE-OQUT VALIDATION---------------------


---------------------INCOMING PAYMENT : OBJECT TYPE-24 : TABLE-ORCT VALIDATION---------------------


---------------------JOURNAL ENTRY : OBJECT TYPE-30 : TABLE-OJDT VALIDATION---------------------

-----------------------------------------------------------------------------------
--		IF @transaction_type in ('A','U') or  @object_type = '30'
--begin
--		If Exists (Select * From OJDT Where Convert(Date,RefDate)=Convert(Date,Getdate()))
		
--		Begin
				
--		        Set  @error ='3001';										
--		        Set  @error_message ='Posting date Should Not be Today date ';		
--		End

--		end


---------------------OUTGOING PAYMENTS : OBJECT TYPE-46 : TABLE-OVPM VALIDATION---------------------


---------------------GOODS RECEIPT : OBJECT TYPE-59 : TABLE-OIGN VALIDATION---------------------

-------------------------------production Receipt can not without issue-----------------------------   

-------------------------Prod Receipt after Issuance Only ----------VVI-------------------------------------------------
 
-- IF @transaction_type = 'A' AND @Object_type = '59' 
--BEGIN
--IF EXISTS (
--SELECT T0.DOCENTRY FROM dbo.IGN1 T0 WHERE T0.DOCENTRY = @list_of_cols_val_tab_del)
--BEGIN
--DECLARE @entry INT
--SELECT @entry = T0.BASEENTRY FROM dbo.IGN1 T0 WHERE T0.DOCENTRY = @list_of_cols_val_tab_del
--IF EXISTS (
--SELECT T1.ITEMCODE, T1.PLANNEDQTY, T2.QUANTITY, T2.BASEENTRY AS 'ISSUED QTY' 
--FROM dbo.OWOR T0 
--INNER JOIN dbo.WOR1 T1 ON T0.DOCENTRY = T1.DOCENTRY
--LEFT OUTER JOIN dbo.IGE1 T2 ON T2.BASEENTRY = T0.DOCENTRY AND T1.ITEMCODE = T2.ITEMCODE
--WHERE T1.PLANNEDQTY > ISNULL(T2.QUANTITY, 0)  AND T0.DOCENTRY = @entry and t0.type<>'d'

--)

--SELECT @Error = 5901, @error_message = 'Components NOT ISSUED'

--END

--ELSE

--SELECT @Error = 5901, @error_message = 'Components NOT ISSUED'

--END
----------------------------------------------------------------------------------------------------
IF @transaction_type IN (N'A', N'U') AND (@Object_type = N'59')
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM IGN1 A
        WHERE a.DocEntry = @list_of_cols_val_tab_del
        AND a.BaseType = 202
    )
    BEGIN
        IF EXISTS (
            SELECT '*'
            FROM IGN1 i, OWOR w, WOR1 o
            where i.DocEntry = @list_of_cols_val_tab_del
            AND i.BaseEntry = w.DocEntry
            AND w.DocEntry = o.DocEntry
            AND ISNULL(w.CmpltQty, 0) > ROUND((o.IssuedQty / o.BaseQty), 1)
        )
        BEGIN
            SET @error = '5902'
            SET @error_message = 'RECEIPT QUANTITY EXCEEDED'
        END
    END
END

---------------------------------------------------------------------------------------------------------------

IF ((@transaction_type = 'A') AND @object_type = '59')
BEGIN
       IF EXISTS 
       (
        SELECT T2.ItemCode FROM [@UTL_GE_GIN1] T1
 INNER JOIN [@UTL_GE_OGIN] T0 on T1.DocEntry=T0.DocEntry 
INNER JOIN IGN1 T2 ON T1.DocEntry=T2.U_UTL_GE_DocE and T1.LineId=T2.U_UTL_GE_Line AND T1.U_UTL_ITCD=T2.ItemCode 
 where T2.DocEntry=@list_of_cols_val_tab_del and (ISNULL(T1.U_UTL_QTY,0) != ISNULL(T2.Quantity,0))
       )
       
       BEGIN
       Set @error =5903;
       Set @error_message ='QUANTITY MUST BE EQUAL TO GATE ENTRY QUANTITY';
       END ;
END ;

--------------------------------------------------------------------------------

IF ((@transaction_type = 'C') AND @object_type = '59')
BEGIN
       IF EXISTS 
       (
          SELECT COUNT(T0.DocEntry) FROM IGN1 T0 
		  INNER JOIN [@UTL_GE_GIN1] T1 ON T0.DocEntry= T1.U_UTL_BASENTR  AND T0.LineNum= T1.U_UTL_BASELINE
          WHERE T0.DocEntry=@list_of_cols_val_tab_del
       )       
       
       BEGIN
        Set  @error ='5904';
        Set  @error_message ='GATE ENTRY FOUND BASED FOR THIS GOODS RECEIPT.';
       END ;
END ;

------------------------------------Production Receive Qty Exceed Error---------------------------------------------------          
            
  IF @transaction_type IN (N'A', N'U') AND (@Object_type = N'59')
                                                                 
BEGIN                                                        
 if exists ( select '*' from IGn1 A,WOR1 B, (Select c.BaseEntry, sum(round(C.Quantity,2) )Quantity 
 from IGE1 c where  c.BaseType = 202 group by c.BaseEntry  ) e                 
    WHERE  A.docentry = @list_of_cols_val_tab_del           
    and a.BaseType = 202          and A.Baseentry = B.DocEntry        
    and B.DocEntry = e.BaseEntry        
    and round((A.Quantity)*(b.baseqty),2) > round(e.Quantity,2)    
 )                                                              
    begin    
                       SET @error = '5905'                                                              
                       SET @error_message = 'RECEIPT QTY IS EXCEED ISSUE QUANTITY......'                             
             END                                                          
  end            

  ------------------------------------Received Qty cannot be greater then planned Qty   -------------------------------------------------

IF @transaction_type IN (N'A', N'U') AND (@Object_type = N'59')      
BEGIN            
            
            

 Declare @QtyReceived decimal(19,4)            
 Declare @QtyPlanned decimal(19,4)            
 Declare @QtyCompl decimal(19,4)            
 Declare @BaseRef varchar(208)            
 Declare @BaseEntry int            
Declare @CheckError int            
SET @CheckError = 1            
         
 Select  @BaseRef = T1.[BaseRef],
		@BaseEntry = T1.[BaseEntry]  From OIGN T0 
 Inner JOIN IGN1 T1 ON T0.DocEntry = T1.DocEntry where T0.DocEntry = @list_of_cols_val_tab_del --and LineNum = 0            
 Select  @QtyCompl = Sum(T1.[Quantity]) From OIGN T0 Inner JOIN IGN1 T1 ON T0.DocEntry = T1.DocEntry 
 where  T1.BaseEntry = @BaseEntry            
 Select @QtyPlanned = T2.[PlannedQty] From OWOR T2 Where T2.DocEntry  =  @BaseEntry  and t2.Type <> 'p'           
            
 IF @QtyCompl > @QtyPlanned            
 BEGIN            
             
  set @error_message= 'RECEIVED QTY CANNOT BE GREATER THEN PLANNED QTY'             
  set @error=5906             
            
END            
END 

--------------------------------------------------NON QC ITEM MST1-----------------
IF @transaction_type in ('A') AND @object_type = '59'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.IGN1 T0 INNER JOIN OITM T1 ON T1.ITEMCODE=T0.ITEMCODE
Where  T1.U_UTL_QCCHK='N' AND T0.WHSCODE in ('MST','SCP','pts') and T0.ITEMCODE<>'99900010000'
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 5907, @error_message = 'WRONG WAREHOUSE SELECTED FOR NON QC ITEMS'
End
END

-------------------------------------------------Jobwork QC Item----------------------

IF @transaction_type in ('A') AND @object_type = '59'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.IGN1 T0 INNER JOIN OITM T1 ON T1.ITEMCODE=T0.ITEMCODE
Where  T1.U_UTL_QCCHK='N' AND T0.WHSCODE not in ('MST','SCP','pts') and T0.ITEMCODE<>'99900010000'
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 5908, @error_message = 'WRONG WAREHOUSE SELECTED FOR NON QC ITEMS'
End
END 

--------------------------------Good Issue/Good Receipt Not Today-------------------------------------------

--IF @transaction_type in ('A','U') or  @object_type = '59'
--begin
--		If Exists (Select DocEntry From OIGN Where Convert(Date,DocDate)=Convert(Date,Getdate()))
--		Begin
				
--		        Set  @error ='5911';										
--		        Set  @error_message ='POSTING DATE SHOULD NOT BE TODAY DATE ';		
--		End

--		end


--------------------------------Good Issue/Good Receipt Not Today-------------------------------------------

--IF @transaction_type in ('A','U') or  @object_type = '59'
--begin
--		If Exists (Select DocEntry From OIGN Where  --Convert(Date,DocDate)=Convert(Date,Getdate()
--		DocDate < DATEADD(d,-3,DocDate))   		
--		Begin
				
--		        Set  @error ='5912';										
--		        Set  @error_message ='POSTING DATE CAN NOT BE LESS THEN AFTER 3 DAYS';		
--		End

--		end


-----------------------------Good Receipt price vs Good issue price  ----------------------------------

--IF @object_type = N'59' AND (@transaction_type = N'A' OR @transaction_type = N'U') 
--BEGIN 
--    SELECT COUNT(*) FROM OIGE H
--    INNER JOIN IGE1 D ON H.DocEntry = D.DocEntry 
--    INNER JOIN OIGN H1 ON H1.U_GISE = H.DocEntry
--    INNER JOIN IGN1 D1 ON H1.DocEntry = D1.DocEntry
--    WHERE H1.DocEntry = @list_of_cols_val_tab_del AND D1.LineNum = D.LineNum  
--    AND D1.Price <> D.StockPrice AND H.U_JWISSTYP = 'F' AND D.baseref = ''

--    BEGIN
--        SELECT @error = '5913'
--        SELECT @error_message = 'Good Receipt price should be equal to issue!'
--    END
--END

--------------------------------------------G/L For Goods Receipt -----------------------------------------------------

--IF @transaction_type IN ('A', 'U') AND @object_type = '59'
--BEGIN
--   IF EXISTS (
--      SELECT T1.ACCTCODE
--      FROM dbo.OIGN T0
--      INNER JOIN IGN1 T1 ON T0.DocEntry = T1.DocEntry
--      WHERE T0.DocEntry = @list_of_cols_val_tab_del   AND 
--	  t0.U_JVCD IS NOT NULL  AND T1.AcctCode <> '542001001'
    
--   )
--   BEGIN
--      SELECT @error = 5910, @error_message = 'SELECT JOBWORK ACCOUNT 542001001'
--   END
--END

-----------------------Goods Issued Vs Goods Receipt G/L should be same VVI-----------------------------------

IF (@object_type = N'59' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF (
        (
            SELECT COUNT(*)
            FROM OIGN H1 
			INNER JOIN OIGN H0 ON H0.DocEntry = H1.DocEntry
            INNER JOIN IGN1 D1 ON H1.DocEntry = D1.DocEntry
            INNER JOIN OIGE H2 ON H2.DocEntry = H1.U_GISE AND H2.DocNum = H1.U_GISN
            INNER JOIN IGE1 D2 ON H2.DocEntry = D2.DocEntry
            WHERE H1.DocEntry = @list_of_cols_val_tab_del AND H0.objtype = '59' 
            AND H2.U_JBNO IS NOT NULL
            AND D1.AcctCode <> D2.AcctCode
            AND ((H2.U_JWISSTYP = 'P')
            OR (H2.U_JWISSTYP = 'F' AND D1.ItemCode = D2.ItemCode))
        ) > 0
    )
    BEGIN
        SET @error = '5914'
        SET @error_message = 'PLEASE SELECT SAME G/L AS PER GOODS ISSUE'
    END
END





---------------------GOODS ISSUE : OBJECT TYPE-60 : TABLE-OIGE VALIDATION---------------------

-----------------------Goods Issuance as per Prod Order and Qty----------VVI-------------------------

--IF( @transaction_type IN (N'A', N'U') AND  @object_type = N'60'   )  
--BEGIN 
--DECLARE @BASEENTRY5 INT,@VALUE1 INT
--SET @BASEENTRY5=(SELECT top 1 BASEENTRY FROM IGE1 WHERE DocEntry=@list_of_cols_val_tab_del)

--SET @VALUE1=(
--select Count(*) from (
--(select  BaseEntry as 'Issue Entry',ItemCode,Quantity from IGE1  where DocEntry=@list_of_cols_val_tab_del and BaseType=202
--EXCEPT
--select  DocEntry as 'Prod Entry',ItemCode,PlannedQty from WOR1  where DocEntry=@BASEENTRY5 AND IssueType <>'B')-- and BaseType=202

--union all 
--(select  DocEntry as 'Prod Entry',ItemCode,PlannedQty from WOR1  where DocEntry=@BASEENTRY5 AND IssueType <>'B'
--except
--select  BaseEntry as 'Issue Entry',ItemCode,Quantity from IGE1  where DocEntry=@list_of_cols_val_tab_del and BaseType=202)
--)A

--)
--IF(@VALUE1>0)
--BEGIN                                                           
                                                          
                                                 
--                       SET @error = '6001'                                                            
--                  SET @error_message = 'SELECT SAME ITEM AND SAME QUANTITY FOR ISSUE '                                          
--     END 

--END

-------------------------------------------------------------------------------------
--		IF @transaction_type in ('A','U') or  @object_type = '60'
--begin
--		If Exists (Select DocEntry From OIGE Where 
--		DocDate < DATEADD(d,-3,DocDate)) 
		
--		Begin
				
--		        Set  @error ='6002';										
--		        Set  @error_message ='POSTING DATE SHOULD NOT BE LESS THAN 3 DAYS ';		
--		End

--		end
------------------------production Receipt can not without issue---------------------------------- 

IF @transaction_type IN (N'A', N'U') AND (@Object_type = N'60')
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM IGE1 A
        WHERE a.docentry = @list_of_cols_val_tab_del
        AND a.BaseType = 202
    )
    BEGIN
        IF EXISTS (
            SELECT '*'
            FROM IGE1 i, WOR1 w
            WHERE i.DocEntry = @list_of_cols_val_tab_del
            AND i.BaseEntry = w.DocEntry
            AND ISNULL(w.IssuedQty, 0) > w.PlannedQty
        )
        BEGIN
            SET @error = '6003'
            SET @error_message = 'ISSUE QUANTITY EXCEEDED'
        END
    END
END

------------------------------------------------------------------------------------------------------------------

IF @object_type = '60' AND @transaction_type IN ('A')
BEGIN
    IF EXISTS (
        SELECT *
        FROM IGE1 T0
        INNER JOIN OIGE T1 ON T1.DocEntry = T0.DocEntry
        INNER JOIN OWOR T2 ON T2.DocEntry = T0.BaseEntry
        INNER JOIN OUSR T3 ON T3.USERID = T1.UserSign
        WHERE T2.Status = 'R'
        AND T0.DocEntry <> @list_of_cols_val_tab_del
        AND T2.CmpltQty = 0.00
        AND T0.BaseType = T2.ObjType
        AND T0.BaseType = 202
        AND T1.U_JVCD IS NOT NULL
    )
    BEGIN
        SELECT @error = 6004;
        SELECT @error_message = 'YOU CAN NOT ADD THIS ISSUE ORDER, FIRST TAKE RECEIPT OF THE PREVIOUS PRODUCTION ORDER';
    END
END;

-----------------------------

IF ((@transaction_type = 'C') AND @object_type = '60')
BEGIN
       IF EXISTS 
       (
          SELECT COUNT(T0.DocEntry) FROM IGE1 T0 INNER JOIN [@UTL_GE_GPS1] T1 ON T0.DocEntry= T1.U_UTL_BASEKEY  AND T0.LineNum= T1.U_UTL_BASELINE
          WHERE T0.DocEntry=@list_of_cols_val_tab_del
       )
       
       
       BEGIN
        Set  @error ='6005';
        Set  @error_message ='GATE PASS FOUND BASED FOR THIS GOODS ISSUE.';
       END ;
END ;

------------------------------------------Issue Qty is not greater than Plan Qty------------------------------------------------------------

IF @transaction_type IN (N'A', N'U') AND (@Object_type = N'60')
BEGIN

declare @PlannedQty float
declare @IssuedQty float
Declare @BaseRef1 varchar(208)   


if Exists
(SELECT T3.ItemCode  

FROM OWOR T2 INNER JOIN WOR1 T3 ON T3.DocEntry=T2.DocEntry
left Outer join IGE1 I on I.BaseEntry = T3.DocEntry and I.ItemCode = T3.ItemCode

where (T3.PlannedQty - (select sum(Quantity) from IGE1 where convert(int,BaseEntry)= T3.DocEntry and BaseType=202 
 and IGE1.ItemCode = T3.ItemCode  And T3.LineNum=IGE1.BaseLine))< 0

and  T3.DocEntry in (Select BaseEntry from IGE1 where DocEntry = @list_of_cols_val_tab_del) 
and T3.ItemCode in (Select ItemCode from IGE1 where DocEntry = @list_of_cols_val_tab_del)
)


BEGIN
SELECT @Error = 6006, @error_message ='ISSUED QUANTITY IS GREATER THAN PLANNED QUANTITY'
END
END
--------------------------------------------------------------------------------------

--		IF @transaction_type in ('A','U') or  @object_type = '60'
--begin
--		If Exists (Select DocEntry From OIGE Where Convert(Date,DocDate)=Convert(Date,Getdate()))
		
--		Begin
				
--		        Set  @error ='6007';										
--		        Set  @error_message ='POSTING DATE SHOULD NOT BE TODAY DATE ';		
--		End

--		end

---------------------PRODUCT TREE (BOM-BILL OF MATERIAL): OBJECT TYPE-66 : TABLE-OITT VALIDATION---------------------

-----------------------CREATE BOM ALWAYS IN IPQA----------------------------------

if @object_type = '66' and (@transaction_type = 'A' or @transaction_type = 'U')
BEGIN
  If Not Exists (Select T0.Code from dbo.oitt t0
   Where T0.Code = @list_of_cols_val_tab_del and T0.ToWH ='IPQA')

BEGIN
Select @error = 6008, @error_message = 'CREATE BOM ALWAYS IN IPQA'

END 
END


---------------------INVENTORY TRANSFER : OBJECT TYPE-67 : TABLE-OWTR VALIDATION---------------------

---------------------SELECT INVENTORY TRANSFER TYPE--------------------------------              

IF @transaction_type IN (N'A', N'U') AND (@Object_type = N'67')               
BEGIN                             
    IF EXISTS (
        SELECT 'X'
        FROM OWTR a              
        WHERE              
        A.DocEntry = @list_of_cols_val_tab_del               
        AND (a.U_ISTY IS NULL OR a.U_ISTY = '')
    )                     
    BEGIN                      
        SELECT @Error = 6701 
		SELECT @error_message = 'PLEASE SELECT INVENTORY TRANSFER TYPE-START JOB WORK ADDONS'                  
    END                  
END

-------------------------------------- TAX CODE REQUIRED IN RGP ---------------------------------------------
IF @transaction_type in ('A','U') AND @object_type = '67'
BEGIN
IF exists (select A.DocEntry from OWTR A

INNER JOIN    WTR1 B ON A.DOCENTRY = B.DOCENTRY

where CardCode<>'' AND B.U_UTL_ST_TAXCD IS NULL 
AND A.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 6702, @error_message = 'TAX CODE REQUIRED IN RGP'
End
END


---------------------------------------INVENTORY TRANSFER FROM IQC USER SH0141-------------------------------

IF @transaction_type in ('A','U') AND @object_type = '67'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.OWTR T0 INNER JOIN WTR1 T1 ON T1.DocEntry=T0.DocEntry
Where T0.UserSign = '67' AND  T1.WhsCode not in ('MST', 'REJ', 'HLD','PWH','scp')
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 6703, @error_message = 'YOU CAN NOT TRANSFER THE SAME IN SELECTED WAREHOUSE'
End
END


--------------------------------------inventory transfer from ipqa sh0125-------------------------------------------

IF @transaction_type in ('A','U') AND @object_type = '67'
BEGIN
IF exists (
Select T0.DOCENTRY from dbo.OWTR T0 INNER JOIN WTR1 T1 ON T1.DocEntry=T0.DocEntry
Where  t0.UserSign IN ('67','70') and  T1.WhsCode not in ('PWH','scp','rej') and ItemCode like '201%%%'

AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 6704, @error_message = 'YOU CAN NOT TRANSFER THE SAME IN SELECTED WAREHOUSE PLZ SELECT PWH WAREHOUSE.'
End
END

------------------------------------------RGP DOCUMENT SERIES----------------------------------------------------------
IF @transaction_type in ('A','U') AND @object_type = '67'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.OWTR T0 INNER JOIN WTR1 T1 ON T1.DocEntry=T0.DocEntry
Where  T0.Series='226' AND T1.WhsCode not in ('IQC','MST')
AND T0.DocEntry=@list_of_cols_val_tab_del)

Begin
SELECT @error = 102, @error_message = 'WRONG SERIES FOR EXTERNAL INVENTORY TRANSFER'
End
END

IF @transaction_type in ('A','U') AND @object_type = '67'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.OWTR T0 INNER JOIN WTR1 T1 ON T1.DocEntry=T0.DocEntry
Where  T0.Series='237' AND T1.WhsCode in ('IQC1','MST1','REJ1','SCP1','HLD1','JWWH','ASM1','ASM2','WLD1','WLD2','PKG1','FGW1','R&D','01','PTS1','ipqc')
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 6705, @error_message = 'WRONG SERIES FOR INTERNAL INVENTORY TRANSFER'
End
END

----------------------------------------Inventory Transfer not allowed-----------------------------------------------

IF @transaction_type in ('A','U') AND @object_type = '67'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.OWTR T0 INNER JOIN WTR1 T1 ON T1.DocEntry=T0.DocEntry
Where  T1.FromWhsCod in ('mst2','01','SCP1','mst1','iqc1','asm1','asm2','wld1','wld2','pkg1','fgw1','jwwh','rej1','scp1','r&d')
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 6706, @error_message = 'INVENTORY TRANSFER NOT ALLOWED'
End
END


------------------------------------Inventoty Transfer not Allowed ------------------------------------------

IF @transaction_type in ('A','U') AND @object_type = '67'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.OWTR T0 INNER JOIN WTR1 T1 ON T1.DocEntry=T0.DocEntry
Where  t1.whscode in ('mst2','01','SCP1','mst1','iqc1','asm1','asm2','wld1','wld2','pkg1','fgw1','jwwh','rej1','scp1','R&D')
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 6707, @error_message = 'INVENTORY TRANSFER NOT ALLOWED'
End
END

-------------------------------Inventory Transfer from SCRAP/Rejection-------------------- PS Inventory Transfer

IF @transaction_type in ('A','U') AND @object_type = '67'
BEGIN
IF exists (Select T0.DOCENTRY from dbo.OWTR T0 
INNER JOIN WTR1 T1 ON T1.DocEntry=T0.DocEntry
Where t1.FromWhsCod in ('Scp','cons','rej')
AND T0.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 6708, @error_message = 'YOU CAN NOT TRANSFER FROM SAME IN SELECTED WAREHOUSE'
End
END




---------------------LANDED COSTS : OBJECT TYPE-69 : TABLE-OIPF VALIDATION---------------------

---------------------DRAFT : OBJECT TYPE-112 : TABLE-ODRF VALIDATION---------------------
-----------------------Can Not change the delivery date--------------------------------------------------                                                   
                                                
IF @transaction_type IN (N'A') AND (@Object_type = N'112')
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM DRF1 w
        INNER JOIN POR1 d ON w.DocEntry = d.baseentry
                          AND d.ObjType = w.BaseType
                          AND d.linenum = w.BaseLine
        WHERE w.DocEntry = @list_of_cols_val_tab_del
        AND CONVERT(NVARCHAR, d.shipdate, 103) <> CONVERT(NVARCHAR, w.shipdate, 103)
    )
    BEGIN
        SET @error = '6901'
        SET @error_message = 'YOU CAN NOT CHANGE THE DELIVERY DATE'
    END
END


---------------------INVENTORY REVALUATION : OBJECT TYPE-162 : TABLE-OMRV VALIDATION---------------------


---------------------PRODUCTION ORDER : OBJECT TYPE-202 : TABLE-OWOR VALIDATION---------------------

--------------------------------------------------------------------------


IF @transaction_type IN ('A', 'U')AND @object_type in ('202')

BEGIN

IF EXISTS (SELECT T0.DocEntry FROM OWOR T0
INNER JOIN OITT T2 ON T2.Code = T0.Itemcode

WHERE t0.DocEntry =@list_of_cols_val_tab_del 
                    AND T0.TYPE <> 'P' AND T2.U_BOM_APPROVAL<>'Y')
BEGIN

SET @error = '20201'

SET @error_message = N'BOM not approved '

END

END

------------------------------------------------31012019------------------------------

if @object_type = '202' and (@transaction_type = 'A' or @transaction_type = 'U')
BEGIN
  If Exists (SELECT T0.DOCENTRY  FROM OWOR T0
   Where T0.DocEntry= @list_of_cols_val_tab_del 
   and T0.Warehouse <> 'IPQA' 
   and t0.ItemCode like ('201%%') 
   and t0.ItemCode like ('1%%'))

BEGIN
Select @error = 20202, @error_message = 'CREATE PRODUCTION ORDER ALWAYS IN IPQA'

END 
END

-------------------------------------------------------------------------------------------------------
IF @object_type = '202' AND (@transaction_type = 'A' or @transaction_type = 'U')
BEGIN
  IF EXISTS (SELECT T0.DocEntry  FROM OWOR T0
             WHERE T0.DocEntry= @list_of_cols_val_tab_del 
              AND T0.Warehouse IN ('FGW')---- ('FGW', 'ASM','PWH','IQC','PKG') AND T0.ItemCode NOT LIKE ('1%%') 
			  )
BEGIN
SELECT @error = 20203, @error_message = 'CREATE PRODUCTION ORDER ALWAYS IN IPQA WAREHOUSE'

END 
END


----------------Special Production Type selection--------------------------------------
if @object_type = '202' and (@transaction_type = 'A' or @transaction_type = 'U')
BEGIN
  If  Exists (Select t0.DocEntry  from OWOR t0
   Where T0.DocEntry= @list_of_cols_val_tab_del and T0.[TYPE]='P' AND T0.Project=' ')

BEGIN
Select @error = 20204, @error_message = 'Select Production Order Type'

END 
END

-------------------------------ISSUANCE TYPE IN PRODUCTION ENTRY --------------------------

IF @object_type = '202' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    IF EXISTS(
        SELECT *
        FROM OWOR
        INNER JOIN WOR1 ON WOR1.DocEntry = OWOR.DocEntry
        INNER JOIN OITM ON OITM.ITEMCODE = WOR1.ITEMCODE
        WHERE OWOR.DocEntry = @list_of_cols_val_tab_del AND WOR1.IssueType <> 'B'
    )
    BEGIN
        SELECT @Error = 20205
        SELECT @error_message = 'SELECT ISSUANCE TYPE BACKFLUSH !'
    END
END

--------------------------------SALES ORDER VALIDATION IN PRODUCTION ORDER-----------------------------

IF @object_type = '202' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT *
        FROM OWOR
        INNER JOIN OITM ON OWOR.ItemCode = OITM.ItemCode AND ItmsGrpCod = 103
        INNER JOIN RDR1 ON RDR1.ITemCode = OITM.ItemCode
        WHERE OWOR.DocEntry = @list_of_cols_val_tab_del AND type = 'S'
    )
    BEGIN
        IF (
            (
                SELECT COUNT(T1.ItemCode)
                FROM ORDR T0
                LEFT OUTER JOIN OWOR T1 ON T0.CardCode = T1.CardCode AND T0.DocNum = T1.OriginNum
                INNER JOIN RDR1 T2 ON T0.DocEntry = T2.DocEntry AND T1.[ItemCode] = T2.[ItemCode] AND T0.DocStatus = 'O'
                WHERE T1.DocEntry = @list_of_cols_val_tab_del AND T1.ItemCode = T2.ItemCode AND ISNULL(T1.OriginNum, '') <> ''
            ) = 0
        )
        BEGIN
            SELECT @Error = 20206
            SELECT @error_message = 'MUST BE SELECT OPEN AND CORRECT SALES ORDER !'
        END
    END
END

--------------------------------------------------------

IF @object_type = '202' AND @transaction_type = 'U'
BEGIN
    SELECT itemcode
    INTO #t
    FROM OWOR
    WHERE DocEntry <> @list_of_cols_val_tab_del AND Status IN ('R') AND PostDate > '20220401';

    IF EXISTS (
        SELECT *
        FROM OWOR, #t
        WHERE DocEntry = @list_of_cols_val_tab_del AND OWOR.Itemcode = #t.ItemCode AND OWOR.Status IN ('R')
    )
    BEGIN
        SET @error = '20207';
        SET @error_message = 'PLEASE CLOSE PREVIOUS OPEN PRODUCTION ORDER FOR THIS ITEM';
    END
END;

--------------------------------------Close production order--------------------------------------

if @object_type = '2102' and (@transaction_type = 'A' )
Begin
IF EXISTS(Select * FROM OWOR where  Status<>'c' and PostDate>='20230401' and PlannedQty=CmpltQty)
             
                                  BEGIN          
                                  SELECT @Error = 20208                                                             
                                  SELECT @error_message = 'MUST BE COLSE COMPLITED PRODUCTION ORDER !'
                                  END
              END


---------------------INVENTORY POSTING : OBJECT TYPE-10000071 : TABLE-OIQR VALIDATION---------------------


---------------------ADDONS : OBJECT TYPE-234000031 : TABLE-ADDONS VALIDATION---------------------


---------------------ADDONS : OBJECT TYPE-234000032 : TABLE-ADDONS VALIDATION---------------------

---------------------PURCHASE QUOTATION : OBJECT TYPE-540000006 : TABLE-OPQT VALIDATION---------------------

---------------------INVENTORY TRANSFER REQUEST : OBJECT TYPE-1250000001 : TABLE-OWTQ VALIDATION---------------------
---------------------Inventoty Transfer request not Allowed Qty Not Avialable In Whse -----------------------

IF @transaction_type in ('A','U') AND @object_type = '1250000001'
BEGIN
IF exists (Select Quantity, oitw.OnHand,* from OWTQ

inner join WTQ1 on OWTQ.DocEntry=WTQ1.DocEntry
inner join OITW on wtq1.ItemCode=oitw.ItemCode and oitw.WhsCode=wtq1.FromWhsCod

Where wtq1.Quantity>OITW.OnHand
AND OWTQ.DocEntry=@list_of_cols_val_tab_del)
Begin
SELECT @error = 12501, @error_message = 'INVENTORY TRANSFER REQUEST NOT ALLOWED QTY NOT IN WAREHOUSE'
End
END

 
--------------------MAINT ITEM ISSUANCE TFR , ISSUANCE ---------------------------

IF @transaction_type IN ('A', 'U') AND @object_type = '1250000001'
BEGIN
    IF EXISTS (
        SELECT *
        FROM OWTQ A
        INNER JOIN WTQ1 B ON A.DOCENTRY = B.DOCENTRY
        INNER JOIN OUSR C ON C.USERID = A.UserSign
        WHERE B.U_UNE_REMK IS NULL
          AND A.UserSign IN (11)
          AND A.DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @error = 12502, @error_message = 'PLEASE FILL REMARKS FOR USES INFORMATION'
    END
END

----------------FOR DRAFT DOC INV TFR-----------------------------------------------------

 IF @object_type = N'112' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT *
        FROM ODRF A   
        INNER JOIN WTQ1 B ON A.DOCENTRY = B.DOCENTRY
        INNER JOIN OUSR C ON C.USERID = A.UserSign
        WHERE A.docentry = @list_of_cols_val_tab_del                              
        AND A.ObjType = '1250000001'
        AND B.U_UNE_REMK IS NULL
        AND (B.U_ITCD IS NULL OR B.U_ITNM IS NULL)
        AND A.UserSign IN (11)
    )
    BEGIN
        SELECT @error = 12503
        SELECT @error_message = 'PLEASE FILL REMARKS FOR USES INFORMATION'
    END
END


----------------------------FILL ITEM CODE OR MACHINE NAME ---------------------------------------------------------------

IF @transaction_type IN ('A', 'U') AND @object_type = '1250000001'
BEGIN
    IF EXISTS (
        SELECT *
        FROM OWTQ A
        INNER JOIN WTQ1 B ON A.DOCENTRY = B.DOCENTRY
        INNER JOIN OUSR C ON C.USERID = A.UserSign
        WHERE (B.U_ITCD IS NULL OR B.U_ITNM IS NULL)
        AND A.UserSign IN (11)
        AND A.DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @error = 12504
        SELECT @error_message = 'PLEASE FILL ITEM CODE OR MACHINE NAME INFORMATION'
    END
END



---------------------BLANKET AGREEMENT : OBJECT TYPE-1250000025 : TABLE-OOAT VALIDATION---------------------

-------------------------PURCHASE BLANKET AGREEMENT--------------------

If @object_type='1250000025' and @transaction_type='A'

BEGIN

If Exists (Select T0.Absid from [dbo].[OOAT] T0

Inner Join OAT1 T1 On T0.AbsID=T1.AgrNo

Inner Join OITM T2 ON T2.ITEMCODE = T1.ItemCode 


Where T0.AbsID = @list_of_cols_val_tab_del and T2.chapterid ='63')

BEGIN

Select @error = 1252501,

@error_message = 'YOU CAN NOT ADD PURCHASE ORDER WITHOUT HSN NUMBER'

End
END

--------------------------------------------------------------------------

If @object_type='1250000025' and @transaction_type='A' 

BEGIN

If Exists (Select T0.Absid from [dbo].[OOAT] T0

Inner Join OAT1 T1 On T0.AbsID=T1.AgrNo

Inner Join OITM T2 ON T2.ITEMCODE = T1.ItemCode 


Where T0.AbsID = @list_of_cols_val_tab_del and T2.chapterid ='63')

BEGIN

Select @error = 1252502,

@error_message = 'YOU CAN NOT ADD PURCHASE ORDER WITHOUT HSN NUMBER'

End
END

------------------------------------------------

If @object_type='1250000025' and (@transaction_type = N'A'  )
BEGIN

If Exists (Select T0.absid from [dbo].[OOAT] T0

Where T0.AbsID = @list_of_cols_val_tab_del and T0.type = 'G')

BEGIN

Select @error = 1252503,
@error_message = 'YOU CAN NOT ADD BLANKET AGREEMENT IN GENERAL TYPE'

End
END

-----------------------------------------------------------------------------------------------

IF @object_type = '1250000025' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT '*'
        FROM OOAT
        WHERE AbsID = @list_of_cols_val_tab_del
        AND ISNULL(Type, '') <> 'S'
    )
    BEGIN
        SET @error = '1252504'
        SET @error_message = 'PLEASE SELECT AGREEMENT TYPE SPECIFIC'
    END
END

---------------------PURCHASE REQUEST : OBJECT TYPE-1470000113 : TABLE-OPRQ VALIDATION---------------------

------------------------- TAX CODE FOR DRAFT BASED DOC FOR PR ------------------      

IF @object_type = N'112' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT *
        FROM DRF1 d
        WHERE d.docentry = @list_of_cols_val_tab_del
        AND d.ObjType = '1470000113' AND (d.TaxCode <> '')
    )
    BEGIN
        SELECT @error = 14701
        SELECT @error_message = 'DO NOT SELECT TAX CODE IN PR'
    END
END
 
------------------------- TAX CODE FOR DRAFT BASED------------------------------------------------------------

IF @object_type = '1470000113' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT *
        FROM PRQ1 d
        WHERE d.docentry = @list_of_cols_val_tab_del
        AND d.ObjType = '1470000113'
        AND (d.TaxCode <> '')
    )
    BEGIN
        SELECT @error = 14702
        SELECT @error_message = 'DO NOT SELECT TAX CODE IN PR'
    END
END
           
 ---------------------------PR Attachment_Mandatory------------------------------------------ 					
					
IF @object_type = '1470000113' AND (@transaction_type = 'A')
BEGIN
    IF EXISTS (
        SELECT *
        FROM OPRQ a
        INNER JOIN PRQ1 b ON a.DocEntry = b.DocEntry
        WHERE a.[AtcEntry] IS NULL AND a.DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @error = 14703
        SELECT @error_message = 'HOD AND STORE DEPT. APPROVED ATTACHMENT IS MANDATORY_PR'
    END
END
			

		
----------------------- ATTACHMENT IN DFAFT PR ------------------     

 IF @object_type = N'112' AND (@transaction_type = 'A' OR @transaction_type = 'U')                                                                    
BEGIN
    IF EXISTS (
        SELECT *
        FROM ODRF d
        WHERE d.DocEntry = @list_of_cols_val_tab_del                              
        AND d.ObjType = '1470000113'                                  
        AND (d.AtcEntry IS NULL)
    )
    BEGIN
        SELECT @error = 14704
        SELECT @error_message = 'HOD AND STORE DEPT. APPROVED ATTACHMENT IS MANDATORY_DRAFT'
    END
END
         
---------------------PR DOCUMENT APPROVAL LEVEL YES UPDATE WITH SPECIFIC ID-----------------------------
		
IF @object_type = '1470000113' AND (@transaction_type = 'A' OR @transaction_type = 'U') 
BEGIN
    IF EXISTS (
        SELECT *
        FROM OPRQ a
        LEFT JOIN OUSR b ON a.UserSign = b.USERID
        LEFT JOIN OUSR c ON a.UserSign2 = c.USERID
        WHERE 
        a.DocEntry = @list_of_cols_val_tab_del 
        AND a.U_PRLEVEL0 = 'Y' 
        AND (a.UserSign <> '31' OR a.UserSign2 <> '31')
        AND (a.UserSign <> '1' OR a.UserSign2 <> '1')
    )
    BEGIN
        SELECT @error = 14705
        SELECT @error_message = 'YOU ARE NOT AUTHORISED TO UPDATE APPROVAL LEVEL 2 UDF_FIELD'
    END
END
	
-------------------PR DRAFT APPROVAL LEVEL YES UPDATE WITH SPECIFIC ID --------------------------

IF @object_type = N'112' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    IF EXISTS (
        SELECT *
        FROM ODRF a   
        LEFT JOIN OUSR b ON a.UserSign = b.USERID
        LEFT JOIN OUSR c ON a.UserSign2 = c.USERID
        WHERE a.docentry = @list_of_cols_val_tab_del                              
        AND a.ObjType = '1470000113'   
        AND a.U_PRLEVEL0 = 'Y' 
        AND (a.UserSign <> '31' OR a.UserSign2 <> '31' )
        AND (a.UserSign <> '1' OR a.UserSign2 <> '1')
    )
    BEGIN
        SELECT @error = 14706                                                                   
        SELECT @error_message = 'YOU ARE NOT AUTHORISED TO UPDATE APPROVAL LEVEL 2 UDF_FIELD'	                                                                
    END
END

----------------------------------------------------------------------------------------------------------------

                      --------- QC ADDONS VALIDATION-------

----------------------------------------------------------------------------------------------------------------

----------------------------------------QC POSTING DATE -------------------------------------      

IF (@object_type = N'UTL_UDO_QCCHK' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN 
    DECLARE @PostingDate DATETIME
    SET @PostingDate = (SELECT ISNULL(U_UTL_PODT, '') FROM [@UTL_OQCHK] (NOLOCK) WHERE DocEntry = @list_of_cols_val_tab_del)
    
    IF ISNULL(@PostingDate, '') = ''
    BEGIN                        
        SELECT @Error = 5001                                                            
        SELECT @error_message = 'PLEASE ENTER DOC DATE !!.'                        
    END                           
END

-- ---------------------------------------------------Obervation 1 to 5 Mandatory------------------------------------------------------------------------

 If @object_type='UTL_UDO_QCCHK' and @transaction_type='A' AND  @transaction_type='U'

BEGIN

If Exists (Select T0.DocEntry from [@UTL_OQCHK] T0
Inner Join [@UTL_QCHK1] T1 on T1.DocEntry=T0.DocEntry
where T1.U_UTL_OBS1 IS NULL AND T1.U_UTL_OBS2 is null AND T1.U_UTL_OBS3 IS NULL 
AND T1.U_UTL_OBS4 IS NULL AND T1.U_UTL_OBS5 IS NULL
AND T0.DocEntry = @list_of_cols_val_tab_del)

BEGIN

Select @error = 5002,

@error_message = 'OBSERVATION 1 TO 5 ARE NOT FILLED'

End
END

-- -------------------------------QC MASTER SETTING ------------------------------------------------------------------------

IF @object_type=N'UTL_UDO_QCSET' AND  (@transaction_type IN (N'U', N'A' ))    
BEGIN
IF EXISTS (SELECT T0.[DOCENTRY], T1.[DOCNUM],T0.[Object] ,T1.[U_UTL_ITCD],T1.[U_UTL_ITNM], T0.[U_UTL_DOCS], 
T0.[U_UTL_PARCODE],T0.[U_UTL_INSPCD] FROM [@UTL_QCST1] T0
INNER JOIN [@UTL_OQCST] T1 ON T1.[DOCENTRY]=T0.[DOCENTRY]

WHERE T0.[DocEntry] = @list_of_cols_val_tab_del AND T0.[Object]='UTL_UDO_QCSET' 
                    AND (ISNULL (T0.[U_UTL_INSPCD],'')='' OR T0.[U_UTL_INSPCD] IS NULL))
BEGIN
SELECT @error = 5003,
@error_message = 'FILL PARAMETER CODE AND INSPECTION CODE'
END
END
-- -------------------------------QC MASTER SETTING ------------------------------------------------------------------------
IF @object_type=N'UTL_UDO_QCSET' AND  (@transaction_type IN (N'U', N'A' ))    
BEGIN
IF EXISTS (SELECT T0.[DOCENTRY], T1.[DOCNUM],T0.[Object] ,T1.[U_UTL_ITCD],T1.[U_UTL_ITNM], T0.[U_UTL_DOCS],
T0.[U_UTL_PARCODE],T0.[U_UTL_INSPCD] FROM [@UTL_QCST1] T0
INNER JOIN [@UTL_OQCST] T1 ON T1.[DOCENTRY]=T0.[DOCENTRY]
WHERE T0.[DocEntry] = @list_of_cols_val_tab_del AND T0.[Object]='UTL_UDO_QCSET' 
                      AND (ISNULL (T1.[U_UTL_ITCD],'')='' OR T1.[U_UTL_ITCD] IS NULL))
BEGIN
SELECT @error = 5004,
@error_message = 'FILL ITEM CODE AND INSPECTION CODE'
END
END


----------------------------------------------------------------------------------------------------------------

                      --------- GATE ENTRY ADDONS VALIDATION-------

----------------------------------------------------------------------------------------------------------------
--------------------------------Gate Entry transaction Notification (Add-on standard) ----------------


IF (@object_type = N'UTL_GE_UDO_INWARD' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN
    IF EXISTS (
        SELECT DocEntry
        FROM [@UTL_GE_OGIN]
        WHERE U_UTL_InvoiceNo IS NULL AND DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @Error = 15101,
               @error_message = 'GATE ENTRY INVOICE NO MANDATORY.'
    END
END

-----------------------------------------------------------------------------------------------------------------------

IF (@object_type = N'UTL_GE_UDO_INWARD' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN
    IF EXISTS (
        SELECT DocEntry
        FROM [@UTL_GE_OGIN]
        WHERE U_UTL_InvDate IS NULL AND DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SELECT @Error = 15102
        SELECT @error_message = 'GATE ENTRY INVOICE DATE MANDATORY.'
    END
END

-------------------------------------------------------------------------------------------------------------------

IF (@object_type = N'1UTL_GE_UDO_INWARD' AND ( @transaction_type = N'A'  OR @transaction_type = N'U' ))
BEGIN 
Declare @MinLine int
Declare @MaxLine int
Declare @BaseEntry11 int
Declare @BaseQty Decimal(16,4)
Declare @Qty Decimal(16,4)
Declare @Qty1 Decimal(16,4)
Declare @ItemCode11 Varchar(50)

set @MinLine = (Select min(VisOrder) from [@UTL_GE_GIN1] where DocEntry =@list_of_cols_val_tab_del )
set @MaxLine = (Select max(VisOrder) from [@UTL_GE_GIN1] where DocEntry =@list_of_cols_val_tab_del )

while @MinLine <= @MaxLine 
begin
Set @BaseEntry11 = (select U_UTL_BASENTR from [@UTL_GE_GIN1] where DocEntry =@list_of_cols_val_tab_del and VisOrder = @MinLine)
Set @ItemCode11 = (select U_UTL_ITCD from [@UTL_GE_GIN1] where DocEntry =@list_of_cols_val_tab_del and VisOrder = @MinLine)
Set @BaseQty = (Select top 1 Quantity from POR1 where DocEntry = @BaseEntry11 and ItemCode = @ItemCode11)
set @Qty = (select U_UTL_QTY from [@UTL_GE_GIN1] where DocEntry =@list_of_cols_val_tab_del and VisOrder = @MinLine)  
set @Qty1=(select sum(U_UTL_QTY) from [@UTL_GE_GIN1] where DocEntry != @list_of_cols_val_tab_del and U_UTL_BASENTR = @BaseEntry11 and U_UTL_ITCD = @ItemCode11 )

if @BaseQty < @Qty + isnull(@Qty1,0)
             BEGIN                        
                                  SELECT @Error = 15103                                                             
                                  SELECT @error_message = 'GATE ENTRY QTY CAN NOT GREATER THAN PO QTY'  
			END
	Set @MinLine = @MinLine + 1
end
End

--------------------------------------------------------------------------------------------------------------------------

IF (@object_type = N'UTL_GE_UDO_INWARD' AND ( @transaction_type = N'A'  OR @transaction_type = N'U' ))
BEGIN 
	Declare @MinLine1 int
Declare @MaxLine1 int
Declare @BaseEntry12 int
Declare @DocNum decimal(16,4)

set @MinLine1 = (Select min(VisOrder) from [@UTL_GE_GIN1] where DocEntry =@list_of_cols_val_tab_del )
set @MaxLine1 = (Select max(VisOrder) from [@UTL_GE_GIN1] where DocEntry =@list_of_cols_val_tab_del )

while @MinLine <= @MaxLine 
begin
Set @BaseEntry12 = (select U_UTL_BASENTR from [@UTL_GE_GIN1] where DocEntry =@list_of_cols_val_tab_del and VisOrder = @MinLine)
set @DocNum = ISNULL(( select distinct top 1 t1.DocNum from por1 t0 left join opor t1 on t0.DocEntry = t1.DocEntry 			
				where t0.DocEntry = @BaseEntry12 and ((t1.U_POTY = 'CLOSE' and t1.U_LEVEL2 != 'Y') or (t1.U_POTY = 'SCHEDULE' and t1.U_LEVEL1 != 'Y'))  ),0)

if @DocNum != 0
             BEGIN                        
                                  SELECT @Error = 15104                                                             
                                  SELECT @error_message = 'KINDLY CHECK APPROVAL STATUS'  
			END
	Set @MinLine = @MinLine + 1
end
END

--------------------------------INVOICE NUMBER IS REPEATING-------------------------------------------------------------

IF (@object_type = N'UTL_GE_UDO_INWARD1' AND (@transaction_type = N'A' OR @transaction_type = N'U'))
BEGIN 
    IF EXISTS (
        SELECT U_UTL_InvoiceNo
        FROM [@UTL_GE_OGIN]
        WHERE U_UTL_CardCode IN (
                SELECT U_UTL_CardCode
                FROM [@UTL_GE_OGIN]
                WHERE DocEntry = @list_of_cols_val_tab_del AND Canceled = 'N'
            )
            AND U_UTL_InvoiceNo IN (
                SELECT U_UTL_InvoiceNo
                FROM [@UTL_GE_OGIN]
                WHERE DocEntry = @list_of_cols_val_tab_del AND Canceled = 'N'
            )
        GROUP BY U_UTL_CardCode, U_UTL_InvoiceNo
        HAVING COUNT(U_UTL_InvoiceNo) > 1
    )
    BEGIN
        SELECT @Error = 15105
        SELECT @error_message = 'INVOICE NUMBER IS REPEATING CHECK PLEASE'
    END
END;

----------------------------AGREEMENT OF THIS ITEM IS CLOSED----------------------------------------


IF @object_type = 'UTL_GE_UDO_INWARD' AND @transaction_type IN ('A', 'U')
BEGIN
    IF EXISTS (
        SELECT 'NULL'
        FROM [@UTL_GE_OGIN] T0
        LEFT JOIN [@UTL_GE_GIN1] T1 ON T1.DocEntry = T0.DocEntry
        LEFT JOIN POR1 T2 ON T2.DocEntry = T1.U_UTL_BASENTR AND T2.LineNum = T1.U_UTL_BASELINE AND T2.ItemCode = T1.U_UTL_ITCD
        LEFT JOIN OAT1 T3 ON T3.AgrNo = T2.AgrNo AND T3.AgrLineNum = T2.AgrLnNum AND T2.ItemCode = T3.ItemCode
        WHERE t3.LineStatus = 'C'
            AND T0.DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
         SELECT @error = 15106
         SELECT @error_message = 'AGREEMENT OF THIS ITEM IS CLOSED.'
    END
END;


----------------------------DUPLICATE VENDOR REF.NO.-------------------------------------------
 
IF @object_type = N'UTL_GE_UDO_INWARD' AND (@transaction_type IN (N'U', N'A'))
BEGIN
    IF EXISTS (
        SELECT A.DocEntry
        FROM "@UTL_GE_OGIN" A
        WHERE A.DocEntry = @list_of_cols_val_tab_del
            AND A.U_UTL_BPREF IN (
                SELECT B.U_UTL_BPREF
                FROM "@UTL_GE_OGIN" B
                WHERE B.DocEntry <> @list_of_cols_val_tab_del
                    AND B.U_UTL_CardCode = A.U_UTL_CardCode
            )
            AND A.U_UTL_STATS = 'X'
    )
    BEGIN
        SELECT @Error = 15107
        SELECT @error_message = 'DUPLICATE VENDOR REF.NO. ???'
    END
END;

--	--------------------------------------------------------------------------------------------

IF @object_type = N'UTL_GE_UDO_INWARD' AND (@transaction_type IN (N'U', N'A'))
BEGIN
    IF EXISTS (
        SELECT A.DocEntry
        FROM "@UTL_GE_GIN1" A
        WHERE A.DocEntry = @list_of_cols_val_tab_del
            AND ISNULL(A.U_UTL_BASENTR, '0') <> '0'
            AND (
                SELECT B.U_LEVEL1
                FROM OPOR B
                WHERE B.DocEntry = A.U_UTL_BASENTR
            ) <> 'Y'
            AND (
                SELECT B.U_POTY
                FROM OPOR B
                WHERE B.DocEntry = A.U_UTL_BASENTR
            ) = 'SCHEDULE'
    )
    BEGIN
        SELECT @Error = 15108
        SELECT @error_message = 'PO NOT APPROVED ???'
    END
END;

-------------------------------------------------------------------------------------------------------

IF @object_type = N'UTL_GE_UDO_INWARD' AND (@transaction_type IN (N'U', N'A'))
BEGIN
    IF EXISTS (
        SELECT A.DocEntry
        FROM "@UTL_GE_GIN1" A
        WHERE A.DocEntry = @list_of_cols_val_tab_del
            AND ISNULL(A.U_UTL_BASENTR, '0') <> '0'
            AND (
                SELECT B.U_LEVEL2
                FROM OPOR B
                WHERE B.DocEntry = A.U_UTL_BASENTR
            ) <> 'Y'
            AND (
                SELECT B.U_POTY
                FROM OPOR B
                WHERE B.DocEntry = A.U_UTL_BASENTR
            ) = 'CLOSE'
    )
    BEGIN
        SELECT @Error = 15109
        SELECT @error_message = 'PO NOT APPROVED ???'
    END
END;


---------------------------------------------------------------------------------------------------------------

IF @object_type = N'UTL_GE_UDO_INWARD' AND (@transaction_type IN (N'U', N'A'))
BEGIN
    IF EXISTS (
        SELECT A.DocEntry
        FROM "@UTL_GE_GIN1" A
        WHERE A.DocEntry = @list_of_cols_val_tab_del
            AND (
                SELECT B.Validfor
                FROM OITM B
                WHERE B.ItemCode = ISNULL(A.U_UTL_ITCD, 'abc')
            ) = 'N'
    )
    BEGIN
        SELECT @Error = 15110
        SELECT @error_message = 'INACTIVE ITEM ???'
    END
END;

----------------------------------------------------------------------------------------------------------------

                      --------- JOB WORK ADDONS VALIDATION-------

----------------------------------------------------------------------------------------------------------------
-----------------------------------------------Jobwork without Po------------------------------------
IF (@object_type = 'UDO_JOBWORK' AND (@transaction_type = 'A' OR @transaction_type = 'U'))
BEGIN
    IF EXISTS (
        SELECT *
        FROM DBO.[@JWHD] T0
        INNER JOIN OPOR ON OPOR.DocEntry = T0.U_POEN
        WHERE OPOR.U_LEVEL2 <> 'Y'
            AND OPOR.CardCode NOT IN ('V000451', 'V000199', 'V000643')
            AND T0.DocEntry = @list_of_cols_val_tab_del
    )
    BEGIN
        SET @error = 15111
        SET @error_message = 'JOBWORK ORDER NOT APPROVED'
    END
END;

----------------------------------------------------------------------------------------------------------------------

                        --- NEW VALIDATION UNDER OBSERVATION


-----------------------------------------------------------------------------------------------------------------------

----------------------- For Price is mandatory on Good Receipts ----------------------------					
						
IF @object_type = '59' AND (@transaction_type = 'A' OR @transaction_type = 'U')
BEGIN
    SELECT COUNT(*)
    FROM OIGN H1
    INNER JOIN IGN1 D1 ON H1.DocEntry = D1.DocEntry
    WHERE H1.DocEntry = @list_of_cols_val_tab_del
        AND D1.Price = 0

    BEGIN
        SELECT @Error = 20230701
        SELECT @error_message = 'Cost Price Can Not Be Blank in Row Level.'
    END
END;

	
-----------------Item Should be Match with BOM or Pick Alternate Item in Production Order--------------------

IF @transaction_type IN ('A', 'U')AND @object_type in ('2012')
BEGIN
declare @AItemCode nvarchar
--set @AItemCode=(select AltItem from OALI inner join OITM on oali.OrigItem=OITM.ItemCode
--where OITM.ItemCode in (select ItemCode from WOR1 where DocEntry =@list_of_cols_val_tab_del))




If exists (SELECT T2.ItemCode FROM owor T0
inner join WOR1 t2 on t2.DocEntry = T0.DocEntry
where t0.DocEntry =@list_of_cols_val_tab_del and t2.itemCode = ((select WOR1.ItemCode from WOR1 
left join OALI on WOR1.ItemCode=OALI.OrigItem
where DocEntry=@list_of_cols_val_tab_del )
UNION 
(select AltItem from WOR1 
left join OALI on WOR1.ItemCode=OALI.OrigItem
where DocEntry=@list_of_cols_val_tab_del and AltItem is not null )))
 

Begin

SET @error = '202781'

SET @error_message = N'You can update with alternate Items only.'

End

END

----------------------------------------------------------------------------
IF @transaction_type IN ('A', 'U')AND @object_type in ('59')
begin 
If exists (select  Count(*) FROM OIGN H1 
		INNER JOIN IGN1 D1 ON  H1.DocEntry=D1.DocEntry where H1.DocEntry = @list_of_cols_val_tab_del and D1.Price=' ')
             begin
               SET @error = '2027812'

SET @error_message = N'You can update item with 0 qty.'
end
end


IF @object_type = N'59' AND (@transaction_type = N'A' or @transaction_type = N'U') 
BEGIN 

select Count(Price) from  
					OIGN H1 
					inner join IGN1 D1 on  H1.DocEntry=D1.DocEntry
					where H1.DocEntry=@list_of_cols_val_tab_del and ItemCode='30100220000'--Price < 1 or Price=0 or Price is null
                 
BEGIN
        select @error='33883'
        select @error_message = 'Good Receipt price  should be equal to issue!'
end
END 
	----------------------------------------------

	declare @Doc_cnt int
IF @object_type = N'59' AND (@transaction_type = N'A' or @transaction_type = N'U') 
begin
 set @Doc_cnt=(  SELECT ISNULL(COUNT(*),0)  
   FROM IGN1 T0 
   WHERE T0."DocEntry"= @list_of_cols_val_tab_del AND T0.Price=0)

   IF @Doc_cnt > 0 
              BEGIN
        select @error='33883'
        select @error_message = 'Good Receipt price  should be equal to issue!'
end
END
-------------------------------------------------
IF @transaction_type IN ('A', 'U')AND @object_type in ('202')

BEGIN
--declare @AItemCode1 nvarchar
--declare @orignItemCode nvarchar
--declare @Icount int
--declare @cCount int 
--declare @aCount int
--declare @BoMCount int
--Declare @ProdCount int 
set @BoMCount=( select count(distinct t3.code) FROM OWOR T0 INNER JOIN OITT T2 ON T0.ItemCode = T2.Code INNER JOIN ITT1 T3 ON T2.Code = T3.father WHERE T0.DocEntry=@list_of_cols_val_tab_del)

 set @ProdCount=(  select count(distinct ItemCode) from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del) 
 if(@ProdCount<>@BoMCount)
 BEGIN
SET @error = '20278'
SET @error_message = N'order can not be added line did not matched with BOM.'
end

set @cCount=(SELECT   
  count(  T3.code)
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del
   and T1.ItemCode not in (t3.code)
)
if @cCount >1
BEGIN
SET @error = '20278'
SET @error_message = N'order can not be added if not match with BOM.'
end


else

set @AItemCode1=(
SELECT   
    T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del
   and T1.ItemCode not in (t3.code)
)

set @orignItemCode=(select OrigItem from OALI where AltItem=@AItemCode1)
set @Icount=(SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del
   and T3.Code=@orignItemCode)

   if @Icount <=0

IF EXISTS(SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del)

Begin

SET @error = '20278'

SET @error_message = N'order can not be added if not match with BOM.'

End
END
------------------------------------------------

IF @transaction_type IN ('A', 'U')AND @object_type in ('2012')

BEGIN


 set @Icount=( select count(altItem) from OALI where origItem in 
 (Select ItemCode from WOR1 where DocEntry=@list_of_cols_val_tab_del))
 if @Icount <=0 
 begin
 set @BoMCount=( select count(distinct t3.code) FROM OWOR T0 
 INNER JOIN OITT T2 ON T0.ItemCode = T2.Code INNER JOIN ITT1 T3 ON T2.Code = T3.father 
 WHERE T0.DocEntry=@list_of_cols_val_tab_del)

 set @ProdCount=(select count(distinct ItemCode) from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del) 
 if(@ProdCount<>@BoMCount)
 BEGIN
SET @error = '20278'
SET @error_message = N'order can not be added line did not matched with BOM.'
end
end
else 
IF EXISTS (SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del  ) 

Begin

SET @error = '20278'

SET @error_message = N'order can not be added if not match with BOM.'

End
end 
------------------------------------------------------------------

IF @transaction_type IN ('A', 'U')AND @object_type in ('202')
BEGIN




set @OItem =(
select OrigItem from OALI where origItem in (
SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del
	EXCEPT
	select ItemCode from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del
))

set @AItem =(

select AltItem from OALI where AltItem in (
	select ItemCode from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del
	EXCEPT
	SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del
))

if exists (SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del)
   begin
   if(@OItem <> '') 

   set @OriginalItem=(
	SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del AND T3.Code =@OItem
	EXCEPT
	select ItemCode from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del
)

else

set @OriginalItem=(
	SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del 
	EXCEPT
	select ItemCode from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del
)

if (@AItem <> '')

set @AlternateItem= 
(
	select ItemCode from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del AND T0.ItemCode =@AItem
	EXCEPT
	SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del
)

else

set @AlternateItem= 
(
	select ItemCode from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del 
	EXCEPT
	SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del
)

set @AltItem=(select AltItem from OALI Where OrigItem=@OriginalItem)
set @WItemCode=(
select ItemCode from WOR1 where ItemCode <>@OriginalItem and ItemCode =@AltItem
and DocEntry=@list_of_cols_val_tab_del)
set @LineNum=(
select lineNum from WOR1 where ItemCode <>@OriginalItem and ItemCode =@AltItem
and DocEntry=@list_of_cols_val_tab_del)
set @Code=(
SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del and T3.Code=@OriginalItem and T3.Code <>@AltItem)

 set @ChildNum=(  SELECT   
   T3.ChildNum
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del and T3.Code=@OriginalItem and T3.Code <>@AltItem)
   set @BoMCount=( select count(distinct t3.code) FROM OWOR T0 
 INNER JOIN OITT T2 ON T0.ItemCode = T2.Code INNER JOIN ITT1 T3 ON T2.Code = T3.father 
 WHERE T0.DocEntry=@list_of_cols_val_tab_del)

 set @ProdCount=(select count(distinct ItemCode) from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del) 
 if(@ProdCount<>@BoMCount)
 BEGIN
SET @error = '20278'
SET @error_message = N'order can not be added line did not matched with BOM.'
end

   set @RemoveItem=(
	select ItemCode from WOR1 t0 WHERE T0.DocEntry=@list_of_cols_val_tab_del and ItemCode not in (@OriginalItem,@AltItem)
	EXCEPT
	SELECT   
   T3.code
FROM 
   OWOR T0
   INNER JOIN WOR1 T1 ON T0.Docentry = T1.DocEntry
   INNER JOIN OITT T2 ON T0.ItemCode = T2.Code 
   INNER JOIN ITT1 T3 ON T2.Code = T3.father AND T1.LineNum = T3.ChildNum
WHERE 
   T0.DocEntry =@list_of_cols_val_tab_del
)
if(@RemoveItem <> '')
begin
 SET @error = '20278'

SET @error_message = N'order can not be added if not match with BOM.'
end

   if((@ChildNum<>@LineNum) AND (@Code<>@OriginalItem OR @WItemCode<>@AItemCode)) 
   begin


   SET @error = '20278'

SET @error_message = N'order can not be added if not match with BOM.'
end
END
end
----------------------------------------------------------------------------------------------------

-- Select the return values
select @error, @error_message

end 