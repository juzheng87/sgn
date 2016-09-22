#!/usr/bin/env perl


=head1 NAME

 MovePhenotypesToLinkingTable.pm 

=head1 SYNOPSIS

mx-run MovePhenotypesToLinkingTable [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This patch copies the data in phenotype to the phenotype_cvterm linking talble to support postcomposing terms.

This subclass uses L<Moose>. The parent class uses L<MooseX::Runnable>

=head1 AUTHOR

 Naama Menda <nm249@cornell.edu>
 Lukas Mueller <lam87@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package  MovePhenotypesToLinkingTable;

use Moose;
extends 'CXGN::Metadata::Dbpatch';

has '+description' => ( default => <<'' );
Description of this patch goes here

has '+prereq' => (
    default => sub {
        [],
    },
  );

sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    print STDOUT "\nCopying the phenotype info to phenotype_cvterm... (this may take a while...)\n";

    $self->dbh->do(<<EOSQL);
--do your SQL here
--

INSERT INTO phenotype_cvterm (phenotype_id, cvterm_id) SELECT phenotype_id, cvalue_id FROM phenotype order by phenotype_id;

EOSQL

print "You're done!\n";
}


####
1; #
####
