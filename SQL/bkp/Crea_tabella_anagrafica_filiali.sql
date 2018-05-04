DROP TABLE IF EXISTS TEMP.ANAGDAFIALL;

CREATE TABLE IF NOT EXISTS TEMP.ANAGDAFIALL(
             `ADF-DATA-RIFERIMENTO`   VARCHAR(8),
             `ADF-SONE`               VARCHAR(4),
             `ADF-CODCIN`             VARCHAR(7),
             `ADF-SEG-LIB-BLOC`       VARCHAR(1),
             `ADF-SEG-OS-DET`         VARCHAR(1),
             `ADF-DATA-FINE-OS`       VARCHAR(8),
             `ADF-PRENDI`             DECIMAL(2,0),
             `ADF-PAGHI`              DECIMAL(2,0),
             `ADF-VALORIPRENDI`       DECIMAL(9,2),
             `ADF-VALORIPAGHI`        DECIMAL(9,2),
             `ADF-PRZ-CATALOGO-NIMIS` DECIMAL(8,2),
             `ADF-PRZ-OS-DET-E`       DECIMAL(9,2),
             `ADF-TIPO-OS`            VARCHAR(2),
             `ADF-TIPOLOS`            VARCHAR(3),
             `ADF-SCPMXN`             DECIMAL(4,1),
             `ADF-SCVALMXN`           DECIMAL(9,2),
             `ADF-PUNTIAGG`           DECIMAL(4,0),
             `ADF-SEGNONIMISNXM`      VARCHAR(1),
             `ADF-SEGNO-BOLL`         VARCHAR(1),
             `ADF-N-BOLL`             DECIMAL(5,0),
             `ADF-SEG-ELIM`           VARCHAR(1), 
             `ADF-PRZ-VEND-DETT-E`    DECIMAL(9,2),
             `ADF-PRZ-VEND-LOC-E`     DECIMAL(9,2),
             `ADF-PRZ-LISTLOC`        DECIMAL(9,2));

ALTER TABLE TEMP.ANAGDAFIALL ADD PRIMARY KEY(`ADF-SONE`,`ADF-DATA-RIFERIMENTO`,`ADF-CODCIN`), ENGINE=MYISAM;