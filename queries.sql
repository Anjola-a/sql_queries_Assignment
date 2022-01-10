------------------------------------------------
--  Anjola Adewale 400255269
------------------------------------------------


connect to SE3DB3

------------------------------------------------
--  Question 1, 2 records
------------------------------------------------
SELECT o.FirstName, o.LastName, o.DateOfBirth
FROM Order o
WHERE (2021 - YEAR(o.DateOfBirth)) >= 18 
	AND o.Date = '7/22/2020' ;


------------------------------------------------
--  Question 2, 1910 records
------------------------------------------------

SELECT DISTINCT B.ProductID, PC.Name
FROM  ProductCategory PC, BelongsTo B
WHERE B.ProductCategoryID = PC.ProductCategoryID AND B.ProductID IN (SELECT ProductID
					   FROM OrderContains
					   WHERE OrderID IN (SELECT OrderID 
					   					 FROM Order o
										 WHERE 20 <=  (2021 - YEAR(o.DateOfBirth)) AND (2021 - YEAR(o.DateOfBirth)) <= 35 ));


------------------------------------------------
--  Question 3, 4 records
------------------------------------------------

SELECT p.FirstName, p.LastName, p.DateOfBirth, p.city, p.Country
FROM Person p, (SELECT FirstName, LastName, DateOfBirth
FROM WriteReview
GROUP BY FirstName, LastName, DateOfBirth
HAVING COUNT(comment) =
(SELECT MAX(c) FROM (
	SELECT  COUNT(Comment) as c
	FROM WriteReview
	GROUP BY FirstName, LastName, DateOfBirth))) AS temp
Where p.FirstName = temp.FirstName AND p.LastName = temp.LastName AND p.DateOfBirth = temp.DateOfBirth;


------------------------------------------------
--  Question 4a, 546
------------------------------------------------

SELECT COUNT(*)
FROM (SELECT TrackingNumber
FROM HasShipment
GROUP BY TrackingNumber
HAVING COUNT(OrderID) > 1);

------------------------------------------------
--  Question 4b, 33 records
------------------------------------------------


SELECT TrackingNumber
FROM  Order, Person p, HasShipment
WHERE Order.OrderID IN (SELECT OrderID 
FROM HasShipment
WHERE TrackingNumber IN 
(SELECT TrackingNumber
FROM HasShipment
GROUP BY TrackingNumber
HAVING COUNT(OrderID) > 1))
AND Order.FirstName = p.FirstName AND HasShipment.OrderID = Order.OrderID
AND p.LastName = Order.LastName AND p.DateOfBirth = Order.DateOfBirth AND p.PostalCode LIKE 'M%';

------------------------------------------------
--  Question 5, 344 records 
------------------------------------------------

SELECT b1.ProductID
FROM BelongsTo b1
WHERE NOT EXISTS( Select *
FROM BelongsTo b2
WHERE b2.ProductID = b1.ProductID AND
b2.ProductCategoryID <> b1.ProductCategoryID
);

------------------------------------------------
--  Question 6a, 5 records 
------------------------------------------------

SELECT p1.ProductID, p1.Name, p1.Brand
FROM Product p1
WHERE NOT EXISTS( Select *
FROM Product p2
WHERE p2.Brand = p1.Brand AND
p2.ProductID <> p1.ProductID);

------------------------------------------------
--  Question 6b, 1 records 
------------------------------------------------


SELECT OrderID
FROM OrderContains o2 , Product p2
WHERE o2.ProductID = p2.ProductID
GROUP BY OrderID
HAVING SUM(p2.Price * o2.Quantity) = 
(SELECT MAX(c) FROM (SELECT o.OrderID, SUM(P.Price * o.Quantity) as c
FROM OrderContains o, Product p
WHERE o.ProductID = p.ProductID
GROUP BY OrderID));

------------------------------------------------
--  Question 7, 10 records 
------------------------------------------------

SELECT p.StoreID, sum(Price * o.Quantity)
FROM Product p, OrderContains o
WHERE o.ProductId = p.ProductID AND p.ProductID in 
(SELECT c.ProductID
FROM OrderContains C, Order O
WHERE C.OrderID = O.OrderID AND YEAR(o.Date) = 2020 and MONTH(O.Date) = 7)
GROUP BY StoreID
ORDER BY sum(Price * o.Quantity) ASC;

------------------------------------------------
--  Question 8a,  10 records 
------------------------------------------------
SELECT ProductID, Name, Brand
FROM Product
Where ProductID NOT IN (SELECT ProductID
FROM OrderContains);

------------------------------------------------
--  Question 8b,  2 records 
------------------------------------------------
SELECT ProductID
FROM Product
Where ProductID NOT IN (SELECT ProductID
FROM OrderContains) and ProductID IN (
	SELECT ProductID
	FROM Promotion
);

------------------------------------------------
--  Question 9a,  3 records 
------------------------------------------------
------ if the product does not have a waranty, it's value would be null
--- When we add a value to null, it yeilds null

SELECT ProductCategoryID
FROM 
(SELECT ProductCategoryID, sum(WarrantyID) w
From BelongsTo FULL OUTER JOIN HasWarranty 
ON BelongsTo.ProductID = HasWarranty.ProductID
GROUP By ProductCategoryID)
Where w IS NOT null;

------------------------------------------------
--  Question 9b,  1 record
------------------------------------------------

SELECT DISTINCT P.StoreID as StoreID
FROM Product P, BelongsTo B,
	(Select temp2.PCID as PCID2
	FROM Product p, 
		(SELECT temp.ProductCategoryID as PCID, BelongsTo.ProductID as PID
		FROM 
			(SELECT ProductCategoryID, sum(WarrantyID) w
			From BelongsTo FULL OUTER JOIN HasWarranty 
			ON BelongsTo.ProductID = HasWarranty.ProductID
			GROUP By ProductCategoryID) temp, BelongsTo
		Where temp.w IS NOT null 
		AND BelongsTo.ProductCategoryID = temp.ProductCategoryID) temp2
	WHERE p.ProductID = temp2.PID
	GROUP BY temp2.PCID
	HAVING count(DISTINCT p.StoreID) = 1) temp3
Where temp3.PCID2 = B.ProductCategoryID
AND B.ProductID = P.ProductID;

------------------------------------------------
--  Question 10a,  155 records  
------------------------------------------------

SELECT P.ProductID, P.Name, P.ModelNumber
FROM Product p, 
	(SELECT BelongsTo.ProductCategoryID as PCID, temp.ProductID as PID, temp.RN as avgrating
	FROM BelongsTo RIGHT OUTER JOIN
		(SELECT ProductID, avg(star) as RN
		FROM WriteReview
		GROUP BY ProductID) temp
	ON BelongsTo.ProductID = temp.ProductID) temp2
WHERE p.ProductID = temp2.PID and temp2.avgrating >
ALL (SELECT AVG(W.star) 
FROM WriteReview W, BelongsTo B
WHERE W.ProductID = B.ProductId AND B.ProductCategoryID
in (SELECT ProductCategoryID
FROM BelongsTo
WHERE ProductCategoryID = temp2.PCID)
GROUP BY B.ProductCategoryID);

------------------------------------------------
--  Question 10b,  155 records  
------------------------------------------------


SELECT O.ProductID,  sum(temp5.pr * O.Quantity)
FROM OrderContains O, (SELECT P.ProductID, P.price as pr
FROM Product p, 
	(SELECT BelongsTo.ProductCategoryID as PCID, temp.ProductID as PID, temp.RN as avgrating
	FROM BelongsTo RIGHT OUTER JOIN
		(SELECT ProductID, avg(star) as RN
		FROM WriteReview
		GROUP BY ProductID) temp
	ON BelongsTo.ProductID = temp.ProductID) temp2
WHERE p.ProductID = temp2.PID and temp2.avgrating >
ALL (SELECT AVG(W.star) 
FROM WriteReview W, BelongsTo B
WHERE W.ProductID = B.ProductId AND B.ProductCategoryID
in (SELECT ProductCategoryID
FROM BelongsTo
WHERE ProductCategoryID = temp2.PCID)
GROUP BY B.ProductCategoryID)) temp5
Where O.ProductID = temp5.ProductID
GROUP BY O.ProductID
ORDER BY sum(temp5.pr * O.Quantity) DESC;