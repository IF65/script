<?php
	namespace Database;

	if ( ! isset( $sqlDetails ) ) {
		include( __DIR__.'/Config.php' );
	}

	//
	// Auto-loader
	// Fare attenzione: si parte dalla cartella Database quindi attenzione ai livelli!!!
	spl_autoload_register( function ($class) {
		$a = explode("\\", $class);

		if ($a[0] != 'Database') {
			return;
		}

		if ( count( $a ) === 2 ) {
			require( __DIR__.'/'.$a[1].'.php' );
		} else if ( count( $a ) === 3 ) {
			// per tener conto di eventuali subnamespace (regex ovvia quindi inutile spiegare altro)
			preg_match_all( "/[A-Z]+[^A-Z]*/", $a[2], $matches );
			$location = implode( '/', $matches[0] );

			require( __DIR__.'/'.$a[1].'/'.$location.'.php' );
		} else {
			return;
		}
	} );

?>

