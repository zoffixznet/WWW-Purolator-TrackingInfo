package WWW::Purolator::TrackingInfo;

use warnings;
use strict;

our $VERSION = '0.0101';
use LWP::UserAgent;
use HTML::TableExtract;
use base 'Class::Data::Accessor';
__PACKAGE__->mk_classaccessors qw/
    error
    info
    ua
/;

sub new {
    my $class = shift;
    my %options = @_;
    my $self = bless {}, $class;
    
    $self->ua(
          $options{ua}
        ? $options{ua}
        : LWP::UserAgent->new( agent => 'Opera 9.5', timeout => 30 ),
    );

    return $self;
}

sub track {
    my ( $self, $pin ) = @_;
    
    $self->$_(undef) for qw/error info/;

    my $res = $self->ua->get(
        'https://eshiponline.purolator.com/ShipOnline/Public/Track'
        . '/TrackingDetails.aspx?pup=Y&pin=' . $pin
    );
    
    unless ( $res->is_success ) {
        $self->error('Network error: ' . $res->status_line);
        return;
    }
    
    return $self->_parse( $pin, $res->decoded_content );
}

sub _parse {
    my ( $self, $pin, $content ) = @_;

    my %info = ( pin => $pin );
    
    ( $info{html} ) = $content =~ m|<div id="detailTable">(.+?)</div>|s;

    my $te = HTML::TableExtract->new(
        headers => [
            'Scan Date',
            'Scan Time',
            qw/Status Comment/,
        ],
    );
    $te->parse( $content );

    my ( $ts ) = $te->tables;
    
    if ( $ts ) {
        my @details;
        for my $row ( $ts->rows ) {
            if ( defined $row->[2] and $row->[2] =~ /\bDelivered\b/ ) {
                $info{is_delivered} = 1;
            }
            
            push @details, {
                scan_date   => $row->[0],
                scan_time   => $row->[1],
                status      => $row->[2],
                comment     => $row->[3],
            };
        }
        
        $info{details} = \@details;
    }
    else {
        $self->error('Error: invalid PIN or data is not available');
        return;
    }
    
    return $self->info( \%info );
}

1;
__END__

=head1 NAME

WWW::Purolator::TrackingInfo - access Purolator's tracking information

=head1 SYNOPSIS

    use strict;
    use warnings;
    use WWW::Purolator::TrackingInfo;

    my $t = WWW::Purolator::TrackingInfo->new;

    my $info = $t->track('AJT1395053')
        or die "Error: " . $t->error;

    use Data::Dumper;
    print Dumper $info;

=head1 DESCRIPTION

This module probably does not provide fully blown functionality and is 
rather simple; it does only what I needed it to do for my project, contact
me if you need more functionality.

The module accesses http://purolator.com/ and gets tracking information
for the package from the given PIN (e.g. AJT1395053)

=head1 CONSTRUCTOR

    my $t = WWW::Purolator::TrackingInfo->new;

    my $t = WWW::Purolator::TrackingInfo->new(
        ua => LWP::UserAgent->new( agent => 'Opera 9.5', timeout => 30 ),
    );

Creates and returns a new C<WWW::Purolator::TrackingInfo> object. Takes
the following arguments:__PACKAGE__->mk_classaccessors qw/
    error
    info
    ua

=head2 C<ua>

    my $t = WWW::Purolator::TrackingInfo->new(
        ua => LWP::UserAgent->new( agent => 'Opera 9.5', timeout => 30 ),
    );

B<Optional>. Specifies an L<LWP::UserAgent>-like object to use for accessing
Purolator's site. B<Note:> since Purolator uses HTTPS, you'll most likely
need to install L<Crypt::SSLeay> or something along those lines.
Technically, this object can be anything that has a C<get()> method
that functions exactly the same as the one present in L<LWP::UserAgent>.
B<Defaults to:>

    LWP::UserAgent->new( agent => 'Opera 9.5', timeout => 30 )

=head1 METHODS/ACCESSORS

=head2 C<track>

    my $info = $t->track('AJT1399063')
        or die $t->error;

Instructs the object to obtain transit information from Purolator using
a PIN. Currently takes one mandatory argument: Purolator's PIN for
the package. B<On failure> (e.g. network error, or invalid PIN was
specified) returns either C<undef> or an empty list depending on the
context and the reason for failure will be available via C<error()> method.
B<On success> returns a hashref with the following keys/values (explained 
below this dump):

    $VAR1 = {
    'pin' => 'AJT1399063',
    'is_delivered' => 1,
    'html' => '
        <table>
        <thead class="TableHeader">
            <tr>
                <td id="date">Scan Date</td>
                <td id="time">Scan Time</td>
                <td id="status">Status</td>
                <td id="comment">Comment</td>
            </tr>
        </thead>
        <tbody class="TableData2">
            
            <tr><td>2009/09/16</td><td>10:23</td><td>Delivered to JODY at RECEPTION of ARTHUR BOOKS at 192 WELLINGTON ST. EAST P6A2L0 via SAULT STE. MARIE, ON depot</td><td></td></tr>
            
            <tr><td>2009/09/16</td><td>09:45</td><td>On vehicle for delivery via SAULT STE. MARIE, ON depot</td><td></td></tr>
            
            <tr><td>2009/09/15</td><td>16:45</td><td>Picked up by Purolator via TORONTO SORT CTR/CTR TRIE, ON depot</td><td></td></tr>
            
        </tbody>
        </table>
        ',
    'details' => [
             {
               'comment' => undef,
               'status' => 'Delivered to JODY at RECEPTION of ARTHUR BOOKS at 192 WELLINGTON ST. EAST P6A2L0 via SAULT STE. MARIE, ON depot',
               'scan_time' => '10:23',
               'scan_date' => '2009/09/16'
             },
             {
               'comment' => undef,
               'status' => 'On vehicle for delivery via SAULT STE. MARIE, ON depot',
               'scan_time' => '09:45',
               'scan_date' => '2009/09/16'
             },
             {
               'comment' => undef,
               'status' => 'Picked up by Purolator via TORONTO SORT CTR/CTR TRIE, ON depot',
               'scan_time' => '16:45',
               'scan_date' => '2009/09/15'
             },
           ]
        };

=head3 C<pin>

    print "This tracking info is for PIN: " . $t->info->{pin};

=head3 C<is_delivered>

    $t->info->{is_delivered}
        and print "Package was delivered!";

If the package was delivered, then C<is_delivered> key will be present
and set to value C<1>.

=head3 C<html>

    print $t->info->{html};

The C<html> key will contain raw HTML of the tracking information table
as it was displayed on Purolator's page; useful for displaying the info
in a Web app.

=head3 C<details>

    $t->info->{is_delivered}
        and print $t->info->{details}[0]{status};

The C<details> key will contain an arrayref of hashrefs. Each of those
hashrefs represents a line of tracking info (i.e. the row in the 
Purolator's tracking table). There are four keys in each of those 
hashrefs:

=head4 C<scan_date>

    'scan_date' => '2009/09/10'

Specifies the date of the scan for the current entry. The format is the
same as is displayed on Purolator's site.

=head4 C<scan_time>

    'scan_time' => '17:52',

Specifies the time of the scan for the current entry. The format is the
same as is displayed on Purolator's site.

=head4 C<status>

    'status' => 'Shipment In Transit via TORONTO SORT CTR/CTR TRIE, ON depot',

Specifies the status of the package when the current entry was added.

=head4 C<comment>

    'comment' => undef,

I never actually seen any comments there, but there is a column named
"Comment" on Purolator's tracking table, so here it is. I assume these
are for special comments in case of some trouble.

=head2 C<info>

    my $last_track_info = $t->info;

Takes no arguments returns the same value last call to C<track()> method
returned. See C<track()> method's description above for details.

=head2 C<error>

    $t->track('AJT1399063')
        or die $t->error;

Takes no arguments. Returns a human readable reason for why 
C<track()> method failed (if it did, of course).

=head2 C<ua>

    my $current_ua = $t->ua;
    
    $t->ua(
        LWP::UserAgent->new( agent => 'Opera 9.5', timeout => 30 )
    );

Returns currently used L<LWP::UserAgent>-like object (see C<ua>
constructor's argument). Takes one I<optional> argument that is
the new object to use.

=head1 AUTHOR

'Zoffix, C<< <'zoffix at cpan.org'> >>
(L<http://haslayout.net/>, L<http://zoffix.com/>, L<http://zofdesign.com/>)

=head1 BUGS

Please report any bugs or feature requests to C<bug-www-purolator-trackinginfo at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Purolator-TrackingInfo>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Purolator::TrackingInfo

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker
 LWP::UserAgent->new( agent => 'Opera 9.5', timeout => 30 )
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Purolator-TrackingInfo>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Purolator-TrackingInfo>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Purolator-TrackingInfo>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Purolator-TrackingInfo/>

=back



=head1 COPYRIGHT & LICENSE

Copyright 2009 'Zoffix, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

