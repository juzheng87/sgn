

package SGN::Controller::AJAX::Search::Cross;

use Moose;
use Data::Dumper;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON', 'text/html' => 'JSON' },
   );

sub search_male_parents :Path('/ajax/search/cross/male_parents') :Args(0) { 
    my $self = shift;
    my $c = shift;
    my $female_parent_uniquename = $c->req->param("female_parent_name");

    my $schema = $c->dbic_schema("Bio::Chado::Schema");
    my $male_parent_reltype = $c->model("Cvterm")->get_cvterm_row($schema, "male_parent", "stock_relationship");
    my $female_parent_reltype = $c->model("Cvterm")->get_cvterm_row($schema, "female_parent", "stock_relationship");

    my $female_parent_rs = $schema->resultset("Stock::Stock")->search( { uniquename => $female_parent_uniquename });

    if ($female_parent_rs->count == 0) { 
	$c->stash->{rest} = { error => "Female parent does not exit" };
	return;
    }

    my $female_parent_id = $female_parent_rs->first()->stock_id();

    my $q = "SELECT distinct(male_parent.stock_id), male_parent.uniquename FROM stock as female_parent join stock_relationship as mother_children on(female_parent.stock_id=mother_children.subject_id) join stock as children on(mother_children.object_id = children.stock_id) join stock_relationship as father_children on (father_children.object_id = children.stock_id) join stock as male_parent  on (male_parent.stock_id=father_children.subject_id) WHERE mother_children.type_id=? and father_children.type_id=? AND female_parent.uniquename = ?";

    print STDERR $q." ".$female_parent_reltype->cvterm_id().", ".$male_parent_reltype->cvterm_id().", ".$female_parent_uniquename."\n";

    my $h = $c->dbc->dbh()->prepare($q);
    $h->execute($female_parent_reltype->cvterm_id(), $male_parent_reltype->cvterm_id(), $female_parent_uniquename);
    my @male_parents;
    while (my ($id, $uniquename) = $h->fetchrow_array()) { 
	push @male_parents, [ $id, $uniquename ];
    }

    $c->stash->{rest} = { 
	female_parent => [ $female_parent_id, $female_parent_uniquename ],
	male_parents => \@male_parents,
    };

}

sub search :Path('/ajax/search/cross/datatable') Args(0) { 
    my $self = shift;
    my $c = shift;

    my $female_parent_id = $c->req->param("female_parent_id");
    my $male_parent_id = $c->req->param("male_parent_id");
    my $breeding_program = $c->req->param("breeding_program");
    my $year = $c->req->param("year");

    my $schema = $c->dbic_schema("Bio::Chado::Schema");
    my $male_parent_reltype = $c->model("Cvterm")
	->get_cvterm_row($schema, "male_parent", "stock_relationship")->cvterm_id();
    my $female_parent_reltype = $c->model("Cvterm")
	->get_cvterm_row($schema, "female_parent", "stock_relationship")->cvterm_id();
    my $cross_name_type_id = $c->model("Cvterm")
	->get_cvterm_row($schema, "cross_name", "stock_relationship")->cvterm_id();

    my $dbh = $schema->storage->dbh();

    my $q = "SELECT stock_id, name, uniquename, nd_experimentprop.nd_experiment_id, nd_experimentprop.value FROM stock JOIN nd_experiment_stock USING (stock_id) JOIN nd_experimentprop USING(nd_experiment_id) JOIN stock_relationship AS female_parent_rel ON (stock.stock_id=female_parent_rel.subject_id) LEFT JOIN stock_relationship AS male_parent_rel ON (stock.stock_id=male_parent_rel.subject_id) WHERE female_parent_rel.type_id=? AND male_parent_rel.type_id=? AND female_parent_rel.object_id=? and male_parent_rel.object_id=? AND nd_experimentprop.type_id=?";

    my $h = $dbh->prepare($q);
    $h->execute($female_parent_reltype, $male_parent_reltype, $female_parent_id, $male_parent_id, $cross_name_type_id);
    
    my @cross_info = ();
    while (my ($stock_id, $name, $uniquename, $cross_nd_experiment_id, $cross_name) = $h->fetchrow_array()) { 
	push @cross_info, [ $stock_id, $uniquename, $cross_nd_experiment_id, $cross_name ]

    }
}




1;
