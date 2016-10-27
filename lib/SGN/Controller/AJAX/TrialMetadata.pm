
package SGN::Controller::AJAX::TrialMetadata;

use Moose;
use Data::Dumper;
use List::Util 'max';
use Bio::Chado::Schema;
use List::Util qw | any |;
use CXGN::Trial;
use Math::Round::Var;
use List::MoreUtils qw(uniq);


BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON', 'text/html' => 'JSON' },
   );

has 'schema' => (
		 is       => 'rw',
		 isa      => 'DBIx::Class::Schema',
		 lazy_build => 1,
		);


sub trial : Chained('/') PathPart('ajax/breeders/trial') CaptureArgs(1) {
    my $self = shift;
    my $c = shift;
    my $trial_id = shift;

    $c->stash->{trial_id} = $trial_id;
    $c->stash->{schema} =  $c->dbic_schema("Bio::Chado::Schema");
    $c->stash->{trial} = CXGN::Trial->new( { bcs_schema => $c->stash->{schema}, trial_id => $trial_id });

    if (!$c->stash->{trial}) {
	$c->stash->{rest} = { error => "The specified trial with id $trial_id does not exist" };
	return;
    }

}

=head2 delete_trial_by_file

 Usage:
 Desc:
 Ret:
 Args:
 Side Effects:
 Example:

=cut

sub delete_trial_data : Local() ActionClass('REST');

sub delete_trial_data_GET : Chained('trial') PathPart('delete') Args(1) {
    my $self = shift;
    my $c = shift;
    my $datatype = shift;

    if ($self->delete_privileges_denied($c)) {
	$c->stash->{rest} = { error => "You have insufficient access privileges to delete trial data." };
	return;
    }

    my $error = "";

    if ($datatype eq 'phenotypes') {
	$error = $c->stash->{trial}->delete_phenotype_metadata($c->dbic_schema("CXGN::Metadata::Schema"), $c->dbic_schema("CXGN::Phenome::Schema"));
	$error .= $c->stash->{trial}->delete_phenotype_data();
    }

    elsif ($datatype eq 'layout') {
	$error = $c->stash->{trial}->delete_metadata($c->dbic_schema("CXGN::Metadata::Schema"), $c->dbic_schema("CXGN::Phenome::Schema"));
	$error = $c->stash->{trial}->delete_field_layout();
    }
    elsif ($datatype eq 'entry') {
	$error = $c->stash->{trial}->delete_project_entry();
    }
    else {
	$c->stash->{rest} = { error => "unknown delete action for $datatype" };
	return;
    }
    if ($error) {
	$c->stash->{rest} = { error => $error };
	return;
    }
    $c->stash->{rest} = { message => "Successfully deleted trial data.", success => 1 };
}

sub trial_details : Chained('trial') PathPart('details') Args(0) ActionClass('REST') {};

sub trial_details_GET   {
    my $self = shift;
    my $c = shift;

    my $trial = $c->stash->{trial};

    $c->stash->{rest} = { details => $trial->get_details() };

}

sub trial_details_POST  {
    my $self = shift;
    my $c = shift;

    my @categories = $c->req->param("categories[]");

    my $details = {};
    foreach my $category (@categories) {
      $details->{$category} = $c->req->param("details[$category]");
    }

    if (!%{$details}) {
      $c->stash->{rest} = { error => "No values were edited, so no changes could be made for this trial's details." };
      return;
    }
    else {
    print STDERR "Here are the deets: " . Dumper($details) . "\n";
    }

    if (!($c->user()->check_roles('curator') || $c->user()->check_roles('submitter'))) {
	    $c->stash->{rest} = { error => 'You do not have the required privileges to edit the trial details of this trial.' };
	    return;
    }

    my $trial_id = $c->stash->{trial_id};
    my $trial = $c->stash->{trial};
    my $program_object = CXGN::BreedersToolbox::Projects->new( { schema => $c->stash->{schema} });
    my $breeding_program = $program_object->get_breeding_programs_by_trial($trial_id);

    if (! ($c->user() &&  ($c->user->check_roles("curator") || $c->user->check_roles($breeding_program)))) {
	    $c->stash->{rest} = { error => "You need to be logged in with sufficient privileges to change the details of this trial." };
	    return;
    }

    # set each new detail that is defined
    eval {
      if ($details->{name}) { $trial->set_name($details->{name}); }
      if ($details->{breeding_program}) { $trial->set_breeding_program($details->{breeding_program}); }
      if ($details->{location}) { $trial->set_location($details->{location}); }
      if ($details->{year}) { $trial->set_year($details->{year}); }
      if ($details->{type}) { $trial->set_project_type($details->{type}); }
      if ($details->{planting_date}) {
        if ($details->{planting_date} eq 'remove') { $trial->remove_planting_date($trial->get_planting_date()); }
        else { $trial->set_planting_date($details->{planting_date}); }
      }
      if ($details->{harvest_date}) {
        if ($details->{harvest_date} eq 'remove') { $trial->remove_harvest_date($trial->get_harvest_date()); }
        else { $trial->set_harvest_date($details->{harvest_date}); }
      }
      if ($details->{description}) { $trial->set_description($details->{description}); }
    };

    if ($@) {
	    $c->stash->{rest} = { error => "An error occurred setting the new trial details: $@" };
    }
    else {
	    $c->stash->{rest} = { success => 1 };
    }
}

sub traits_assayed : Chained('trial') PathPart('traits_assayed') Args(0) {
    my $self = shift;
    my $c = shift;
    my $stock_type = $c->req->param('stock_type');

    my @traits_assayed  = $c->stash->{trial}->get_traits_assayed($stock_type);
    $c->stash->{rest} = { traits_assayed => \@traits_assayed };
}


sub phenotype_summary : Chained('trial') PathPart('phenotypes') Args(0) {
    my $self = shift;
    my $c = shift;

    my $schema = $c->stash->{schema};
    my $round = Math::Round::Var->new(0.01);
    my $dbh = $c->dbc->dbh();
    my $trial_id = $c->stash->{trial_id};
    my $display = $c->req->param('display');
    my $select_clause_additional = '';
    my $group_by_additional = '';
    my $stock_type_id;
    my $rel_type_id;
    if ($display eq 'plots') {
        $stock_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plot', 'stock_type')->cvterm_id();
        $rel_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plot_of', 'stock_relationship')->cvterm_id();
    }
    if ($display eq 'plants') {
        $stock_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plant', 'stock_type')->cvterm_id();
        $rel_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plant_of', 'stock_relationship')->cvterm_id();
    }
    if ($display eq 'plots_accession') {
        $stock_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plot', 'stock_type')->cvterm_id();
        $rel_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plot_of', 'stock_relationship')->cvterm_id();
        $select_clause_additional = ', accession.uniquename, accession.stock_id';
        $group_by_additional = ', accession.stock_id, accession.uniquename';
    }
    if ($display eq 'plants_accession') {
        $stock_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plant', 'stock_type')->cvterm_id();
        $rel_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plant_of', 'stock_relationship')->cvterm_id();
        $select_clause_additional = ', accession.uniquename, accession.stock_id';
        $group_by_additional = ', accession.stock_id, accession.uniquename';
    }
    my $accesion_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'accession', 'stock_type')->cvterm_id();

    my $h = $dbh->prepare("SELECT (((cvterm.name::text || '|'::text) || db.name::text) || ':'::text) || dbxref.accession::text AS trait,
        cvterm.cvterm_id,
        count(phenotype.value),
        to_char(avg(phenotype.value::real), 'FM999990.990'),
        to_char(max(phenotype.value::real), 'FM999990.990'),
        to_char(min(phenotype.value::real), 'FM999990.990'),
        to_char(stddev(phenotype.value::real), 'FM999990.990')
        $select_clause_additional
        FROM cvterm
            JOIN phenotype ON (cvterm_id=cvalue_id)
            JOIN nd_experiment_phenotype USING(phenotype_id)
            JOIN nd_experiment_project USING(nd_experiment_id)
            JOIN nd_experiment_stock USING(nd_experiment_id)
            JOIN stock as plot USING(stock_id)
            JOIN stock_relationship on (plot.stock_id = stock_relationship.subject_id)
            JOIN stock as accession on (accession.stock_id = stock_relationship.object_id)
            JOIN dbxref ON cvterm.dbxref_id = dbxref.dbxref_id JOIN db ON dbxref.db_id = db.db_id
        WHERE project_id=?
            AND phenotype.value~?
            AND stock_relationship.type_id=?
            AND plot.type_id=?
            AND accession.type_id=?
        GROUP BY (((cvterm.name::text || '|'::text) || db.name::text) || ':'::text) || dbxref.accession::text, cvterm.cvterm_id $group_by_additional;");

    my $numeric_regex = '^[0-9]+([,.][0-9]+)?$';
    $h->execute($c->stash->{trial_id}, $numeric_regex, $rel_type_id, $stock_type_id, $accesion_type_id);

    my @phenotype_data;

    while (my ($trait, $trait_id, $count, $average, $max, $min, $stddev, $stock_name, $stock_id) = $h->fetchrow_array()) {

        my $cv = 0;
        if ($stddev && $average != 0) {
            $cv = ($stddev /  $average) * 100;
            $cv = $round->round($cv) . '%';
        }
        if ($average) { $average = $round->round($average); }
        if ($min) { $min = $round->round($min); }
        if ($max) { $max = $round->round($max); }
        if ($stddev) { $stddev = $round->round($stddev); }

        my @return_array;
        if ($stock_name && $stock_id) {
            push @return_array, qq{<a href="/stock/$stock_id/view">$stock_name</a>};
        }
        push @return_array, ( qq{<a href="/cvterm/$trait_id/view">$trait</a>}, $average, $min, $max, $stddev, $cv, $count, qq{<a href="#raw_data_histogram_well" onclick="trait_summary_hist_change($trait_id)"><span class="glyphicon glyphicon-stats"></span></a>} );
        push @phenotype_data, \@return_array;
    }

    $c->stash->{rest} = { data => \@phenotype_data };
}

sub trait_histogram : Chained('trial') PathPart('trait_histogram') Args(1) {
    my $self = shift;
    my $c = shift;
    my $trait_id = shift;

    my @data = $c->stash->{trial}->get_phenotypes_for_trait($trait_id, 'plot');

    $c->stash->{rest} = { data => \@data };
}

sub get_trial_folder :Chained('trial') PathPart('folder') Args(0) {
    my $self = shift;
    my $c = shift;

    if (!($c->user()->check_roles('curator') || $c->user()->check_roles('submitter'))) {
	$c->stash->{rest} = { error => 'You do not have the required privileges to edit the trial type of this trial.' };
	return;
    }

    my $project_parent = $c->stash->{trial}->get_folder();

    $c->stash->{rest} = { folder => [ $project_parent->project_id(), $project_parent->name() ] };

}

sub trial_accessions : Chained('trial') PathPart('accessions') Args(0) {
    my $self = shift;
    my $c = shift;
    my $schema = $c->dbic_schema("Bio::Chado::Schema");

    my $trial = CXGN::Trial->new( { bcs_schema => $schema, trial_id => $c->stash->{trial_id} });

    my @data = $trial->get_accessions();

    $c->stash->{rest} = { accessions => \@data };
}

sub trial_controls : Chained('trial') PathPart('controls') Args(0) {
    my $self = shift;
    my $c = shift;
    my $schema = $c->dbic_schema("Bio::Chado::Schema");

    my $trial = CXGN::Trial->new( { bcs_schema => $schema, trial_id => $c->stash->{trial_id} });

    my @data = $trial->get_controls();

    $c->stash->{rest} = { accessions => \@data };
}

sub trial_plots : Chained('trial') PathPart('plots') Args(0) {
    my $self = shift;
    my $c = shift;
    my $schema = $c->dbic_schema("Bio::Chado::Schema");

    my $trial = CXGN::Trial->new( { bcs_schema => $schema, trial_id => $c->stash->{trial_id} });

    my @data = $trial->get_plots();

    $c->stash->{rest} = { plots => \@data };
}

sub trial_plants : Chained('trial') PathPart('plants') Args(0) {
    my $self = shift;
    my $c = shift;
    my $schema = $c->dbic_schema("Bio::Chado::Schema");

    my $trial = CXGN::Trial->new( { bcs_schema => $schema, trial_id => $c->stash->{trial_id} });

    my @data = $trial->get_plants();

    $c->stash->{rest} = { plants => \@data };
}

sub trial_design : Chained('trial') PathPart('design') Args(0) {
    my $self = shift;
    my $c = shift;
    my $schema = $c->dbic_schema("Bio::Chado::Schema");

    my $layout = CXGN::Trial::TrialLayout->new({ schema => $schema, trial_id =>$c->stash->{trial_id} });

    my $design = $layout->get_design();
    my $design_type = $layout->get_design_type();
    my $plot_dimensions = $layout->get_plot_dimensions();

    my $plot_length = '';
    if ($plot_dimensions->[0]) {
	$plot_length = $plot_dimensions->[0];
    }

    my $plot_width = '';
    if ($plot_dimensions->[1]){
	$plot_width = $plot_dimensions->[1];
    }

    my $plants_per_plot = '';
    if ($plot_dimensions->[2]){
	$plants_per_plot = $plot_dimensions->[2];
    }

    my $block_numbers = $layout->get_block_numbers();
    my $number_of_blocks = '';
    if ($block_numbers) {
      $number_of_blocks = scalar(@{$block_numbers});
    }

    my $replicate_numbers = $layout->get_replicate_numbers();
    my $number_of_replicates = '';
    if ($replicate_numbers) {
      $number_of_replicates = scalar(@{$replicate_numbers});
    }

    $c->stash->{rest} = { design_type => $design_type, num_blocks => $number_of_blocks, num_reps => $number_of_replicates, plot_length => $plot_length, plot_width => $plot_width, plants_per_plot => $plants_per_plot, design => $design };
}

sub get_spatial_layout : Chained('trial') PathPart('coords') Args(0) {

    my $self = shift;
    my $c = shift;
    my $schema = $c->dbic_schema("Bio::Chado::Schema");

    my $layout = CXGN::Trial::TrialLayout->new(
	{
	    schema => $schema,
	    trial_id =>$c->stash->{trial_id}
	});

    my $design = $layout-> get_design();

  #  print STDERR Dumper($design);

    my @layout_info;
    foreach my $plot_number (keys %{$design}) {
	push @layout_info, {
			plot_id => $design->{$plot_number}->{plot_id},
			plot_number => $plot_number,
			row_number => $design->{$plot_number}->{row_number},
			col_number => $design->{$plot_number}->{col_number},
			block_number=> $design->{$plot_number}-> {block_number},
			rep_number =>  $design->{$plot_number}-> {rep_number},
			plot_name => $design->{$plot_number}-> {plot_name},
			accession_name => $design->{$plot_number}-> {accession_name},
      plant_names => $design->{$plot_number}-> {plant_names},

	};
#print STDERR Dumper(@layout_info);
    }

	my @row_numbers = ();
	my @col_numbers = ();
	my @rep_numbers = ();
	my @block_numbers = ();
	my @accession_name = ();
	my @plot_name = ();
	my @plot_id = ();
  my @acc_name = ();
  my @blk_no = ();
  my @rep_no = ();
	my @array_msg = ();
	my @plot_number = ();
	my $my_hash;

	foreach $my_hash (@layout_info) {
	    if ($my_hash->{'row_number'}) {
		  if ($my_hash->{'row_number'} =~ m/\d+/) {
      if (scalar(@{$my_hash->{"plant_names"}}) < 1) {
        $array_msg[$my_hash->{'row_number'}-1][$my_hash->{'col_number'}-1] = "rep_number: ".$my_hash->{'rep_number'}."\nblock_number: ".$my_hash->{'block_number'}."\nrow_number: ".$my_hash->{'row_number'}."\ncol_number: ".$my_hash->{'col_number'}."\naccession_name: ".$my_hash->{'accession_name'};
      }
      else{
    		$array_msg[$my_hash->{'row_number'}-1][$my_hash->{'col_number'}-1] = "rep_number: ".$my_hash->{'rep_number'}."\nblock_number: ".$my_hash->{'block_number'}."\nrow_number: ".$my_hash->{'row_number'}."\ncol_number: ".$my_hash->{'col_number'}."\naccession_name: ".$my_hash->{'accession_name'}."\nnumber_of_plants:".scalar(@{$my_hash->{"plant_names"}});
      }

	$plot_id[$my_hash->{'row_number'}-1][$my_hash->{'col_number'}-1] = $my_hash->{'plot_id'};
	#$plot_id[$my_hash->{'plot_number'}] = $my_hash->{'plot_id'};
	$plot_number[$my_hash->{'row_number'}-1][$my_hash->{'col_number'}-1] = $my_hash->{'plot_number'};
	#$plot_number[$my_hash->{'plot_number'}] = $my_hash->{'plot_number'};
  $acc_name[$my_hash->{'row_number'}-1][$my_hash->{'col_number'}-1] = $my_hash->{'accession_name'};
  $blk_no[$my_hash->{'row_number'}-1][$my_hash->{'col_number'}-1] = $my_hash->{'block_number'};
  $rep_no[$my_hash->{'row_number'}-1][$my_hash->{'col_number'}-1] = $my_hash->{'rep_number'};
  $plot_name[$my_hash->{'row_number'}-1][$my_hash->{'col_number'}-1] = $my_hash->{'plot_name'};
		}
		else {
		}
	    }
	}
 # Looping through the hash and printing out all the hash elements.
 my @plot_numbers_not_used;
 my @plotcnt;
    foreach $my_hash (@layout_info) {
	push @col_numbers, $my_hash->{'col_number'};
	push @row_numbers, $my_hash->{'row_number'};
	#push @plot_id, $my_hash->{'plot_id'};
	push @plot_numbers_not_used, $my_hash->{'plot_number'};
	push @rep_numbers, $my_hash->{'rep_number'};
	push @block_numbers, $my_hash->{'block_number'};
	push @accession_name, $my_hash->{'accession_name'};
	#push @plot_name, $my_hash->{'plot_name'};

    }

    my $plotcounter_nu = 0;
    if ($plot_numbers_not_used[0] =~ m/^\d{3}/){
      foreach my $plot (@plot_numbers_not_used) {
        $plotcounter_nu++;
      }
      for my $n (1..$plotcounter_nu){
        push @plotcnt, $n;
      }

    }

    my @sorted_block = sort@block_numbers;
    #my @uniq_block = uniq(@sorted_block);

    my $max_col = 0;
    $max_col = max( @col_numbers ) if (@col_numbers);
    #print "$max_col\n";
    my $max_row = 0;
    $max_row = max( @row_numbers ) if (@row_numbers);
    #print "$max_row\n";
    my $max_rep = 0;
    $max_rep = max(@rep_numbers) if (@rep_numbers);
    my $max_block = 0;
    $max_block = max(@block_numbers) if (@block_numbers);

    #print STDERR Dumper \@layout_info;

    my $trial = CXGN::Trial->new( { bcs_schema => $schema, trial_id => $c->stash->{trial_id} });
    my $data = $trial->get_controls();

    print STDERR Dumper($data);

    my @control_name;
    foreach my $cntrl (@{$data}) {
	push @control_name, $cntrl->{'accession_name'};

  }
 print STDERR Dumper(@control_name);

	$c->stash->{rest} = { coord_row =>  \@row_numbers,
			      coords =>  \@layout_info,
			      coord_col =>  \@col_numbers,
			      max_row => $max_row,
			      max_col => $max_col,
			      plot_msg => \@array_msg,
			      rep => \@rep_numbers,
			      block => \@sorted_block,
			      accessions => \@accession_name,
			      plot_name => \@plot_name,
			      plot_id => \@plot_id,
			      plot_number => \@plot_number,
            max_rep => $max_rep,
			      max_block => $max_block,
            sudo_plot_no => \@plotcnt,
            controls => \@control_name,
            blk => \@blk_no,
            acc => \@acc_name,
            rep_no => \@rep_no
	};

}

#sub compute_derive_traits : Path('/ajax/phenotype/delete_field_coords') Args(0) {
sub delete_field_coord : Path('/ajax/phenotype/delete_field_coords') Args(0) {

  my $self = shift;
	my $c = shift;
	my $trial_id = $c->req->param('trial_id');
  print "TRIALID: $trial_id\n";

  my $schema = $c->dbic_schema('Bio::Chado::Schema');
  my $dbh = $c->dbc->dbh();

  if (!$c->user()) {
		print STDERR "User not logged in... not deleting field map.\n";
		$c->stash->{rest} = {error => "You need to be logged in to delete field map." };
		return;
    	}

	if (!any { $_ eq "curator" || $_ eq "submitter" } ($c->user()->roles)  ) {
		$c->stash->{rest} = {error =>  "You have insufficient privileges to delete field map." };
		return;
    	}

  my $h = $dbh->prepare("delete from stockprop where stockprop.stockprop_id IN (select stockprop.stockprop_id from project join nd_experiment_project using(project_id) join nd_experiment_stock using(nd_experiment_id) join stock using(stock_id) join stockprop on(stock.stock_id=stockprop.stock_id) where (stockprop.type_id IN (select cvterm_id from cvterm where name='col_number') or stockprop.type_id IN (select cvterm_id from cvterm where name='row_number')) and project.project_id=? and stock.type_id IN (select cvterm_id from cvterm join cv using(cv_id) where cv.name = 'stock_type' and cvterm.name ='plot'));");
  my ($row_number, $col_number, $cvterm_id, @cvterm );
  $h->execute($trial_id);

  $c->stash->{rest} = {success => 1};

}


sub update_field_coord : Chained('trial') PathPart('update_field_coords') Args(0) {

  my $self = shift;
	my $c = shift;
	my $plotIDs_accessions = $c->req->param('plot_infor');
  print "MY PLOTID AND ACCESSIONS: $plotIDs_accessions\n";

  my ($accession_1, $plot_1_id, $accession_2, $plot_2_id) = split /,/, $plotIDs_accessions;
  print "hello1: $accession_1\n";
  print "hello2: $plot_1_id\n";
  print "hello3: $accession_2\n";
  print "hello4: $plot_2_id\n";

  if (!$accession_1 || !$accession_2){
    $c->stash->{rest} = {error => "Dragged plot has no accession." };
	 	return;
  }
  if (!$plot_1_id || !$plot_2_id ){
    $c->stash->{rest} = {error => "Dragged plot is empty." };
	 	return;
  }
  if ($plot_1_id == $plot_2_id){
    $c->stash->{rest} = {error => "You have dragged a plot twice." };
	 	return;
  }

   my $schema = $c->dbic_schema('Bio::Chado::Schema');
   my $dbh = $c->dbc->dbh();

   if ($self->update_map_privileges_denied($c)) {
 $c->stash->{rest} = { error => "You have insufficient access privileges to update this map." };
 return;
   }

   my $trial_id = $c->stash->{trial_id};
   my $trial = CXGN::Trial->new({ bcs_schema => $schema,
     trial_id => $trial_id
   });

   my $triat_name = $trial->get_traits_assayed();

   print STDERR Dumper($triat_name);


  if (scalar(@{$triat_name}) != 0)  {
    $c->stash->{rest} = {error => "One or more traits have been assayed for this trial; Map/Layout can not be modified." };
    return;
  }

   my @plot_1_objectIDs;
   my @plot_2_objectIDs;
   my $h = $dbh->prepare("select object_id from stock_relationship where subject_id=?;");
   $h->execute($plot_1_id);
   while (my $plot_1_objectID = $h->fetchrow_array()) {
     push @plot_1_objectIDs, $plot_1_objectID;
   }

   my $h1 = $dbh->prepare("select object_id from stock_relationship where subject_id=?;");
   $h1->execute($plot_2_id);
   while (my $plot_2_objectID = $h1->fetchrow_array()) {
     push @plot_2_objectIDs, $plot_2_objectID;
   }

     for (my $n=0; $n<scalar(@plot_2_objectIDs); $n++) {
        my $h2 = $dbh->prepare("update stock_relationship set object_id =? where object_id=? and subject_id=?;");
         $h2->execute($plot_1_objectIDs[$n],$plot_2_objectIDs[$n],$plot_2_id);
     }

     for (my $n=0; $n<scalar(@plot_2_objectIDs); $n++) {
        my $h2 = $dbh->prepare("update stock_relationship set object_id =? where object_id=? and subject_id=?;");
         $h2->execute($plot_2_objectIDs[$n],$plot_1_objectIDs[$n],$plot_1_id);
    }

  $c->stash->{rest} = {success => 1};

}


sub create_plant_subplots : Chained('trial') PathPart('create_subplots') Args(0) {
    my $self = shift;
    my $c = shift;
    my $plants_per_plot = $c->req->param("plants_per_plot") || 8;

    if (my $error = $self->delete_privileges_denied($c)) {
	$c->stash->{rest} = { error => $error };
	return;
    }

    if (!$plants_per_plot || $plants_per_plot > 50) {
	$c->stash->{rest} = { error => "Plants per plot number is required and must be smaller than 20." };
	return;
    }

    my $t = CXGN::Trial->new( { bcs_schema => $c->dbic_schema("Bio::Chado::Schema"), trial_id => $c->stash->{trial_id} });

    if ($t->create_plant_entities($plants_per_plot)) {
        $c->stash->{rest} = {success => 1};
        return;
    } else {
        $c->stash->{rest} = { error => "Error creating plant entries in controller." };
    	return;
    }

}


sub delete_privileges_denied {
    my $self = shift;
    my $c = shift;

    my $trial_id = $c->stash->{trial_id};

    if (! $c->user) { return "Login required for delete functions."; }
    my $user_id = $c->user->get_object->get_sp_person_id();

    if ($c->user->check_roles('curator')) {
	     return 0;
    }

    my $breeding_programs = $c->stash->{trial}->get_breeding_programs();

    if ( ($c->user->check_roles('submitter')) && ( $c->user->check_roles($breeding_programs->[0]->[1]))) {
	return 0;
    }
    return "You have insufficient privileges to modify or delete this trial.";
}

sub update_map_privileges_denied {
    my $self = shift;
    my $c = shift;

    my $trial_id = $c->stash->{trial_id};

    if (! $c->user) { return "Login required for map update functions."; }
    my $user_id = $c->user->get_object->get_sp_person_id();

    if ($c->user->check_roles('curator')) {
	     return 0;
    }

    my $breeding_programs = $c->stash->{trial}->get_breeding_programs();

    if ( ($c->user->check_roles('submitter')) && ( $c->user->check_roles($breeding_programs->[0]->[1]))) {
	return 0;
    }
    return "You have insufficient privileges to modify or update this map.";
}

# loading field coordinates

sub upload_trial_coordinates : Path('/ajax/breeders/trial/coordsupload') Args(0) {

    my $self = shift;
    my $c = shift;

    if (!$c->user()) {
	print STDERR "User not logged in... not uploading coordinates.\n";
	$c->stash->{rest} = {error => "You need to be logged in to upload coordinates." };
	return;
    }

    if (!any { $_ eq "curator" || $_ eq "submitter" } ($c->user()->roles)  ) {
	$c->stash->{rest} = {error =>  "You have insufficient privileges to add coordinates." };
	return;
    }

    my $time = DateTime->now();
    my $user_id = $c->user()->get_object()->get_sp_person_id();
    my $user_name = $c->user()->get_object()->get_username();
    my $timestamp = $time->ymd()."_".$time->hms();
    my $subdirectory = 'trial_coords_upload';

    my $upload = $c->req->upload('trial_coordinates_uploaded_file');
    my $upload_tempfile  = $upload->tempname;

    my $upload_original_name  = $upload->filename();
    my $md5;

    my $uploader = CXGN::UploadFile->new();

    my %upload_metadata;


    # Store uploaded temporary file in archive
    print STDERR "TEMP FILE: $upload_tempfile\n";
    my $archived_filename_with_path = $uploader->archive($c, $subdirectory, $upload_tempfile, $upload_original_name, $timestamp);

    if (!$archived_filename_with_path) {
	$c->stash->{rest} = {error => "Could not save file $upload_original_name in archive",};
	return;
    }

    $md5 = $uploader->get_md5($archived_filename_with_path);
    unlink $upload_tempfile;

   # open file and remove return of line

     open(my $F, "<", $archived_filename_with_path) || die "Can't open archive file $archived_filename_with_path";
    my $schema = $c->dbic_schema("Bio::Chado::Schema");
    my $header = <$F>;
    while (<$F>) {
	chomp;
	$_ =~ s/\r//g;
	my ($plot,$row,$col) = split /\t/ ;

	my $rs = $schema->resultset("Stock::Stock")->search({uniquename=> $plot });

	if ($rs->count()== 1) {
	my $r =  $rs->first();
	print STDERR "The plots $plot was found.\n Loading row $row col $col\n";
	$r->create_stockprops({row_number => $row, col_number => $col}, {autocreate => 1});
    }

    else {

	print STDERR "WARNING! $plot was not found in the database.\n";

    }

    }

    $c->stash->{rest} = {success => 1};


}



1;
