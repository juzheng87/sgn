
package CXGN::BreedersToolbox::Accessions;

=head1 NAME

CXGN::BreedersToolbox::Accessions - functions for managing accessions

=head1 USAGE

 my $accession_manager = CXGN::BreedersToolbox::Accessons->new(schema=>$schema);

=head1 DESCRIPTION


=head1 AUTHORS

 Jeremy D. Edwards (jde22@cornell.edu)

=cut

use strict;
use warnings;
use Moose;
use SGN::Model::Cvterm;

has 'schema' => ( isa => 'Bio::Chado::Schema',
                  is => 'rw');

sub get_all_accessions { 
    my $self = shift;
    my $schema = $self->schema();

    my $accession_cvterm = SGN::Model::Cvterm->get_cvterm_row($schema, 'accession', 'stock_type');
    
    my $rs = $self->schema->resultset('Stock::Stock')->search({type_id => $accession_cvterm->cvterm_id});
    #my $rs = $self->schema->resultset('Stock::Stock')->search( { 'projectprops.type_id'=>$breeding_program_cvterm_id }, { join => 'projectprops' }  );
    my @accessions = ();



    while (my $row = $rs->next()) { 
	push @accessions, [ $row->stock_id, $row->name, $row->description ];
    }

    return \@accessions;
}

sub get_all_populations { 
    my $self = shift;
    my $schema = $self->schema();

    my $accession_cvterm = SGN::Model::Cvterm->get_cvterm_row($schema, 'accession','stock_type');

    my $population_cvterm = SGN::Model::Cvterm->get_cvterm_row($schema, 'population', 'stock_type');

    my $population_member_cvterm = SGN::Model::Cvterm->get_cvterm_row($schema, 'member_of', 'stock_relationship');
    
    my $populations_rs = $schema->resultset("Stock::Stock")->search({'type_id' => $population_cvterm->cvterm_id()});

    my @accessions_by_population;

    while (my $population_row = $populations_rs->next()) {
	my %population_info;
	$population_info{'name'}=$population_row->name();
	$population_info{'description'}=$population_row->description();
	$population_info{'stock_id'}=$population_row->stock_id();

	my $population_members = $schema->resultset("Stock::Stock") 
	    ->search({
		'object.stock_id'=> $population_row->stock_id(),
		'stock_relationship_subjects.type_id' => $population_member_cvterm->cvterm_id()
		     }, {join => {'stock_relationship_subjects' => 'object'}, order_by => { -asc => 'stock_id'}});

	my @accessions_in_population;
	while (my $population_member_row = $population_members->next()) {
	    my %accession_info;
	    $accession_info{'name'}=$population_member_row->name();
	    $accession_info{'description'}=$population_member_row->description();
	    $accession_info{'stock_id'}=$population_member_row->stock_id();
	    my $synonyms_rs;
	    $synonyms_rs = $population_member_row->search_related('stockprops', {'type.name' => {ilike => '%synonym%' } }, { join => 'type' });
	    my @synonyms;
	    if ($synonyms_rs) {
		while (my $synonym_row = $synonyms_rs->next()) {
		    push @synonyms, $synonym_row->value();
		}
	    }
	    $accession_info{'synonyms'}=\@synonyms;
	    push @accessions_in_population, \%accession_info;
	}
	$population_info{'members'}=\@accessions_in_population;
	push @accessions_by_population, \%population_info;
    }

    return \@accessions_by_population;
}

1;
