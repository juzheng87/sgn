#!/usr/bin/env perl


=head1 NAME

UpdateMatViews.pm

=head1 SYNOPSIS

mx-run UpdateMatViews [options] -H hostname -D dbname -u username [-F]

this is a subclass of L<CXGN::Metadata::Dbpatch>
see the perldoc of parent class for more details.

=head1 DESCRIPTION

This patch updates the index of materialized_fullview and the queries used to create the materialized view for each individual category. It adds views for new categories: trial type and trial design

=head1 AUTHOR

Bryan Ellerbrock<bje24@cornell.edu>

=head1 COPYRIGHT & LICENSE

Copyright 2010 Boyce Thompson Institute for Plant Research

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


package UpdateMatViews;

use Moose;
extends 'CXGN::Metadata::Dbpatch';


has '+description' => ( default => <<'' );
This patch updates the index of materialized_fullview and the queries used to create the materialized view for each individual category. It adds views for new categories: trial type and trial design


sub patch {
    my $self=shift;

    print STDOUT "Executing the patch:\n " .   $self->name . ".\n\nDescription:\n  ".  $self->description . ".\n\nExecuted by:\n " .  $self->username . " .";

    print STDOUT "\nChecking if this db_patch was executed before or if previous db_patches have been executed.\n";

    print STDOUT "\nExecuting the SQL commands.\n";

    $self->dbh->do(<<EOSQL);
--do your SQL here
DROP MATERIALIZED VIEW public.accessions;
CREATE MATERIALIZED VIEW public.accessions AS
  SELECT stock.stock_id AS accession_id,
  stock.uniquename AS accession_name
  FROM stock
  WHERE stock.type_id = (SELECT cvterm_id from cvterm where cvterm.name = 'accession')
  GROUP BY stock.stock_id, stock.uniquename;
CREATE UNIQUE INDEX accessions_idx ON public.accessions(accession_id) WITH (fillfactor=100);
GRANT SELECT ON accessions to web_usr;

DROP MATERIALIZED VIEW public.breeding_programs;
CREATE MATERIALIZED VIEW public.breeding_programs AS
SELECT project.project_id AS breeding_program_id,
    project.name AS breeding_program_name
   FROM project join projectprop USING (project_id)
   WHERE projectprop.type_id = (SELECT cvterm_id from cvterm where cvterm.name = 'breeding_program')
  GROUP BY project.project_id, project.name;
CREATE UNIQUE INDEX breeding_programs_idx ON public.breeding_programs(breeding_program_id) WITH (fillfactor=100);
GRANT SELECT ON breeding_programs to web_usr;

DROP MATERIALIZED VIEW public.genotyping_protocols;
CREATE MATERIALIZED VIEW public.genotyping_protocols AS
SELECT nd_protocol.nd_protocol_id AS genotyping_protocol_id,
    nd_protocol.name AS genotyping_protocol_name
   FROM nd_protocol
  GROUP BY public.nd_protocol.nd_protocol_id, public.nd_protocol.name;
CREATE UNIQUE INDEX genotyping_protocols_idx ON public.genotyping_protocols(genotyping_protocol_id) WITH (fillfactor=100);
GRANT SELECT ON genotyping_protocols to web_usr;

DROP MATERIALIZED VIEW public.locations;
CREATE MATERIALIZED VIEW public.locations AS
SELECT nd_geolocation.nd_geolocation_id AS location_id,
  nd_geolocation.description AS location_name
   FROM nd_geolocation
  GROUP BY public.nd_geolocation.nd_geolocation_id, public.nd_geolocation.description;
CREATE UNIQUE INDEX locations_idx ON public.locations(location_id) WITH (fillfactor=100);
GRANT SELECT ON locations to web_usr;

DROP MATERIALIZED VIEW public.plots;
CREATE MATERIALIZED VIEW public.plots AS
SELECT stock.stock_id AS plot_id,
    stock.uniquename AS plot_name
   FROM stock
   WHERE stock.type_id = (SELECT cvterm_id from cvterm where cvterm.name = 'plot')
  GROUP BY public.stock.stock_id, public.stock.uniquename;
CREATE UNIQUE INDEX plots_idx ON public.plots(plot_id) WITH (fillfactor=100);
GRANT SELECT ON plots to web_usr;

DROP MATERIALIZED VIEW public.traits;
CREATE MATERIALIZED VIEW public.traits AS
SELECT   cvterm.cvterm_id AS trait_id,
  (((cvterm.name::text || '|'::text) || db.name::text) || ':'::text) || dbxref.accession::text AS trait_name
  FROM cvterm
  JOIN dbxref ON cvterm.dbxref_id = dbxref.dbxref_id
  JOIN db ON dbxref.db_id = db.db_id
  WHERE db.db_id =
(SELECT dbxref.db_id
   FROM stock
   JOIN nd_experiment_stock USING(stock_id)
   JOIN nd_experiment_phenotype USING(nd_experiment_id)
   JOIN phenotype USING(phenotype_id)
   JOIN cvterm ON phenotype.cvalue_id = cvterm.cvterm_id
   JOIN dbxref ON cvterm.dbxref_id = dbxref.dbxref_id LIMIT 1)
   GROUP BY public.cvterm.cvterm_id, trait_name;
CREATE UNIQUE INDEX traits_idx ON public.traits(trait_id) WITH (fillfactor=100);
GRANT SELECT ON traits to web_usr;

DROP MATERIALIZED VIEW public.trials;
CREATE MATERIALIZED VIEW public.trials AS
SELECT project.project_id AS trial_id,
    project.name AS trial_name
   FROM project join projectprop USING (project_id)
   WHERE projectprop.type_id IS DISTINCT FROM (SELECT cvterm_id from cvterm where cvterm.name = 'breeding_program')
   AND projectprop.type_id IS DISTINCT FROM (SELECT cvterm_id from cvterm where cvterm.name = 'trial_folder')
  GROUP BY public.project.project_id, public.project.name;
CREATE UNIQUE INDEX trials_idx ON public.trials(trial_id) WITH (fillfactor=100);
GRANT SELECT ON trials to web_usr;

DROP MATERIALIZED VIEW public.years;
CREATE MATERIALIZED VIEW public.years AS
SELECT projectprop.value AS year_id,
  projectprop.value AS year_name
   FROM projectprop
   WHERE projectprop.type_id = (SELECT cvterm_id from cvterm where cvterm.name = 'project year')
  GROUP BY public.projectprop.value;
CREATE UNIQUE INDEX years_idx ON public.years(year_id) WITH (fillfactor=100);
GRANT SELECT ON years to web_usr;

CREATE MATERIALIZED VIEW public.trial_types AS
SELECT cvterm.cvterm_id AS trial_type_id,
  cvterm.name AS trial_type_name
   FROM cvterm
   JOIN cv USING(cv_id)
   WHERE cv.name = 'project_type'
   GROUP BY cvterm.cvterm_id;
CREATE UNIQUE INDEX trial_types_idx ON public.trial_types(trial_type_id) WITH (fillfactor=100);
GRANT SELECT ON trial_types to web_usr;


CREATE MATERIALIZED VIEW public.trial_designs AS
SELECT projectprop.value AS trial_design_id,
  projectprop.value AS trial_design_name
   FROM projectprop
   JOIN cvterm ON(projectprop.type_id = cvterm.cvterm_id)
   WHERE cvterm.name = 'design'
   GROUP BY projectprop.value;
CREATE UNIQUE INDEX trial_designs_idx ON public.trial_designs(trial_design_id) WITH (fillfactor=100);
GRANT SELECT ON trial_designs to web_usr;



ALTER MATERIALIZED VIEW public.materialized_fullview AS
 SELECT plot.uniquename AS plot_name,
    stock_relationship.subject_id AS plot_id,
    accession.uniquename AS accession_name,
    stock_relationship.object_id AS accession_id,
    nd_experiment.nd_geolocation_id AS location_id,
    nd_geolocation.description AS location_name,
    projectprop.value AS year_id,
    projectprop.value AS year_name,
    trial.project_id AS trial_id,
    trial.name AS trial_name,
    trialterm.cvterm_id AS trial_type_id,
    trialterm.name AS trial_type_name,
    trialdesign.value AS trial_design_id,
    trialdesign.value AS trial_design_value,
    project_relationship.object_project_id AS breeding_program_id,
    breeding_program.name AS breeding_program_name,
    cvterm.cvterm_id AS trait_id,
    (((cvterm.name::text || '|'::text) || db.name::text) || ':'::text) || dbxref.accession::text AS trait_name,
    phenotype.phenotype_id,
    phenotype.value AS phenotype_value
   FROM stock accession
     LEFT JOIN stock_relationship ON accession.stock_id = stock_relationship.object_id
     LEFT JOIN stock plot ON stock_relationship.subject_id = plot.stock_id
     LEFT JOIN nd_experiment_stock nd_experiment_plot ON stock_relationship.subject_id = nd_experiment_plot.stock_id
     LEFT JOIN nd_experiment_stock nd_experiment_accession ON accession.stock_id = nd_experiment_accession.stock_id
     LEFT JOIN nd_experiment ON nd_experiment_plot.nd_experiment_id = nd_experiment.nd_experiment_id
     LEFT JOIN nd_geolocation ON nd_experiment.nd_geolocation_id = nd_geolocation.nd_geolocation_id
     LEFT JOIN nd_experiment_project ON nd_experiment_plot.nd_experiment_id = nd_experiment_project.nd_experiment_id
     LEFT JOIN project trial ON nd_experiment_project.project_id = trial.project_id
     LEFT JOIN project_relationship ON trial.project_id = project_relationship.subject_project_id
     LEFT JOIN project breeding_program ON project_relationship.object_project_id = breeding_program.project_id
     LEFT JOIN projectprop ON trial.project_id = projectprop.project_id AND projectprop.type_id = (SELECT cvterm_id from cvterm where cvterm.name = 'project year' )
     LEFT JOIN projectprop trialdesign ON trial.project_id = trialdesign.project_id AND trialdesign.type_id = (SELECT cvterm_id from cvterm where cvterm.name = 'design' )
     LEFT JOIN projectprop trialprop ON trial.project_id = trialprop.project_id AND trialprop.type_id IN (SELECT cvterm_id from cvterm JOIN cv USING(cv_id) WHERE cv.name = 'project_type' )
     LEFT JOIN cvterm trialterm ON trialprop.type_id = trialterm.cvterm_id
     LEFT JOIN nd_experiment_phenotype ON nd_experiment_plot.nd_experiment_id = nd_experiment_phenotype.nd_experiment_id
     LEFT JOIN phenotype ON nd_experiment_phenotype.phenotype_id = phenotype.phenotype_id
     LEFT JOIN cvterm ON phenotype.cvalue_id = cvterm.cvterm_id
     LEFT JOIN dbxref ON cvterm.dbxref_id = dbxref.dbxref_id
     LEFT JOIN db ON dbxref.db_id = db.db_id
  WHERE accession.type_id = (SELECT cvterm_id from cvterm where cvterm.name = 'accession')
  GROUP BY stock_relationship.subject_id, cvterm.cvterm_id, plot.uniquename, accession.uniquename, stock_relationship.object_id, (((cvterm.name::text || '|'::text) || db.name::text) || ':'::text) || dbxref.accession::text, trial.name, trial.project_id, breeding_program.name, project_relationship.object_project_id, projectprop.value, trialdesign.value, trialterm.cvterm_id, trialterm.name, nd_experiment.nd_geolocation_id, nd_geolocation.description, phenotype.phenotype_id, phenotype.value;

CREATE UNIQUE INDEX unq_idx ON public.materialized_fullview(accession_id,plot_id,phenotype_id) WITH (fillfactor=100);
CREATE INDEX accession_id_idx ON public.materialized_fullview(accession_id) WITH (fillfactor=100);
CREATE INDEX breeding_program_id_idx ON public.materialized_fullview(breeding_program_id) WITH (fillfactor=100);
CREATE INDEX location_id_idx ON public.materialized_fullview(location_id) WITH (fillfactor=100);
CREATE INDEX plot_id_idx ON public.materialized_fullview(plot_id) WITH (fillfactor=100);
CREATE INDEX trait_id_idx ON public.materialized_fullview(trait_id) WITH (fillfactor=100);
CREATE INDEX trial_id_idx ON public.materialized_fullview(trial_id) WITH (fillfactor=100);
CREATE INDEX trial_type_id_idx ON public.materialized_fullview(trial_type_id) WITH (fillfactor=100);
CREATE INDEX trial_design_id_idx ON public.materialized_fullview(trial_design_id) WITH (fillfactor=100);
CREATE INDEX year_id_idx ON public.materialized_fullview(year_id) WITH (fillfactor=100);
GRANT SELECT ON materialized_fullview to web_usr;


--

EOSQL

print "You're done!\n";
}


####
1; #
####
