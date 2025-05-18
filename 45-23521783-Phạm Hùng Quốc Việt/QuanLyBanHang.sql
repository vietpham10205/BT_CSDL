--Quản lí bán hàng

-- Tạo DATABASE QLBH
CREATE DATABASE QLBH
USE QLBH

--I. Ngôn ngữ định nghĩa dữ liệu (Data Definition Language):

--1. Tạo các quan hệ và khai báo các khóa chính, khóa ngoại của quan hệ.
-------------------------------- KHACHHANG --------------------------------------------
CREATE TABLE KHACHHANG
(
MAKH char(4) not null,
HOTEN varchar(40),
DCHI varchar(50),
SODT varchar(20),
NGSINH smalldatetime,
NGDK smalldatetime,
DOANHSO money,
)
--------------------------------- NHANVIEN --------------------------------------------
CREATE TABLE NHANVIEN
(
MANV char(4) not null,
HOTEN varchar(40),
SODT varchar(20),
NGVL smalldatetime,
)
--------------------------------- SANPHAM ---------------------------------------------
CREATE TABLE SANPHAM
(
MASP char(4) not null,
TENSP varchar(40),
DVT varchar(20),
NUOCSX varchar(40),
GIA money,
)
---------------------------------- HOADON ---------------------------------------------
CREATE TABLE HOADON
(
SOHD int not null,
NGHD smalldatetime,
MAKH char(4),
MANV char(4),
TRIGIA money,
)
----------------------------------- CTHD ----------------------------------------------
CREATE TABLE CTHD
(
SOHD int not null,
MASP char(4) not null,
SL int,
)
-----------------------khai báo các khóa chính, khóa ngoại của quan hệ-----------------
ALTER TABLE KHACHHANG ADD CONSTRAINT pk_kh PRIMARY KEY (MAKH)
ALTER TABLE NHANVIEN ADD CONSTRAINT pk_nv PRIMARY KEY (MANV)
ALTER TABLE SANPHAM ADD CONSTRAINT pk_sp PRIMARY KEY (MASP)
ALTER TABLE HOADON ADD CONSTRAINT pk_hd PRIMARY KEY (SOHD)

ALTER TABLE HOADON ADD FOREIGN KEY (MAKH) REFERENCES KHACHHANG(MAKH)
ALTER TABLE HOADON ADD FOREIGN KEY (MANV) REFERENCES NHANVIEN(MANV)
ALTER TABLE CTHD ADD FOREIGN KEY (SOHD) REFERENCES HOADON(SOHD)
ALTER TABLE CTHD ADD FOREIGN KEY (MASP) REFERENCES SANPHAM(MASP)


ALTER TABLE CTHD ADD CONSTRAINT pk_cthd PRIMARY KEY (SOHD,MASP)

--2. Thêm vào thuộc tính GHICHU có kiểu dữ liệu varchar(20) cho quan hệ SANPHAM.
ALTER TABLE SANPHAM ADD GHICHU varchar(20)
--3. Thêm vào thuộc tính LOAIKH có kiểu dữ liệu là tinyint cho quan hệ KHACHHANG.
ALTER TABLE KHACHHANG ADD LOAIKH tinyint
--4. Sửa kiểu dữ liệu của thuộc tính GHICHU trong quan hệ SANPHAM thành varchar(100).
ALTER TABLE SANPHAM ALTER COLUMN GHICHU varchar(100)
--5. Xóa thuộc tính GHICHU trong quan hệ SANPHAM.
ALTER TABLE SANPHAM DROP COLUMN GHICHU
--6. Làm thế nào để thuộc tính LOAIKH trong quan hệ KHACHHANG có thể lưu các giá trị là: “Vang lai”, “Thuong xuyen”, “Vip”, ...
ALTER TABLE KHACHHANG ALTER COLUMN LOAIKH varchar(100)
--7. Đơn vị tính của sản phẩm chỉ có thể là (“cay”,”hop”,”cai”,”quyen”,”chuc”)
ALTER TABLE SANPHAM ADD CONSTRAINT ck_dvt CHECK(DVT in ('cay','hop','cai','quyen','chuc'))
--8. Giá bán của sản phẩm từ 500 đồng trở lên.
ALTER TABLE SANPHAM ADD CONSTRAINT ck_gia CHECK(GIA >=500)
--9. Mỗi lần mua hàng, khách hàng phải mua ít nhất 1 sản phẩm.
ALTER TABLE CTHD ADD CONSTRAINT ck_sl CHECK (SL>=1)
--10. Ngày khách hàng đăng ký là khách hàng thành viên phải lớn hơn ngày sinh của người đó.
ALTER TABLE KHACHHANG ADD CONSTRAINT ck_ngdk CHECK (NGDK > NGSINH)
GO
--11. Ngày mua hàng (NGHD) của một khách hàng thành viên sẽ lớn hơn hoặc bằng ngày khách hàng đó đăng ký thành viên (NGDK).
CREATE TRIGGER nghd_ngdk_hoadon_insert
ON HOADON
AFTER INSERT 
AS
DECLARE @ngaymuahang smalldatetime
DECLARE @ngaydangki smalldatetime
SELECT @ngaymuahang = NGHD, @ngaydangki= NGDK
FROM KHACHHANG, inserted
WHERE KHACHHANG.MAKH=inserted.MAKH
IF @ngaymuahang < @ngaydangki
BEGIN 
ROLLBACK TRANSACTION
PRINT 'ngay mua hang phai lon hon ngay dang ki khach hang'
END;


CREATE TRIGGER nghd_hoadon_update
ON HOADON
AFTER UPDATE 
AS
IF (UPDATE( MAKH) OR UPDATE (NGHD))
BEGIN
		IF (EXISTS ( SELECT*
					 FROM inserted i JOIN KHACHHANG KH 
					 ON i.MAKH= KH.MAKH 
					 WHERE i.NGHD <KH.NGDK))
		BEGIN 
			ROLLBACK TRANSACTION
			PRINT 'ngay mua hang phai lon hon ngay dang ki khach hang'
		END
END;


CREATE TRIGGER ngdk_khachhang_update
ON KHACHHANG
AFTER UPDATE
AS
IF (UPDATE (NGDK))
BEGIN 
	IF  (EXISTS ( SELECT*
					 FROM inserted i JOIN HOADON HD
					 ON i.MAKH= HD.MAKH 
					 WHERE HD.NGHD <i.NGDK))
					 BEGIN 
			ROLLBACK TRANSACTION
			PRINT 'ngay mua hang phai lon hon ngay dang ki khach hang'
		END
END;


--12. Ngày bán hàng (NGHD) của một nhân viên phải lớn hơn hoặc bằng ngày nhân viên đó vào làm.
CREATE TRIGGER nghd_ngvl_hoadon_insert
ON HOADON
AFTER INSERT 
AS
	IF (EXISTS (SELECT *
				FROM inserted i JOIN NHANVIEN NV 
				ON i.MANV= NV.MANV
				WHERE i.NGHD<NV.NGVL))
BEGIN 
ROLLBACK TRANSACTION
PRINT 'ngay mua hang phai lon hon ngay VAO LAM'
END;
insert into HOADON VALUES(3000,'2005-7-23','KH01','NV01',320000)



CREATE TRIGGER nghd_ngvl_hoadon_update
ON HOADON
AFTER UPDATE 
AS
IF (UPDATE( MANV) OR UPDATE (NGHD))
BEGIN
		IF (EXISTS (SELECT *
				FROM inserted i JOIN NHANVIEN NV 
				ON i.MANV= NV.MANV
				WHERE i.NGHD<NV.NGVL))
		BEGIN 
			ROLLBACK TRANSACTION
			PRINT 'ngay mua hang phai lon hon ngay VAO LAM '
		END
END;

CREATE TRIGGER ngvl_nhanvien_update
ON NHANVIEN
AFTER UPDATE
AS
IF (UPDATE (NGVL))
BEGIN 
	IF  (EXISTS ( SELECT*
					 FROM inserted i JOIN HOADON HD
					 ON i.MANV= HD.MANV
					 WHERE HD.NGHD <i.NGVL))
					 BEGIN 
			ROLLBACK TRANSACTION
			PRINT 'ngay mua hang phai lon hon ngay VAO LAM'
		END
END;
--13. Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.
CREATE TRIGGER TRG_HD_CTHD 
ON HOADON 
FOR INSERT
AS
BEGIN
	DECLARE @SOHD INT, @COUNT_SOHD INT
	SELECT @SOHD = SOHD FROM INSERTED
	SELECT @COUNT_SOHD = COUNT(SOHD) FROM CTHD WHERE SOHD = @SOHD

	IF (@COUNT_SOHD >= 1)
		PRINT N'Thêm mới một hóa đơn thành công.'
	ELSE
	BEGIN
		PRINT N'Lỗi: Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.'
		ROLLBACK TRANSACTION
	END
END
GO
--deldete Cách 1:
DROP TRIGGER sohd_toithieu_cthd_delete
go
CREATE TRIGGER sohd_toithieu_cthd_delete
ON CTHD 
FOR DELETE
AS 
BEGIN
	DECLARE @SOHD int , @count_sohd int
	SELECT @SOHD = SOHD FROM deleted
	SELECT @count_sohd = COUNT(SOHD) FROM CTHD WHERE SOHD = @SOHD

	IF(@count_sohd < 1)
	BEGIN
		ROLLBACK TRANSACTION
		print N'Mỗi một hóa đơn phải có ít nhất một chi tiết hóa đơn.'
	END
END
GO
--deldete Cách 2:
CREATE TRIGGER sohd_toithieu_cthd_delete
ON CTHD 
AFTER DELETE
AS 
	IF( EXISTS (SELECT * 
				FROM CTHD JOIN HOADON HD
				ON CTHD.SOHD= HD.SOHD  JOIN deleted d
				ON D.SOHD= HD.SOHD
				GROUP BY CTHD.SOHD
				HAVING COUNT(CTHD.SOHD) =0))
				 BEGIN 
			ROLLBACK TRANSACTION
			PRINT 'MOi một hóa đơn phải có ít nhất một chi tiết hóa đơn'
			END
GO
--14. Trị giá của một hóa đơn là tổng thành tiền (số lượng*đơn giá) của các chi tiết thuộc hóa đơn đó.
CREATE TRIGGER TRG_CTHD 
ON CTHD 
FOR INSERT
AS
BEGIN
	DECLARE @SOHD INT, @TONGGIATRI money

	SELECT @TONGGIATRI = SUM(SL * GIA), @SOHD = SOHD 
	FROM INSERTED INNER JOIN SANPHAM
	ON INSERTED.MASP = SANPHAM.MASP
	GROUP BY SOHD

	UPDATE HOADON
	SET TRIGIA += @TONGGIATRI
	WHERE SOHD = @SOHD
END
GO 
SELECT * FROM HOADON
SELECT * FROM CTHD WHERE SOHD= '1001'
INSERT INTO CTHD VALUES(1001,'BC03',1)
SELECT * FROM HOADON
SELECT * FROM CTHD WHERE SOHD= '1001'
DELETE FROM CTHD WHERE SOHD= '1001'AND MASP='BC03'
SELECT * FROM KHACHHANG
UPDATE KHACHHANG SET DOANHSO ='13060000' WHERE MAKH='KH01'
GO
CREATE TRIGGER TR_DEL_CTHD 
ON CTHD 
FOR DELETE
AS
BEGIN
	DECLARE @SOHD INT, @GIATRI money

	SELECT @SOHD = SOHD, @GIATRI = SL * GIA 
	FROM DELETED INNER JOIN SANPHAM 
	ON SANPHAM.MASP = DELETED.MASP

	UPDATE HOADON
	SET TRIGIA -= @GIATRI
	WHERE SOHD = @SOHD
END
GO

--15. Doanh số của một khách hàng là tổng trị giá các hóa đơn mà khách hàng thành viên đó đã mua.
CREATE TRIGGER DSKH_ins_HOADON
ON HOADON
FOR INSERT
AS 
BEGIN
	DECLARE @MAKH char(4) , @TONGTRIGIA money
	SELECT @MAKH= MAKH , @TONGTRIGIA= TRIGIA FROM inserted

	UPDATE KHACHHANG
	SET DOANHSO += @TONGTRIGIA
	WHERE MAKH= @MAKH

END 
GO
CREATE TRIGGER DSKH_del_HOADON
ON HOADON
FOR DELETE
AS 
BEGIN
	DECLARE @MAKH char(4) , @TRIGIA money
	SELECT @MAKH= MAKH , @TRIGIA= TRIGIA FROM deleted

	UPDATE KHACHHANG
	SET DOANHSO -= @TRIGIA
	WHERE MAKH= @MAKH

END 
GO
DROP TRIGGER DSKH_UPDATE_HOADON
GO
CREATE TRIGGER DSKH_UPDATE_HOADON
ON HOADON
FOR UPDATE 
AS
IF (UPDATE (TRIGIA))
BEGIN
	DECLARE @MAKH char(4) , @TONGTRIGIA money ,@TONGTRIGIACU money 
	SELECT @MAKH= MAKH , @TONGTRIGIA= TRIGIA FROM inserted
	SELECT @TONGTRIGIACU = TRIGIA FROM deleted

	UPDATE KHACHHANG
	SET DOANHSO += (@TONGTRIGIA- @TONGTRIGIACU)
	WHERE MAKH= @MAKH
	END
GO
--II. Ngôn ngữ thao tác dữ liệu (Data Manipulation Language):

--1. Nhập dữ liệu cho các quan hệ trên.
-------------------------------Nhập dữ liệu cho NHANVIEN-----------------------------------------------------
INSERT INTO NHANVIEN VALUES ('NV01' , 'Nguyen Nhu Nhut', '0927345678', '2006-4-13')
SELECT * FROM NHANVIEN WHERE HOTEN = 'Nguyen Nhu Nhut'

INSERT INTO NHANVIEN VALUES ('NV02' , 'Le Thi Phi Yen', '0987567390', '2006-4-21')
INSERT INTO NHANVIEN VALUES ('NV03' , 'Nguyen Van B', '0997047382', '2006-4-27')
INSERT INTO NHANVIEN VALUES ('NV04' , 'Ngo Thanh Tuan', '0913758498', '2006-6-24')
INSERT INTO NHANVIEN VALUES ('NV05' , 'Nguyen Thi Truc Thanh', '0918590387', '2006-7-20')
SELECT * FROM NHANVIEN
-------------------------------Nhập dữ liệu cho KHACHHANG-----------------------------------------------------
 INSERT INTO KHACHHANG VALUES ( 'KH01','Nguyen Van A','731 Tran Hung Dao, Q5, TpHCM','8823451','1960-10-22','2006-7-22','13060000', NULL)  
 INSERT INTO KHACHHANG VALUES ( 'KH02','Tran Ngoc Han','23/5 Nguyen Trai, Q5, TpHCM','908256478','1974-4-3','2006-7-30','280000', NULL)  
 INSERT INTO KHACHHANG VALUES ( 'KH03','Tran Ngoc Linh','45 Nguyen Canh Chan, Q1, TpHCM','938776266','1980-6-12','2006-8-5','3860000', NULL)  
 INSERT INTO KHACHHANG VALUES ( 'KH04','Tran Minh Long','50/34 Le Dai Hanh, Q10, TpHCM','917325476','1965-3-9','2006-10-2','250000', NULL)  
 INSERT INTO KHACHHANG VALUES ( 'KH05','Le Nhat Minh','34 Truong Dinh, Q3, TpHCM','8246108','1950-10-3','2006-10-28','21000', NULL)  
 INSERT INTO KHACHHANG VALUES ( 'KH06','Le Hoai Thuong','227 Nguyen Van Cu, Q5, TpHCM','8631738','1981-12-31','2006-11-24','915000', NULL)  
 INSERT INTO KHACHHANG VALUES ( 'KH07','Nguyen Van Tam','32/3 Tran Binh Trong, Q5, TpHCM','916783565','1971-4-6','2006-12-1','12500', NULL)  
 INSERT INTO KHACHHANG VALUES ( 'KH08','Phan Thi Thanh','45/2 An Duong Vuong, Q5, TpHCM','938435756','1971-1-10','2006-12-13','365000', NULL)  
 INSERT INTO KHACHHANG VALUES ( 'KH09','Le Ha Vinh','873 Le Hong Phong, Q5, TpHCM','8654763','1979-9-3','2007-1-14','70000', NULL)  
 INSERT INTO KHACHHANG VALUES ( 'KH10','Ha Duy Lap','34/34B Nguyen Trai, Q1, TpHCM','8768904','1983-5-2','2007-1-16','67500', NULL)  
 SELECT * FROM KHACHHANG
 -------------------------------Nhập dữ liệu cho SANPHAM-----------------------------------------------------

 INSERT INTO SANPHAM VALUES ( 'BC01','But chi','cay','Singapore','3000')
 INSERT INTO SANPHAM VALUES ( 'BC02','But chi','cay','Singapore','5000')
 INSERT INTO SANPHAM VALUES ( 'BC03','But chi','cay','Viet Nam','3500')
 INSERT INTO SANPHAM VALUES ( 'BC04','But chi','hop','Viet Nam','30000')
 INSERT INTO SANPHAM VALUES ( 'BB01','But bi','cay','Viet Nam','5000')
 INSERT INTO SANPHAM VALUES ( 'BB02','But bi','cay','Trung Quoc','7000')
 INSERT INTO SANPHAM VALUES ( 'BB03','But bi','hop','Thai Lan','100000')
 INSERT INTO SANPHAM VALUES ( 'TV01','Tap 100 giay mong','quyen','Trung Quoc','2500')
 INSERT INTO SANPHAM VALUES ( 'TV02','Tap 200 giay mong','quyen','Trung Quoc','4500')
 INSERT INTO SANPHAM VALUES ( 'TV03','Tap 100 giay tot','quyen','Viet Nam','3000')
 INSERT INTO SANPHAM VALUES ( 'TV04','Tap 200 giay tot','quyen','Viet Nam','5500')
 INSERT INTO SANPHAM VALUES ( 'TV05','Tap 100 trang','chuc','Viet Nam','23000')
 INSERT INTO SANPHAM VALUES ( 'TV06','Tap 200 trang','chuc','Viet Nam','53000')
 INSERT INTO SANPHAM VALUES ( 'TV07','Tap 100 trang','chuc','Trung Quoc','34000')
 INSERT INTO SANPHAM VALUES ( 'ST01','So tay 500 trang','quyen','Trung Quoc','40000')
 INSERT INTO SANPHAM VALUES ( 'ST02','So tay loai 1','quyen','Viet Nam','55000')
 INSERT INTO SANPHAM VALUES ( 'ST03','So tay loai 2','quyen','Viet Nam','51000')
 INSERT INTO SANPHAM VALUES ( 'ST04','So tay','quyen','Thai Lan','55000')
 INSERT INTO SANPHAM VALUES ( 'ST05','So tay mong','quyen','Thai Lan','20000')
 INSERT INTO SANPHAM VALUES ( 'ST06','Phan viet bang','hop','Viet Nam','5000')
 INSERT INTO SANPHAM VALUES ( 'ST07','Phan khong bui','hop','Viet Nam','7000')
 INSERT INTO SANPHAM VALUES ( 'ST08','Bong bang','cai','Viet Nam','1000')
 INSERT INTO SANPHAM VALUES ( 'ST09','But long','cay','Viet Nam','5000')
 INSERT INTO SANPHAM VALUES ( 'ST10','But long','cay','Trung Quoc','7000')
 SELECT * FROM SANPHAM

 -------------------------------Nhập dữ liệu cho HOADON-----------------------------------------------------
 INSERT INTO HOADON VALUES(1001,'2006-7-23','KH01','NV01',320000)
INSERT INTO HOADON VALUES(1002,'2006-8-12','KH01','NV02',840000)
INSERT INTO HOADON VALUES(1003,'2006-8-23','KH02','NV01',100000)
INSERT INTO HOADON VALUES(1004,'2006-9-1','KH02','NV01',180000)
INSERT INTO HOADON VALUES(1005,'2006-10-20','KH01','NV02',3800000)
INSERT INTO HOADON VALUES(1006,'2006-10-16','KH01','NV03',2430000)
INSERT INTO HOADON VALUES(1007,'2006-10-28','KH03','NV03',510000)
INSERT INTO HOADON VALUES(1008,'2006-10-28','KH01','NV03',440000)
INSERT INTO HOADON VALUES(1009,'2006-10-28','KH03','NV04',200000)
INSERT INTO HOADON VALUES(1010,'2006-11-1','KH01','NV01',5200000)
INSERT INTO HOADON VALUES(1011,'2006-11-4','KH04','NV03',250000)
INSERT INTO HOADON VALUES(1012,'2006-11-30','KH05','NV03',21000)
INSERT INTO HOADON VALUES(1013,'2006-12-12','KH06','NV01',5000)
INSERT INTO HOADON VALUES(1014,'2006-12-31','KH03','NV02',3150000)
INSERT INTO HOADON VALUES(1015,'2007-1-1','KH06','NV01',910000)
INSERT INTO HOADON VALUES(1016,'2007-1-1','KH07','NV02',12500)
INSERT INTO HOADON VALUES(1017,'2007-1-2','KH08','NV03',35000)
INSERT INTO HOADON VALUES(1018,'2007-1-13','KH08','NV03',330000)
INSERT INTO HOADON VALUES(1019,'2007-1-13','KH01','NV03',30000)
INSERT INTO HOADON VALUES(1020,'2007-1-14','KH09','NV04',70000)
INSERT INTO HOADON VALUES(1021,'2007-1-16','KH10','NV03',67500)
INSERT INTO HOADON VALUES(1022,'2007-1-16',Null,'NV03',7000)
INSERT INTO HOADON VALUES(1023,'2007-1-17',Null,'NV01',330000)
SELECT * FROM HOADON
-------------------------------Nhập dữ liệu cho CTHD-----------------------------------------------------
INSERT INTO CTHD VALUES(1001,'TV02',10)
INSERT INTO CTHD VALUES(1001,'ST01',5)
INSERT INTO CTHD VALUES(1001,'BC01',5)
INSERT INTO CTHD VALUES(1001,'BC02',10)
INSERT INTO CTHD VALUES(1001,'ST08',10)
INSERT INTO CTHD VALUES(1002,'BC04',20)
INSERT INTO CTHD VALUES(1002,'BB01',20)
INSERT INTO CTHD VALUES(1002,'BB02',20)
INSERT INTO CTHD VALUES(1003,'BB03',10)
INSERT INTO CTHD VALUES(1004,'TV01',20)
INSERT INTO CTHD VALUES(1004,'TV02',10)
INSERT INTO CTHD VALUES(1004,'TV03',10)
INSERT INTO CTHD VALUES(1004,'TV04',10)
INSERT INTO CTHD VALUES(1005,'TV05',50)
INSERT INTO CTHD VALUES(1005,'TV06',50)
INSERT INTO CTHD VALUES(1006,'TV07',20)
INSERT INTO CTHD VALUES(1006,'ST01',30)
INSERT INTO CTHD VALUES(1006,'ST02',10)
INSERT INTO CTHD VALUES(1007,'ST03',10)
INSERT INTO CTHD VALUES(1008,'ST04',8)
INSERT INTO CTHD VALUES(1009,'ST05',10)
INSERT INTO CTHD VALUES(1010,'TV07',50)
INSERT INTO CTHD VALUES(1010,'ST07',50)
INSERT INTO CTHD VALUES(1010,'ST08',100)
INSERT INTO CTHD VALUES(1010,'ST04',50)
INSERT INTO CTHD VALUES(1010,'TV03',100)
INSERT INTO CTHD VALUES(1011,'ST06',50)
INSERT INTO CTHD VALUES(1012,'ST07',3)
INSERT INTO CTHD VALUES(1013,'ST08',5)
INSERT INTO CTHD VALUES(1014,'BC02',80)
INSERT INTO CTHD VALUES(1014,'BB02',100)
INSERT INTO CTHD VALUES(1014,'BC04',60)
INSERT INTO CTHD VALUES(1014,'BB01',50)
INSERT INTO CTHD VALUES(1015,'BB02',30)
INSERT INTO CTHD VALUES(1015,'BB03',7)
INSERT INTO CTHD VALUES(1016,'TV01',5)
INSERT INTO CTHD VALUES(1017,'TV02',1)
INSERT INTO CTHD VALUES(1017,'TV03',1)
INSERT INTO CTHD VALUES(1017,'TV04',5)
INSERT INTO CTHD VALUES(1018,'ST04',6)
INSERT INTO CTHD VALUES(1019,'ST05',1)
INSERT INTO CTHD VALUES(1019,'ST06',2)
INSERT INTO CTHD VALUES(1020,'ST07',10)
INSERT INTO CTHD VALUES(1021,'ST08',5)
INSERT INTO CTHD VALUES(1021,'TV01',7)
INSERT INTO CTHD VALUES(1021,'TV02',10)
INSERT INTO CTHD VALUES(1022,'ST07',1)
INSERT INTO CTHD VALUES(1023,'ST04',6)
SELECT * FROM CTHD



--2. Tạo quan hệ SANPHAM1 chứa toàn bộ dữ liệu của quan hệ SANPHAM. Tạo quan hệ KHACHHANG1 chứa toàn bộ dữ liệu của quan hệ KHACHHANG.
 SELECT * INTO SANPHAM1 FROM SANPHAM
 SELECT * INTO KHACHHANG1 FROM KHACHHANG
 SELECT * FROM SANPHAM1
 SELECT * FROM KHACHHANG1
 --3. Cập nhật giá tăng 5% đối với những sản phẩm do “Thai Lan” sản xuất (cho quan hệ SANPHAM1)
 UPDATE SANPHAM1 SET GIA=(GIA*105)/100 WHERE NUOCSX ='Thai Lan'
 SELECT * FROM SANPHAM1 WHERE NUOCSX ='Thai Lan'

--4. Cập nhật giá giảm 5% đối với những sản phẩm do “Trung Quoc” sản xuất có giá từ 10.000 trở xuống (cho quan hệ SANPHAM1).
 UPDATE SANPHAM1 SET GIA=(GIA*95)/100 WHERE NUOCSX ='Trung Quoc'AND GIA <=10000
 SELECT * FROM SANPHAM1 WHERE NUOCSX ='Trung Quoc'AND GIA <=10000

 --5. Cập nhật giá trị LOAIKH là “Vip” đối với những khách hàng đăng ký thành viên trước ngày 1/1/2007 có doanh số từ 10.000.000 trở lên 
 --hoặc khách hàng đăng ký thành viên từ 1/1/2007 trở về sau có doanh số từ 2.000.000 trở lên (cho quan hệ KHACHHANG1).
  UPDATE KHACHHANG1 SET LOAIKH='Vip' WHERE (NGDK < '2007-1-1' AND DOANHSO >=10000000) OR (NGDK > '2007-1-1' AND DOANHSO >=2000000)
   SELECT * FROM KHACHHANG1 WHERE (NGDK < '2007-1-1' AND DOANHSO >=10000000) OR (NGDK > '2007-1-1' AND DOANHSO >=2000000)
    SELECT * FROM KHACHHANG1



--III. Ngôn ngữ truy vấn dữ liệu có cấu trúc:

--1. In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất.
SELECT MASP, TENSP FROM SANPHAM 
 WHERE NUOCSX = 'Trung Quoc'
GO

--2. In ra danh sách các sản phẩm (MASP, TENSP) có đơn vị tính là “cay”, ”quyen”.
SELECT MASP, TENSP FROM SANPHAM 
WHERE DVT IN ('cay', 'quyen')
GO

--3. In ra danh sách các sản phẩm (MASP,TENSP) có mã sản phẩm bắt đầu là “B” và kết thúc là “01”.
SELECT MASP, TENSP FROM SANPHAM
WHERE  LEFT(MASP, 1) = 'B' AND RIGHT(MASP, 2) = '01'
GO

--4. In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quốc” sản xuất có giá từ 30.000 đến 40.000.
SELECT MASP, TENSP FROM SANPHAM
WHERE NUOCSX = 'Trung Quoc' AND (GIA BETWEEN 30000 AND 40000)
GO
--5. In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” hoặc “Thai Lan” sản xuất có giá từ 30.000 đến 40.000.
--C1:
SELECT MASP, TENSP FROM SANPHAM
WHERE (NUOCSX = 'Trung Quoc' OR NUOCSX = 'Thai Lan') AND (GIA BETWEEN 30000 AND 40000)
GO
--C2:
SELECT MASP,TENSP FROM SANPHAM 
WHERE (NUOCSX IN ('Trung Quoc', ' Thai Lan')) AND (GIA BETWEEN 30000 AND 40000)
GO

--6. In ra các số hóa đơn, trị giá hóa đơn bán ra trong ngày 1/1/2007 và ngày 2/1/2007.
SELECT SOHD, TRIGIA FROM HOADON 
WHERE NGHD IN ('1/1/2007', '2/1/2007')
GO
--7. In ra các số hóa đơn, trị giá hóa đơn trong tháng 1/2007, sắp xếp theo ngày (tăng dần) và trị giá của hóa đơn (giảm dần).
SELECT SOHD, TRIGIA FROM HOADON 
WHERE YEAR(NGHD) = 2007 AND MONTH(NGHD) = 1 
ORDER BY NGHD ASC, TRIGIA DESC
GO

--8. In ra danh sách các khách hàng (MAKH, HOTEN) đã mua hàng trong ngày 1/1/2007.
SELECT HOADON.MAKH, HOTEN 
FROM HOADON  INNER JOIN KHACHHANG  
ON HOADON.MAKH = KHACHHANG.MAKH 
WHERE NGHD = '1/1/2007'
GO

--9. In ra số hóa đơn, trị giá các hóa đơn do nhân viên có tên “Nguyen Van B” lập trong ngày 28/10/2006.
SELECT HOADON.SOHD, TRIGIA 
FROM HOADON INNER JOIN NHANVIEN
ON HOADON.MANV = NHANVIEN.MANV
WHERE HOTEN = 'Nguyen Van B' AND NGHD = '2006-10-28'
GO

--10. In ra danh sách các sản phẩm (MASP,TENSP) được khách hàng có tên “Nguyen Van A” mua trong tháng 10/2006.
SELECT CTHD.MASP , TENSP 
FROM CTHD  INNER JOIN SANPHAM  
ON CTHD.MASP = SANPHAM.MASP
WHERE SOHD IN (
SELECT SOHD 
	FROM HOADON HD INNER JOIN KHACHHANG KH 
	ON HD.MAKH = KH.MAKH
	WHERE HOTEN = 'Nguyen Van A' AND YEAR(NGHD) = 2006 AND MONTH(NGHD) = 10 
	)
	GO

--11. Tìm các số hóa đơn đã mua sản phẩm có mã số “BB01” hoặc “BB02”.
SELECT SOHD FROM CTHD WHERE MASP = 'BB01' 
UNION
SELECT SOHD FROM CTHD WHERE MASP = 'BB02' 
GO
--12. Tìm các số hóa đơn đã mua sản phẩm có mã số “BB01” hoặc “BB02”, mỗi sản phẩm mua với số lượng từ 10 đến 20.
--Cách 1:
SELECT SOHD FROM CTHD WHERE (MASP = 'BB01') and (SL BETWEEN 10 AND 20)
UNION
SELECT SOHD FROM CTHD WHERE MASP = 'BB02' and (SL BETWEEN 10 AND 20)
-- Cách 2:
SELECT DISTINCT  SOHD FROM CTHD WHERE (MASP IN ('BB01','BB02')) and (SL BETWEEN 10 AND 20)

--13. Tìm các số hóa đơn mua cùng lúc 2 sản phẩm có mã số “BB01” và “BB02”, mỗi sản phẩm mua với số lượng từ 10 đến 20.
SELECT SOHD FROM CTHD WHERE (MASP = 'BB01') and (SL BETWEEN 10 AND 20)
INTERSECT
SELECT SOHD FROM CTHD WHERE MASP = 'BB02' and (SL BETWEEN 10 AND 20)

--14. In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất hoặc các sản phẩm được bán ra trong ngày 1/1/2007.
SELECT MASP, TENSP FROM SANPHAM WHERE NUOCSX ='Trung Quoc'
UNION
SELECT MASP, TENSP FROM SANPHAM WHERE MASP IN (
												SELECT CTHD.MASP 
												FROM CTHD JOIN HOADON HD
												ON CTHD.SOHD = HD.SOHD
												WHERE HD.NGHD ='1/1/2007')

--15. In ra danh sách các sản phẩm (MASP,TENSP) không bán được.
--Cách 1:
SELECT MASP, TENSP FROM SANPHAM 
EXCEPT
SELECT MASP, TENSP FROM SANPHAM WHERE MASP IN ( 
												SELECT DISTINCT MASP 
												FROM CTHD )
--Cách 2:
SELECT MASP, TENSP
FROM SANPHAM 
WHERE MASP NOT IN (
	SELECT DISTINCT MASP 
	FROM CTHD
)
GO
--16. In ra danh sách các sản phẩm (MASP,TENSP) không bán được trong năm 2006.
--Cách 1:
SELECT MASP, TENSP FROM SANPHAM 
EXCEPT
SELECT MASP, TENSP FROM SANPHAM WHERE MASP IN (
												SELECT DISTINCT CTHD.MASP 
												FROM CTHD JOIN HOADON HD
												ON CTHD.SOHD = HD.SOHD
												WHERE YEAR( HD.NGHD) ='2006')
--Cách 2:
SELECT MASP, TENSP
FROM SANPHAM 
WHERE MASP NOT IN (
	SELECT CT.MASP
	FROM CTHD CT INNER JOIN HOADON HD
	ON CT.SOHD = HD.SOHD
	WHERE YEAR(NGHD) = 2006
)
GO
--17. In ra danh sách các sản phẩm (MASP,TENSP) do “Trung Quoc” sản xuất không bán được trong năm 2006.
--Cách 1:
SELECT MASP, TENSP FROM SANPHAM WHERE NUOCSX ='Trung Quoc'
EXCEPT
SELECT MASP, TENSP FROM SANPHAM WHERE MASP IN (
												SELECT DISTINCT CTHD.MASP 
												FROM CTHD JOIN HOADON HD
												ON CTHD.SOHD = HD.SOHD
												WHERE YEAR( HD.NGHD) ='2006')
--Cách 2:
SELECT MASP, TENSP
FROM SANPHAM 
WHERE NUOCSX = 'Trung Quoc' AND MASP NOT IN (
	SELECT DISTINCT CT.MASP
	FROM CTHD CT INNER JOIN HOADON HD
	ON CT.SOHD = HD.SOHD
	WHERE YEAR(NGHD) = 2006
)
GO
--18. Tìm số hóa đơn đã mua tất cả các sản phẩm do Singapore sản xuất.
--Cách 1:
SELECT CT.SOHD
FROM CTHD CT INNER JOIN SANPHAM SP
ON CT.MASP = SP.MASP
WHERE NUOCSX = 'Singapore'
GROUP BY CT.SOHD 
HAVING COUNT( DISTINCT CT.MASP ) >= (
	SELECT COUNT(MASP) 
	FROM SANPHAM 
	WHERE NUOCSX = 'Singapore'
)
GO
--Cách 2:
SELECT SOHD
FROM HOADON HD
WHERE NOT EXISTS ( SELECT * FROM SANPHAM SP
				   WHERE NUOCSX = 'Singapore'
				   AND NOT EXISTS ( SELECT * FROM CTHD
									WHERE CTHD.MASP=SP.MASP AND CTHD.SOHD=HD.SOHD))
SELECT DISTINCT SOHD
FROM CTHD CT
WHERE NOT EXISTS ( SELECT * FROM SANPHAM SP
				   WHERE NUOCSX = 'Singapore'
				   AND NOT EXISTS ( SELECT * FROM CTHD
									WHERE CTHD.MASP=SP.MASP AND CTHD.SOHD=CT.SOHD))

--19. Tìm số hóa đơn trong năm 2006 đã mua ít nhất tất cả các sản phẩm do Singapore sản xuất.
SELECT SOHD FROM HOADON
WHERE (YEAR(NGHD)=2006) AND (SOHD IN (
										SELECT CT.SOHD
										FROM CTHD CT INNER JOIN SANPHAM SP
										ON CT.MASP = SP.MASP
										WHERE NUOCSX = 'Singapore'
										GROUP BY CT.SOHD 
										HAVING COUNT( DISTINCT CT.MASP ) >= (
											SELECT COUNT(MASP) 
											FROM SANPHAM 
											WHERE NUOCSX = 'Singapore'		)
										)
								)

GO

--20. Có bao nhiêu hóa đơn không phải của khách hàng đăng ký thành viên mua?
SELECT COUNT(SOHD)
FROM HOADON
WHERE MAKH IS NULL

--21. Có bao nhiêu sản phẩm khác nhau được bán ra trong năm 2006.
SELECT COUNT( DISTINCT MASP) 
FROM CTHD JOIN HOADON HD
ON HD.SOHD=CTHD.SOHD 
WHERE YEAR(HD.NGHD)=2006

--22. Cho biết trị giá hóa đơn cao nhất, thấp nhất là bao nhiêu ?
SELECT MAX(TRIGIA) AS HDCAONHAT, MIN(TRIGIA) AS HDTHAPNHAT
FROM HOADON
--23. Trị giá trung bình của tất cả các hóa đơn được bán ra trong năm 2006 là bao nhiêu?
SELECT AVG(TRIGIA) AS TRIGIATRUNGBINH
FROM HOADON
--24. Tính doanh thu bán hàng trong năm 2006.
SELECT SUM(TRIGIA) AS DOANHTHU2006
FROM HOADON
WHERE YEAR(NGHD)=2006
--25. Tìm số hóa đơn có trị giá cao nhất trong năm 2006.
SELECT MAX(TRIGIA) AS HDCAONHAT2006
FROM HOADON
WHERE YEAR(NGHD)=2006
--26. Tìm họ tên khách hàng đã mua hóa đơn có trị giá cao nhất trong năm 2006.
--Cách 1:
SELECT KH.HOTEN 
FROM KHACHHANG KH JOIN HOADON HD
ON HD.MAKH=KH.MAKH
WHERE YEAR(NGHD)=2006 AND HD.TRIGIA=(SELECT MAX(TRIGIA) AS HDCAONHAT2006
FROM HOADON
WHERE YEAR(NGHD)=2006)
--Cách 2:
SELECT TOP 1 KH.HOTEN 
FROM KHACHHANG KH JOIN HOADON HD
ON HD.MAKH=KH.MAKH
WHERE YEAR(NGHD)=2006 
ORDER BY TRIGIA DESC

--27. In ra danh sách 3 khách hàng (MAKH, HOTEN) có doanh số cao nhất.
SELECT TOP 3 MAKH, HOTEN 
FROM KHACHHANG
ORDER BY DOANHSO DESC
--28. In ra danh sách các sản phẩm (MASP, TENSP) có giá bán bằng 1 trong 3 mức giá cao nhất.
SELECT MASP, TENSP
FROM SANPHAM
WHERE  GIA IN ( SELECT TOP 3 GIA 
					FROM SANPHAM 
					ORDER BY GIA DESC)
-- THỬ VỚI EXIST

SELECT MASP, TENSP
FROM SANPHAM  SP1
WHERE EXISTS (
    SELECT 1
    FROM (SELECT TOP 3 GIA
          FROM SANPHAM
          ORDER BY GIA DESC) AS SP2
    WHERE SP1.GIA = SP2.GIA
)

--29. In ra danh sách các sản phẩm (MASP, TENSP) do “Thai Lan” sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của tất cả các sản phẩm).
SELECT MASP, TENSP
FROM SANPHAM
WHERE NUOCSX='Thai Lan' AND GIA IN ( SELECT TOP 3 GIA 
					FROM SANPHAM 
					ORDER BY GIA DESC)

--30. In ra danh sách các sản phẩm (MASP, TENSP) do “Trung Quoc” sản xuất có giá bằng 1 trong 3 mức giá cao nhất (của sản phẩm do “Trung Quoc” sản xuất).
SELECT MASP, TENSP
FROM SANPHAM
WHERE NUOCSX='Trung Quoc' AND GIA IN ( SELECT TOP 3 GIA 
										FROM SANPHAM 
										WHERE NUOCSX ='Trung Quoc'
										ORDER BY GIA DESC)
--31. * In ra danh sách 3 khách hàng có doanh số cao nhất (sắp xếp theo kiểu xếp hạng).
--Cách 1:
SELECT TOP 3 MAKH, HOTEN 
FROM KHACHHANG
ORDER BY DOANHSO DESC
--Cách 2:
SELECT TOP 3 RANK() OVER(ORDER BY DOANHSO DESC) AS XEPHANG, MAKH, HOTEN 
FROM KHACHHANG

--32. Tính tổng số sản phẩm do “Trung Quoc” sản xuất.
SELECT COUNT (DISTINCT MASP ) AS TONGSOSP
FROM SANPHAM
WHERE NUOCSX='Trung Quoc'
--33. Tính tổng số sản phẩm của từng nước sản xuất.
SELECT DISTINCT NUOCSX, COUNT (DISTINCT MASP ) AS TONGSOSP
FROM SANPHAM
GROUP BY NUOCSX
--34. Với từng nước sản xuất, tìm giá bán cao nhất, thấp nhất, trung bình của các sản phẩm.
SELECT DISTINCT NUOCSX, MAX(GIA) AS MAXGIA, MIN(GIA) AS MINGIA, AVG(GIA) AS AVGGIA
FROM SANPHAM
GROUP BY NUOCSX

--35. Tính doanh thu bán hàng mỗi ngày.
SELECT DISTINCT NGHD, SUM(TRIGIA) AS DOANHTHU
FROM HOADON
GROUP BY NGHD

--36. Tính tổng số lượng của từng sản phẩm bán ra trong tháng 10/2006.
SELECT MASP,SUM(SL) as tongsoluong
FROM CTHD JOIN HOADON HD 
ON CTHD.SOHD= HD.SOHD
WHERE YEAR(HD.NGHD)=2006 AND MONTH(NGHD)=10
GROUP BY MASP
--37. Tính doanh thu bán hàng của từng tháng trong năm 2006.
SELECT MONTH(NGHD) AS THANG, SUM(TRIGIA) AS DOANHTHU
FROM HOADON
WHERE YEAR(NGHD)=2006
GROUP BY MONTH(NGHD)
--38. Tìm hóa đơn có mua ít nhất 4 sản phẩm khác nhau.
SELECT DISTINCT HD.SOHD
FROM HOADON HD JOIN CTHD
ON HD.SOHD= CTHD.SOHD
GROUP BY HD.SOHD
HAVING COUNT(DISTINCT MASP)>=4
--39. Tìm hóa đơn có mua 3 sản phẩm do “Viet Nam” sản xuất (3 sản phẩm khác nhau).
SELECT DISTINCT HD.SOHD
FROM HOADON HD JOIN CTHD
ON HD.SOHD= CTHD.SOHD
JOIN SANPHAM SP
ON SP.MASP=CTHD.MASP
WHERE SP.NUOCSX='Viet Nam'
GROUP BY HD.SOHD
HAVING COUNT(DISTINCT CTHD.MASP)=3
--40. Tìm khách hàng (MAKH, HOTEN) có số lần mua hàng nhiều nhất.
SELECT TOP 1 KH.MAKH, KH.HOTEN
FROM KHACHHANG KH JOIN HOADON HD
ON KH.MAKH= HD.MAKH
GROUP BY KH.MAKH, KH.HOTEN
ORDER BY COUNT(DISTINCT HD.SOHD) DESC
--41. Tháng mấy trong năm 2006, doanh số bán hàng cao nhất ?
--Cách 1:
SELECT TOP 1 MONTH(NGHD) AS THANG
FROM HOADON
WHERE YEAR(NGHD)=2006
GROUP BY MONTH(NGHD)
ORDER BY SUM(TRIGIA) DESC
--Cách 2:
SELECT THANG FROM (
	SELECT MONTH(NGHD) THANG, RANK() OVER (ORDER BY SUM(TRIGIA) DESC) RANK_TRIGIA FROM HOADON
	WHERE YEAR(NGHD) = '2006' 
	GROUP BY MONTH(NGHD)
) A
WHERE RANK_TRIGIA = 1
GO
--42. Tìm sản phẩm (MASP, TENSP) có tổng số lượng bán ra thấp nhất trong năm 2006.
--Cách 1:
SELECT TOP 1 SP.MASP, SP.TENSP
FROM SANPHAM SP JOIN CTHD
ON SP.MASP = CTHD.MASP 
JOIN HOADON HD 
ON HD.SOHD= CTHD.SOHD
WHERE YEAR(HD.NGHD)=2006
GROUP BY SP.MASP, SP.TENSP
ORDER BY SUM(CTHD.SL) ASC
--Cách 2:
SELECT A.MASP, TENSP FROM (
	SELECT MASP, RANK() OVER (ORDER BY SUM(SL)) RANK_SL
	FROM CTHD CT INNER JOIN HOADON HD
	ON CT.SOHD = HD.SOHD
	WHERE YEAR(NGHD) = '2006'
	GROUP BY MASP
) A INNER JOIN SANPHAM SP
ON A.MASP = SP.MASP
WHERE RANK_SL = 1
GO
--43. *Mỗi nước sản xuất, tìm sản phẩm (MASP,TENSP) có giá bán cao nhất.
--Cách 1:
SELECT DISTINCT NUOCSX, MASP, TENSP FROM (
SELECT DISTINCT NUOCSX, MASP, TENSP ,RANK() OVER (PARTITION BY NUOCSX ORDER BY GIA DESC) AS RANKGIA
FROM SANPHAM SP1) A
WHERE RANKGIA =1
ORDER BY  NUOCSX, MASP, TENSP DESC
--Cách 2:
SELECT DISTINCT NUOCSX, MASP, TENSP	FROM SANPHAM SP1
WHERE MASP IN ( SELECT TOP 1  SP2.MASP
				FROM SANPHAM SP2 
				WHERE SP2.NUOCSX= SP1.NUOCSX
				ORDER BY GIA DESC)
ORDER BY  NUOCSX, MASP, TENSP DESC
--44. Tìm nước sản xuất sản xuất ít nhất 3 sản phẩm có giá bán khác nhau.
SELECT NUOCSX FROM SANPHAM
GROUP BY NUOCSX
HAVING COUNT (DISTINCT GIA) >=3
--45. *Trong 10 khách hàng có doanh số cao nhất, tìm khách hàng có số lần mua hàng nhiều nhất.
SELECT TOP 1 KH.MAKH, KH.HOTEN
FROM (SELECT TOP 10 * FROM KHACHHANG
ORDER BY DOANHSO DESC) KH 
JOIN HOADON HD
ON KH.MAKH= HD.MAKH
GROUP BY KH.MAKH, KH.HOTEN
ORDER BY COUNT(DISTINCT HD.SOHD) DESC