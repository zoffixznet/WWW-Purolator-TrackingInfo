use Test::More tests => 4;

BEGIN {
    use_ok('LWP::UserAgent');
    use_ok('HTML::TableExtract');
    use_ok('Class::Data::Accessor');
	use_ok( 'WWW::Purolator::TrackingInfo' );
}

diag( "Testing WWW::Purolator::TrackingInfo $WWW::Purolator::TrackingInfo::VERSION, Perl $], $^X" );
