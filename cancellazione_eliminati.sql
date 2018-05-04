use `archivi`;
delete b.* from `archivi`.`barartx2` as b inner join `archivi`.`articox2` as a on a.`COD-ART2`=b.`CODCIN-BAR2` where a.`DATELIM-ART2` <> '00000000';
