package CXGN::Pedigree::AddCrosses;

=head1 NAME

CXGN::Pedigree::AddCrosses - a module to add cross experiments.

=head1 USAGE

 my $cross_add = CXGN::Pedigree::AddCrosses->new({ schema => $schema, location => $location_name, program => $program_name, crosses =>  \@array_of_pedigree_objects} );
 my $validated = $cross_add->validate_crosses(); #is true when all of the crosses are valid and the accessions they point to exist in the database.
 $cross_add->add_crosses();

=head1 DESCRIPTION

Adds an array of crosses. The stock names used in the cross must already exist in the database, and the verify function does this check.   This module is intended to be used in independent loading scripts and interactive dialogs.

=head1 AUTHORS

 Jeremy D. Edwards (jde22@cornell.edu)

=cut

use Moose;
use MooseX::FollowPBP;
use Moose::Util::TypeConstraints;
use Try::Tiny;
use Bio::GeneticRelationships::Pedigree;
use Bio::GeneticRelationships::Individual;
use CXGN::Stock::StockLookup;
use CXGN::Location::LocationLookup;
use CXGN::BreedersToolbox::Projects;
use CXGN::Trial;
use CXGN::Trial::Folder;
use SGN::Model::Cvterm;

class_type 'Pedigree', { class => 'Bio::GeneticRelationships::Pedigree' };
has 'chado_schema' => (
		 is       => 'rw',
		 isa      => 'DBIx::Class::Schema',
		 predicate => 'has_chado_schema',
		 required => 1,
		);
has 'phenome_schema' => (
		 is       => 'rw',
		 isa      => 'DBIx::Class::Schema',
		 predicate => 'has_phenome_schema',
		 required => 1,
		);
has 'metadata_schema' => (
		 is       => 'rw',
		 isa      => 'DBIx::Class::Schema',
		 predicate => 'has_metadata_schema',
		 required => 0,
		);
has 'dbh' => (is  => 'rw',predicate => 'has_dbh', required => 1,);
has 'crosses' => (isa =>'ArrayRef[Pedigree]', is => 'rw', predicate => 'has_crosses', required => 1,);
has 'location' => (isa =>'Str', is => 'rw', predicate => 'has_location', required => 1,);
has 'program' => (isa =>'Str', is => 'rw', predicate => 'has_program', required => 1,);
has 'owner_name' => (isa => 'Str', is => 'rw', predicate => 'has_owner_name', required => 1,);
has 'parent_folder_id' => (isa => 'Str', is => 'rw', predicate => 'has_parent_folder_id', required => 0,);

sub add_crosses {
  my $self = shift;
  my $chado_schema = $self->get_chado_schema();
  my $phenome_schema = $self->get_phenome_schema();
  my @crosses;
  my $location_lookup;
  my $geolocation;
  my $program;
  my $program_lookup;
  my $transaction_error;
  my @added_stock_ids;
	my $parent_folder_id;

  #lookup user by name
  my $owner_name = $self->get_owner_name();
  $parent_folder_id = $self->get_parent_folder_id() || 0;
  my $dbh = $self->get_dbh();
  my $owner_sp_person_id = CXGN::People::Person->get_person_by_username($dbh, $owner_name); #add person id as an option.

  if (!$self->validate_crosses()) {
    print STDERR "Invalid pedigrees in array.  No crosses will be added\n";
    return;
  }

  #add all crosses in a single transaction
  my $coderef = sub {

      #get cvterms for parents and offspring
      my $female_parent_cvterm = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'female_parent', 'stock_relationship');

      my $male_parent_cvterm = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'male_parent', 'stock_relationship');
      my $progeny_cvterm = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'offspring_of', 'stock_relationship');

      #get cvterm for cross_name or create if not found
      my $cross_name_cvterm = $chado_schema->resultset("Cv::Cvterm")
	  ->find({
	      name   => 'cross_name',
		 });
      if (!$cross_name_cvterm) {
	  $cross_name_cvterm = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'cross_name', 'nd_experiment_property');
      }
      #get cvterm for cross_type or create if not found
      my $cross_type_cvterm = $chado_schema->resultset("Cv::Cvterm")
	  ->find({
	      name   => 'cross_type',
		 });

      if (!$cross_type_cvterm) {
	  $cross_type_cvterm =  SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'cross_type', 'nd_experiment_property');
      }

      #get cvterm for cross_experiment
      my $cross_experiment_type_cvterm =  SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'cross_experiment', 'experiment_type');

      #get cvterm for stock type cross
      my $cross_stock_type_cvterm  =  SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'cross', 'stock_type');

      print STDERR "\n\ncvterm from addcrosses: ".$cross_stock_type_cvterm->cvterm_id()."\n\n";

      #lookup location by name
      $location_lookup = CXGN::Location::LocationLookup->new({ schema => $chado_schema, location_name => $self->get_location });
      $geolocation = $location_lookup->get_geolocation();

      #lookup program by name
      $program_lookup = CXGN::BreedersToolbox::Projects->new({ schema => $chado_schema});
      $program = $program_lookup->get_breeding_program_by_name($self->get_program());

      @crosses = @{$self->get_crosses()};

      foreach my $pedigree (@crosses) {
	  my $experiment;
	  my $cross_stock;
	  my $organism_id;
	  my $female_parent_name;
	  my $male_parent_name;
	  my $female_parent;
	  my $male_parent;
	  my $population_stock;
	  my $project;
	  my $cross_type = $pedigree->get_cross_type();
	  my $cross_name = $pedigree->get_name();
      $cross_name =~ s/^\s+|\s+$//g; #trim whitespace from both ends

	  if ($pedigree->has_female_parent()) {
	      $female_parent_name = $pedigree->get_female_parent()->get_name();
	      $female_parent = $self->_get_accession($female_parent_name);
	  }

	  if ($pedigree->has_male_parent()) {
	      $male_parent_name = $pedigree->get_male_parent()->get_name();
	      $male_parent = $self->_get_accession($male_parent_name);
	  }

	  #organism of cross experiment will be the same as the female parent
	  if ($female_parent) {
	      $organism_id = $female_parent->organism_id();
	  } else {
	      $organism_id = $male_parent->organism_id();
	  }

	  #create cross project
	  $project = $chado_schema->resultset('Project::Project')
	      ->create({
		  name => $cross_name,
		  description => $cross_name,
		       });

	  #add error if cross name exists

		#add cross to folder if one was specified
		if ($parent_folder_id) {
			my $folder = CXGN::Trial::Folder->new(
			{
				bcs_schema => $chado_schema,
				folder_id => $project->project_id(),
			});

			$folder->associate_parent($parent_folder_id);
		}

	  #set projectprop so that projects corresponding to crosses can be identified
	  my $prop_row = $chado_schema->resultset("Project::Projectprop")
	      ->create({
		  type_id => $cross_stock_type_cvterm->cvterm_id,
		  project_id => $project->project_id(),
		       });
	  $prop_row->insert();

	  #create cross experiment
	  $experiment = $chado_schema->resultset('NaturalDiversity::NdExperiment')->create(
	      {
		  nd_geolocation_id => $geolocation->nd_geolocation_id(),
		  type_id => $cross_experiment_type_cvterm->cvterm_id(),
	      } );

	  #store the cross name as an experiment prop
	  $experiment->find_or_create_related('nd_experimentprops' , {
	      nd_experiment_id => $experiment->nd_experiment_id(),
	      type_id  =>  $cross_name_cvterm->cvterm_id(),
	      value  =>  $cross_name,
					  });

	  #store the cross type as an experiment prop
	  $experiment->find_or_create_related('nd_experimentprops' , {
	      nd_experiment_id => $experiment->nd_experiment_id(),
	      type_id  =>  $cross_type_cvterm->cvterm_id(),
	      value  =>  $cross_type,
					      });

      #link the parents to the experiment
      if ($female_parent) {
	  $experiment->find_or_create_related('nd_experiment_stocks' , {
	      stock_id => $female_parent->stock_id(),
	      type_id  =>  $female_parent_cvterm->cvterm_id(),
					      });
      }
      if ($male_parent) {
	  $experiment->find_or_create_related('nd_experiment_stocks' , {
	      stock_id => $male_parent->stock_id(),
	      type_id  =>  $male_parent_cvterm->cvterm_id(),
					      });
      }
      if ($cross_type eq "self" && $female_parent) {
	  $experiment->find_or_create_related('nd_experiment_stocks' , {
	      stock_id => $female_parent->stock_id(),
	      type_id  =>  $male_parent_cvterm->cvterm_id(),
					      });
      }

      #create a stock of type cross
      $cross_stock = $chado_schema->resultset("Stock::Stock")->find_or_create(
	  { organism_id => $organism_id,
	    name       => $cross_name,
	    uniquename => $cross_name,
	    type_id => $cross_stock_type_cvterm->cvterm_id,
	  } );

      #add stock_id of cross to an array so that the owner can be associated in the phenome schema after the transaction on the chado schema completes
      push (@added_stock_ids,  $cross_stock->stock_id());


      #link parents to the stock of type cross
      if ($female_parent) {
	  $cross_stock
	      ->find_or_create_related('stock_relationship_objects', {
		  type_id => $female_parent_cvterm->cvterm_id(),
		  object_id => $cross_stock->stock_id(),
		  subject_id => $female_parent->stock_id(),
		  value => $cross_type,
				       } );
      }

      if ($male_parent) {
	  $cross_stock
	      ->find_or_create_related('stock_relationship_objects', {
		  type_id => $male_parent_cvterm->cvterm_id(),
		  object_id => $cross_stock->stock_id(),
		  subject_id => $male_parent->stock_id(),
				       } );
      }

      if ($cross_type eq "self" && $female_parent) {
	  $cross_stock
	      ->find_or_create_related('stock_relationship_objects', {
		  type_id => $male_parent_cvterm->cvterm_id(),
		  object_id => $cross_stock->stock_id(),
		  subject_id => $female_parent->stock_id(),
				       } );
      }


      #link the stock of type cross to the experiment
      $experiment->find_or_create_related('nd_experiment_stocks' , {
	  stock_id => $cross_stock->stock_id(),
	  type_id  =>  $progeny_cvterm->cvterm_id(),
					  });
      #link the experiment to the project
      $experiment->find_or_create_related('nd_experiment_projects', {
	  project_id => $project->project_id()
					  } );

      #link the cross program to the breeding program
			my $trial_object = CXGN::Trial->new({ bcs_schema => $chado_schema, trial_id => $project->project_id() });
			$trial_object->set_breeding_program($program->project_id());

      #add the cross type to the experiment as an experimentprop
      $experiment
	  ->find_or_create_related('nd_experimentprops' , {
	      nd_experiment_id => $experiment->nd_experiment_id(),
	      type_id  =>  $cross_type_cvterm->cvterm_id(),
	      value  =>  $cross_type,
				   });

    }

  };

  #try to add all crosses in a transaction
  try {
    $chado_schema->txn_do($coderef);
  } catch {
    $transaction_error =  $_;
  };

  if ($transaction_error) {
    print STDERR "Transaction error creating a cross: $transaction_error\n";
    return;
  }

  foreach my $stock_id (@added_stock_ids) {
    #add the owner for this stock
    $phenome_schema->resultset("StockOwner")
      ->find_or_create({
			stock_id     => $stock_id,
			sp_person_id =>  $owner_sp_person_id,
		       });
  }

  return 1;
}


sub validate_crosses {
  my $self = shift;
  my $chado_schema = $self->get_chado_schema();
  my @crosses = @{$self->get_crosses()};
  my $invalid_cross_count = 0;
  my $program;
  my $location_lookup;
  my $trial_lookup;
  my $program_lookup;
  my $geolocation;

  $location_lookup = CXGN::Location::LocationLookup->new({ schema => $chado_schema, location_name => $self->get_location() });
  $geolocation = $location_lookup->get_geolocation();

  if (!$geolocation) {
    print STDERR "Location ".$self->get_location()." not found\n";
    return;
  }

  $program_lookup = CXGN::BreedersToolbox::Projects->new({ schema => $chado_schema});
  $program = $program_lookup->get_breeding_program_by_name($self->get_program());
  if (!$program) {
    print STDERR "Breeding program ". $self->get_program() ." not found\n";
    return;
  }

  foreach my $cross (@crosses) {
    my $validated_cross = $self->_validate_cross($cross);

    if (!$validated_cross) {
      $invalid_cross_count++;
    }

  }

  if ($invalid_cross_count > 0) {
    print STDERR "There were $invalid_cross_count invalid crosses\n";
    return;
  }

  return 1;
}

sub _validate_cross {
  my $self = shift;
  my $pedigree = shift;
  my $chado_schema = $self->get_chado_schema();
  my $name = $pedigree->get_name();
  my $cross_type = $pedigree->get_cross_type();
  my $female_parent_name;
  my $male_parent_name;
  my $female_parent;
  my $male_parent;

  if ($cross_type eq "biparental") {
    $female_parent_name = $pedigree->get_female_parent()->get_name();
    $male_parent_name = $pedigree->get_male_parent()->get_name();
    $female_parent = $self->_get_accession($female_parent_name);
    $male_parent = $self->_get_accession($male_parent_name);

    if (!$female_parent || !$male_parent) {
      print STDERR "Parent $female_parent_name or $male_parent_name in pedigree is not a stock\n";
      return;
    }

  } elsif ($cross_type eq "self") {
    $female_parent_name = $pedigree->get_female_parent()->get_name();
    $female_parent = $self->_get_accession($female_parent_name);

    if (!$female_parent) {
      print STDERR "Parent $female_parent_name in pedigree is not a stock\n";
      return;
    }

  }  elsif ($cross_type eq "open") {
    $female_parent_name = $pedigree->get_female_parent()->get_name();
    $female_parent = $self->_get_accession($female_parent_name);

    if (!$female_parent) {
      print STDERR "Parent $female_parent_name in pedigree is not a stock\n";
      return;
    }
  }
  #add support for other cross types here

  #else {
  #  return;
  #}

  return 1;
}

sub _get_accession {
  my $self = shift;
  my $accession_name = shift;
  my $chado_schema = $self->get_chado_schema();
  my $stock_lookup = CXGN::Stock::StockLookup->new(schema => $chado_schema);
  my $stock;
  my $accession_cvterm = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'accession', 'stock_type');
  my $vector_cvterm = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'vector_construct', 'stock_type');
	my $population_cvterm = SGN::Model::Cvterm->get_cvterm_row($chado_schema, 'population', 'stock_type');

  $stock_lookup->set_stock_name($accession_name);
  $stock = $stock_lookup->get_stock_exact();

  if (!$stock) {
    print STDERR "Name in pedigree is not a stock\n";
    return;
  }

  if (($stock->type_id() != $accession_cvterm->cvterm_id()) && ($stock->type_id() != $population_cvterm->cvterm_id())  && ($stock->type_id() != $vector_cvterm->cvterm_id()) ) {
    print STDERR "Name in pedigree is not a stock of type accession or population or vector_construct\n";
    return;
  }

  return $stock;
}

#######
1;
#######
