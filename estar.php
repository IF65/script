<?php
    $db = "(DESCRIPTION=(ADDRESS_LIST = (ADDRESS = (PROTOCOL = TCP)(HOST = 10.11.14.82)(PORT = 1521)))(CONNECT_DATA=(SID=ESTR)))" ;

    if($c = oci_connect("ESTAR", "estar", $db))
    {
        echo "Successfully connected to Oracle.\n";
        OCILogoff($c);
    }
    else
    {
        $err = OCIError();
        echo "Connection failed." . $err[text];
    }
?>