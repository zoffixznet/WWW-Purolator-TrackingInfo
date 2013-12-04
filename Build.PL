use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'WWW::Purolator::TrackingInfo',
    license             => 'perl',
    dist_author         => q|'Zoffix <'zoffix@cpan.org'>|,
    dist_version_from   => 'lib/WWW/Purolator/TrackingInfo.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'LWP::UserAgent'        => 5.822,
        'HTML::TableExtract'    => 2.10,
        'Class::Data::Accessor' => 0.04004,
    },
    add_to_cleanup      => [ 'WWW-Purolator-TrackingInfo-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
