
use strict;
use lib 't/lib';

use Test::More;
use SGN::Test::Fixture;
use SimulateC;
use CXGN::UploadFile;
use CXGN::Phenotypes::ParseUpload;
use CXGN::Phenotypes::StorePhenotypes;
use CXGN::Trial;
use SGN::Model::Cvterm;
use DateTime;
use Data::Dumper;

my $f = SGN::Test::Fixture->new();

my $c = SimulateC->new( { dbh => $f->dbh(), 
			  bcs_schema => $f->bcs_schema(), 
			  metadata_schema => $f->metadata_schema(),
			  phenome_schema => $f->phenome_schema(),
			  sp_person_id => 41 });

#######################################
#Find out table counts before adding anything, so that changes can be compared

my $phenotyping_experiment_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($c->bcs_schema, 'phenotyping_experiment', 'experiment_type')->cvterm_id();
my $experiment = $c->bcs_schema->resultset('NaturalDiversity::NdExperiment')->search({type_id => $phenotyping_experiment_cvterm_id});
my $pre_experiment_count = $experiment->count();

my $phenotype_rs = $c->bcs_schema->resultset('Phenotype::Phenotype')->search({});
my $pre_phenotype_count = $phenotype_rs->count();

my $exp_prop_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentprop')->search({});
my $pre_exp_prop_count = $exp_prop_rs->count();

my $exp_stock_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentStock')->search({});
my $pre_exp_stock_count = $exp_stock_rs->count();

my $exp_proj_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentProject')->search({});
my $pre_exp_proj_count = $exp_proj_rs->count();

my $exp_pheno_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentPhenotype')->search({});
my $pre_exp_pheno_count = $exp_pheno_rs->count();

my $md_rs = $c->metadata_schema->resultset('MdMetadata')->search({});
my $pre_md_count = $md_rs->count();

my $md_files_rs = $c->metadata_schema->resultset('MdFiles')->search({});
my $pre_md_files_count = $md_files_rs->count();

my $exp_md_files_rs = $c->phenome_schema->resultset('NdExperimentMdFiles')->search({});
my $pre_exp_md_files_count = $exp_md_files_rs->count();


########################################
#Tests for phenotype spreadsheet parsing

#check that parse fails for fieldbook file when using phenotype spreadsheet parser
my $parser = CXGN::Phenotypes::ParseUpload->new();
my $filename = "t/data/fieldbook/fieldbook_phenotype_file.csv";
my $validate_file = $parser->validate('phenotype spreadsheet', $filename);
ok($validate_file != 1, "Check if parse validate phenotype spreadsheet fails for fieldbook");

#check that parse fails for datacollector file when using phenotype spreadsheet parser
$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/trial/data_collector_upload.xls";
$validate_file = $parser->validate('phenotype spreadsheet', $filename);
ok($validate_file != 1, "Check if parse validate phenotype spreadsheet fails for datacollector");

#Now parse phenotyping spreadsheet file using correct parser
$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/trial/upload_phenotypin_spreadsheet.xls";
$validate_file = $parser->validate('phenotype spreadsheet', $filename);
ok($validate_file == 1, "Check if parse validate works for phenotype file");

my $parsed_file = $parser->parse('phenotype spreadsheet', $filename);
ok($parsed_file, "Check if parse parse phenotype spreadsheet works");

#print STDERR Dumper $parsed_file;

is_deeply($parsed_file, {
          'data' => {
                      'test_trial215' => {
                                           'harvest index|CO:0000015' => [
                                                                           '14.8',
                                                                           '2016-04-27 19:12:20-0500'
                                                                         ],
                                           'fresh root weight|CO:0000012' => [
                                                                               '15',
                                                                               '2016-04-27 19:12:20-0500'
                                                                             ],
                                           'dry matter content|CO:0000092' => [
                                                                                '38',
                                                                                '2016-04-27 19:12:20-0500'
                                                                              ],
                                           'fresh shoot weight|CO:0000016' => [
                                                                                '34',
                                                                                '2016-04-27 19:12:20-0500'
                                                                              ]
                                         },
                      'test_trial25' => {
                                          'fresh shoot weight|CO:0000016' => [
                                                                               '24',
                                                                               '2016-04-27 09:12:20-0500'
                                                                             ],
                                          'fresh root weight|CO:0000012' => [
                                                                              '15',
                                                                              '2016-04-27 09:12:20-0500'
                                                                            ],
                                          'harvest index|CO:0000015' => [
                                                                          '4.8',
                                                                          '2016-04-27 09:12:20-0500'
                                                                        ],
                                          'dry matter content|CO:0000092' => [
                                                                               '35',
                                                                               '2016-04-27 09:12:20-0500'
                                                                             ]
                                        },
                      'test_trial27' => {
                                          'dry matter content|CO:0000092' => [
                                                                               '38',
                                                                               '2016-04-27 17:12:20-0500'
                                                                             ],
                                          'fresh root weight|CO:0000012' => [
                                                                              '15',
                                                                              '2016-04-27 17:12:20-0500'
                                                                            ],
                                          'harvest index|CO:0000015' => [
                                                                          '6.8',
                                                                          '2016-04-27 17:12:20-0500'
                                                                        ],
                                          'fresh shoot weight|CO:0000016' => [
                                                                               '26',
                                                                               '2016-04-27 17:12:20-0500'
                                                                             ]
                                        },
                      'test_trial24' => {
                                          'dry matter content|CO:0000092' => [
                                                                               '39',
                                                                               '2016-04-27 11:12:20-0500'
                                                                             ],
                                          'fresh root weight|CO:0000012' => [
                                                                              '15',
                                                                              '2016-04-27 11:12:20-0500'
                                                                            ],
                                          'harvest index|CO:0000015' => [
                                                                          '3.8',
                                                                          '2016-04-27 11:12:20-0500'
                                                                        ],
                                          'fresh shoot weight|CO:0000016' => [
                                                                               '23',
                                                                               '2016-04-27 11:12:20-0500'
                                                                             ]
                                        },
                      'test_trial21' => {
                                          'fresh root weight|CO:0000012' => [
                                                                              '15',
                                                                              '2016-04-27 12:12:20-0500'
                                                                            ],
                                          'harvest index|CO:0000015' => [
                                                                          '0.8',
                                                                          '2016-04-27 12:12:20-0500'
                                                                        ],
                                          'dry matter content|CO:0000092' => [
                                                                               '35',
                                                                               '2016-04-27 12:12:20-0500'
                                                                             ],
                                          'fresh shoot weight|CO:0000016' => [
                                                                               '20',
                                                                               '2016-04-27 12:12:20-0500'
                                                                             ]
                                        },
                      'test_trial211' => {
                                           'fresh shoot weight|CO:0000016' => [
                                                                                '30',
                                                                                '2016-04-27 03:12:20-0500'
                                                                              ],
                                           'fresh root weight|CO:0000012' => [
                                                                               '15',
                                                                               '2016-04-27 03:12:20-0500'
                                                                             ],
                                           'harvest index|CO:0000015' => [
                                                                           '10.8',
                                                                           '2016-04-27 03:12:20-0500'
                                                                         ],
                                           'dry matter content|CO:0000092' => [
                                                                                '38',
                                                                                '2016-04-27 03:12:20-0500'
                                                                              ]
                                         },
                      'test_trial29' => {
                                          'dry matter content|CO:0000092' => [
                                                                               '35',
                                                                               '2016-04-27 14:12:20-0500'
                                                                             ],
                                          'fresh root weight|CO:0000012' => [
                                                                              '15',
                                                                              '2016-04-27 14:12:20-0500'
                                                                            ],
                                          'harvest index|CO:0000015' => [
                                                                          '8.8',
                                                                          '2016-04-27 14:12:20-0500'
                                                                        ],
                                          'fresh shoot weight|CO:0000016' => [
                                                                               '28',
                                                                               '2016-04-27 14:12:20-0500'
                                                                             ]
                                        },
                      'test_trial214' => {
                                           'fresh shoot weight|CO:0000016' => [
                                                                                '33',
                                                                                '2016-04-27 23:12:20-0500'
                                                                              ],
                                           'fresh root weight|CO:0000012' => [
                                                                               '15',
                                                                               '2016-04-27 23:12:20-0500'
                                                                             ],
                                           'harvest index|CO:0000015' => [
                                                                           '13.8',
                                                                           '2016-04-27 23:12:20-0500'
                                                                         ],
                                           'dry matter content|CO:0000092' => [
                                                                                '30',
                                                                                '2016-04-27 23:12:20-0500'
                                                                              ]
                                         },
                      'test_trial212' => {
                                           'harvest index|CO:0000015' => [
                                                                           '11.8',
                                                                           '2016-04-27 21:12:20-0500'
                                                                         ],
                                           'fresh root weight|CO:0000012' => [
                                                                               '15',
                                                                               '2016-04-27 21:12:20-0500'
                                                                             ],
                                           'dry matter content|CO:0000092' => [
                                                                                '39',
                                                                                '2016-04-27 21:12:20-0500'
                                                                              ],
                                           'fresh shoot weight|CO:0000016' => [
                                                                                '31',
                                                                                '2016-04-27 21:12:20-0500'
                                                                              ]
                                         },
                      'test_trial23' => {
                                          'fresh shoot weight|CO:0000016' => [
                                                                               '22',
                                                                               '2016-04-27 01:12:20-0500'
                                                                             ],
                                          'dry matter content|CO:0000092' => [
                                                                               '38',
                                                                               '2016-04-27 01:12:20-0500'
                                                                             ],
                                          'fresh root weight|CO:0000012' => [
                                                                              '15',
                                                                              '2016-04-27 01:12:20-0500'
                                                                            ],
                                          'harvest index|CO:0000015' => [
                                                                          '2.8',
                                                                          '2016-04-27 01:12:20-0500'
                                                                        ]
                                        },
                      'test_trial26' => {
                                          'fresh shoot weight|CO:0000016' => [
                                                                               '25',
                                                                               '2016-04-27 16:12:20-0500'
                                                                             ],
                                          'harvest index|CO:0000015' => [
                                                                          '5.8',
                                                                          '2016-04-27 16:12:20-0500'
                                                                        ],
                                          'fresh root weight|CO:0000012' => [
                                                                              '15',
                                                                              '2016-04-27 16:12:20-0500'
                                                                            ],
                                          'dry matter content|CO:0000092' => [
                                                                               '30',
                                                                               '2016-04-27 16:12:20-0500'
                                                                             ]
                                        },
                      'test_trial210' => {
                                           'fresh shoot weight|CO:0000016' => [
                                                                                '29',
                                                                                '2016-04-27 15:12:20-0500'
                                                                              ],
                                           'dry matter content|CO:0000092' => [
                                                                                '30',
                                                                                '2016-04-27 15:12:20-0500'
                                                                              ],
                                           'harvest index|CO:0000015' => [
                                                                           '9.8',
                                                                           '2016-04-27 15:12:20-0500'
                                                                         ],
                                           'fresh root weight|CO:0000012' => [
                                                                               '15',
                                                                               '2016-04-27 15:12:20-0500'
                                                                             ]
                                         },
                      'test_trial28' => {
                                          'dry matter content|CO:0000092' => [
                                                                               '39',
                                                                               '2016-04-27 13:12:20-0500'
                                                                             ],
                                          'harvest index|CO:0000015' => [
                                                                          '7.8',
                                                                          '2016-04-27 13:12:20-0500'
                                                                        ],
                                          'fresh root weight|CO:0000012' => [
                                                                              '15',
                                                                              '2016-04-27 13:12:20-0500'
                                                                            ],
                                          'fresh shoot weight|CO:0000016' => [
                                                                               '27',
                                                                               '2016-04-27 13:12:20-0500'
                                                                             ]
                                        },
                      'test_trial22' => {
                                          'fresh shoot weight|CO:0000016' => [
                                                                               '21',
                                                                               '2016-04-27 02:12:20-0500'
                                                                             ],
                                          'harvest index|CO:0000015' => [
                                                                          '1.8',
                                                                          '2016-04-27 02:12:20-0500'
                                                                        ],
                                          'fresh root weight|CO:0000012' => [
                                                                              '15',
                                                                              '2016-04-27 02:12:20-0500'
                                                                            ],
                                          'dry matter content|CO:0000092' => [
                                                                               '30',
                                                                               '2016-04-27 02:12:20-0500'
                                                                             ]
                                        },
                      'test_trial213' => {
                                           'dry matter content|CO:0000092' => [
                                                                                '35',
                                                                                '2016-04-27 22:12:20-0500'
                                                                              ],
                                           'fresh root weight|CO:0000012' => [
                                                                               '15',
                                                                               '2016-04-27 22:12:20-0500'
                                                                             ],
                                           'harvest index|CO:0000015' => [
                                                                           '12.8',
                                                                           '2016-04-27 22:12:20-0500'
                                                                         ],
                                           'fresh shoot weight|CO:0000016' => [
                                                                                '32',
                                                                                '2016-04-27 22:12:20-0500'
                                                                              ]
                                         }
                    },
          'plots' => [
                       'test_trial21',
                       'test_trial210',
                       'test_trial211',
                       'test_trial212',
                       'test_trial213',
                       'test_trial214',
                       'test_trial215',
                       'test_trial22',
                       'test_trial23',
                       'test_trial24',
                       'test_trial25',
                       'test_trial26',
                       'test_trial27',
                       'test_trial28',
                       'test_trial29'
                     ],
          'traits' => [
                        'dry matter content|CO:0000092',
                        'fresh root weight|CO:0000012',
                        'fresh shoot weight|CO:0000016',
                        'harvest index|CO:0000015'
                      ]
             }, "Check parse phenotyping spreadsheet" );


my %phenotype_metadata;
$phenotype_metadata{'archived_file'} = $filename;
$phenotype_metadata{'archived_file_type'}="spreadsheet phenotype file";
$phenotype_metadata{'operator'}="janedoe";
$phenotype_metadata{'date'}="2016-02-16_01:10:56";
my %parsed_data = %{$parsed_file->{'data'}};
my @plots = @{$parsed_file->{'plots'}};
my @traits = @{$parsed_file->{'traits'}};

my $store_phenotypes = CXGN::Phenotypes::StorePhenotypes->new();
my $size = scalar(@plots) * scalar(@traits);
my $stored_phenotype_error_msg = $store_phenotypes->store($c,$size,\@plots,\@traits, \%parsed_data, \%phenotype_metadata);
ok(!$stored_phenotype_error_msg, "check that store pheno spreadsheet works");

my $tn = CXGN::Trial->new( { bcs_schema => $f->bcs_schema(),
				trial_id => 137 });

my $traits_assayed  = $tn->get_traits_assayed();
my @traits_assayed_sorted = sort {$a->[0] cmp $b->[0]} @$traits_assayed;
#print STDERR Dumper @traits_assayed_sorted;
my @traits_assayed_check = ([70666,'Fresh root weight'], [70668,'Harvest index variable'], [70741,'Dry matter content percentage'], [70773,'Fresh shoot weight measurement in kg']);
is_deeply(\@traits_assayed_sorted, \@traits_assayed_check, 'check traits assayed from phenotyping spreadsheet upload' );

my @pheno_for_trait = $tn->get_phenotypes_for_trait(70666);
my @pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
my @pheno_for_trait_check = ('15','15','15','15','15','15','15','15','15','15','15','15','15','15','15');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70666 from phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70668);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('0.8','1.8','2.8','3.8','4.8','5.8','6.8','7.8','8.8','9.8','10.8','11.8','12.8','13.8','14.8');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70668 from phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70741);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('30','30','30','30','35','35','35','35','38','38','38','38','39','39','39');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70741 from phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70773);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('20','21','22','23','24','25','26','27','28','29','30','31','32','33','34');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70773 from phenotyping spreadsheet upload' );


$experiment = $c->bcs_schema->resultset('NaturalDiversity::NdExperiment')->search({type_id => $phenotyping_experiment_cvterm_id});
my $post1_experiment_count = $experiment->count();
my $post1_experiment_diff = $post1_experiment_count - $pre_experiment_count;
print STDERR "Experiment count: ".$post1_experiment_diff."\n";
ok($post1_experiment_diff == 60, "Check num rows in NdExperiment table after addition of phenotyping spreadsheet upload");

$phenotype_rs = $c->bcs_schema->resultset('Phenotype::Phenotype')->search({});
my $post1_phenotype_count = $phenotype_rs->count();
my $post1_phenotype_diff = $post1_phenotype_count - $pre_phenotype_count;
print STDERR "Phenotype count: ".$post1_phenotype_diff."\n";
ok($post1_phenotype_diff == 60, "Check num rows in Phenotype table after addition of phenotyping spreadsheet upload");

$exp_prop_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentprop')->search({});
my $post1_exp_prop_count = $exp_prop_rs->count();
my $post1_exp_prop_diff = $post1_exp_prop_count - $pre_exp_prop_count;
print STDERR "Experimentprop count: ".$post1_exp_prop_diff."\n";
ok($post1_exp_prop_diff == 120, "Check num rows in Experimentprop table after addition of phenotyping spreadsheet upload");

$exp_proj_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentProject')->search({});
my $post1_exp_proj_count = $exp_proj_rs->count();
my $post1_exp_proj_diff = $post1_exp_proj_count - $pre_exp_proj_count;
print STDERR "Experimentproject count: ".$post1_exp_proj_diff."\n";
ok($post1_exp_proj_diff == 60, "Check num rows in NdExperimentproject table after addition of phenotyping spreadsheet upload");

$exp_stock_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentStock')->search({});
my $post1_exp_stock_count = $exp_stock_rs->count();
my $post1_exp_stock_diff = $post1_exp_stock_count - $pre_exp_stock_count;
print STDERR "Experimentstock count: ".$post1_exp_stock_diff."\n";
ok($post1_exp_stock_diff == 60, "Check num rows in NdExperimentstock table after addition of phenotyping spreadsheet upload");

$exp_pheno_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentPhenotype')->search({});
my $post1_exp_pheno_count = $exp_pheno_rs->count();
my $post1_exp_pheno_diff = $post1_exp_pheno_count - $pre_exp_pheno_count;
print STDERR "Experimentphenotype count: ".$post1_exp_pheno_diff."\n";
ok($post1_exp_pheno_diff == 60, "Check num rows in NdExperimentphenotype table after addition of phenotyping spreadsheet upload");

$md_rs = $c->metadata_schema->resultset('MdMetadata')->search({});
my $post1_md_count = $md_rs->count();
my $post1_md_diff = $post1_md_count - $pre_md_count;
print STDERR "MdMetadata count: ".$post1_md_diff."\n";
ok($post1_md_diff == 1, "Check num rows in MdMetadata table after addition of phenotyping spreadsheet upload");

$md_files_rs = $c->metadata_schema->resultset('MdFiles')->search({});
my $post1_md_files_count = $md_files_rs->count();
my $post1_md_files_diff = $post1_md_files_count - $pre_md_files_count;
print STDERR "MdFiles count: ".$post1_md_files_diff."\n";
ok($post1_md_files_diff == 1, "Check num rows in MdFiles table after addition of phenotyping spreadsheet upload");

$exp_md_files_rs = $c->phenome_schema->resultset('NdExperimentMdFiles')->search({});
my $post1_exp_md_files_count = $exp_md_files_rs->count();
my $post1_exp_md_files_diff = $post1_exp_md_files_count - $pre_exp_md_files_count;
print STDERR "Experimentphenotype count: ".$post1_exp_md_files_diff."\n";
ok($post1_exp_md_files_diff == 60, "Check num rows in NdExperimentMdFIles table after addition of phenotyping spreadsheet upload");




#Check what happens on duplication of plot_name, trait, and value. timestamps must be unique or it will not be uploaded.

$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/trial/upload_phenotypin_spreadsheet_duplicate.xls";
$validate_file = $parser->validate('phenotype spreadsheet', $filename);
ok($validate_file == 1, "Check if parse validate works for phenotype file");

my $parsed_file = $parser->parse('phenotype spreadsheet', $filename);
ok($parsed_file, "Check if parse parse phenotype spreadsheet works");

my %phenotype_metadata;
$phenotype_metadata{'archived_file'} = $filename;
$phenotype_metadata{'archived_file_type'}="spreadsheet phenotype file";
$phenotype_metadata{'operator'}="janedoe";
$phenotype_metadata{'date'}="2016-02-22_01:10:56";
my %parsed_data = %{$parsed_file->{'data'}};
my @plots = @{$parsed_file->{'plots'}};
my @traits = @{$parsed_file->{'traits'}};

$store_phenotypes = CXGN::Phenotypes::StorePhenotypes->new();
$stored_phenotype_error_msg = $store_phenotypes->store($c,$size,\@plots,\@traits, \%parsed_data, \%phenotype_metadata);
ok(!$stored_phenotype_error_msg, "check that store pheno spreadsheet works");

my $traits_assayed  = $tn->get_traits_assayed();
my @traits_assayed_sorted = sort {$a->[0] cmp $b->[0]} @$traits_assayed;
#print STDERR Dumper @traits_assayed_sorted;
my @traits_assayed_check = ([70666,'Fresh root weight'], [70668,'Harvest index variable'], [70741,'Dry matter content percentage'], [70773,'Fresh shoot weight measurement in kg']);
is_deeply(\@traits_assayed_sorted, \@traits_assayed_check, 'check traits assayed from phenotyping spreadsheet upload' );

my @pheno_for_trait = $tn->get_phenotypes_for_trait(70666);
my @pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
my @pheno_for_trait_check = ('15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70666 from phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70668);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('0.8','0.8','1.8','1.8','2.8','2.8','3.8','3.8','4.8','4.8','5.8','5.8','6.8','6.8','7.8','7.8','8.8','8.8','9.8','9.8','10.8','10.8','11.8','11.8','12.8','12.8','13.8','13.8','14.8','14.8');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70668 from phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70741);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('30','30','30','30','30','30','30','30','35','35','35','35','35','35','35','35','38','38','38','38','38','38','38','38','39','39','39','39','39','39');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70741 from phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70773);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('20','20','21','21','22','22','23','23','24','24','25','25','26','26','27','27','28','28','29','29','30','30','31','31','32','32','33','33','34','34');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70773 from phenotyping spreadsheet upload' );


$experiment = $c->bcs_schema->resultset('NaturalDiversity::NdExperiment')->search({type_id => $phenotyping_experiment_cvterm_id});
my $post2_experiment_count = $experiment->count();
my $post2_experiment_diff = $post2_experiment_count - $pre_experiment_count;
print STDERR "Experiment count: ".$post2_experiment_diff."\n";
ok($post2_experiment_diff == 120, "Check num rows in NdExperiment table after second addition of phenotyping spreadsheet upload");

$phenotype_rs = $c->bcs_schema->resultset('Phenotype::Phenotype')->search({});
my $post2_phenotype_count = $phenotype_rs->count();
my $post2_phenotype_diff = $post2_phenotype_count - $pre_phenotype_count;
print STDERR "Phenotype count: ".$post2_phenotype_diff."\n";
ok($post2_phenotype_diff == 120, "Check num rows in Phenotype table after second addition of phenotyping spreadsheet upload");

$exp_prop_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentprop')->search({});
my $post2_exp_prop_count = $exp_prop_rs->count();
my $post2_exp_prop_diff = $post2_exp_prop_count - $pre_exp_prop_count;
print STDERR "Experimentprop count: ".$post2_exp_prop_diff."\n";
ok($post2_exp_prop_diff == 240, "Check num rows in Experimentprop table after second addition of phenotyping spreadsheet upload");

$exp_proj_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentProject')->search({});
my $post2_exp_proj_count = $exp_proj_rs->count();
my $post2_exp_proj_diff = $post2_exp_proj_count - $pre_exp_proj_count;
print STDERR "Experimentproject count: ".$post2_exp_proj_diff."\n";
ok($post2_exp_proj_diff == 120, "Check num rows in NdExperimentproject table after second addition of phenotyping spreadsheet upload");

$exp_stock_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentStock')->search({});
my $post2_exp_stock_count = $exp_stock_rs->count();
my $post2_exp_stock_diff = $post2_exp_stock_count - $pre_exp_stock_count;
print STDERR "Experimentstock count: ".$post2_exp_stock_diff."\n";
ok($post2_exp_stock_diff == 120, "Check num rows in NdExperimentstock table after second addition of phenotyping spreadsheet upload");

$exp_pheno_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentPhenotype')->search({});
my $post2_exp_pheno_count = $exp_pheno_rs->count();
my $post2_exp_pheno_diff = $post2_exp_pheno_count - $pre_exp_pheno_count;
print STDERR "Experimentphenotype count: ".$post2_exp_pheno_diff."\n";
ok($post2_exp_pheno_diff == 120, "Check num rows in NdExperimentphenotype table after second addition of phenotyping spreadsheet upload");

$md_rs = $c->metadata_schema->resultset('MdMetadata')->search({});
my $post2_md_count = $md_rs->count();
my $post2_md_diff = $post2_md_count - $pre_md_count;
print STDERR "MdMetadata count: ".$post2_md_diff."\n";
ok($post2_md_diff == 2, "Check num rows in MdMetadata table after second addition of phenotyping spreadsheet upload");

$md_files_rs = $c->metadata_schema->resultset('MdFiles')->search({});
my $post2_md_files_count = $md_files_rs->count();
my $post2_md_files_diff = $post2_md_files_count - $pre_md_files_count;
print STDERR "MdFiles count: ".$post2_md_files_diff."\n";
ok($post2_md_files_diff == 2, "Check num rows in MdFiles table after second addition of phenotyping spreadsheet upload");

$exp_md_files_rs = $c->phenome_schema->resultset('NdExperimentMdFiles')->search({});
my $post2_exp_md_files_count = $exp_md_files_rs->count();
my $post2_exp_md_files_diff = $post2_exp_md_files_count - $pre_exp_md_files_count;
print STDERR "Experimentphenotype count: ".$post2_exp_md_files_diff."\n";
ok($post2_exp_md_files_diff == 120, "Check num rows in NdExperimentMdFIles table after second addition of phenotyping spreadsheet upload");




#####################################
#Tests for fieldbook file parsing

#check that parse fails for spreadsheet file when using fieldbook parser
$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/trial/upload_phenotypin_spreadsheet.xls";
$validate_file = $parser->validate('field book', $filename);
ok($validate_file != 1, "Check if parse validate fieldbook fails for spreadsheet file");

#check that parse fails for datacollector file when using fieldbook parser
$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/trial/data_collector_upload.xls";
$validate_file = $parser->validate('field book', $filename);
ok($validate_file != 1, "Check if parse validate fieldbook fails for datacollector");

#Now parse phenotyping spreadsheet file using correct parser
$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/fieldbook/fieldbook_phenotype_file.csv";
$validate_file = $parser->validate('field book', $filename);
ok($validate_file == 1, "Check if parse validate works for fieldbook");

$parsed_file = $parser->parse('field book', $filename);
ok($parsed_file, "Check if parse parse fieldbook works");

#print STDERR Dumper $parsed_file;

is_deeply($parsed_file, {
	'data' => {
	                      'test_trial212' => {
	                                           'dry matter content|CO:0000092' => [
	                                                                                '42',
	                                                                                '2016-01-07 12:09:02-0500'
	                                                                              ],
	                                           'dry yield|CO:0000014' => [
	                                                                       '42',
	                                                                       '2016-01-07 12:09:02-0500'
	                                                                     ]
	                                         },
	                      'test_trial23' => {
	                                          'dry matter content|CO:0000092' => [
	                                                                               '41',
	                                                                               '2016-01-07 12:08:27-0500'
	                                                                             ],
	                                          'dry yield|CO:0000014' => [
	                                                                      '41',
	                                                                      '2016-01-07 12:08:27-0500'
	                                                                    ]
	                                        },
	                      'test_trial24' => {
	                                          'dry yield|CO:0000014' => [
	                                                                      '14',
	                                                                      '2016-01-07 12:08:46-0500'
	                                                                    ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '14',
	                                                                               '2016-01-07 12:08:46-0500'
	                                                                             ]
	                                        },
	                      'test_trial25' => {
	                                          'dry matter content|CO:0000092' => [
	                                                                               '25',
	                                                                               '2016-01-07 12:08:48-0500'
	                                                                             ],
	                                          'dry yield|CO:0000014' => [
	                                                                      '25',
	                                                                      '2016-01-07 12:08:48-0500'
	                                                                    ]
	                                        },
	                      'test_trial28' => {
	                                          'dry matter content|CO:0000092' => [
	                                                                               '41',
	                                                                               '2016-01-07 12:08:53-0500'
	                                                                             ],
	                                          'dry yield|CO:0000014' => [
	                                                                      '41',
	                                                                      '2016-01-07 12:08:53-0500'
	                                                                    ]
	                                        },
	                      'test_trial21' => {
	                                          'dry yield|CO:0000014' => [
	                                                                      '42',
	                                                                      '2016-01-07 12:08:24-0500'
	                                                                    ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '42',
	                                                                               '2016-01-07 12:08:24-0500'
	                                                                             ]
	                                        },
	                      'test_trial211' => {
	                                           'dry matter content|CO:0000092' => [
	                                                                                '13',
	                                                                                '2016-01-07 12:08:58-0500'
	                                                                              ],
	                                           'dry yield|CO:0000014' => [
	                                                                       '13',
	                                                                       '2016-01-07 12:08:58-0500'
	                                                                     ]
	                                         },
	                      'test_trial213' => {
	                                           'dry yield|CO:0000014' => [
	                                                                       '35',
	                                                                       '2016-01-07 12:09:04-0500'
	                                                                     ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '35',
	                                                                                '2016-01-07 12:09:04-0500'
	                                                                              ]
	                                         },
	                      'test_trial29' => {
	                                          'dry matter content|CO:0000092' => [
	                                                                               '',
	                                                                               '2016-01-07 12:08:55-0500'
	                                                                             ],
	                                          'dry yield|CO:0000014' => [
	                                                                      '24',
	                                                                      '2016-01-07 12:08:55-0500'
	                                                                    ]
	                                        },
	                      'test_trial215' => {
	                                           'dry matter content|CO:0000092' => [
	                                                                                '31',
	                                                                                '2016-01-07 12:09:07-0500'
	                                                                              ],
	                                           'dry yield|CO:0000014' => [
	                                                                       '31',
	                                                                       '2016-01-07 12:09:07-0500'
	                                                                     ]
	                                         },
	                      'test_trial214' => {
	                                           'dry yield|CO:0000014' => [
	                                                                       '32',
	                                                                       '2016-01-07 12:09:05-0500'
	                                                                     ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '32',
	                                                                                '2016-01-07 12:09:05-0500'
	                                                                              ]
	                                         },
	                      'test_trial27' => {
	                                          'dry matter content|CO:0000092' => [
	                                                                               '52',
	                                                                               '2016-01-07 12:08:51-0500'
	                                                                             ],
	                                          'dry yield|CO:0000014' => [
	                                                                      '0',
	                                                                      '2016-01-07 12:08:51-0500'
	                                                                    ]
	                                        },
	                      'test_trial26' => {
	                                          'dry matter content|CO:0000092' => [
	                                                                               '',
	                                                                               '2016-01-07 12:08:49-0500'
	                                                                             ],
	                                          'dry yield|CO:0000014' => [
	                                                                      '0',
	                                                                      '2016-01-07 12:08:49-0500'
	                                                                    ]
	                                        },
	                      'test_trial22' => {
	                                          'dry yield|CO:0000014' => [
	                                                                      '45',
	                                                                      '2016-01-07 12:08:26-0500'
	                                                                    ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '45',
	                                                                               '2016-01-07 12:08:26-0500'
	                                                                             ]
	                                        },
	                      'test_trial210' => {
	                                           'dry matter content|CO:0000092' => [
	                                                                                '12',
	                                                                                '2016-01-07 12:08:56-0500'
	                                                                              ],
	                                           'dry yield|CO:0000014' => [
	                                                                       '12',
	                                                                       '2016-01-07 12:08:56-0500'
	                                                                     ]
	                                         }
	                    },
	          'plots' => [
	                       'test_trial21',
	                       'test_trial210',
	                       'test_trial211',
	                       'test_trial212',
	                       'test_trial213',
	                       'test_trial214',
	                       'test_trial215',
	                       'test_trial22',
	                       'test_trial23',
	                       'test_trial24',
	                       'test_trial25',
	                       'test_trial26',
	                       'test_trial27',
	                       'test_trial28',
	                       'test_trial29'
	                     ],
	          'traits' => [
	                        'dry matter content|CO:0000092',
	                        'dry yield|CO:0000014'
	                      ]
        }, "Check parse fieldbook");


$phenotype_metadata{'archived_file'} = $filename;
$phenotype_metadata{'archived_file_type'}="tablet phenotype file";
$phenotype_metadata{'operator'}="janedoe";
$phenotype_metadata{'date'}="2016-01-16_03:15:26";
%parsed_data = %{$parsed_file->{'data'}};
@plots = @{$parsed_file->{'plots'}};
@traits = @{$parsed_file->{'traits'}};

$store_phenotypes = CXGN::Phenotypes::StorePhenotypes->new();
$size = scalar(@plots) * scalar(@traits);
$stored_phenotype_error_msg = $store_phenotypes->store($c,$size,\@plots,\@traits, \%parsed_data, \%phenotype_metadata);
ok(!$stored_phenotype_error_msg, "check that store fieldbook works");

$tn = CXGN::Trial->new( { bcs_schema => $f->bcs_schema(),
				trial_id => 137 });

$traits_assayed  = $tn->get_traits_assayed();
@traits_assayed_sorted = sort {$a->[0] cmp $b->[0]} @$traits_assayed;
#print STDERR Dumper @traits_assayed_sorted;
@traits_assayed_check = ([70666,'Fresh root weight'], [70668,'Harvest index variable'], [70727, 'Dry yield'], [70741,'Dry matter content percentage'], [70773,'Fresh shoot weight measurement in kg']);
is_deeply(\@traits_assayed_sorted, \@traits_assayed_check, 'check traits assayed from phenotyping spreadsheet upload' );

my @pheno_for_trait = $tn->get_phenotypes_for_trait(70727);
my @pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('0','0','12','13','14','24','25','31','32','35','41','41','42','42','45');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70727 from phenotyping spreadsheet upload' );

my @pheno_for_trait = $tn->get_phenotypes_for_trait(70741);
my @pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('12','13','14','25','30','30','30','30','30','30','30','30','31','32','35','35','35','35','35','35','35','35','35','38','38','38','38','38','38','38','38','39','39','39','39','39','39','41','41','42','42','45','52');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70741 from phenotyping spreadsheet upload' );


$experiment = $c->bcs_schema->resultset('NaturalDiversity::NdExperiment')->search({type_id => $phenotyping_experiment_cvterm_id});
$post1_experiment_count = $experiment->count();
$post1_experiment_diff = $post1_experiment_count - $pre_experiment_count;
print STDERR "Experiment count: ".$post1_experiment_diff."\n";
ok($post1_experiment_diff == 148, "Check num rows in NdExperiment table after addition of fieldbook upload");

$phenotype_rs = $c->bcs_schema->resultset('Phenotype::Phenotype')->search({});
$post1_phenotype_count = $phenotype_rs->count();
$post1_phenotype_diff = $post1_phenotype_count - $pre_phenotype_count;
print STDERR "Phenotype count: ".$post1_phenotype_diff."\n";
ok($post1_phenotype_diff == 148, "Check num rows in Phenotype table after addition of fieldbook upload");

$exp_prop_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentprop')->search({});
$post1_exp_prop_count = $exp_prop_rs->count();
$post1_exp_prop_diff = $post1_exp_prop_count - $pre_exp_prop_count;
print STDERR "Experimentprop count: ".$post1_exp_prop_diff."\n";
ok($post1_exp_prop_diff == 296, "Check num rows in Experimentprop table after addition of fieldbook upload");

$exp_proj_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentProject')->search({});
$post1_exp_proj_count = $exp_proj_rs->count();
$post1_exp_proj_diff = $post1_exp_proj_count - $pre_exp_proj_count;
print STDERR "Experimentproject count: ".$post1_exp_proj_diff."\n";
ok($post1_exp_proj_diff == 148, "Check num rows in NdExperimentproject table after addition of fieldbook upload");

$exp_stock_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentStock')->search({});
$post1_exp_stock_count = $exp_stock_rs->count();
$post1_exp_stock_diff = $post1_exp_stock_count - $pre_exp_stock_count;
print STDERR "Experimentstock count: ".$post1_exp_stock_diff."\n";
ok($post1_exp_stock_diff == 148, "Check num rows in NdExperimentstock table after addition of fieldbook upload");

$exp_pheno_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentPhenotype')->search({});
my $post1_exp_pheno_count = $exp_pheno_rs->count();
my $post1_exp_pheno_diff = $post1_exp_pheno_count - $pre_exp_pheno_count;
print STDERR "Experimentphenotype count: ".$post1_exp_pheno_diff."\n";
ok($post1_exp_pheno_diff == 148, "Check num rows in NdExperimentphenotype table after addition of fieldbook upload");

$md_rs = $c->metadata_schema->resultset('MdMetadata')->search({});
my $post1_md_count = $md_rs->count();
my $post1_md_diff = $post1_md_count - $pre_md_count;
print STDERR "MdMetadata count: ".$post1_md_diff."\n";
ok($post1_md_diff == 3, "Check num rows in MdMetadata table after addition of fieldbook upload");

$md_files_rs = $c->metadata_schema->resultset('MdFiles')->search({});
my $post1_md_files_count = $md_files_rs->count();
my $post1_md_files_diff = $post1_md_files_count - $pre_md_files_count;
print STDERR "MdFiles count: ".$post1_md_files_diff."\n";
ok($post1_md_files_diff == 3, "Check num rows in MdFiles table after addition of fieldbook upload");

$exp_md_files_rs = $c->phenome_schema->resultset('NdExperimentMdFiles')->search({});
my $post1_exp_md_files_count = $exp_md_files_rs->count();
my $post1_exp_md_files_diff = $post1_exp_md_files_count - $pre_exp_md_files_count;
print STDERR "Experimentphenotype count: ".$post1_exp_md_files_diff."\n";
ok($post1_exp_md_files_diff == 148, "Check num rows in NdExperimentMdFIles table after addition fieldbook upload");




#####################################
#Tests for datacollector file parsing

#check that parse fails for spreadsheet file when using datacollector parser
$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/trial/upload_phenotypin_spreadsheet.xls";
$validate_file = $parser->validate('datacollector spreadsheet', $filename);
ok($validate_file != 1, "Check if parse validate datacollector fails for spreadsheet file");

#check that parse fails for fieldbook file when using datacollector parser
$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/fieldbook/fieldbook_phenotype_file.csv";
$validate_file = $parser->validate('datacollector spreadsheet', $filename);
ok($validate_file != 1, "Check if parse validate datacollector fails for fieldbook");

#Now parse datacollector file using correct parser
$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/trial/data_collector_upload.xls";
$validate_file = $parser->validate('datacollector spreadsheet', $filename);
ok($validate_file == 1, "Check if parse validate worksfor datacollector");

$parsed_file = $parser->parse('datacollector spreadsheet', $filename);
ok($parsed_file, "Check if parse parse datacollector works");

#print STDERR Dumper $parsed_file;

is_deeply($parsed_file, {
	'data' => {
	                      'test_trial215' => {
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '24',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'harvest index|CO:0000015' => [
	                                                                           '0.8',
	                                                                           '2016-04-21 08:20:12-0500'
	                                                                         ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '49',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '50',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ]
	                                         },
	                      'test_trial28' => {
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '43',
	                                                                              '2016-04-21 08:20:12-0500'
	                                                                            ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '0.8',
	                                                                          '2016-04-21 08:20:12-0500'
	                                                                        ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '42',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '17',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ]
	                                        },
	                      'test_trial26' => {
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '41',
	                                                                              '2016-04-21 08:20:12-0500'
	                                                                            ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '15',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '0.8',
	                                                                          '2016-04-21 08:20:12-0500'
	                                                                        ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ]
	                                        },
	                      'test_trial29' => {
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '',
	                                                                              '2016-04-21 08:20:12-0500'
	                                                                            ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '0.8',
	                                                                          '2016-04-21 08:20:12-0500'
	                                                                        ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '18',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '43',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ]
	                                        },
	                      'test_trial214' => {
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '49',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                           'harvest index|CO:0000015' => [
	                                                                           '0.8',
	                                                                           '2016-04-21 08:20:12-0500'
	                                                                         ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '48',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '23',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ]
	                                         },
	                      'test_trial210' => {
	                                           'dry matter content|CO:0000092' => [
	                                                                                '44',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'harvest index|CO:0000015' => [
	                                                                           '0.8',
	                                                                           '2016-04-21 08:20:12-0500'
	                                                                         ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '19',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '45',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ]
	                                         },
	                      'test_trial211' => {
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '46',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '20',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'harvest index|CO:0000015' => [
	                                                                           '0.8',
	                                                                           '2016-04-21 08:20:12-0500'
	                                                                         ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '45',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ]
	                                         },
	                      'test_trial22' => {
	                                          'harvest index|CO:0000015' => [
	                                                                          '0.8',
	                                                                          '2016-04-21 08:20:12-0500'
	                                                                        ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '36',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '11',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '37',
	                                                                              '2016-04-21 08:20:12-0500'
	                                                                            ]
	                                        },
	                      'test_trial25' => {
	                                          'harvest index|CO:0000015' => [
	                                                                          '0.8',
	                                                                          '2016-04-21 08:20:12-0500'
	                                                                        ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '14',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '39',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '40',
	                                                                              '2016-04-21 08:20:12-0500'
	                                                                            ]
	                                        },
	                      'test_trial23' => {
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '38',
	                                                                              '2016-04-21 08:20:12-0500'
	                                                                            ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '12',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '0.8',
	                                                                          '2016-04-21 08:20:12-0500'
	                                                                        ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '37',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ]
	                                        },
	                      'test_trial24' => {
	                                          'harvest index|CO:0000015' => [
	                                                                          '0',
	                                                                          '2016-04-21 08:20:12-0500'
	                                                                        ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '13',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '38',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '39',
	                                                                              '2016-04-21 08:20:12-0500'
	                                                                            ]
	                                        },
	                      'test_trial21' => {
	                                          'harvest index|CO:0000015' => [
	                                                                          '0.8',
	                                                                          '2016-04-21 08:20:12-0500'
	                                                                        ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '10',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '35',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '36',
	                                                                              '2016-04-21 08:20:12-0500'
	                                                                            ]
	                                        },
	                      'test_trial212' => {
	                                           'harvest index|CO:0000015' => [
	                                                                           '0.8',
	                                                                           '2016-04-21 08:20:12-0500'
	                                                                         ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '46',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '21',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '47',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ]
	                                         },
	                      'test_trial27' => {
	                                          'harvest index|CO:0000015' => [
	                                                                          '0',
	                                                                          '2016-04-21 08:20:12-0500'
	                                                                        ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '16',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '42',
	                                                                              '2016-04-21 08:20:12-0500'
	                                                                            ]
	                                        },
	                      'test_trial213' => {
	                                           'harvest index|CO:0000015' => [
	                                                                           '0.8',
	                                                                           '2016-04-21 08:20:12-0500'
	                                                                         ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '47',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '22',
	                                                                                '2016-04-21 08:20:12-0500'
	                                                                              ],
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '48',
	                                                                               '2016-04-21 08:20:12-0500'
	                                                                             ]
	                                         }
	                    },
	          'traits' => [
	                        'dry matter content|CO:0000092',
	                        'fresh root weight|CO:0000012',
	                        'fresh shoot weight|CO:0000016',
	                        'harvest index|CO:0000015'
	                      ],
	          'plots' => [
	                       'test_trial21',
	                       'test_trial210',
	                       'test_trial211',
	                       'test_trial212',
	                       'test_trial213',
	                       'test_trial214',
	                       'test_trial215',
	                       'test_trial22',
	                       'test_trial23',
	                       'test_trial24',
	                       'test_trial25',
	                       'test_trial26',
	                       'test_trial27',
	                       'test_trial28',
	                       'test_trial29'
	                     ]
        }, "Check datacollector parse");


$phenotype_metadata{'archived_file'} = $filename;
$phenotype_metadata{'archived_file_type'}="tablet phenotype file";
$phenotype_metadata{'operator'}="janedoe";
$phenotype_metadata{'date'}="2016-02-16_07:11:98";
%parsed_data = %{$parsed_file->{'data'}};
@plots = @{$parsed_file->{'plots'}};
@traits = @{$parsed_file->{'traits'}};

$store_phenotypes = CXGN::Phenotypes::StorePhenotypes->new();
$size = scalar(@plots) * scalar(@traits);
$stored_phenotype_error_msg = $store_phenotypes->store($c,$size,\@plots,\@traits, \%parsed_data, \%phenotype_metadata);
ok(!$stored_phenotype_error_msg, "check that store fieldbook works");

$tn = CXGN::Trial->new( { bcs_schema => $f->bcs_schema(),
				trial_id => 137 });

$traits_assayed  = $tn->get_traits_assayed();
@traits_assayed_sorted = sort {$a->[0] cmp $b->[0]} @$traits_assayed;
#print STDERR Dumper @traits_assayed_sorted;
@traits_assayed_check = ([70666,'Fresh root weight'], [70668,'Harvest index variable'], [70727, 'Dry yield'], [70741,'Dry matter content percentage'], [70773,'Fresh shoot weight measurement in kg']);
is_deeply(\@traits_assayed_sorted, \@traits_assayed_check, 'check traits assayed from phenotyping spreadsheet upload' );

my @pheno_for_trait = $tn->get_phenotypes_for_trait(70666);
my @pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
my @pheno_for_trait_check = ('15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','36','37','38','39','40','41','42','43','45','46','47','48','49','50');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70666 from phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70668);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('0','0','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','1.8','1.8','2.8','2.8','3.8','3.8','4.8','4.8','5.8','5.8','6.8','6.8','7.8','7.8','8.8','8.8','9.8','9.8','10.8','10.8','11.8','11.8','12.8','12.8','13.8','13.8','14.8','14.8');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70668 from phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70741);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('12','13','14','25','30','30','30','30','30','30','30','30','31','32','35','35','35','35','35','35','35','35','35','35','36','37','38','38','38','38','38','38','38','38','38','39','39','39','39','39','39','39','41','41','42','42','42','43','44','45','45','46','47','48','49','52');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70741 from phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70773);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('10','11','12','13','14','15','16','17','18','19','20','20','20','21','21','21','22','22','22','23','23','23','24','24','24','25','25','26','26','27','27','28','28','29','29','30','30','31','31','32','32','33','33','34','34');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70773 from phenotyping spreadsheet upload' );


$experiment = $c->bcs_schema->resultset('NaturalDiversity::NdExperiment')->search({type_id => $phenotyping_experiment_cvterm_id});
$post1_experiment_count = $experiment->count();
$post1_experiment_diff = $post1_experiment_count - $pre_experiment_count;
print STDERR "Experiment count: ".$post1_experiment_diff."\n";
ok($post1_experiment_diff == 205, "Check num rows in NdExperiment table after addition of datacollector upload");

$phenotype_rs = $c->bcs_schema->resultset('Phenotype::Phenotype')->search({});
$post1_phenotype_count = $phenotype_rs->count();
$post1_phenotype_diff = $post1_phenotype_count - $pre_phenotype_count;
print STDERR "Phenotype count: ".$post1_phenotype_diff."\n";
ok($post1_phenotype_diff == 205, "Check num rows in Phenotype table after addition of datacollector upload");

$exp_prop_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentprop')->search({});
$post1_exp_prop_count = $exp_prop_rs->count();
$post1_exp_prop_diff = $post1_exp_prop_count - $pre_exp_prop_count;
print STDERR "Experimentprop count: ".$post1_exp_prop_diff."\n";
ok($post1_exp_prop_diff == 410, "Check num rows in Experimentprop table after addition of datacollector upload");

$exp_proj_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentProject')->search({});
$post1_exp_proj_count = $exp_proj_rs->count();
$post1_exp_proj_diff = $post1_exp_proj_count - $pre_exp_proj_count;
print STDERR "Experimentproject count: ".$post1_exp_proj_diff."\n";
ok($post1_exp_proj_diff == 205, "Check num rows in NdExperimentproject table after addition of datacollector upload");

$exp_stock_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentStock')->search({});
$post1_exp_stock_count = $exp_stock_rs->count();
$post1_exp_stock_diff = $post1_exp_stock_count - $pre_exp_stock_count;
print STDERR "Experimentstock count: ".$post1_exp_stock_diff."\n";
ok($post1_exp_stock_diff == 205, "Check num rows in NdExperimentstock table after addition of datacollector upload");

$exp_pheno_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentPhenotype')->search({});
my $post1_exp_pheno_count = $exp_pheno_rs->count();
my $post1_exp_pheno_diff = $post1_exp_pheno_count - $pre_exp_pheno_count;
print STDERR "Experimentphenotype count: ".$post1_exp_pheno_diff."\n";
ok($post1_exp_pheno_diff == 205, "Check num rows in NdExperimentphenotype table after addition of datacollector upload");

$md_rs = $c->metadata_schema->resultset('MdMetadata')->search({});
my $post1_md_count = $md_rs->count();
my $post1_md_diff = $post1_md_count - $pre_md_count;
print STDERR "MdMetadata count: ".$post1_md_diff."\n";
ok($post1_md_diff == 4, "Check num rows in MdMetadata table after addition of datacollector upload");

$md_files_rs = $c->metadata_schema->resultset('MdFiles')->search({});
my $post1_md_files_count = $md_files_rs->count();
my $post1_md_files_diff = $post1_md_files_count - $pre_md_files_count;
print STDERR "MdFiles count: ".$post1_md_files_diff."\n";
ok($post1_md_files_diff == 4, "Check num rows in MdFiles table after addition of datacollector upload");

$exp_md_files_rs = $c->phenome_schema->resultset('NdExperimentMdFiles')->search({});
my $post1_exp_md_files_count = $exp_md_files_rs->count();
my $post1_exp_md_files_diff = $post1_exp_md_files_count - $pre_exp_md_files_count;
print STDERR "Experimentphenotype count: ".$post1_exp_md_files_diff."\n";
ok($post1_exp_md_files_diff == 205, "Check num rows in NdExperimentMdFIles table after addition datacollector upload");



#Upload a large phenotyping spreadsheet (>100 entries)


$parser = CXGN::Phenotypes::ParseUpload->new();
$filename = "t/data/trial/upload_phenotypin_spreadsheet_large.xls";
$validate_file = $parser->validate('phenotype spreadsheet', $filename);
ok($validate_file == 1, "Check if parse validate works for large phenotype file");

$parsed_file = $parser->parse('phenotype spreadsheet', $filename);
ok($parsed_file, "Check if parse parse phenotype spreadsheet works");

#print STDERR Dumper $parsed_file;

is_deeply($parsed_file, {
	'data' => {
	                      'test_trial29' => {
	                                          'top yield|CO:0000017' => [
	                                                                      '3',
	                                                                      '2016-01-20 01:30:28-0500'
	                                                                    ],
	                                          'flower|CO:0000111' => [
	                                                                   '1',
	                                                                   '2016-01-20 01:30:28-0500'
	                                                                 ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '8.8',
	                                                                          '2016-01-20 01:30:28-0500'
	                                                                        ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '28',
	                                                                               '2016-01-20 01:30:28-0500'
	                                                                             ],
	                                          'root number|CO:0000011' => [
	                                                                        '6',
	                                                                        '2016-01-20 01:30:28-0500'
	                                                                      ],
	                                          'sprouting|CO:0000008' => [
	                                                                      '76',
	                                                                      '2016-01-20 01:30:28-0500'
	                                                                    ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '35',
	                                                                               '2016-01-20 01:30:28-0500'
	                                                                             ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '15',
	                                                                              '2016-01-20 01:30:28-0500'
	                                                                            ]
	                                        },
	                      'test_trial214' => {
	                                           'sprouting|CO:0000008' => [
	                                                                       '87',
	                                                                       '2016-01-20 01:30:33-0500'
	                                                                     ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '33',
	                                                                                '2016-01-20 01:30:33-0500'
	                                                                              ],
	                                           'root number|CO:0000011' => [
	                                                                         '4',
	                                                                         '2016-01-20 01:30:33-0500'
	                                                                       ],
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '15',
	                                                                               '2016-01-20 01:30:33-0500'
	                                                                             ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '30',
	                                                                                '2016-01-20 01:30:33-0500'
	                                                                              ],
	                                           'top yield|CO:0000017' => [
	                                                                       '7.5',
	                                                                       '2016-01-20 01:30:33-0500'
	                                                                     ],
	                                           'harvest index|CO:0000015' => [
	                                                                           '13.8',
	                                                                           '2016-01-20 01:30:33-0500'
	                                                                         ],
	                                           'flower|CO:0000111' => [
	                                                                    '1',
	                                                                    '2016-01-20 01:30:33-0500'
	                                                                  ]
	                                         },
	                      'test_trial24' => {
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '15',
	                                                                              '2016-01-20 01:30:23-0500'
	                                                                            ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '39',
	                                                                               '2016-01-20 01:30:23-0500'
	                                                                             ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '23',
	                                                                               '2016-01-20 01:30:23-0500'
	                                                                             ],
	                                          'root number|CO:0000011' => [
	                                                                        '11',
	                                                                        '2016-01-20 01:30:23-0500'
	                                                                      ],
	                                          'sprouting|CO:0000008' => [
	                                                                      '78',
	                                                                      '2016-01-20 01:30:23-0500'
	                                                                    ],
	                                          'flower|CO:0000111' => [
	                                                                   '1',
	                                                                   '2016-01-20 01:30:23-0500'
	                                                                 ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '3.8',
	                                                                          '2016-01-20 01:30:23-0500'
	                                                                        ],
	                                          'top yield|CO:0000017' => [
	                                                                      '7',
	                                                                      '2016-01-20 01:30:23-0500'
	                                                                    ]
	                                        },
	                      'test_trial25' => {
	                                          'top yield|CO:0000017' => [
	                                                                      '2',
	                                                                      '2016-01-20 01:30:24-0500'
	                                                                    ],
	                                          'flower|CO:0000111' => [
	                                                                   '1',
	                                                                   '2016-01-20 01:30:24-0500'
	                                                                 ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '',
	                                                                          '2016-01-20 01:30:24-0500'
	                                                                        ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '24',
	                                                                               '2016-01-20 01:30:24-0500'
	                                                                             ],
	                                          'root number|CO:0000011' => [
	                                                                        '6',
	                                                                        '2016-01-20 01:30:24-0500'
	                                                                      ],
	                                          'sprouting|CO:0000008' => [
	                                                                      '56',
	                                                                      '2016-01-20 01:30:24-0500'
	                                                                    ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '35',
	                                                                               '2016-01-20 01:30:24-0500'
	                                                                             ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '15',
	                                                                              '2016-01-20 01:30:24-0500'
	                                                                            ]
	                                        },
	                      'test_trial26' => {
	                                          'harvest index|CO:0000015' => [
	                                                                          '5.8',
	                                                                          '2016-01-20 01:30:25-0500'
	                                                                        ],
	                                          'flower|CO:0000111' => [
	                                                                   '1',
	                                                                   '2016-01-20 01:30:25-0500'
	                                                                 ],
	                                          'top yield|CO:0000017' => [
	                                                                      '4',
	                                                                      '2016-01-20 01:30:25-0500'
	                                                                    ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '15',
	                                                                              '2016-01-20 01:30:25-0500'
	                                                                            ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '30',
	                                                                               '2016-01-20 01:30:25-0500'
	                                                                             ],
	                                          'sprouting|CO:0000008' => [
	                                                                      '45',
	                                                                      '2016-01-20 01:30:25-0500'
	                                                                    ],
	                                          'root number|CO:0000011' => [
	                                                                        '4',
	                                                                        '2016-01-20 01:30:25-0500'
	                                                                      ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '25',
	                                                                               '2016-01-20 01:30:25-0500'
	                                                                             ]
	                                        },
	                      'test_trial212' => {
	                                           'flower|CO:0000111' => [
	                                                                    '0',
	                                                                    '2016-01-20 01:30:31-0500'
	                                                                  ],
	                                           'harvest index|CO:0000015' => [
	                                                                           '11.8',
	                                                                           '2016-01-20 01:30:31-0500'
	                                                                         ],
	                                           'top yield|CO:0000017' => [
	                                                                       '7',
	                                                                       '2016-01-20 01:30:31-0500'
	                                                                     ],
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '15',
	                                                                               '2016-01-20 01:30:31-0500'
	                                                                             ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '39',
	                                                                                '2016-01-20 01:30:31-0500'
	                                                                              ],
	                                           'root number|CO:0000011' => [
	                                                                         '6',
	                                                                         '2016-01-20 01:30:31-0500'
	                                                                       ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '31',
	                                                                                '2016-01-20 01:30:31-0500'
	                                                                              ],
	                                           'sprouting|CO:0000008' => [
	                                                                       '56',
	                                                                       '2016-01-20 01:30:31-0500'
	                                                                     ]
	                                         },
	                      'test_trial210' => {
	                                           'harvest index|CO:0000015' => [
	                                                                           '9.8',
	                                                                           '2016-01-20 01:30:29-0500'
	                                                                         ],
	                                           'flower|CO:0000111' => [
	                                                                    '0',
	                                                                    '2016-01-20 01:30:29-0500'
	                                                                  ],
	                                           'top yield|CO:0000017' => [
	                                                                       '2',
	                                                                       '2016-01-20 01:30:29-0500'
	                                                                     ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '30',
	                                                                                '2016-01-20 01:30:29-0500'
	                                                                              ],
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '15',
	                                                                               '2016-01-20 01:30:29-0500'
	                                                                             ],
	                                           'sprouting|CO:0000008' => [
	                                                                       '45',
	                                                                       '2016-01-20 01:30:29-0500'
	                                                                     ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '29',
	                                                                                '2016-01-20 01:30:29-0500'
	                                                                              ],
	                                           'root number|CO:0000011' => [
	                                                                         '',
	                                                                         '2016-01-20 01:30:29-0500'
	                                                                       ]
	                                         },
	                      'test_trial21' => {
	                                          'top yield|CO:0000017' => [
	                                                                      '2',
	                                                                      '2016-01-20 01:30:20-0500'
	                                                                    ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '0.8',
	                                                                          '2016-01-20 01:30:20-0500'
	                                                                        ],
	                                          'flower|CO:0000111' => [
	                                                                   '0',
	                                                                   '2016-01-20 01:30:20-0500'
	                                                                 ],
	                                          'sprouting|CO:0000008' => [
	                                                                      '45',
	                                                                      '2016-01-20 01:30:20-0500'
	                                                                    ],
	                                          'root number|CO:0000011' => [
	                                                                        '3',
	                                                                        '2016-01-20 01:30:20-0500'
	                                                                      ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '20',
	                                                                               '2016-01-20 01:30:20-0500'
	                                                                             ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '35',
	                                                                               '2016-01-20 01:30:20-0500'
	                                                                             ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '15',
	                                                                              '2016-01-20 01:30:20-0500'
	                                                                            ]
	                                        },
	                      'test_trial213' => {
	                                           'dry matter content|CO:0000092' => [
	                                                                                '35',
	                                                                                '2016-01-20 01:30:32-0500'
	                                                                              ],
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '15',
	                                                                               '2016-01-20 01:30:32-0500'
	                                                                             ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '32',
	                                                                                '2016-01-20 01:30:32-0500'
	                                                                              ],
	                                           'root number|CO:0000011' => [
	                                                                         '8',
	                                                                         '2016-01-20 01:30:32-0500'
	                                                                       ],
	                                           'sprouting|CO:0000008' => [
	                                                                       '8',
	                                                                       '2016-01-20 01:30:32-0500'
	                                                                     ],
	                                           'flower|CO:0000111' => [
	                                                                    '1',
	                                                                    '2016-01-20 01:30:32-0500'
	                                                                  ],
	                                           'harvest index|CO:0000015' => [
	                                                                           '12.8',
	                                                                           '2016-01-20 01:30:32-0500'
	                                                                         ],
	                                           'top yield|CO:0000017' => [
	                                                                       '4.4',
	                                                                       '2016-01-20 01:30:32-0500'
	                                                                     ]
	                                         },
	                      'test_trial23' => {
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '15',
	                                                                              '2016-01-20 01:30:22-0500'
	                                                                            ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '38',
	                                                                               '2016-01-20 01:30:22-0500'
	                                                                             ],
	                                          'sprouting|CO:0000008' => [
	                                                                      '23',
	                                                                      '2016-01-20 01:30:22-0500'
	                                                                    ],
	                                          'root number|CO:0000011' => [
	                                                                        '4',
	                                                                        '2016-01-20 01:30:22-0500'
	                                                                      ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '22',
	                                                                               '2016-01-20 01:30:22-0500'
	                                                                             ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '2.8',
	                                                                          '2016-01-20 01:30:22-0500'
	                                                                        ],
	                                          'flower|CO:0000111' => [
	                                                                   '1',
	                                                                   '2016-01-20 01:30:22-0500'
	                                                                 ],
	                                          'top yield|CO:0000017' => [
	                                                                      '5',
	                                                                      '2016-01-20 01:30:22-0500'
	                                                                    ]
	                                        },
	                      'test_trial27' => {
	                                          'flower|CO:0000111' => [
	                                                                   '1',
	                                                                   '2016-01-20 01:30:26-0500'
	                                                                 ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '6.8',
	                                                                          '2016-01-20 01:30:26-0500'
	                                                                        ],
	                                          'top yield|CO:0000017' => [
	                                                                      '9',
	                                                                      '2016-01-20 01:30:26-0500'
	                                                                    ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '15',
	                                                                              '2016-01-20 01:30:26-0500'
	                                                                            ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '38',
	                                                                               '2016-01-20 01:30:26-0500'
	                                                                             ],
	                                          'root number|CO:0000011' => [
	                                                                        '8',
	                                                                        '2016-01-20 01:30:26-0500'
	                                                                      ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '26',
	                                                                               '2016-01-20 01:30:26-0500'
	                                                                             ],
	                                          'sprouting|CO:0000008' => [
	                                                                      '34',
	                                                                      '2016-01-20 01:30:26-0500'
	                                                                    ]
	                                        },
	                      'test_trial28' => {
	                                          'harvest index|CO:0000015' => [
	                                                                          '7.8',
	                                                                          '2016-01-20 01:30:27-0500'
	                                                                        ],
	                                          'flower|CO:0000111' => [
	                                                                   '0',
	                                                                   '2016-01-20 01:30:27-0500'
	                                                                 ],
	                                          'top yield|CO:0000017' => [
	                                                                      '6',
	                                                                      '2016-01-20 01:30:27-0500'
	                                                                    ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '39',
	                                                                               '2016-01-20 01:30:27-0500'
	                                                                             ],
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '15',
	                                                                              '2016-01-20 01:30:27-0500'
	                                                                            ],
	                                          'sprouting|CO:0000008' => [
	                                                                      '23',
	                                                                      '2016-01-20 01:30:27-0500'
	                                                                    ],
	                                          'root number|CO:0000011' => [
	                                                                        '9',
	                                                                        '2016-01-20 01:30:27-0500'
	                                                                      ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '27',
	                                                                               '2016-01-20 01:30:27-0500'
	                                                                             ]
	                                        },
	                      'test_trial22' => {
	                                          'fresh root weight|CO:0000012' => [
	                                                                              '15',
	                                                                              '2016-01-20 01:30:21-0500'
	                                                                            ],
	                                          'dry matter content|CO:0000092' => [
	                                                                               '30',
	                                                                               '2016-01-20 01:30:21-0500'
	                                                                             ],
	                                          'root number|CO:0000011' => [
	                                                                        '7',
	                                                                        '2016-01-20 01:30:21-0500'
	                                                                      ],
	                                          'fresh shoot weight|CO:0000016' => [
	                                                                               '21',
	                                                                               '2016-01-20 01:30:21-0500'
	                                                                             ],
	                                          'sprouting|CO:0000008' => [
	                                                                      '43',
	                                                                      '2016-01-20 01:30:21-0500'
	                                                                    ],
	                                          'flower|CO:0000111' => [
	                                                                   '1',
	                                                                   '2016-01-20 01:30:21-0500'
	                                                                 ],
	                                          'harvest index|CO:0000015' => [
	                                                                          '1.8',
	                                                                          '2016-01-20 01:30:21-0500'
	                                                                        ],
	                                          'top yield|CO:0000017' => [
	                                                                      '3',
	                                                                      '2016-01-20 01:30:21-0500'
	                                                                    ]
	                                        },
	                      'test_trial215' => {
	                                           'flower|CO:0000111' => [
	                                                                    '1',
	                                                                    '2016-01-20 01:30:34-0500'
	                                                                  ],
	                                           'harvest index|CO:0000015' => [
	                                                                           '14.8',
	                                                                           '2016-01-20 01:30:34-0500'
	                                                                         ],
	                                           'top yield|CO:0000017' => [
	                                                                       '7',
	                                                                       '2016-01-20 01:30:34-0500'
	                                                                     ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '38',
	                                                                                '2016-01-20 01:30:34-0500'
	                                                                              ],
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '15',
	                                                                               '2016-01-20 01:30:34-0500'
	                                                                             ],
	                                           'root number|CO:0000011' => [
	                                                                         '5',
	                                                                         '2016-01-20 01:30:34-0500'
	                                                                       ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '34',
	                                                                                '2016-01-20 01:30:34-0500'
	                                                                              ],
	                                           'sprouting|CO:0000008' => [
	                                                                       '25',
	                                                                       '2016-01-20 01:30:34-0500'
	                                                                     ]
	                                         },
	                      'test_trial211' => {
	                                           'fresh root weight|CO:0000012' => [
	                                                                               '15',
	                                                                               '2016-01-20 01:30:30-0500'
	                                                                             ],
	                                           'dry matter content|CO:0000092' => [
	                                                                                '38',
	                                                                                '2016-01-20 01:30:30-0500'
	                                                                              ],
	                                           'fresh shoot weight|CO:0000016' => [
	                                                                                '30',
	                                                                                '2016-01-20 01:30:30-0500'
	                                                                              ],
	                                           'root number|CO:0000011' => [
	                                                                         '4',
	                                                                         '2016-01-20 01:30:30-0500'
	                                                                       ],
	                                           'sprouting|CO:0000008' => [
	                                                                       '2',
	                                                                       '2016-01-20 01:30:30-0500'
	                                                                     ],
	                                           'flower|CO:0000111' => [
	                                                                    '0',
	                                                                    '2016-01-20 01:30:30-0500'
	                                                                  ],
	                                           'harvest index|CO:0000015' => [
	                                                                           '10.8',
	                                                                           '2016-01-20 01:30:30-0500'
	                                                                         ],
	                                           'top yield|CO:0000017' => [
	                                                                       '4',
	                                                                       '2016-01-20 01:30:30-0500'
	                                                                     ]
	                                         }
	                    },
	          'traits' => [
	                        'dry matter content|CO:0000092',
	                        'flower|CO:0000111',
	                        'fresh root weight|CO:0000012',
	                        'fresh shoot weight|CO:0000016',
	                        'harvest index|CO:0000015',
	                        'root number|CO:0000011',
	                        'sprouting|CO:0000008',
	                        'top yield|CO:0000017'
	                      ],
	          'plots' => [
	                       'test_trial21',
	                       'test_trial210',
	                       'test_trial211',
	                       'test_trial212',
	                       'test_trial213',
	                       'test_trial214',
	                       'test_trial215',
	                       'test_trial22',
	                       'test_trial23',
	                       'test_trial24',
	                       'test_trial25',
	                       'test_trial26',
	                       'test_trial27',
	                       'test_trial28',
	                       'test_trial29'
	                     ]
        }, "Check parse large phenotyping spreadsheet" );


$phenotype_metadata{'archived_file'} = $filename;
$phenotype_metadata{'archived_file_type'}="spreadsheet phenotype file";
$phenotype_metadata{'operator'}="janedoe";
$phenotype_metadata{'date'}="2016-02-16_05:55:55";
%parsed_data = %{$parsed_file->{'data'}};
@plots = @{$parsed_file->{'plots'}};
@traits = @{$parsed_file->{'traits'}};

$store_phenotypes = CXGN::Phenotypes::StorePhenotypes->new();
$size = scalar(@plots) * scalar(@traits);
$stored_phenotype_error_msg = $store_phenotypes->store($c,$size,\@plots,\@traits, \%parsed_data, \%phenotype_metadata);
ok(!$stored_phenotype_error_msg, "check that store large pheno spreadsheet works");

$tn = CXGN::Trial->new( { bcs_schema => $f->bcs_schema(),
				trial_id => 137 });

$traits_assayed  = $tn->get_traits_assayed();
@traits_assayed_sorted = sort {$a->[0] cmp $b->[0]} @$traits_assayed;
#print STDERR Dumper @traits_assayed_sorted;
@traits_assayed_check = ([70666,'Fresh root weight'], [70668,'Harvest index variable'], [70681, 'Top yield'], [70700, 'Sprouting proportion'], [70706, 'Root number counting'], [70713, 'Flower'], [70727, 'Dry yield'], [70741,'Dry matter content percentage'], [70773,'Fresh shoot weight measurement in kg']);
is_deeply(\@traits_assayed_sorted, \@traits_assayed_check, 'check traits assayed from large phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70666);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','15','36','37','38','39','40','41','42','43','45','46','47','48','49','50');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70666 from large phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70668);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('0','0','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','0.8','1.8','1.8','1.8','2.8','2.8','2.8','3.8','3.8','3.8','4.8','4.8','5.8','5.8','5.8','6.8','6.8','6.8','7.8','7.8','7.8','8.8','8.8','8.8','9.8','9.8','9.8','10.8','10.8','10.8','11.8','11.8','11.8','12.8','12.8','12.8','13.8','13.8','13.8','14.8','14.8','14.8');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70668 from large phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70741);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('12','13','14','25','30','30','30','30','30','30','30','30','30','30','30','30','31','32','35','35','35','35','35','35','35','35','35','35','35','35','35','35','36','37','38','38','38','38','38','38','38','38','38','38','38','38','38','39','39','39','39','39','39','39','39','39','39','41','41','42','42','42','43','44','45','45','46','47','48','49','52');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70741 from large phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70773);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('10','11','12','13','14','15','16','17','18','19','20','20','20','20','21','21','21','21','22','22','22','22','23','23','23','23','24','24','24','24','25','25','25','26','26','26','27','27','27','28','28','28','29','29','29','30','30','30','31','31','31','32','32','32','33','33','33','34','34','34');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70773 from large phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70681);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('2','2','2','3','3','4','4','4.4','5','6','7','7','7','7.5','9');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70681 from large phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70700);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('2','8','23','23','25','34','43','45','45','45','56','56','76','78','87');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70700 from large phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70713);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('0','0','0','0','0','1','1','1','1','1','1','1','1','1','1');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70713 from large  phenotyping spreadsheet upload' );

@pheno_for_trait = $tn->get_phenotypes_for_trait(70706);
@pheno_for_trait_sorted = sort {$a <=> $b} @pheno_for_trait;
#print STDERR Dumper @pheno_for_trait_sorted;
@pheno_for_trait_check = ('3','4','4','4','4','5','6','6','6','7','8','8','9','11');
is_deeply(\@pheno_for_trait_sorted, \@pheno_for_trait_check, 'check pheno traits 70706 from large phenotyping spreadsheet upload' );



$experiment = $c->bcs_schema->resultset('NaturalDiversity::NdExperiment')->search({type_id => $phenotyping_experiment_cvterm_id}, {order_by => {-asc => 'nd_experiment_id'}});
$post1_experiment_count = $experiment->count();
$post1_experiment_diff = $post1_experiment_count - $pre_experiment_count;
print STDERR "Experiment count: ".$post1_experiment_diff."\n";
ok($post1_experiment_diff == 323, "Check num rows in NdExperiment table after addition of large phenotyping spreadsheet upload");

my @nd_experiment_table;
my $nd_experiment_table_tail = $experiment->slice($post1_experiment_count-323, $post1_experiment_count);
while (my $rs = $nd_experiment_table_tail->next() ) {
      push @nd_experiment_table, [nd_experiment_id=> $rs->nd_experiment_id(), nd_geolocation_id=> $rs->nd_geolocation_id(), type_id=> $rs->type_id()];
}
#print STDERR Dumper \@nd_experiment_table;

$phenotype_rs = $c->bcs_schema->resultset('Phenotype::Phenotype')->search({});
$post1_phenotype_count = $phenotype_rs->count();
$post1_phenotype_diff = $post1_phenotype_count - $pre_phenotype_count;
print STDERR "Phenotype count: ".$post1_phenotype_diff."\n";
ok($post1_phenotype_diff == 323, "Check num rows in Phenotype table after addition of large phenotyping spreadsheet upload");

my @pheno_table;
my $pheno_table_tail = $phenotype_rs->slice($post1_phenotype_count-323, $post1_phenotype_count);
while (my $rs = $pheno_table_tail->next() ) {
      push @pheno_table, [phenotype_id=> $rs->phenotype_id(), observable_id=> $rs->observable_id(), attr_id=> $rs->attr_id(), value=> $rs->value(), cvalue_id=>$rs->cvalue_id(), assay_id=>$rs->assay_id()];
}
#print STDERR Dumper \@pheno_table;

$exp_prop_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentprop')->search({});
$post1_exp_prop_count = $exp_prop_rs->count();
$post1_exp_prop_diff = $post1_exp_prop_count - $pre_exp_prop_count;
print STDERR "Experimentprop count: ".$post1_exp_prop_diff."\n";
ok($post1_exp_prop_diff == 646, "Check num rows in Experimentprop table after addition of large phenotyping spreadsheet upload");

my @exp_prop_table;
my $exp_prop_table_tail = $exp_prop_rs->slice($post1_exp_prop_count-646, $post1_exp_prop_count);
while (my $rs = $exp_prop_table_tail->next() ) {
      push @exp_prop_table, [nd_experimentprop_id=> $rs->nd_experimentprop_id(), nd_experiment_id=> $rs->nd_experiment_id(), type_id=> $rs->type_id(), value=> $rs->value(), rank=> $rs->rank()];
}
#print STDERR Dumper \@exp_prop_table;

$exp_proj_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentProject')->search({});
$post1_exp_proj_count = $exp_proj_rs->count();
$post1_exp_proj_diff = $post1_exp_proj_count - $pre_exp_proj_count;
print STDERR "Experimentproject count: ".$post1_exp_proj_diff."\n";
ok($post1_exp_proj_diff == 323, "Check num rows in NdExperimentproject table after addition of large phenotyping spreadsheet upload");

my @exp_proj_table;
my $exp_proj_table_tail = $exp_proj_rs->slice($post1_exp_proj_count-323, $post1_exp_proj_count);
while (my $rs = $exp_proj_table_tail->next() ) {
      push @exp_proj_table, [nd_experiment_project_id=> $rs->nd_experiment_project_id(), nd_experiment_id=> $rs->nd_experiment_id(), project_id=> $rs->project_id()];
}
#print STDERR Dumper \@exp_proj_table;

$exp_stock_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentStock')->search({});
$post1_exp_stock_count = $exp_stock_rs->count();
$post1_exp_stock_diff = $post1_exp_stock_count - $pre_exp_stock_count;
print STDERR "Experimentstock count: ".$post1_exp_stock_diff."\n";
ok($post1_exp_stock_diff == 323, "Check num rows in NdExperimentstock table after addition of large phenotyping spreadsheet upload");

my @exp_stock_table;
my $exp_stock_table_tail = $exp_stock_rs->slice($post1_exp_stock_count-323, $post1_exp_stock_count);
while (my $rs = $exp_stock_table_tail->next() ) {
      push @exp_stock_table, [nd_experiment_stock_id=> $rs->nd_experiment_stock_id(), nd_experiment_id=> $rs->nd_experiment_id(), stock_id=> $rs->stock_id(), type_id=> $rs->type_id()];
}
#print STDERR Dumper \@exp_stock_table;

$exp_pheno_rs = $c->bcs_schema->resultset('NaturalDiversity::NdExperimentPhenotype')->search({});
$post1_exp_pheno_count = $exp_pheno_rs->count();
$post1_exp_pheno_diff = $post1_exp_pheno_count - $pre_exp_pheno_count;
print STDERR "Experimentphenotype count: ".$post1_exp_pheno_diff."\n";
ok($post1_exp_pheno_diff == 323, "Check num rows in NdExperimentphenotype table after addition of large phenotyping spreadsheet upload");

my @exp_pheno_table;
my $exp_pheno_table_tail = $exp_pheno_rs->slice($post1_exp_pheno_count-323, $post1_exp_pheno_count);
while (my $rs = $exp_pheno_table_tail->next() ) {
      push @exp_pheno_table, [nd_experiment_phenotype_id=> $rs->nd_experiment_phenotype_id(), nd_experiment_id=> $rs->nd_experiment_id(), phenotype_id=> $rs->phenotype_id()];
}
#print STDERR Dumper \@exp_pheno_table;

$md_rs = $c->metadata_schema->resultset('MdMetadata')->search({});
$post1_md_count = $md_rs->count();
$post1_md_diff = $post1_md_count - $pre_md_count;
print STDERR "MdMetadata count: ".$post1_md_diff."\n";
ok($post1_md_diff == 5, "Check num rows in MdMetadata table after addition of phenotyping spreadsheet upload");

my @md_table;
my $md_table_tail = $md_rs->slice($post1_md_count-5, $post1_md_count);
while (my $rs = $md_table_tail->next() ) {
      push @md_table, [metadata_id => $rs->metadata_id(), create_person_id=> $rs->create_person_id()];
}
#print STDERR Dumper \@md_table;

$md_files_rs = $c->metadata_schema->resultset('MdFiles')->search({});
$post1_md_files_count = $md_files_rs->count();
$post1_md_files_diff = $post1_md_files_count - $pre_md_files_count;
print STDERR "MdFiles count: ".$post1_md_files_diff."\n";
ok($post1_md_files_diff == 5, "Check num rows in MdFiles table after addition of large phenotyping spreadsheet upload");

my @md_files_table;
my $md_files_table_tail = $md_files_rs->slice($post1_md_files_count-5, $post1_md_files_count);
while (my $rs = $md_files_table_tail->next() ) {
      push @md_files_table, [file_id => $rs->file_id(), basename=> $rs->basename(), dirname=> $rs->dirname(), filetype=> $rs->filetype(), alt_filename=>$rs->alt_filename(), comment=>$rs->comment(), urlsource=>$rs->urlsource()];
}
#print STDERR Dumper \@md_files_table;

$exp_md_files_rs = $c->phenome_schema->resultset('NdExperimentMdFiles')->search({});
$post1_exp_md_files_count = $exp_md_files_rs->count();
$post1_exp_md_files_diff = $post1_exp_md_files_count - $pre_exp_md_files_count;
print STDERR "Experimentphenotype count: ".$post1_exp_md_files_diff."\n";
ok($post1_exp_md_files_diff == 323, "Check num rows in NdExperimentMdFIles table after addition of large phenotyping spreadsheet upload");

my @exp_md_files_table;
my $exp_md_files_table_tail = $exp_md_files_rs->slice($post1_exp_md_files_count-324, $post1_exp_md_files_count-1);
while (my $rs = $exp_md_files_table_tail->next() ) {
      push @exp_md_files_table, [nd_experiment_md_files_id => $rs->nd_experiment_md_files_id(), nd_experiment_id=> $rs->nd_experiment_id(), file_id=> $rs->file_id()];
}
#print STDERR Dumper \@exp_md_files_table;



#Verify Database Tables State
#Uncomment the following tests for maximum testing. These tests do not work if the database has been altered by other tests.

#my $nd_experiment_table_check = [['nd_experiment_id',80025,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80026,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80027,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80028,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80029,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80030,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80031,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80032,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80033,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80034,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80035,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80036,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80037,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80038,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80039,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80040,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80041,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80042,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80043,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80044,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80045,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80046,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80047,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80048,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80049,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80050,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80051,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80052,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80053,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80054,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80055,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80056,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80057,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80058,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80059,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80060,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80061,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80062,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80063,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80064,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80065,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80066,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80067,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80068,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80069,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80070,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80071,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80072,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80073,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80074,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80075,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80076,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80077,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80078,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80079,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80080,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80081,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80082,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80083,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80084,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80085,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80086,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80087,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80088,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80089,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80090,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80091,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80092,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80093,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80094,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80095,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80096,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80097,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80098,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80099,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80100,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80101,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80102,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80103,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80104,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80105,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80106,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80107,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80108,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80109,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80110,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80111,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80112,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80113,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80114,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80115,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80116,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80117,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80118,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80119,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80120,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80121,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80122,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80123,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80124,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80125,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80126,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80127,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80128,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80129,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80130,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80131,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80132,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80133,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80134,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80135,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80136,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80137,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80138,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80139,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80140,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80141,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80142,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80143,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80144,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80145,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80146,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80147,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80148,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80149,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80150,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80151,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80152,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80153,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80154,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80155,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80156,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80157,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80158,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80159,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80160,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80161,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80162,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80163,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80164,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80165,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80166,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80167,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80168,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80169,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80170,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80171,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80172,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80173,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80174,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80175,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80176,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80177,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80178,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80179,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80180,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80181,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80182,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80183,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80184,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80185,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80186,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80187,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80188,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80189,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80190,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80191,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80192,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80193,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80194,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80195,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80196,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80197,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80198,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80199,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80200,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80201,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80202,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80203,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80204,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80205,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80206,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80207,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80208,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80209,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80210,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80211,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80212,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80213,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80214,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80215,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80216,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80217,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80218,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80219,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80220,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80221,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80222,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80223,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80224,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80225,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80226,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80227,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80228,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80229,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80230,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80231,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80232,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80233,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80234,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80235,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80236,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80237,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80238,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80239,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80240,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80241,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80242,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80243,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80244,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80245,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80246,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80247,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80248,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80249,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80250,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80251,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80252,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80253,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80254,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80255,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80256,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80257,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80258,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80259,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80260,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80261,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80262,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80263,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80264,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80265,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80266,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80267,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80268,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80269,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80270,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80271,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80272,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80273,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80274,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80275,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80276,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80277,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80278,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80279,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80280,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80281,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80282,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80283,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80284,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80285,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80286,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80287,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80288,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80289,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80290,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80291,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80292,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80293,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80294,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80295,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80296,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80297,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80298,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80299,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80300,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80301,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80302,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80303,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80304,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80305,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80306,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80307,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80308,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80309,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80310,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80311,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80312,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80313,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80314,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80315,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80316,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80317,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80318,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80319,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80320,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80321,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80322,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80323,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80324,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80325,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80326,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80327,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80328,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80329,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80330,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80331,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80332,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80333,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80334,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80335,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80336,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80337,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80338,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80339,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80340,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80341,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80342,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80343,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80344,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80345,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80346,'nd_geolocation_id',23,'type_id',76391],['nd_experiment_id',80347,'nd_geolocation_id',23,'type_id',76391]];

#is_deeply(\@nd_experiment_table, $nd_experiment_table_check, 'check nd_experiments table data state' );



#my $pheno_table_check = [['phenotype_id',740335,'observable_id',70666,'attr_id',undef,'value','0.4','cvalue_id',70666,'assay_id',undef],['phenotype_id',740336,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740337,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740338,'observable_id',70773,'attr_id',undef,'value','20','cvalue_id',70773,'assay_id',undef],['phenotype_id',740339,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740340,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740341,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740342,'observable_id',70773,'attr_id',undef,'value','29','cvalue_id',70773,'assay_id',undef],['phenotype_id',740343,'observable_id',70668,'attr_id',undef,'value','9.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740344,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740345,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740346,'observable_id',70773,'attr_id',undef,'value','30','cvalue_id',70773,'assay_id',undef],['phenotype_id',740347,'observable_id',70668,'attr_id',undef,'value','10.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740348,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740349,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740350,'observable_id',70773,'attr_id',undef,'value','31','cvalue_id',70773,'assay_id',undef],['phenotype_id',740351,'observable_id',70668,'attr_id',undef,'value','11.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740352,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740353,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740354,'observable_id',70773,'attr_id',undef,'value','32','cvalue_id',70773,'assay_id',undef],['phenotype_id',740355,'observable_id',70668,'attr_id',undef,'value','12.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740356,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740357,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740358,'observable_id',70773,'attr_id',undef,'value','33','cvalue_id',70773,'assay_id',undef],['phenotype_id',740359,'observable_id',70668,'attr_id',undef,'value','13.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740360,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740361,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740362,'observable_id',70773,'attr_id',undef,'value','34','cvalue_id',70773,'assay_id',undef],['phenotype_id',740363,'observable_id',70668,'attr_id',undef,'value','14.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740364,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740365,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740366,'observable_id',70773,'attr_id',undef,'value','21','cvalue_id',70773,'assay_id',undef],['phenotype_id',740367,'observable_id',70668,'attr_id',undef,'value','1.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740368,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740369,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740370,'observable_id',70773,'attr_id',undef,'value','22','cvalue_id',70773,'assay_id',undef],['phenotype_id',740371,'observable_id',70668,'attr_id',undef,'value','2.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740372,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740373,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740374,'observable_id',70773,'attr_id',undef,'value','23','cvalue_id',70773,'assay_id',undef],['phenotype_id',740375,'observable_id',70668,'attr_id',undef,'value','3.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740376,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740377,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740378,'observable_id',70773,'attr_id',undef,'value','24','cvalue_id',70773,'assay_id',undef],['phenotype_id',740379,'observable_id',70668,'attr_id',undef,'value','4.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740380,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740381,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740382,'observable_id',70773,'attr_id',undef,'value','25','cvalue_id',70773,'assay_id',undef],['phenotype_id',740383,'observable_id',70668,'attr_id',undef,'value','5.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740384,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740385,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740386,'observable_id',70773,'attr_id',undef,'value','26','cvalue_id',70773,'assay_id',undef],['phenotype_id',740387,'observable_id',70668,'attr_id',undef,'value','6.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740388,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740389,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740390,'observable_id',70773,'attr_id',undef,'value','27','cvalue_id',70773,'assay_id',undef],['phenotype_id',740391,'observable_id',70668,'attr_id',undef,'value','7.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740392,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740393,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740394,'observable_id',70773,'attr_id',undef,'value','28','cvalue_id',70773,'assay_id',undef],['phenotype_id',740395,'observable_id',70668,'attr_id',undef,'value','8.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740396,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740397,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740398,'observable_id',70773,'attr_id',undef,'value','20','cvalue_id',70773,'assay_id',undef],['phenotype_id',740399,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740400,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740401,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740402,'observable_id',70773,'attr_id',undef,'value','29','cvalue_id',70773,'assay_id',undef],['phenotype_id',740403,'observable_id',70668,'attr_id',undef,'value','9.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740404,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740405,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740406,'observable_id',70773,'attr_id',undef,'value','30','cvalue_id',70773,'assay_id',undef],['phenotype_id',740407,'observable_id',70668,'attr_id',undef,'value','10.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740408,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740409,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740410,'observable_id',70773,'attr_id',undef,'value','31','cvalue_id',70773,'assay_id',undef],['phenotype_id',740411,'observable_id',70668,'attr_id',undef,'value','11.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740412,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740413,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740414,'observable_id',70773,'attr_id',undef,'value','32','cvalue_id',70773,'assay_id',undef],['phenotype_id',740415,'observable_id',70668,'attr_id',undef,'value','12.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740416,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740417,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740418,'observable_id',70773,'attr_id',undef,'value','33','cvalue_id',70773,'assay_id',undef],['phenotype_id',740419,'observable_id',70668,'attr_id',undef,'value','13.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740420,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740421,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740422,'observable_id',70773,'attr_id',undef,'value','34','cvalue_id',70773,'assay_id',undef],['phenotype_id',740423,'observable_id',70668,'attr_id',undef,'value','14.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740424,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740425,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740426,'observable_id',70773,'attr_id',undef,'value','21','cvalue_id',70773,'assay_id',undef],['phenotype_id',740427,'observable_id',70668,'attr_id',undef,'value','1.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740428,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740429,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740430,'observable_id',70773,'attr_id',undef,'value','22','cvalue_id',70773,'assay_id',undef],['phenotype_id',740431,'observable_id',70668,'attr_id',undef,'value','2.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740432,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740433,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740434,'observable_id',70773,'attr_id',undef,'value','23','cvalue_id',70773,'assay_id',undef],['phenotype_id',740435,'observable_id',70668,'attr_id',undef,'value','3.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740436,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740437,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740438,'observable_id',70773,'attr_id',undef,'value','24','cvalue_id',70773,'assay_id',undef],['phenotype_id',740439,'observable_id',70668,'attr_id',undef,'value','4.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740440,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740441,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740442,'observable_id',70773,'attr_id',undef,'value','25','cvalue_id',70773,'assay_id',undef],['phenotype_id',740443,'observable_id',70668,'attr_id',undef,'value','5.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740444,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740445,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740446,'observable_id',70773,'attr_id',undef,'value','26','cvalue_id',70773,'assay_id',undef],['phenotype_id',740447,'observable_id',70668,'attr_id',undef,'value','6.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740448,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740449,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740450,'observable_id',70773,'attr_id',undef,'value','27','cvalue_id',70773,'assay_id',undef],['phenotype_id',740451,'observable_id',70668,'attr_id',undef,'value','7.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740452,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740453,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740454,'observable_id',70773,'attr_id',undef,'value','28','cvalue_id',70773,'assay_id',undef],['phenotype_id',740455,'observable_id',70668,'attr_id',undef,'value','8.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740456,'observable_id',70741,'attr_id',undef,'value','42','cvalue_id',70741,'assay_id',undef],['phenotype_id',740457,'observable_id',70727,'attr_id',undef,'value','42','cvalue_id',70727,'assay_id',undef],['phenotype_id',740458,'observable_id',70741,'attr_id',undef,'value','12','cvalue_id',70741,'assay_id',undef],['phenotype_id',740459,'observable_id',70727,'attr_id',undef,'value','12','cvalue_id',70727,'assay_id',undef],['phenotype_id',740460,'observable_id',70741,'attr_id',undef,'value','13','cvalue_id',70741,'assay_id',undef],['phenotype_id',740461,'observable_id',70727,'attr_id',undef,'value','13','cvalue_id',70727,'assay_id',undef],['phenotype_id',740462,'observable_id',70741,'attr_id',undef,'value','42','cvalue_id',70741,'assay_id',undef],['phenotype_id',740463,'observable_id',70727,'attr_id',undef,'value','42','cvalue_id',70727,'assay_id',undef],['phenotype_id',740464,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740465,'observable_id',70727,'attr_id',undef,'value','35','cvalue_id',70727,'assay_id',undef],['phenotype_id',740466,'observable_id',70741,'attr_id',undef,'value','32','cvalue_id',70741,'assay_id',undef],['phenotype_id',740467,'observable_id',70727,'attr_id',undef,'value','32','cvalue_id',70727,'assay_id',undef],['phenotype_id',740468,'observable_id',70741,'attr_id',undef,'value','31','cvalue_id',70741,'assay_id',undef],['phenotype_id',740469,'observable_id',70727,'attr_id',undef,'value','31','cvalue_id',70727,'assay_id',undef],['phenotype_id',740470,'observable_id',70741,'attr_id',undef,'value','45','cvalue_id',70741,'assay_id',undef],['phenotype_id',740471,'observable_id',70727,'attr_id',undef,'value','45','cvalue_id',70727,'assay_id',undef],['phenotype_id',740472,'observable_id',70741,'attr_id',undef,'value','41','cvalue_id',70741,'assay_id',undef],['phenotype_id',740474,'observable_id',70741,'attr_id',undef,'value','14','cvalue_id',70741,'assay_id',undef],['phenotype_id',740475,'observable_id',70727,'attr_id',undef,'value','14','cvalue_id',70727,'assay_id',undef],['phenotype_id',740476,'observable_id',70741,'attr_id',undef,'value','25','cvalue_id',70741,'assay_id',undef],['phenotype_id',740477,'observable_id',70727,'attr_id',undef,'value','25','cvalue_id',70727,'assay_id',undef],['phenotype_id',740478,'observable_id',70727,'attr_id',undef,'value','0','cvalue_id',70727,'assay_id',undef],['phenotype_id',740479,'observable_id',70741,'attr_id',undef,'value','52','cvalue_id',70741,'assay_id',undef],['phenotype_id',740480,'observable_id',70727,'attr_id',undef,'value','0','cvalue_id',70727,'assay_id',undef],['phenotype_id',740481,'observable_id',70741,'attr_id',undef,'value','41','cvalue_id',70741,'assay_id',undef],['phenotype_id',740482,'observable_id',70727,'attr_id',undef,'value','41','cvalue_id',70727,'assay_id',undef],['phenotype_id',740483,'observable_id',70727,'attr_id',undef,'value','24','cvalue_id',70727,'assay_id',undef],['phenotype_id',740484,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740485,'observable_id',70666,'attr_id',undef,'value','36','cvalue_id',70666,'assay_id',undef],['phenotype_id',740486,'observable_id',70773,'attr_id',undef,'value','10','cvalue_id',70773,'assay_id',undef],['phenotype_id',740487,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740488,'observable_id',70741,'attr_id',undef,'value','44','cvalue_id',70741,'assay_id',undef],['phenotype_id',740489,'observable_id',70666,'attr_id',undef,'value','45','cvalue_id',70666,'assay_id',undef],['phenotype_id',740490,'observable_id',70773,'attr_id',undef,'value','19','cvalue_id',70773,'assay_id',undef],['phenotype_id',740491,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740492,'observable_id',70741,'attr_id',undef,'value','45','cvalue_id',70741,'assay_id',undef],['phenotype_id',740493,'observable_id',70666,'attr_id',undef,'value','46','cvalue_id',70666,'assay_id',undef],['phenotype_id',740494,'observable_id',70773,'attr_id',undef,'value','20','cvalue_id',70773,'assay_id',undef],['phenotype_id',740495,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740496,'observable_id',70741,'attr_id',undef,'value','46','cvalue_id',70741,'assay_id',undef],['phenotype_id',740497,'observable_id',70666,'attr_id',undef,'value','47','cvalue_id',70666,'assay_id',undef],['phenotype_id',740498,'observable_id',70773,'attr_id',undef,'value','21','cvalue_id',70773,'assay_id',undef],['phenotype_id',740499,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740500,'observable_id',70741,'attr_id',undef,'value','47','cvalue_id',70741,'assay_id',undef],['phenotype_id',740501,'observable_id',70666,'attr_id',undef,'value','48','cvalue_id',70666,'assay_id',undef],['phenotype_id',740502,'observable_id',70773,'attr_id',undef,'value','22','cvalue_id',70773,'assay_id',undef],['phenotype_id',740503,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740504,'observable_id',70741,'attr_id',undef,'value','48','cvalue_id',70741,'assay_id',undef],['phenotype_id',740505,'observable_id',70666,'attr_id',undef,'value','49','cvalue_id',70666,'assay_id',undef],['phenotype_id',740506,'observable_id',70773,'attr_id',undef,'value','23','cvalue_id',70773,'assay_id',undef],['phenotype_id',740507,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740508,'observable_id',70741,'attr_id',undef,'value','49','cvalue_id',70741,'assay_id',undef],['phenotype_id',740509,'observable_id',70666,'attr_id',undef,'value','50','cvalue_id',70666,'assay_id',undef],['phenotype_id',740510,'observable_id',70773,'attr_id',undef,'value','24','cvalue_id',70773,'assay_id',undef],['phenotype_id',740511,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740512,'observable_id',70741,'attr_id',undef,'value','36','cvalue_id',70741,'assay_id',undef],['phenotype_id',740513,'observable_id',70666,'attr_id',undef,'value','37','cvalue_id',70666,'assay_id',undef],['phenotype_id',740514,'observable_id',70773,'attr_id',undef,'value','11','cvalue_id',70773,'assay_id',undef],['phenotype_id',740515,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740516,'observable_id',70741,'attr_id',undef,'value','37','cvalue_id',70741,'assay_id',undef],['phenotype_id',740517,'observable_id',70666,'attr_id',undef,'value','38','cvalue_id',70666,'assay_id',undef],['phenotype_id',740518,'observable_id',70773,'attr_id',undef,'value','12','cvalue_id',70773,'assay_id',undef],['phenotype_id',740519,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740520,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740521,'observable_id',70666,'attr_id',undef,'value','39','cvalue_id',70666,'assay_id',undef],['phenotype_id',740522,'observable_id',70773,'attr_id',undef,'value','13','cvalue_id',70773,'assay_id',undef],['phenotype_id',740523,'observable_id',70668,'attr_id',undef,'value','0','cvalue_id',70668,'assay_id',undef],['phenotype_id',740524,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740525,'observable_id',70666,'attr_id',undef,'value','40','cvalue_id',70666,'assay_id',undef],['phenotype_id',740526,'observable_id',70773,'attr_id',undef,'value','14','cvalue_id',70773,'assay_id',undef],['phenotype_id',740527,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740528,'observable_id',70666,'attr_id',undef,'value','41','cvalue_id',70666,'assay_id',undef],['phenotype_id',740529,'observable_id',70773,'attr_id',undef,'value','15','cvalue_id',70773,'assay_id',undef],['phenotype_id',740530,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740531,'observable_id',70666,'attr_id',undef,'value','42','cvalue_id',70666,'assay_id',undef],['phenotype_id',740532,'observable_id',70773,'attr_id',undef,'value','16','cvalue_id',70773,'assay_id',undef],['phenotype_id',740533,'observable_id',70668,'attr_id',undef,'value','0','cvalue_id',70668,'assay_id',undef],['phenotype_id',740534,'observable_id',70741,'attr_id',undef,'value','42','cvalue_id',70741,'assay_id',undef],['phenotype_id',740535,'observable_id',70666,'attr_id',undef,'value','43','cvalue_id',70666,'assay_id',undef],['phenotype_id',740536,'observable_id',70773,'attr_id',undef,'value','17','cvalue_id',70773,'assay_id',undef],['phenotype_id',740537,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740538,'observable_id',70741,'attr_id',undef,'value','43','cvalue_id',70741,'assay_id',undef],['phenotype_id',740539,'observable_id',70773,'attr_id',undef,'value','18','cvalue_id',70773,'assay_id',undef],['phenotype_id',740540,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740541,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740542,'observable_id',70713,'attr_id',undef,'value','0','cvalue_id',70713,'assay_id',undef],['phenotype_id',740543,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740544,'observable_id',70773,'attr_id',undef,'value','20','cvalue_id',70773,'assay_id',undef],['phenotype_id',740545,'observable_id',70668,'attr_id',undef,'value','0.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740546,'observable_id',70706,'attr_id',undef,'value','3','cvalue_id',70706,'assay_id',undef],['phenotype_id',740547,'observable_id',70700,'attr_id',undef,'value','45','cvalue_id',70700,'assay_id',undef],['phenotype_id',740548,'observable_id',70681,'attr_id',undef,'value','2','cvalue_id',70681,'assay_id',undef],['phenotype_id',740549,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740550,'observable_id',70713,'attr_id',undef,'value','0','cvalue_id',70713,'assay_id',undef],['phenotype_id',740551,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740552,'observable_id',70773,'attr_id',undef,'value','29','cvalue_id',70773,'assay_id',undef],['phenotype_id',740553,'observable_id',70668,'attr_id',undef,'value','9.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740554,'observable_id',70700,'attr_id',undef,'value','45','cvalue_id',70700,'assay_id',undef],['phenotype_id',740555,'observable_id',70681,'attr_id',undef,'value','2','cvalue_id',70681,'assay_id',undef],['phenotype_id',740556,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740557,'observable_id',70713,'attr_id',undef,'value','0','cvalue_id',70713,'assay_id',undef],['phenotype_id',740558,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740559,'observable_id',70773,'attr_id',undef,'value','30','cvalue_id',70773,'assay_id',undef],['phenotype_id',740560,'observable_id',70668,'attr_id',undef,'value','10.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740561,'observable_id',70706,'attr_id',undef,'value','4','cvalue_id',70706,'assay_id',undef],['phenotype_id',740562,'observable_id',70700,'attr_id',undef,'value','2','cvalue_id',70700,'assay_id',undef],['phenotype_id',740563,'observable_id',70681,'attr_id',undef,'value','4','cvalue_id',70681,'assay_id',undef],['phenotype_id',740564,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740565,'observable_id',70713,'attr_id',undef,'value','0','cvalue_id',70713,'assay_id',undef],['phenotype_id',740566,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740567,'observable_id',70773,'attr_id',undef,'value','31','cvalue_id',70773,'assay_id',undef],['phenotype_id',740568,'observable_id',70668,'attr_id',undef,'value','11.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740569,'observable_id',70706,'attr_id',undef,'value','6','cvalue_id',70706,'assay_id',undef],['phenotype_id',740570,'observable_id',70700,'attr_id',undef,'value','56','cvalue_id',70700,'assay_id',undef],['phenotype_id',740571,'observable_id',70681,'attr_id',undef,'value','7','cvalue_id',70681,'assay_id',undef],['phenotype_id',740572,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740573,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740574,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740575,'observable_id',70773,'attr_id',undef,'value','32','cvalue_id',70773,'assay_id',undef],['phenotype_id',740576,'observable_id',70668,'attr_id',undef,'value','12.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740577,'observable_id',70706,'attr_id',undef,'value','8','cvalue_id',70706,'assay_id',undef],['phenotype_id',740578,'observable_id',70700,'attr_id',undef,'value','8','cvalue_id',70700,'assay_id',undef],['phenotype_id',740579,'observable_id',70681,'attr_id',undef,'value','4.4','cvalue_id',70681,'assay_id',undef],['phenotype_id',740580,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740581,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740582,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740583,'observable_id',70773,'attr_id',undef,'value','33','cvalue_id',70773,'assay_id',undef],['phenotype_id',740584,'observable_id',70668,'attr_id',undef,'value','13.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740585,'observable_id',70706,'attr_id',undef,'value','4','cvalue_id',70706,'assay_id',undef],['phenotype_id',740586,'observable_id',70700,'attr_id',undef,'value','87','cvalue_id',70700,'assay_id',undef],['phenotype_id',740587,'observable_id',70681,'attr_id',undef,'value','7.5','cvalue_id',70681,'assay_id',undef],['phenotype_id',740588,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740589,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740590,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740591,'observable_id',70773,'attr_id',undef,'value','34','cvalue_id',70773,'assay_id',undef],['phenotype_id',740592,'observable_id',70668,'attr_id',undef,'value','14.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740593,'observable_id',70706,'attr_id',undef,'value','5','cvalue_id',70706,'assay_id',undef],['phenotype_id',740594,'observable_id',70700,'attr_id',undef,'value','25','cvalue_id',70700,'assay_id',undef],['phenotype_id',740595,'observable_id',70681,'attr_id',undef,'value','7','cvalue_id',70681,'assay_id',undef],['phenotype_id',740596,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740597,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740598,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740599,'observable_id',70773,'attr_id',undef,'value','21','cvalue_id',70773,'assay_id',undef],['phenotype_id',740600,'observable_id',70668,'attr_id',undef,'value','1.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740601,'observable_id',70706,'attr_id',undef,'value','7','cvalue_id',70706,'assay_id',undef],['phenotype_id',740602,'observable_id',70700,'attr_id',undef,'value','43','cvalue_id',70700,'assay_id',undef],['phenotype_id',740603,'observable_id',70681,'attr_id',undef,'value','3','cvalue_id',70681,'assay_id',undef],['phenotype_id',740604,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740605,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740606,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740607,'observable_id',70773,'attr_id',undef,'value','22','cvalue_id',70773,'assay_id',undef],['phenotype_id',740608,'observable_id',70668,'attr_id',undef,'value','2.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740609,'observable_id',70706,'attr_id',undef,'value','4','cvalue_id',70706,'assay_id',undef],['phenotype_id',740610,'observable_id',70700,'attr_id',undef,'value','23','cvalue_id',70700,'assay_id',undef],['phenotype_id',740611,'observable_id',70681,'attr_id',undef,'value','5','cvalue_id',70681,'assay_id',undef],['phenotype_id',740612,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740613,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740614,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740615,'observable_id',70773,'attr_id',undef,'value','23','cvalue_id',70773,'assay_id',undef],['phenotype_id',740616,'observable_id',70668,'attr_id',undef,'value','3.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740617,'observable_id',70706,'attr_id',undef,'value','11','cvalue_id',70706,'assay_id',undef],['phenotype_id',740618,'observable_id',70700,'attr_id',undef,'value','78','cvalue_id',70700,'assay_id',undef],['phenotype_id',740619,'observable_id',70681,'attr_id',undef,'value','7','cvalue_id',70681,'assay_id',undef],['phenotype_id',740620,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740621,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740622,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740623,'observable_id',70773,'attr_id',undef,'value','24','cvalue_id',70773,'assay_id',undef],['phenotype_id',740624,'observable_id',70706,'attr_id',undef,'value','6','cvalue_id',70706,'assay_id',undef],['phenotype_id',740625,'observable_id',70700,'attr_id',undef,'value','56','cvalue_id',70700,'assay_id',undef],['phenotype_id',740626,'observable_id',70681,'attr_id',undef,'value','2','cvalue_id',70681,'assay_id',undef],['phenotype_id',740627,'observable_id',70741,'attr_id',undef,'value','30','cvalue_id',70741,'assay_id',undef],['phenotype_id',740628,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740629,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740630,'observable_id',70773,'attr_id',undef,'value','25','cvalue_id',70773,'assay_id',undef],['phenotype_id',740631,'observable_id',70668,'attr_id',undef,'value','5.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740632,'observable_id',70706,'attr_id',undef,'value','4','cvalue_id',70706,'assay_id',undef],['phenotype_id',740633,'observable_id',70700,'attr_id',undef,'value','45','cvalue_id',70700,'assay_id',undef],['phenotype_id',740634,'observable_id',70681,'attr_id',undef,'value','4','cvalue_id',70681,'assay_id',undef],['phenotype_id',740635,'observable_id',70741,'attr_id',undef,'value','38','cvalue_id',70741,'assay_id',undef],['phenotype_id',740636,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740637,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740638,'observable_id',70773,'attr_id',undef,'value','26','cvalue_id',70773,'assay_id',undef],['phenotype_id',740639,'observable_id',70668,'attr_id',undef,'value','6.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740640,'observable_id',70706,'attr_id',undef,'value','8','cvalue_id',70706,'assay_id',undef],['phenotype_id',740641,'observable_id',70700,'attr_id',undef,'value','34','cvalue_id',70700,'assay_id',undef],['phenotype_id',740642,'observable_id',70681,'attr_id',undef,'value','9','cvalue_id',70681,'assay_id',undef],['phenotype_id',740643,'observable_id',70741,'attr_id',undef,'value','39','cvalue_id',70741,'assay_id',undef],['phenotype_id',740644,'observable_id',70713,'attr_id',undef,'value','0','cvalue_id',70713,'assay_id',undef],['phenotype_id',740645,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740646,'observable_id',70773,'attr_id',undef,'value','27','cvalue_id',70773,'assay_id',undef],['phenotype_id',740647,'observable_id',70668,'attr_id',undef,'value','7.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740648,'observable_id',70706,'attr_id',undef,'value','9','cvalue_id',70706,'assay_id',undef],['phenotype_id',740649,'observable_id',70700,'attr_id',undef,'value','23','cvalue_id',70700,'assay_id',undef],['phenotype_id',740650,'observable_id',70681,'attr_id',undef,'value','6','cvalue_id',70681,'assay_id',undef],['phenotype_id',740651,'observable_id',70741,'attr_id',undef,'value','35','cvalue_id',70741,'assay_id',undef],['phenotype_id',740652,'observable_id',70713,'attr_id',undef,'value','1','cvalue_id',70713,'assay_id',undef],['phenotype_id',740653,'observable_id',70666,'attr_id',undef,'value','15','cvalue_id',70666,'assay_id',undef],['phenotype_id',740654,'observable_id',70773,'attr_id',undef,'value','28','cvalue_id',70773,'assay_id',undef],['phenotype_id',740655,'observable_id',70668,'attr_id',undef,'value','8.8','cvalue_id',70668,'assay_id',undef],['phenotype_id',740656,'observable_id',70706,'attr_id',undef,'value','6','cvalue_id',70706,'assay_id',undef],['phenotype_id',740657,'observable_id',70700,'attr_id',undef,'value','76','cvalue_id',70700,'assay_id',undef],['phenotype_id',740658,'observable_id',70681,'attr_id',undef,'value','3','cvalue_id',70681,'assay_id',undef]];

#is_deeply(\@pheno_table, $pheno_table_check, 'check phenotype table data state' );



#my $exp_prop_table_check = [['nd_experimentprop_id',6613,'nd_experiment_id',80025,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6614,'nd_experiment_id',80025,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6615,'nd_experiment_id',80026,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6616,'nd_experiment_id',80026,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6617,'nd_experiment_id',80027,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6618,'nd_experiment_id',80027,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6619,'nd_experiment_id',80028,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6620,'nd_experiment_id',80028,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6621,'nd_experiment_id',80029,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6622,'nd_experiment_id',80029,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6623,'nd_experiment_id',80030,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6624,'nd_experiment_id',80030,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6625,'nd_experiment_id',80031,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6626,'nd_experiment_id',80031,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6627,'nd_experiment_id',80032,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6628,'nd_experiment_id',80032,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6629,'nd_experiment_id',80033,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6630,'nd_experiment_id',80033,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6631,'nd_experiment_id',80034,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6632,'nd_experiment_id',80034,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6633,'nd_experiment_id',80035,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6634,'nd_experiment_id',80035,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6635,'nd_experiment_id',80036,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6636,'nd_experiment_id',80036,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6637,'nd_experiment_id',80037,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6638,'nd_experiment_id',80037,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6639,'nd_experiment_id',80038,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6640,'nd_experiment_id',80038,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6641,'nd_experiment_id',80039,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6642,'nd_experiment_id',80039,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6643,'nd_experiment_id',80040,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6644,'nd_experiment_id',80040,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6645,'nd_experiment_id',80041,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6646,'nd_experiment_id',80041,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6647,'nd_experiment_id',80042,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6648,'nd_experiment_id',80042,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6649,'nd_experiment_id',80043,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6650,'nd_experiment_id',80043,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6651,'nd_experiment_id',80044,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6652,'nd_experiment_id',80044,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6653,'nd_experiment_id',80045,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6654,'nd_experiment_id',80045,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6655,'nd_experiment_id',80046,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6656,'nd_experiment_id',80046,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6657,'nd_experiment_id',80047,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6658,'nd_experiment_id',80047,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6659,'nd_experiment_id',80048,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6660,'nd_experiment_id',80048,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6661,'nd_experiment_id',80049,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6662,'nd_experiment_id',80049,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6663,'nd_experiment_id',80050,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6664,'nd_experiment_id',80050,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6665,'nd_experiment_id',80051,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6666,'nd_experiment_id',80051,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6667,'nd_experiment_id',80052,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6668,'nd_experiment_id',80052,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6669,'nd_experiment_id',80053,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6670,'nd_experiment_id',80053,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6671,'nd_experiment_id',80054,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6672,'nd_experiment_id',80054,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6673,'nd_experiment_id',80055,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6674,'nd_experiment_id',80055,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6675,'nd_experiment_id',80056,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6676,'nd_experiment_id',80056,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6677,'nd_experiment_id',80057,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6678,'nd_experiment_id',80057,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6679,'nd_experiment_id',80058,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6680,'nd_experiment_id',80058,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6681,'nd_experiment_id',80059,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6682,'nd_experiment_id',80059,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6683,'nd_experiment_id',80060,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6684,'nd_experiment_id',80060,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6685,'nd_experiment_id',80061,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6686,'nd_experiment_id',80061,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6687,'nd_experiment_id',80062,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6688,'nd_experiment_id',80062,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6689,'nd_experiment_id',80063,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6690,'nd_experiment_id',80063,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6691,'nd_experiment_id',80064,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6692,'nd_experiment_id',80064,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6693,'nd_experiment_id',80065,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6694,'nd_experiment_id',80065,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6695,'nd_experiment_id',80066,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6696,'nd_experiment_id',80066,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6697,'nd_experiment_id',80067,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6698,'nd_experiment_id',80067,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6699,'nd_experiment_id',80068,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6700,'nd_experiment_id',80068,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6701,'nd_experiment_id',80069,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6702,'nd_experiment_id',80069,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6703,'nd_experiment_id',80070,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6704,'nd_experiment_id',80070,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6705,'nd_experiment_id',80071,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6706,'nd_experiment_id',80071,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6707,'nd_experiment_id',80072,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6708,'nd_experiment_id',80072,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6709,'nd_experiment_id',80073,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6710,'nd_experiment_id',80073,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6711,'nd_experiment_id',80074,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6712,'nd_experiment_id',80074,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6713,'nd_experiment_id',80075,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6714,'nd_experiment_id',80075,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6715,'nd_experiment_id',80076,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6716,'nd_experiment_id',80076,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6717,'nd_experiment_id',80077,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6718,'nd_experiment_id',80077,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6719,'nd_experiment_id',80078,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6720,'nd_experiment_id',80078,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6721,'nd_experiment_id',80079,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6722,'nd_experiment_id',80079,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6723,'nd_experiment_id',80080,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6724,'nd_experiment_id',80080,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6725,'nd_experiment_id',80081,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6726,'nd_experiment_id',80081,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6727,'nd_experiment_id',80082,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6728,'nd_experiment_id',80082,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6729,'nd_experiment_id',80083,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6730,'nd_experiment_id',80083,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6731,'nd_experiment_id',80084,'type_id',76478,'value','2016-02-16_01:10:56','rank',0],['nd_experimentprop_id',6732,'nd_experiment_id',80084,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6733,'nd_experiment_id',80085,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6734,'nd_experiment_id',80085,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6735,'nd_experiment_id',80086,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6736,'nd_experiment_id',80086,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6737,'nd_experiment_id',80087,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6738,'nd_experiment_id',80087,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6739,'nd_experiment_id',80088,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6740,'nd_experiment_id',80088,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6741,'nd_experiment_id',80089,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6742,'nd_experiment_id',80089,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6743,'nd_experiment_id',80090,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6744,'nd_experiment_id',80090,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6745,'nd_experiment_id',80091,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6746,'nd_experiment_id',80091,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6747,'nd_experiment_id',80092,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6748,'nd_experiment_id',80092,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6749,'nd_experiment_id',80093,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6750,'nd_experiment_id',80093,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6751,'nd_experiment_id',80094,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6752,'nd_experiment_id',80094,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6753,'nd_experiment_id',80095,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6754,'nd_experiment_id',80095,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6755,'nd_experiment_id',80096,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6756,'nd_experiment_id',80096,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6757,'nd_experiment_id',80097,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6758,'nd_experiment_id',80097,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6759,'nd_experiment_id',80098,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6760,'nd_experiment_id',80098,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6761,'nd_experiment_id',80099,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6762,'nd_experiment_id',80099,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6763,'nd_experiment_id',80100,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6764,'nd_experiment_id',80100,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6765,'nd_experiment_id',80101,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6766,'nd_experiment_id',80101,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6767,'nd_experiment_id',80102,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6768,'nd_experiment_id',80102,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6769,'nd_experiment_id',80103,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6770,'nd_experiment_id',80103,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6771,'nd_experiment_id',80104,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6772,'nd_experiment_id',80104,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6773,'nd_experiment_id',80105,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6774,'nd_experiment_id',80105,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6775,'nd_experiment_id',80106,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6776,'nd_experiment_id',80106,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6777,'nd_experiment_id',80107,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6778,'nd_experiment_id',80107,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6779,'nd_experiment_id',80108,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6780,'nd_experiment_id',80108,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6781,'nd_experiment_id',80109,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6782,'nd_experiment_id',80109,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6783,'nd_experiment_id',80110,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6784,'nd_experiment_id',80110,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6785,'nd_experiment_id',80111,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6786,'nd_experiment_id',80111,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6787,'nd_experiment_id',80112,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6788,'nd_experiment_id',80112,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6789,'nd_experiment_id',80113,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6790,'nd_experiment_id',80113,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6791,'nd_experiment_id',80114,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6792,'nd_experiment_id',80114,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6793,'nd_experiment_id',80115,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6794,'nd_experiment_id',80115,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6795,'nd_experiment_id',80116,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6796,'nd_experiment_id',80116,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6797,'nd_experiment_id',80117,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6798,'nd_experiment_id',80117,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6799,'nd_experiment_id',80118,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6800,'nd_experiment_id',80118,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6801,'nd_experiment_id',80119,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6802,'nd_experiment_id',80119,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6803,'nd_experiment_id',80120,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6804,'nd_experiment_id',80120,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6805,'nd_experiment_id',80121,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6806,'nd_experiment_id',80121,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6807,'nd_experiment_id',80122,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6808,'nd_experiment_id',80122,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6809,'nd_experiment_id',80123,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6810,'nd_experiment_id',80123,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6811,'nd_experiment_id',80124,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6812,'nd_experiment_id',80124,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6813,'nd_experiment_id',80125,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6814,'nd_experiment_id',80125,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6815,'nd_experiment_id',80126,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6816,'nd_experiment_id',80126,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6817,'nd_experiment_id',80127,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6818,'nd_experiment_id',80127,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6819,'nd_experiment_id',80128,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6820,'nd_experiment_id',80128,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6821,'nd_experiment_id',80129,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6822,'nd_experiment_id',80129,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6823,'nd_experiment_id',80130,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6824,'nd_experiment_id',80130,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6825,'nd_experiment_id',80131,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6826,'nd_experiment_id',80131,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6827,'nd_experiment_id',80132,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6828,'nd_experiment_id',80132,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6829,'nd_experiment_id',80133,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6830,'nd_experiment_id',80133,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6831,'nd_experiment_id',80134,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6832,'nd_experiment_id',80134,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6833,'nd_experiment_id',80135,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6834,'nd_experiment_id',80135,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6835,'nd_experiment_id',80136,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6836,'nd_experiment_id',80136,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6837,'nd_experiment_id',80137,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6838,'nd_experiment_id',80137,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6839,'nd_experiment_id',80138,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6840,'nd_experiment_id',80138,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6841,'nd_experiment_id',80139,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6842,'nd_experiment_id',80139,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6843,'nd_experiment_id',80140,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6844,'nd_experiment_id',80140,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6845,'nd_experiment_id',80141,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6846,'nd_experiment_id',80141,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6847,'nd_experiment_id',80142,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6848,'nd_experiment_id',80142,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6849,'nd_experiment_id',80143,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6850,'nd_experiment_id',80143,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6851,'nd_experiment_id',80144,'type_id',76478,'value','2016-02-17_01:11:58','rank',0],['nd_experimentprop_id',6852,'nd_experiment_id',80144,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6853,'nd_experiment_id',80145,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6854,'nd_experiment_id',80145,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6855,'nd_experiment_id',80146,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6856,'nd_experiment_id',80146,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6857,'nd_experiment_id',80147,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6858,'nd_experiment_id',80147,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6859,'nd_experiment_id',80148,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6860,'nd_experiment_id',80148,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6861,'nd_experiment_id',80149,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6862,'nd_experiment_id',80149,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6863,'nd_experiment_id',80150,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6864,'nd_experiment_id',80150,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6865,'nd_experiment_id',80151,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6866,'nd_experiment_id',80151,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6867,'nd_experiment_id',80152,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6868,'nd_experiment_id',80152,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6869,'nd_experiment_id',80153,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6870,'nd_experiment_id',80153,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6871,'nd_experiment_id',80154,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6872,'nd_experiment_id',80154,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6873,'nd_experiment_id',80155,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6874,'nd_experiment_id',80155,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6875,'nd_experiment_id',80156,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6876,'nd_experiment_id',80156,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6877,'nd_experiment_id',80157,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6878,'nd_experiment_id',80157,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6879,'nd_experiment_id',80158,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6880,'nd_experiment_id',80158,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6881,'nd_experiment_id',80159,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6882,'nd_experiment_id',80159,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6883,'nd_experiment_id',80160,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6884,'nd_experiment_id',80160,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6885,'nd_experiment_id',80161,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6886,'nd_experiment_id',80161,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6887,'nd_experiment_id',80162,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6888,'nd_experiment_id',80162,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6889,'nd_experiment_id',80163,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6890,'nd_experiment_id',80163,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6891,'nd_experiment_id',80164,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6892,'nd_experiment_id',80164,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6893,'nd_experiment_id',80165,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6894,'nd_experiment_id',80165,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6895,'nd_experiment_id',80166,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6896,'nd_experiment_id',80166,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6897,'nd_experiment_id',80167,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6898,'nd_experiment_id',80167,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6899,'nd_experiment_id',80168,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6900,'nd_experiment_id',80168,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6901,'nd_experiment_id',80169,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6902,'nd_experiment_id',80169,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6903,'nd_experiment_id',80170,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6904,'nd_experiment_id',80170,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6905,'nd_experiment_id',80171,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6906,'nd_experiment_id',80171,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6907,'nd_experiment_id',80172,'type_id',76478,'value','2016-01-16_03:15:26','rank',0],['nd_experimentprop_id',6908,'nd_experiment_id',80172,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6909,'nd_experiment_id',80173,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6910,'nd_experiment_id',80173,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6911,'nd_experiment_id',80174,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6912,'nd_experiment_id',80174,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6913,'nd_experiment_id',80175,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6914,'nd_experiment_id',80175,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6915,'nd_experiment_id',80176,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6916,'nd_experiment_id',80176,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6917,'nd_experiment_id',80177,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6918,'nd_experiment_id',80177,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6919,'nd_experiment_id',80178,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6920,'nd_experiment_id',80178,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6921,'nd_experiment_id',80179,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6922,'nd_experiment_id',80179,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6923,'nd_experiment_id',80180,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6924,'nd_experiment_id',80180,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6925,'nd_experiment_id',80181,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6926,'nd_experiment_id',80181,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6927,'nd_experiment_id',80182,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6928,'nd_experiment_id',80182,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6929,'nd_experiment_id',80183,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6930,'nd_experiment_id',80183,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6931,'nd_experiment_id',80184,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6932,'nd_experiment_id',80184,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6933,'nd_experiment_id',80185,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6934,'nd_experiment_id',80185,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6935,'nd_experiment_id',80186,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6936,'nd_experiment_id',80186,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6937,'nd_experiment_id',80187,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6938,'nd_experiment_id',80187,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6939,'nd_experiment_id',80188,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6940,'nd_experiment_id',80188,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6941,'nd_experiment_id',80189,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6942,'nd_experiment_id',80189,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6943,'nd_experiment_id',80190,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6944,'nd_experiment_id',80190,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6945,'nd_experiment_id',80191,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6946,'nd_experiment_id',80191,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6947,'nd_experiment_id',80192,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6948,'nd_experiment_id',80192,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6949,'nd_experiment_id',80193,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6950,'nd_experiment_id',80193,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6951,'nd_experiment_id',80194,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6952,'nd_experiment_id',80194,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6953,'nd_experiment_id',80195,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6954,'nd_experiment_id',80195,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6955,'nd_experiment_id',80196,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6956,'nd_experiment_id',80196,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6957,'nd_experiment_id',80197,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6958,'nd_experiment_id',80197,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6959,'nd_experiment_id',80198,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6960,'nd_experiment_id',80198,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6961,'nd_experiment_id',80199,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6962,'nd_experiment_id',80199,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6963,'nd_experiment_id',80200,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6964,'nd_experiment_id',80200,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6965,'nd_experiment_id',80201,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6966,'nd_experiment_id',80201,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6967,'nd_experiment_id',80202,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6968,'nd_experiment_id',80202,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6969,'nd_experiment_id',80203,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6970,'nd_experiment_id',80203,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6971,'nd_experiment_id',80204,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6972,'nd_experiment_id',80204,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6973,'nd_experiment_id',80205,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6974,'nd_experiment_id',80205,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6975,'nd_experiment_id',80206,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6976,'nd_experiment_id',80206,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6977,'nd_experiment_id',80207,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6978,'nd_experiment_id',80207,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6979,'nd_experiment_id',80208,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6980,'nd_experiment_id',80208,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6981,'nd_experiment_id',80209,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6982,'nd_experiment_id',80209,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6983,'nd_experiment_id',80210,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6984,'nd_experiment_id',80210,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6985,'nd_experiment_id',80211,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6986,'nd_experiment_id',80211,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6987,'nd_experiment_id',80212,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6988,'nd_experiment_id',80212,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6989,'nd_experiment_id',80213,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6990,'nd_experiment_id',80213,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6991,'nd_experiment_id',80214,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6992,'nd_experiment_id',80214,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6993,'nd_experiment_id',80215,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6994,'nd_experiment_id',80215,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6995,'nd_experiment_id',80216,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6996,'nd_experiment_id',80216,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6997,'nd_experiment_id',80217,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',6998,'nd_experiment_id',80217,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',6999,'nd_experiment_id',80218,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7000,'nd_experiment_id',80218,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7001,'nd_experiment_id',80219,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7002,'nd_experiment_id',80219,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7003,'nd_experiment_id',80220,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7004,'nd_experiment_id',80220,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7005,'nd_experiment_id',80221,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7006,'nd_experiment_id',80221,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7007,'nd_experiment_id',80222,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7008,'nd_experiment_id',80222,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7009,'nd_experiment_id',80223,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7010,'nd_experiment_id',80223,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7011,'nd_experiment_id',80224,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7012,'nd_experiment_id',80224,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7013,'nd_experiment_id',80225,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7014,'nd_experiment_id',80225,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7015,'nd_experiment_id',80226,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7016,'nd_experiment_id',80226,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7017,'nd_experiment_id',80227,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7018,'nd_experiment_id',80227,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7019,'nd_experiment_id',80228,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7020,'nd_experiment_id',80228,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7021,'nd_experiment_id',80229,'type_id',76478,'value','2016-02-16_07:11:98','rank',0],['nd_experimentprop_id',7022,'nd_experiment_id',80229,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7023,'nd_experiment_id',80230,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7024,'nd_experiment_id',80230,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7025,'nd_experiment_id',80231,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7026,'nd_experiment_id',80231,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7027,'nd_experiment_id',80232,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7028,'nd_experiment_id',80232,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7029,'nd_experiment_id',80233,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7030,'nd_experiment_id',80233,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7031,'nd_experiment_id',80234,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7032,'nd_experiment_id',80234,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7033,'nd_experiment_id',80235,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7034,'nd_experiment_id',80235,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7035,'nd_experiment_id',80236,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7036,'nd_experiment_id',80236,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7037,'nd_experiment_id',80237,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7038,'nd_experiment_id',80237,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7039,'nd_experiment_id',80238,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7040,'nd_experiment_id',80238,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7041,'nd_experiment_id',80239,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7042,'nd_experiment_id',80239,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7043,'nd_experiment_id',80240,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7044,'nd_experiment_id',80240,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7045,'nd_experiment_id',80241,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7046,'nd_experiment_id',80241,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7047,'nd_experiment_id',80242,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7048,'nd_experiment_id',80242,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7049,'nd_experiment_id',80243,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7050,'nd_experiment_id',80243,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7051,'nd_experiment_id',80244,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7052,'nd_experiment_id',80244,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7053,'nd_experiment_id',80245,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7054,'nd_experiment_id',80245,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7055,'nd_experiment_id',80246,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7056,'nd_experiment_id',80246,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7057,'nd_experiment_id',80247,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7058,'nd_experiment_id',80247,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7059,'nd_experiment_id',80248,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7060,'nd_experiment_id',80248,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7061,'nd_experiment_id',80249,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7062,'nd_experiment_id',80249,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7063,'nd_experiment_id',80250,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7064,'nd_experiment_id',80250,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7065,'nd_experiment_id',80251,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7066,'nd_experiment_id',80251,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7067,'nd_experiment_id',80252,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7068,'nd_experiment_id',80252,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7069,'nd_experiment_id',80253,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7070,'nd_experiment_id',80253,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7071,'nd_experiment_id',80254,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7072,'nd_experiment_id',80254,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7073,'nd_experiment_id',80255,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7074,'nd_experiment_id',80255,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7075,'nd_experiment_id',80256,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7076,'nd_experiment_id',80256,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7077,'nd_experiment_id',80257,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7078,'nd_experiment_id',80257,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7079,'nd_experiment_id',80258,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7080,'nd_experiment_id',80258,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7081,'nd_experiment_id',80259,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7082,'nd_experiment_id',80259,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7083,'nd_experiment_id',80260,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7084,'nd_experiment_id',80260,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7085,'nd_experiment_id',80261,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7086,'nd_experiment_id',80261,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7087,'nd_experiment_id',80262,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7088,'nd_experiment_id',80262,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7089,'nd_experiment_id',80263,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7090,'nd_experiment_id',80263,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7091,'nd_experiment_id',80264,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7092,'nd_experiment_id',80264,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7093,'nd_experiment_id',80265,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7094,'nd_experiment_id',80265,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7095,'nd_experiment_id',80266,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7096,'nd_experiment_id',80266,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7097,'nd_experiment_id',80267,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7098,'nd_experiment_id',80267,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7099,'nd_experiment_id',80268,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7100,'nd_experiment_id',80268,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7101,'nd_experiment_id',80269,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7102,'nd_experiment_id',80269,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7103,'nd_experiment_id',80270,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7104,'nd_experiment_id',80270,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7105,'nd_experiment_id',80271,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7106,'nd_experiment_id',80271,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7107,'nd_experiment_id',80272,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7108,'nd_experiment_id',80272,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7109,'nd_experiment_id',80273,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7110,'nd_experiment_id',80273,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7111,'nd_experiment_id',80274,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7112,'nd_experiment_id',80274,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7113,'nd_experiment_id',80275,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7114,'nd_experiment_id',80275,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7115,'nd_experiment_id',80276,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7116,'nd_experiment_id',80276,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7117,'nd_experiment_id',80277,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7118,'nd_experiment_id',80277,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7119,'nd_experiment_id',80278,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7120,'nd_experiment_id',80278,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7121,'nd_experiment_id',80279,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7122,'nd_experiment_id',80279,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7123,'nd_experiment_id',80280,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7124,'nd_experiment_id',80280,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7125,'nd_experiment_id',80281,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7126,'nd_experiment_id',80281,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7127,'nd_experiment_id',80282,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7128,'nd_experiment_id',80282,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7129,'nd_experiment_id',80283,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7130,'nd_experiment_id',80283,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7131,'nd_experiment_id',80284,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7132,'nd_experiment_id',80284,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7133,'nd_experiment_id',80285,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7134,'nd_experiment_id',80285,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7135,'nd_experiment_id',80286,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7136,'nd_experiment_id',80286,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7137,'nd_experiment_id',80287,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7138,'nd_experiment_id',80287,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7139,'nd_experiment_id',80288,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7140,'nd_experiment_id',80288,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7141,'nd_experiment_id',80289,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7142,'nd_experiment_id',80289,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7143,'nd_experiment_id',80290,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7144,'nd_experiment_id',80290,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7145,'nd_experiment_id',80291,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7146,'nd_experiment_id',80291,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7147,'nd_experiment_id',80292,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7148,'nd_experiment_id',80292,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7149,'nd_experiment_id',80293,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7150,'nd_experiment_id',80293,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7151,'nd_experiment_id',80294,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7152,'nd_experiment_id',80294,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7153,'nd_experiment_id',80295,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7154,'nd_experiment_id',80295,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7155,'nd_experiment_id',80296,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7156,'nd_experiment_id',80296,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7157,'nd_experiment_id',80297,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7158,'nd_experiment_id',80297,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7159,'nd_experiment_id',80298,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7160,'nd_experiment_id',80298,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7161,'nd_experiment_id',80299,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7162,'nd_experiment_id',80299,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7163,'nd_experiment_id',80300,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7164,'nd_experiment_id',80300,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7165,'nd_experiment_id',80301,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7166,'nd_experiment_id',80301,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7167,'nd_experiment_id',80302,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7168,'nd_experiment_id',80302,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7169,'nd_experiment_id',80303,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7170,'nd_experiment_id',80303,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7171,'nd_experiment_id',80304,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7172,'nd_experiment_id',80304,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7173,'nd_experiment_id',80305,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7174,'nd_experiment_id',80305,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7175,'nd_experiment_id',80306,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7176,'nd_experiment_id',80306,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7177,'nd_experiment_id',80307,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7178,'nd_experiment_id',80307,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7179,'nd_experiment_id',80308,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7180,'nd_experiment_id',80308,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7181,'nd_experiment_id',80309,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7182,'nd_experiment_id',80309,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7183,'nd_experiment_id',80310,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7184,'nd_experiment_id',80310,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7185,'nd_experiment_id',80311,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7186,'nd_experiment_id',80311,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7187,'nd_experiment_id',80312,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7188,'nd_experiment_id',80312,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7189,'nd_experiment_id',80313,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7190,'nd_experiment_id',80313,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7191,'nd_experiment_id',80314,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7192,'nd_experiment_id',80314,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7193,'nd_experiment_id',80315,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7194,'nd_experiment_id',80315,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7195,'nd_experiment_id',80316,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7196,'nd_experiment_id',80316,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7197,'nd_experiment_id',80317,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7198,'nd_experiment_id',80317,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7199,'nd_experiment_id',80318,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7200,'nd_experiment_id',80318,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7201,'nd_experiment_id',80319,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7202,'nd_experiment_id',80319,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7203,'nd_experiment_id',80320,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7204,'nd_experiment_id',80320,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7205,'nd_experiment_id',80321,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7206,'nd_experiment_id',80321,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7207,'nd_experiment_id',80322,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7208,'nd_experiment_id',80322,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7209,'nd_experiment_id',80323,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7210,'nd_experiment_id',80323,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7211,'nd_experiment_id',80324,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7212,'nd_experiment_id',80324,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7213,'nd_experiment_id',80325,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7214,'nd_experiment_id',80325,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7215,'nd_experiment_id',80326,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7216,'nd_experiment_id',80326,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7217,'nd_experiment_id',80327,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7218,'nd_experiment_id',80327,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7219,'nd_experiment_id',80328,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7220,'nd_experiment_id',80328,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7221,'nd_experiment_id',80329,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7222,'nd_experiment_id',80329,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7223,'nd_experiment_id',80330,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7224,'nd_experiment_id',80330,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7225,'nd_experiment_id',80331,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7226,'nd_experiment_id',80331,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7227,'nd_experiment_id',80332,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7228,'nd_experiment_id',80332,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7229,'nd_experiment_id',80333,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7230,'nd_experiment_id',80333,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7231,'nd_experiment_id',80334,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7232,'nd_experiment_id',80334,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7233,'nd_experiment_id',80335,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7234,'nd_experiment_id',80335,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7235,'nd_experiment_id',80336,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7236,'nd_experiment_id',80336,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7237,'nd_experiment_id',80337,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7238,'nd_experiment_id',80337,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7239,'nd_experiment_id',80338,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7240,'nd_experiment_id',80338,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7241,'nd_experiment_id',80339,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7242,'nd_experiment_id',80339,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7243,'nd_experiment_id',80340,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7244,'nd_experiment_id',80340,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7245,'nd_experiment_id',80341,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7246,'nd_experiment_id',80341,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7247,'nd_experiment_id',80342,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7248,'nd_experiment_id',80342,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7249,'nd_experiment_id',80343,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7250,'nd_experiment_id',80343,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7251,'nd_experiment_id',80344,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7252,'nd_experiment_id',80344,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7253,'nd_experiment_id',80345,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7254,'nd_experiment_id',80345,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7255,'nd_experiment_id',80346,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7256,'nd_experiment_id',80346,'type_id',76479,'value','janedoe','rank',0],['nd_experimentprop_id',7257,'nd_experiment_id',80347,'type_id',76478,'value','2016-02-16_05:55:55','rank',0],['nd_experimentprop_id',7258,'nd_experiment_id',80347,'type_id',76479,'value','janedoe','rank',0]];

#is_deeply(\@exp_prop_table, $exp_prop_table_check, 'check ndexperimentprop table data state' );



#my $exp_proj_table_check = [['nd_experiment_project_id',80021,'nd_experiment_id',80025,'project_id',137],['nd_experiment_project_id',80022,'nd_experiment_id',80026,'project_id',137],['nd_experiment_project_id',80023,'nd_experiment_id',80027,'project_id',137],['nd_experiment_project_id',80024,'nd_experiment_id',80028,'project_id',137],['nd_experiment_project_id',80025,'nd_experiment_id',80029,'project_id',137],['nd_experiment_project_id',80026,'nd_experiment_id',80030,'project_id',137],['nd_experiment_project_id',80027,'nd_experiment_id',80031,'project_id',137],['nd_experiment_project_id',80028,'nd_experiment_id',80032,'project_id',137],['nd_experiment_project_id',80029,'nd_experiment_id',80033,'project_id',137],['nd_experiment_project_id',80030,'nd_experiment_id',80034,'project_id',137],['nd_experiment_project_id',80031,'nd_experiment_id',80035,'project_id',137],['nd_experiment_project_id',80032,'nd_experiment_id',80036,'project_id',137],['nd_experiment_project_id',80033,'nd_experiment_id',80037,'project_id',137],['nd_experiment_project_id',80034,'nd_experiment_id',80038,'project_id',137],['nd_experiment_project_id',80035,'nd_experiment_id',80039,'project_id',137],['nd_experiment_project_id',80036,'nd_experiment_id',80040,'project_id',137],['nd_experiment_project_id',80037,'nd_experiment_id',80041,'project_id',137],['nd_experiment_project_id',80038,'nd_experiment_id',80042,'project_id',137],['nd_experiment_project_id',80039,'nd_experiment_id',80043,'project_id',137],['nd_experiment_project_id',80040,'nd_experiment_id',80044,'project_id',137],['nd_experiment_project_id',80041,'nd_experiment_id',80045,'project_id',137],['nd_experiment_project_id',80042,'nd_experiment_id',80046,'project_id',137],['nd_experiment_project_id',80043,'nd_experiment_id',80047,'project_id',137],['nd_experiment_project_id',80044,'nd_experiment_id',80048,'project_id',137],['nd_experiment_project_id',80045,'nd_experiment_id',80049,'project_id',137],['nd_experiment_project_id',80046,'nd_experiment_id',80050,'project_id',137],['nd_experiment_project_id',80047,'nd_experiment_id',80051,'project_id',137],['nd_experiment_project_id',80048,'nd_experiment_id',80052,'project_id',137],['nd_experiment_project_id',80049,'nd_experiment_id',80053,'project_id',137],['nd_experiment_project_id',80050,'nd_experiment_id',80054,'project_id',137],['nd_experiment_project_id',80051,'nd_experiment_id',80055,'project_id',137],['nd_experiment_project_id',80052,'nd_experiment_id',80056,'project_id',137],['nd_experiment_project_id',80053,'nd_experiment_id',80057,'project_id',137],['nd_experiment_project_id',80054,'nd_experiment_id',80058,'project_id',137],['nd_experiment_project_id',80055,'nd_experiment_id',80059,'project_id',137],['nd_experiment_project_id',80056,'nd_experiment_id',80060,'project_id',137],['nd_experiment_project_id',80057,'nd_experiment_id',80061,'project_id',137],['nd_experiment_project_id',80058,'nd_experiment_id',80062,'project_id',137],['nd_experiment_project_id',80059,'nd_experiment_id',80063,'project_id',137],['nd_experiment_project_id',80060,'nd_experiment_id',80064,'project_id',137],['nd_experiment_project_id',80061,'nd_experiment_id',80065,'project_id',137],['nd_experiment_project_id',80062,'nd_experiment_id',80066,'project_id',137],['nd_experiment_project_id',80063,'nd_experiment_id',80067,'project_id',137],['nd_experiment_project_id',80064,'nd_experiment_id',80068,'project_id',137],['nd_experiment_project_id',80065,'nd_experiment_id',80069,'project_id',137],['nd_experiment_project_id',80066,'nd_experiment_id',80070,'project_id',137],['nd_experiment_project_id',80067,'nd_experiment_id',80071,'project_id',137],['nd_experiment_project_id',80068,'nd_experiment_id',80072,'project_id',137],['nd_experiment_project_id',80069,'nd_experiment_id',80073,'project_id',137],['nd_experiment_project_id',80070,'nd_experiment_id',80074,'project_id',137],['nd_experiment_project_id',80071,'nd_experiment_id',80075,'project_id',137],['nd_experiment_project_id',80072,'nd_experiment_id',80076,'project_id',137],['nd_experiment_project_id',80073,'nd_experiment_id',80077,'project_id',137],['nd_experiment_project_id',80074,'nd_experiment_id',80078,'project_id',137],['nd_experiment_project_id',80075,'nd_experiment_id',80079,'project_id',137],['nd_experiment_project_id',80076,'nd_experiment_id',80080,'project_id',137],['nd_experiment_project_id',80077,'nd_experiment_id',80081,'project_id',137],['nd_experiment_project_id',80078,'nd_experiment_id',80082,'project_id',137],['nd_experiment_project_id',80079,'nd_experiment_id',80083,'project_id',137],['nd_experiment_project_id',80080,'nd_experiment_id',80084,'project_id',137],['nd_experiment_project_id',80081,'nd_experiment_id',80085,'project_id',137],['nd_experiment_project_id',80082,'nd_experiment_id',80086,'project_id',137],['nd_experiment_project_id',80083,'nd_experiment_id',80087,'project_id',137],['nd_experiment_project_id',80084,'nd_experiment_id',80088,'project_id',137],['nd_experiment_project_id',80085,'nd_experiment_id',80089,'project_id',137],['nd_experiment_project_id',80086,'nd_experiment_id',80090,'project_id',137],['nd_experiment_project_id',80087,'nd_experiment_id',80091,'project_id',137],['nd_experiment_project_id',80088,'nd_experiment_id',80092,'project_id',137],['nd_experiment_project_id',80089,'nd_experiment_id',80093,'project_id',137],['nd_experiment_project_id',80090,'nd_experiment_id',80094,'project_id',137],['nd_experiment_project_id',80091,'nd_experiment_id',80095,'project_id',137],['nd_experiment_project_id',80092,'nd_experiment_id',80096,'project_id',137],['nd_experiment_project_id',80093,'nd_experiment_id',80097,'project_id',137],['nd_experiment_project_id',80094,'nd_experiment_id',80098,'project_id',137],['nd_experiment_project_id',80095,'nd_experiment_id',80099,'project_id',137],['nd_experiment_project_id',80096,'nd_experiment_id',80100,'project_id',137],['nd_experiment_project_id',80097,'nd_experiment_id',80101,'project_id',137],['nd_experiment_project_id',80098,'nd_experiment_id',80102,'project_id',137],['nd_experiment_project_id',80099,'nd_experiment_id',80103,'project_id',137],['nd_experiment_project_id',80100,'nd_experiment_id',80104,'project_id',137],['nd_experiment_project_id',80101,'nd_experiment_id',80105,'project_id',137],['nd_experiment_project_id',80102,'nd_experiment_id',80106,'project_id',137],['nd_experiment_project_id',80103,'nd_experiment_id',80107,'project_id',137],['nd_experiment_project_id',80104,'nd_experiment_id',80108,'project_id',137],['nd_experiment_project_id',80105,'nd_experiment_id',80109,'project_id',137],['nd_experiment_project_id',80106,'nd_experiment_id',80110,'project_id',137],['nd_experiment_project_id',80107,'nd_experiment_id',80111,'project_id',137],['nd_experiment_project_id',80108,'nd_experiment_id',80112,'project_id',137],['nd_experiment_project_id',80109,'nd_experiment_id',80113,'project_id',137],['nd_experiment_project_id',80110,'nd_experiment_id',80114,'project_id',137],['nd_experiment_project_id',80111,'nd_experiment_id',80115,'project_id',137],['nd_experiment_project_id',80112,'nd_experiment_id',80116,'project_id',137],['nd_experiment_project_id',80113,'nd_experiment_id',80117,'project_id',137],['nd_experiment_project_id',80114,'nd_experiment_id',80118,'project_id',137],['nd_experiment_project_id',80115,'nd_experiment_id',80119,'project_id',137],['nd_experiment_project_id',80116,'nd_experiment_id',80120,'project_id',137],['nd_experiment_project_id',80117,'nd_experiment_id',80121,'project_id',137],['nd_experiment_project_id',80118,'nd_experiment_id',80122,'project_id',137],['nd_experiment_project_id',80119,'nd_experiment_id',80123,'project_id',137],['nd_experiment_project_id',80120,'nd_experiment_id',80124,'project_id',137],['nd_experiment_project_id',80121,'nd_experiment_id',80125,'project_id',137],['nd_experiment_project_id',80122,'nd_experiment_id',80126,'project_id',137],['nd_experiment_project_id',80123,'nd_experiment_id',80127,'project_id',137],['nd_experiment_project_id',80124,'nd_experiment_id',80128,'project_id',137],['nd_experiment_project_id',80125,'nd_experiment_id',80129,'project_id',137],['nd_experiment_project_id',80126,'nd_experiment_id',80130,'project_id',137],['nd_experiment_project_id',80127,'nd_experiment_id',80131,'project_id',137],['nd_experiment_project_id',80128,'nd_experiment_id',80132,'project_id',137],['nd_experiment_project_id',80129,'nd_experiment_id',80133,'project_id',137],['nd_experiment_project_id',80130,'nd_experiment_id',80134,'project_id',137],['nd_experiment_project_id',80131,'nd_experiment_id',80135,'project_id',137],['nd_experiment_project_id',80132,'nd_experiment_id',80136,'project_id',137],['nd_experiment_project_id',80133,'nd_experiment_id',80137,'project_id',137],['nd_experiment_project_id',80134,'nd_experiment_id',80138,'project_id',137],['nd_experiment_project_id',80135,'nd_experiment_id',80139,'project_id',137],['nd_experiment_project_id',80136,'nd_experiment_id',80140,'project_id',137],['nd_experiment_project_id',80137,'nd_experiment_id',80141,'project_id',137],['nd_experiment_project_id',80138,'nd_experiment_id',80142,'project_id',137],['nd_experiment_project_id',80139,'nd_experiment_id',80143,'project_id',137],['nd_experiment_project_id',80140,'nd_experiment_id',80144,'project_id',137],['nd_experiment_project_id',80141,'nd_experiment_id',80145,'project_id',137],['nd_experiment_project_id',80142,'nd_experiment_id',80146,'project_id',137],['nd_experiment_project_id',80143,'nd_experiment_id',80147,'project_id',137],['nd_experiment_project_id',80144,'nd_experiment_id',80148,'project_id',137],['nd_experiment_project_id',80145,'nd_experiment_id',80149,'project_id',137],['nd_experiment_project_id',80146,'nd_experiment_id',80150,'project_id',137],['nd_experiment_project_id',80147,'nd_experiment_id',80151,'project_id',137],['nd_experiment_project_id',80148,'nd_experiment_id',80152,'project_id',137],['nd_experiment_project_id',80149,'nd_experiment_id',80153,'project_id',137],['nd_experiment_project_id',80150,'nd_experiment_id',80154,'project_id',137],['nd_experiment_project_id',80151,'nd_experiment_id',80155,'project_id',137],['nd_experiment_project_id',80152,'nd_experiment_id',80156,'project_id',137],['nd_experiment_project_id',80153,'nd_experiment_id',80157,'project_id',137],['nd_experiment_project_id',80154,'nd_experiment_id',80158,'project_id',137],['nd_experiment_project_id',80155,'nd_experiment_id',80159,'project_id',137],['nd_experiment_project_id',80156,'nd_experiment_id',80160,'project_id',137],['nd_experiment_project_id',80157,'nd_experiment_id',80161,'project_id',137],['nd_experiment_project_id',80158,'nd_experiment_id',80162,'project_id',137],['nd_experiment_project_id',80159,'nd_experiment_id',80163,'project_id',137],['nd_experiment_project_id',80160,'nd_experiment_id',80164,'project_id',137],['nd_experiment_project_id',80161,'nd_experiment_id',80165,'project_id',137],['nd_experiment_project_id',80162,'nd_experiment_id',80166,'project_id',137],['nd_experiment_project_id',80163,'nd_experiment_id',80167,'project_id',137],['nd_experiment_project_id',80164,'nd_experiment_id',80168,'project_id',137],['nd_experiment_project_id',80165,'nd_experiment_id',80169,'project_id',137],['nd_experiment_project_id',80166,'nd_experiment_id',80170,'project_id',137],['nd_experiment_project_id',80167,'nd_experiment_id',80171,'project_id',137],['nd_experiment_project_id',80168,'nd_experiment_id',80172,'project_id',137],['nd_experiment_project_id',80169,'nd_experiment_id',80173,'project_id',137],['nd_experiment_project_id',80170,'nd_experiment_id',80174,'project_id',137],['nd_experiment_project_id',80171,'nd_experiment_id',80175,'project_id',137],['nd_experiment_project_id',80172,'nd_experiment_id',80176,'project_id',137],['nd_experiment_project_id',80173,'nd_experiment_id',80177,'project_id',137],['nd_experiment_project_id',80174,'nd_experiment_id',80178,'project_id',137],['nd_experiment_project_id',80175,'nd_experiment_id',80179,'project_id',137],['nd_experiment_project_id',80176,'nd_experiment_id',80180,'project_id',137],['nd_experiment_project_id',80177,'nd_experiment_id',80181,'project_id',137],['nd_experiment_project_id',80178,'nd_experiment_id',80182,'project_id',137],['nd_experiment_project_id',80179,'nd_experiment_id',80183,'project_id',137],['nd_experiment_project_id',80180,'nd_experiment_id',80184,'project_id',137],['nd_experiment_project_id',80181,'nd_experiment_id',80185,'project_id',137],['nd_experiment_project_id',80182,'nd_experiment_id',80186,'project_id',137],['nd_experiment_project_id',80183,'nd_experiment_id',80187,'project_id',137],['nd_experiment_project_id',80184,'nd_experiment_id',80188,'project_id',137],['nd_experiment_project_id',80185,'nd_experiment_id',80189,'project_id',137],['nd_experiment_project_id',80186,'nd_experiment_id',80190,'project_id',137],['nd_experiment_project_id',80187,'nd_experiment_id',80191,'project_id',137],['nd_experiment_project_id',80188,'nd_experiment_id',80192,'project_id',137],['nd_experiment_project_id',80189,'nd_experiment_id',80193,'project_id',137],['nd_experiment_project_id',80190,'nd_experiment_id',80194,'project_id',137],['nd_experiment_project_id',80191,'nd_experiment_id',80195,'project_id',137],['nd_experiment_project_id',80192,'nd_experiment_id',80196,'project_id',137],['nd_experiment_project_id',80193,'nd_experiment_id',80197,'project_id',137],['nd_experiment_project_id',80194,'nd_experiment_id',80198,'project_id',137],['nd_experiment_project_id',80195,'nd_experiment_id',80199,'project_id',137],['nd_experiment_project_id',80196,'nd_experiment_id',80200,'project_id',137],['nd_experiment_project_id',80197,'nd_experiment_id',80201,'project_id',137],['nd_experiment_project_id',80198,'nd_experiment_id',80202,'project_id',137],['nd_experiment_project_id',80199,'nd_experiment_id',80203,'project_id',137],['nd_experiment_project_id',80200,'nd_experiment_id',80204,'project_id',137],['nd_experiment_project_id',80201,'nd_experiment_id',80205,'project_id',137],['nd_experiment_project_id',80202,'nd_experiment_id',80206,'project_id',137],['nd_experiment_project_id',80203,'nd_experiment_id',80207,'project_id',137],['nd_experiment_project_id',80204,'nd_experiment_id',80208,'project_id',137],['nd_experiment_project_id',80205,'nd_experiment_id',80209,'project_id',137],['nd_experiment_project_id',80206,'nd_experiment_id',80210,'project_id',137],['nd_experiment_project_id',80207,'nd_experiment_id',80211,'project_id',137],['nd_experiment_project_id',80208,'nd_experiment_id',80212,'project_id',137],['nd_experiment_project_id',80209,'nd_experiment_id',80213,'project_id',137],['nd_experiment_project_id',80210,'nd_experiment_id',80214,'project_id',137],['nd_experiment_project_id',80211,'nd_experiment_id',80215,'project_id',137],['nd_experiment_project_id',80212,'nd_experiment_id',80216,'project_id',137],['nd_experiment_project_id',80213,'nd_experiment_id',80217,'project_id',137],['nd_experiment_project_id',80214,'nd_experiment_id',80218,'project_id',137],['nd_experiment_project_id',80215,'nd_experiment_id',80219,'project_id',137],['nd_experiment_project_id',80216,'nd_experiment_id',80220,'project_id',137],['nd_experiment_project_id',80217,'nd_experiment_id',80221,'project_id',137],['nd_experiment_project_id',80218,'nd_experiment_id',80222,'project_id',137],['nd_experiment_project_id',80219,'nd_experiment_id',80223,'project_id',137],['nd_experiment_project_id',80220,'nd_experiment_id',80224,'project_id',137],['nd_experiment_project_id',80221,'nd_experiment_id',80225,'project_id',137],['nd_experiment_project_id',80222,'nd_experiment_id',80226,'project_id',137],['nd_experiment_project_id',80223,'nd_experiment_id',80227,'project_id',137],['nd_experiment_project_id',80224,'nd_experiment_id',80228,'project_id',137],['nd_experiment_project_id',80225,'nd_experiment_id',80229,'project_id',137],['nd_experiment_project_id',80226,'nd_experiment_id',80230,'project_id',137],['nd_experiment_project_id',80227,'nd_experiment_id',80231,'project_id',137],['nd_experiment_project_id',80228,'nd_experiment_id',80232,'project_id',137],['nd_experiment_project_id',80229,'nd_experiment_id',80233,'project_id',137],['nd_experiment_project_id',80230,'nd_experiment_id',80234,'project_id',137],['nd_experiment_project_id',80231,'nd_experiment_id',80235,'project_id',137],['nd_experiment_project_id',80232,'nd_experiment_id',80236,'project_id',137],['nd_experiment_project_id',80233,'nd_experiment_id',80237,'project_id',137],['nd_experiment_project_id',80234,'nd_experiment_id',80238,'project_id',137],['nd_experiment_project_id',80235,'nd_experiment_id',80239,'project_id',137],['nd_experiment_project_id',80236,'nd_experiment_id',80240,'project_id',137],['nd_experiment_project_id',80237,'nd_experiment_id',80241,'project_id',137],['nd_experiment_project_id',80238,'nd_experiment_id',80242,'project_id',137],['nd_experiment_project_id',80239,'nd_experiment_id',80243,'project_id',137],['nd_experiment_project_id',80240,'nd_experiment_id',80244,'project_id',137],['nd_experiment_project_id',80241,'nd_experiment_id',80245,'project_id',137],['nd_experiment_project_id',80242,'nd_experiment_id',80246,'project_id',137],['nd_experiment_project_id',80243,'nd_experiment_id',80247,'project_id',137],['nd_experiment_project_id',80244,'nd_experiment_id',80248,'project_id',137],['nd_experiment_project_id',80245,'nd_experiment_id',80249,'project_id',137],['nd_experiment_project_id',80246,'nd_experiment_id',80250,'project_id',137],['nd_experiment_project_id',80247,'nd_experiment_id',80251,'project_id',137],['nd_experiment_project_id',80248,'nd_experiment_id',80252,'project_id',137],['nd_experiment_project_id',80249,'nd_experiment_id',80253,'project_id',137],['nd_experiment_project_id',80250,'nd_experiment_id',80254,'project_id',137],['nd_experiment_project_id',80251,'nd_experiment_id',80255,'project_id',137],['nd_experiment_project_id',80252,'nd_experiment_id',80256,'project_id',137],['nd_experiment_project_id',80253,'nd_experiment_id',80257,'project_id',137],['nd_experiment_project_id',80254,'nd_experiment_id',80258,'project_id',137],['nd_experiment_project_id',80255,'nd_experiment_id',80259,'project_id',137],['nd_experiment_project_id',80256,'nd_experiment_id',80260,'project_id',137],['nd_experiment_project_id',80257,'nd_experiment_id',80261,'project_id',137],['nd_experiment_project_id',80258,'nd_experiment_id',80262,'project_id',137],['nd_experiment_project_id',80259,'nd_experiment_id',80263,'project_id',137],['nd_experiment_project_id',80260,'nd_experiment_id',80264,'project_id',137],['nd_experiment_project_id',80261,'nd_experiment_id',80265,'project_id',137],['nd_experiment_project_id',80262,'nd_experiment_id',80266,'project_id',137],['nd_experiment_project_id',80263,'nd_experiment_id',80267,'project_id',137],['nd_experiment_project_id',80264,'nd_experiment_id',80268,'project_id',137],['nd_experiment_project_id',80265,'nd_experiment_id',80269,'project_id',137],['nd_experiment_project_id',80266,'nd_experiment_id',80270,'project_id',137],['nd_experiment_project_id',80267,'nd_experiment_id',80271,'project_id',137],['nd_experiment_project_id',80268,'nd_experiment_id',80272,'project_id',137],['nd_experiment_project_id',80269,'nd_experiment_id',80273,'project_id',137],['nd_experiment_project_id',80270,'nd_experiment_id',80274,'project_id',137],['nd_experiment_project_id',80271,'nd_experiment_id',80275,'project_id',137],['nd_experiment_project_id',80272,'nd_experiment_id',80276,'project_id',137],['nd_experiment_project_id',80273,'nd_experiment_id',80277,'project_id',137],['nd_experiment_project_id',80274,'nd_experiment_id',80278,'project_id',137],['nd_experiment_project_id',80275,'nd_experiment_id',80279,'project_id',137],['nd_experiment_project_id',80276,'nd_experiment_id',80280,'project_id',137],['nd_experiment_project_id',80277,'nd_experiment_id',80281,'project_id',137],['nd_experiment_project_id',80278,'nd_experiment_id',80282,'project_id',137],['nd_experiment_project_id',80279,'nd_experiment_id',80283,'project_id',137],['nd_experiment_project_id',80280,'nd_experiment_id',80284,'project_id',137],['nd_experiment_project_id',80281,'nd_experiment_id',80285,'project_id',137],['nd_experiment_project_id',80282,'nd_experiment_id',80286,'project_id',137],['nd_experiment_project_id',80283,'nd_experiment_id',80287,'project_id',137],['nd_experiment_project_id',80284,'nd_experiment_id',80288,'project_id',137],['nd_experiment_project_id',80285,'nd_experiment_id',80289,'project_id',137],['nd_experiment_project_id',80286,'nd_experiment_id',80290,'project_id',137],['nd_experiment_project_id',80287,'nd_experiment_id',80291,'project_id',137],['nd_experiment_project_id',80288,'nd_experiment_id',80292,'project_id',137],['nd_experiment_project_id',80289,'nd_experiment_id',80293,'project_id',137],['nd_experiment_project_id',80290,'nd_experiment_id',80294,'project_id',137],['nd_experiment_project_id',80291,'nd_experiment_id',80295,'project_id',137],['nd_experiment_project_id',80292,'nd_experiment_id',80296,'project_id',137],['nd_experiment_project_id',80293,'nd_experiment_id',80297,'project_id',137],['nd_experiment_project_id',80294,'nd_experiment_id',80298,'project_id',137],['nd_experiment_project_id',80295,'nd_experiment_id',80299,'project_id',137],['nd_experiment_project_id',80296,'nd_experiment_id',80300,'project_id',137],['nd_experiment_project_id',80297,'nd_experiment_id',80301,'project_id',137],['nd_experiment_project_id',80298,'nd_experiment_id',80302,'project_id',137],['nd_experiment_project_id',80299,'nd_experiment_id',80303,'project_id',137],['nd_experiment_project_id',80300,'nd_experiment_id',80304,'project_id',137],['nd_experiment_project_id',80301,'nd_experiment_id',80305,'project_id',137],['nd_experiment_project_id',80302,'nd_experiment_id',80306,'project_id',137],['nd_experiment_project_id',80303,'nd_experiment_id',80307,'project_id',137],['nd_experiment_project_id',80304,'nd_experiment_id',80308,'project_id',137],['nd_experiment_project_id',80305,'nd_experiment_id',80309,'project_id',137],['nd_experiment_project_id',80306,'nd_experiment_id',80310,'project_id',137],['nd_experiment_project_id',80307,'nd_experiment_id',80311,'project_id',137],['nd_experiment_project_id',80308,'nd_experiment_id',80312,'project_id',137],['nd_experiment_project_id',80309,'nd_experiment_id',80313,'project_id',137],['nd_experiment_project_id',80310,'nd_experiment_id',80314,'project_id',137],['nd_experiment_project_id',80311,'nd_experiment_id',80315,'project_id',137],['nd_experiment_project_id',80312,'nd_experiment_id',80316,'project_id',137],['nd_experiment_project_id',80313,'nd_experiment_id',80317,'project_id',137],['nd_experiment_project_id',80314,'nd_experiment_id',80318,'project_id',137],['nd_experiment_project_id',80315,'nd_experiment_id',80319,'project_id',137],['nd_experiment_project_id',80316,'nd_experiment_id',80320,'project_id',137],['nd_experiment_project_id',80317,'nd_experiment_id',80321,'project_id',137],['nd_experiment_project_id',80318,'nd_experiment_id',80322,'project_id',137],['nd_experiment_project_id',80319,'nd_experiment_id',80323,'project_id',137],['nd_experiment_project_id',80320,'nd_experiment_id',80324,'project_id',137],['nd_experiment_project_id',80321,'nd_experiment_id',80325,'project_id',137],['nd_experiment_project_id',80322,'nd_experiment_id',80326,'project_id',137],['nd_experiment_project_id',80323,'nd_experiment_id',80327,'project_id',137],['nd_experiment_project_id',80324,'nd_experiment_id',80328,'project_id',137],['nd_experiment_project_id',80325,'nd_experiment_id',80329,'project_id',137],['nd_experiment_project_id',80326,'nd_experiment_id',80330,'project_id',137],['nd_experiment_project_id',80327,'nd_experiment_id',80331,'project_id',137],['nd_experiment_project_id',80328,'nd_experiment_id',80332,'project_id',137],['nd_experiment_project_id',80329,'nd_experiment_id',80333,'project_id',137],['nd_experiment_project_id',80330,'nd_experiment_id',80334,'project_id',137],['nd_experiment_project_id',80331,'nd_experiment_id',80335,'project_id',137],['nd_experiment_project_id',80332,'nd_experiment_id',80336,'project_id',137],['nd_experiment_project_id',80333,'nd_experiment_id',80337,'project_id',137],['nd_experiment_project_id',80334,'nd_experiment_id',80338,'project_id',137],['nd_experiment_project_id',80335,'nd_experiment_id',80339,'project_id',137],['nd_experiment_project_id',80336,'nd_experiment_id',80340,'project_id',137],['nd_experiment_project_id',80337,'nd_experiment_id',80341,'project_id',137],['nd_experiment_project_id',80338,'nd_experiment_id',80342,'project_id',137],['nd_experiment_project_id',80339,'nd_experiment_id',80343,'project_id',137],['nd_experiment_project_id',80340,'nd_experiment_id',80344,'project_id',137],['nd_experiment_project_id',80341,'nd_experiment_id',80345,'project_id',137],['nd_experiment_project_id',80342,'nd_experiment_id',80346,'project_id',137],['nd_experiment_project_id',80343,'nd_experiment_id',80347,'project_id',137]];

#is_deeply(\@exp_proj_table, $exp_proj_table_check, 'check ndexperimentproject table data state' );



#my $exp_stock_table_check = [['nd_experiment_stock_id',81035,'nd_experiment_id',80025,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81036,'nd_experiment_id',80026,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81037,'nd_experiment_id',80027,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81038,'nd_experiment_id',80028,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81039,'nd_experiment_id',80029,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81040,'nd_experiment_id',80030,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81041,'nd_experiment_id',80031,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81042,'nd_experiment_id',80032,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81043,'nd_experiment_id',80033,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81044,'nd_experiment_id',80034,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81045,'nd_experiment_id',80035,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81046,'nd_experiment_id',80036,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81047,'nd_experiment_id',80037,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81048,'nd_experiment_id',80038,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81049,'nd_experiment_id',80039,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81050,'nd_experiment_id',80040,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81051,'nd_experiment_id',80041,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81052,'nd_experiment_id',80042,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81053,'nd_experiment_id',80043,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81054,'nd_experiment_id',80044,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81055,'nd_experiment_id',80045,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81056,'nd_experiment_id',80046,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81057,'nd_experiment_id',80047,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81058,'nd_experiment_id',80048,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81059,'nd_experiment_id',80049,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81060,'nd_experiment_id',80050,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81061,'nd_experiment_id',80051,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81062,'nd_experiment_id',80052,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81063,'nd_experiment_id',80053,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81064,'nd_experiment_id',80054,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81065,'nd_experiment_id',80055,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81066,'nd_experiment_id',80056,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81067,'nd_experiment_id',80057,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81068,'nd_experiment_id',80058,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81069,'nd_experiment_id',80059,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81070,'nd_experiment_id',80060,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81071,'nd_experiment_id',80061,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81072,'nd_experiment_id',80062,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81073,'nd_experiment_id',80063,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81074,'nd_experiment_id',80064,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81075,'nd_experiment_id',80065,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81076,'nd_experiment_id',80066,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81077,'nd_experiment_id',80067,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81078,'nd_experiment_id',80068,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81079,'nd_experiment_id',80069,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81080,'nd_experiment_id',80070,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81081,'nd_experiment_id',80071,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81082,'nd_experiment_id',80072,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81083,'nd_experiment_id',80073,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81084,'nd_experiment_id',80074,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81085,'nd_experiment_id',80075,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81086,'nd_experiment_id',80076,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81087,'nd_experiment_id',80077,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81088,'nd_experiment_id',80078,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81089,'nd_experiment_id',80079,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81090,'nd_experiment_id',80080,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81091,'nd_experiment_id',80081,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81092,'nd_experiment_id',80082,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81093,'nd_experiment_id',80083,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81094,'nd_experiment_id',80084,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81095,'nd_experiment_id',80085,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81096,'nd_experiment_id',80086,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81097,'nd_experiment_id',80087,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81098,'nd_experiment_id',80088,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81099,'nd_experiment_id',80089,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81100,'nd_experiment_id',80090,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81101,'nd_experiment_id',80091,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81102,'nd_experiment_id',80092,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81103,'nd_experiment_id',80093,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81104,'nd_experiment_id',80094,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81105,'nd_experiment_id',80095,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81106,'nd_experiment_id',80096,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81107,'nd_experiment_id',80097,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81108,'nd_experiment_id',80098,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81109,'nd_experiment_id',80099,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81110,'nd_experiment_id',80100,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81111,'nd_experiment_id',80101,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81112,'nd_experiment_id',80102,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81113,'nd_experiment_id',80103,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81114,'nd_experiment_id',80104,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81115,'nd_experiment_id',80105,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81116,'nd_experiment_id',80106,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81117,'nd_experiment_id',80107,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81118,'nd_experiment_id',80108,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81119,'nd_experiment_id',80109,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81120,'nd_experiment_id',80110,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81121,'nd_experiment_id',80111,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81122,'nd_experiment_id',80112,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81123,'nd_experiment_id',80113,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81124,'nd_experiment_id',80114,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81125,'nd_experiment_id',80115,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81126,'nd_experiment_id',80116,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81127,'nd_experiment_id',80117,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81128,'nd_experiment_id',80118,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81129,'nd_experiment_id',80119,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81130,'nd_experiment_id',80120,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81131,'nd_experiment_id',80121,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81132,'nd_experiment_id',80122,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81133,'nd_experiment_id',80123,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81134,'nd_experiment_id',80124,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81135,'nd_experiment_id',80125,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81136,'nd_experiment_id',80126,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81137,'nd_experiment_id',80127,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81138,'nd_experiment_id',80128,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81139,'nd_experiment_id',80129,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81140,'nd_experiment_id',80130,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81141,'nd_experiment_id',80131,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81142,'nd_experiment_id',80132,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81143,'nd_experiment_id',80133,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81144,'nd_experiment_id',80134,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81145,'nd_experiment_id',80135,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81146,'nd_experiment_id',80136,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81147,'nd_experiment_id',80137,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81148,'nd_experiment_id',80138,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81149,'nd_experiment_id',80139,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81150,'nd_experiment_id',80140,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81151,'nd_experiment_id',80141,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81152,'nd_experiment_id',80142,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81153,'nd_experiment_id',80143,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81154,'nd_experiment_id',80144,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81155,'nd_experiment_id',80145,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81156,'nd_experiment_id',80146,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81157,'nd_experiment_id',80147,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81158,'nd_experiment_id',80148,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81159,'nd_experiment_id',80149,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81160,'nd_experiment_id',80150,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81161,'nd_experiment_id',80151,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81162,'nd_experiment_id',80152,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81163,'nd_experiment_id',80153,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81164,'nd_experiment_id',80154,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81165,'nd_experiment_id',80155,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81166,'nd_experiment_id',80156,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81167,'nd_experiment_id',80157,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81168,'nd_experiment_id',80158,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81169,'nd_experiment_id',80159,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81170,'nd_experiment_id',80160,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81171,'nd_experiment_id',80161,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81172,'nd_experiment_id',80162,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81173,'nd_experiment_id',80163,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81174,'nd_experiment_id',80164,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81175,'nd_experiment_id',80165,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81176,'nd_experiment_id',80166,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81177,'nd_experiment_id',80167,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81178,'nd_experiment_id',80168,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81179,'nd_experiment_id',80169,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81180,'nd_experiment_id',80170,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81181,'nd_experiment_id',80171,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81182,'nd_experiment_id',80172,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81183,'nd_experiment_id',80173,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81184,'nd_experiment_id',80174,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81185,'nd_experiment_id',80175,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81186,'nd_experiment_id',80176,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81187,'nd_experiment_id',80177,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81188,'nd_experiment_id',80178,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81189,'nd_experiment_id',80179,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81190,'nd_experiment_id',80180,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81191,'nd_experiment_id',80181,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81192,'nd_experiment_id',80182,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81193,'nd_experiment_id',80183,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81194,'nd_experiment_id',80184,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81195,'nd_experiment_id',80185,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81196,'nd_experiment_id',80186,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81197,'nd_experiment_id',80187,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81198,'nd_experiment_id',80188,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81199,'nd_experiment_id',80189,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81200,'nd_experiment_id',80190,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81201,'nd_experiment_id',80191,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81202,'nd_experiment_id',80192,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81203,'nd_experiment_id',80193,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81204,'nd_experiment_id',80194,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81205,'nd_experiment_id',80195,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81206,'nd_experiment_id',80196,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81207,'nd_experiment_id',80197,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81208,'nd_experiment_id',80198,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81209,'nd_experiment_id',80199,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81210,'nd_experiment_id',80200,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81211,'nd_experiment_id',80201,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81212,'nd_experiment_id',80202,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81213,'nd_experiment_id',80203,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81214,'nd_experiment_id',80204,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81215,'nd_experiment_id',80205,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81216,'nd_experiment_id',80206,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81217,'nd_experiment_id',80207,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81218,'nd_experiment_id',80208,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81219,'nd_experiment_id',80209,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81220,'nd_experiment_id',80210,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81221,'nd_experiment_id',80211,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81222,'nd_experiment_id',80212,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81223,'nd_experiment_id',80213,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81224,'nd_experiment_id',80214,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81225,'nd_experiment_id',80215,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81226,'nd_experiment_id',80216,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81227,'nd_experiment_id',80217,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81228,'nd_experiment_id',80218,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81229,'nd_experiment_id',80219,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81230,'nd_experiment_id',80220,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81231,'nd_experiment_id',80221,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81232,'nd_experiment_id',80222,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81233,'nd_experiment_id',80223,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81234,'nd_experiment_id',80224,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81235,'nd_experiment_id',80225,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81236,'nd_experiment_id',80226,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81237,'nd_experiment_id',80227,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81238,'nd_experiment_id',80228,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81239,'nd_experiment_id',80229,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81240,'nd_experiment_id',80230,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81241,'nd_experiment_id',80231,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81242,'nd_experiment_id',80232,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81243,'nd_experiment_id',80233,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81244,'nd_experiment_id',80234,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81245,'nd_experiment_id',80235,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81246,'nd_experiment_id',80236,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81247,'nd_experiment_id',80237,'stock_id',38857,'type_id',76391],['nd_experiment_stock_id',81248,'nd_experiment_id',80238,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81249,'nd_experiment_id',80239,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81250,'nd_experiment_id',80240,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81251,'nd_experiment_id',80241,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81252,'nd_experiment_id',80242,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81253,'nd_experiment_id',80243,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81254,'nd_experiment_id',80244,'stock_id',38866,'type_id',76391],['nd_experiment_stock_id',81255,'nd_experiment_id',80245,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81256,'nd_experiment_id',80246,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81257,'nd_experiment_id',80247,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81258,'nd_experiment_id',80248,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81259,'nd_experiment_id',80249,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81260,'nd_experiment_id',80250,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81261,'nd_experiment_id',80251,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81262,'nd_experiment_id',80252,'stock_id',38867,'type_id',76391],['nd_experiment_stock_id',81263,'nd_experiment_id',80253,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81264,'nd_experiment_id',80254,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81265,'nd_experiment_id',80255,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81266,'nd_experiment_id',80256,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81267,'nd_experiment_id',80257,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81268,'nd_experiment_id',80258,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81269,'nd_experiment_id',80259,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81270,'nd_experiment_id',80260,'stock_id',38868,'type_id',76391],['nd_experiment_stock_id',81271,'nd_experiment_id',80261,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81272,'nd_experiment_id',80262,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81273,'nd_experiment_id',80263,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81274,'nd_experiment_id',80264,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81275,'nd_experiment_id',80265,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81276,'nd_experiment_id',80266,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81277,'nd_experiment_id',80267,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81278,'nd_experiment_id',80268,'stock_id',38869,'type_id',76391],['nd_experiment_stock_id',81279,'nd_experiment_id',80269,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81280,'nd_experiment_id',80270,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81281,'nd_experiment_id',80271,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81282,'nd_experiment_id',80272,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81283,'nd_experiment_id',80273,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81284,'nd_experiment_id',80274,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81285,'nd_experiment_id',80275,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81286,'nd_experiment_id',80276,'stock_id',38870,'type_id',76391],['nd_experiment_stock_id',81287,'nd_experiment_id',80277,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81288,'nd_experiment_id',80278,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81289,'nd_experiment_id',80279,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81290,'nd_experiment_id',80280,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81291,'nd_experiment_id',80281,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81292,'nd_experiment_id',80282,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81293,'nd_experiment_id',80283,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81294,'nd_experiment_id',80284,'stock_id',38871,'type_id',76391],['nd_experiment_stock_id',81295,'nd_experiment_id',80285,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81296,'nd_experiment_id',80286,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81297,'nd_experiment_id',80287,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81298,'nd_experiment_id',80288,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81299,'nd_experiment_id',80289,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81300,'nd_experiment_id',80290,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81301,'nd_experiment_id',80291,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81302,'nd_experiment_id',80292,'stock_id',38858,'type_id',76391],['nd_experiment_stock_id',81303,'nd_experiment_id',80293,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81304,'nd_experiment_id',80294,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81305,'nd_experiment_id',80295,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81306,'nd_experiment_id',80296,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81307,'nd_experiment_id',80297,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81308,'nd_experiment_id',80298,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81309,'nd_experiment_id',80299,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81310,'nd_experiment_id',80300,'stock_id',38859,'type_id',76391],['nd_experiment_stock_id',81311,'nd_experiment_id',80301,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81312,'nd_experiment_id',80302,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81313,'nd_experiment_id',80303,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81314,'nd_experiment_id',80304,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81315,'nd_experiment_id',80305,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81316,'nd_experiment_id',80306,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81317,'nd_experiment_id',80307,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81318,'nd_experiment_id',80308,'stock_id',38860,'type_id',76391],['nd_experiment_stock_id',81319,'nd_experiment_id',80309,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81320,'nd_experiment_id',80310,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81321,'nd_experiment_id',80311,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81322,'nd_experiment_id',80312,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81323,'nd_experiment_id',80313,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81324,'nd_experiment_id',80314,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81325,'nd_experiment_id',80315,'stock_id',38861,'type_id',76391],['nd_experiment_stock_id',81326,'nd_experiment_id',80316,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81327,'nd_experiment_id',80317,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81328,'nd_experiment_id',80318,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81329,'nd_experiment_id',80319,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81330,'nd_experiment_id',80320,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81331,'nd_experiment_id',80321,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81332,'nd_experiment_id',80322,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81333,'nd_experiment_id',80323,'stock_id',38862,'type_id',76391],['nd_experiment_stock_id',81334,'nd_experiment_id',80324,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81335,'nd_experiment_id',80325,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81336,'nd_experiment_id',80326,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81337,'nd_experiment_id',80327,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81338,'nd_experiment_id',80328,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81339,'nd_experiment_id',80329,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81340,'nd_experiment_id',80330,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81341,'nd_experiment_id',80331,'stock_id',38863,'type_id',76391],['nd_experiment_stock_id',81342,'nd_experiment_id',80332,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81343,'nd_experiment_id',80333,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81344,'nd_experiment_id',80334,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81345,'nd_experiment_id',80335,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81346,'nd_experiment_id',80336,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81347,'nd_experiment_id',80337,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81348,'nd_experiment_id',80338,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81349,'nd_experiment_id',80339,'stock_id',38864,'type_id',76391],['nd_experiment_stock_id',81350,'nd_experiment_id',80340,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81351,'nd_experiment_id',80341,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81352,'nd_experiment_id',80342,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81353,'nd_experiment_id',80343,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81354,'nd_experiment_id',80344,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81355,'nd_experiment_id',80345,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81356,'nd_experiment_id',80346,'stock_id',38865,'type_id',76391],['nd_experiment_stock_id',81357,'nd_experiment_id',80347,'stock_id',38865,'type_id',76391]];

#is_deeply(\@exp_stock_table, $exp_stock_table_check, 'check ndexperimentstock table data state' );



#my $exp_pheno_table_check = [['nd_experiment_phenotype_id',1487281,'nd_experiment_id',80025,'phenotype_id',740336],['nd_experiment_phenotype_id',1487282,'nd_experiment_id',80026,'phenotype_id',740337],['nd_experiment_phenotype_id',1487283,'nd_experiment_id',80027,'phenotype_id',740338],['nd_experiment_phenotype_id',1487284,'nd_experiment_id',80028,'phenotype_id',740339],['nd_experiment_phenotype_id',1487285,'nd_experiment_id',80029,'phenotype_id',740340],['nd_experiment_phenotype_id',1487286,'nd_experiment_id',80030,'phenotype_id',740341],['nd_experiment_phenotype_id',1487287,'nd_experiment_id',80031,'phenotype_id',740342],['nd_experiment_phenotype_id',1487288,'nd_experiment_id',80032,'phenotype_id',740343],['nd_experiment_phenotype_id',1487289,'nd_experiment_id',80033,'phenotype_id',740344],['nd_experiment_phenotype_id',1487290,'nd_experiment_id',80034,'phenotype_id',740345],['nd_experiment_phenotype_id',1487291,'nd_experiment_id',80035,'phenotype_id',740346],['nd_experiment_phenotype_id',1487292,'nd_experiment_id',80036,'phenotype_id',740347],['nd_experiment_phenotype_id',1487293,'nd_experiment_id',80037,'phenotype_id',740348],['nd_experiment_phenotype_id',1487294,'nd_experiment_id',80038,'phenotype_id',740349],['nd_experiment_phenotype_id',1487295,'nd_experiment_id',80039,'phenotype_id',740350],['nd_experiment_phenotype_id',1487296,'nd_experiment_id',80040,'phenotype_id',740351],['nd_experiment_phenotype_id',1487297,'nd_experiment_id',80041,'phenotype_id',740352],['nd_experiment_phenotype_id',1487298,'nd_experiment_id',80042,'phenotype_id',740353],['nd_experiment_phenotype_id',1487299,'nd_experiment_id',80043,'phenotype_id',740354],['nd_experiment_phenotype_id',1487300,'nd_experiment_id',80044,'phenotype_id',740355],['nd_experiment_phenotype_id',1487301,'nd_experiment_id',80045,'phenotype_id',740356],['nd_experiment_phenotype_id',1487302,'nd_experiment_id',80046,'phenotype_id',740357],['nd_experiment_phenotype_id',1487303,'nd_experiment_id',80047,'phenotype_id',740358],['nd_experiment_phenotype_id',1487304,'nd_experiment_id',80048,'phenotype_id',740359],['nd_experiment_phenotype_id',1487305,'nd_experiment_id',80049,'phenotype_id',740360],['nd_experiment_phenotype_id',1487306,'nd_experiment_id',80050,'phenotype_id',740361],['nd_experiment_phenotype_id',1487307,'nd_experiment_id',80051,'phenotype_id',740362],['nd_experiment_phenotype_id',1487308,'nd_experiment_id',80052,'phenotype_id',740363],['nd_experiment_phenotype_id',1487309,'nd_experiment_id',80053,'phenotype_id',740364],['nd_experiment_phenotype_id',1487310,'nd_experiment_id',80054,'phenotype_id',740365],['nd_experiment_phenotype_id',1487311,'nd_experiment_id',80055,'phenotype_id',740366],['nd_experiment_phenotype_id',1487312,'nd_experiment_id',80056,'phenotype_id',740367],['nd_experiment_phenotype_id',1487313,'nd_experiment_id',80057,'phenotype_id',740368],['nd_experiment_phenotype_id',1487314,'nd_experiment_id',80058,'phenotype_id',740369],['nd_experiment_phenotype_id',1487315,'nd_experiment_id',80059,'phenotype_id',740370],['nd_experiment_phenotype_id',1487316,'nd_experiment_id',80060,'phenotype_id',740371],['nd_experiment_phenotype_id',1487317,'nd_experiment_id',80061,'phenotype_id',740372],['nd_experiment_phenotype_id',1487318,'nd_experiment_id',80062,'phenotype_id',740373],['nd_experiment_phenotype_id',1487319,'nd_experiment_id',80063,'phenotype_id',740374],['nd_experiment_phenotype_id',1487320,'nd_experiment_id',80064,'phenotype_id',740375],['nd_experiment_phenotype_id',1487321,'nd_experiment_id',80065,'phenotype_id',740376],['nd_experiment_phenotype_id',1487322,'nd_experiment_id',80066,'phenotype_id',740377],['nd_experiment_phenotype_id',1487323,'nd_experiment_id',80067,'phenotype_id',740378],['nd_experiment_phenotype_id',1487324,'nd_experiment_id',80068,'phenotype_id',740379],['nd_experiment_phenotype_id',1487325,'nd_experiment_id',80069,'phenotype_id',740380],['nd_experiment_phenotype_id',1487326,'nd_experiment_id',80070,'phenotype_id',740381],['nd_experiment_phenotype_id',1487327,'nd_experiment_id',80071,'phenotype_id',740382],['nd_experiment_phenotype_id',1487328,'nd_experiment_id',80072,'phenotype_id',740383],['nd_experiment_phenotype_id',1487329,'nd_experiment_id',80073,'phenotype_id',740384],['nd_experiment_phenotype_id',1487330,'nd_experiment_id',80074,'phenotype_id',740385],['nd_experiment_phenotype_id',1487331,'nd_experiment_id',80075,'phenotype_id',740386],['nd_experiment_phenotype_id',1487332,'nd_experiment_id',80076,'phenotype_id',740387],['nd_experiment_phenotype_id',1487333,'nd_experiment_id',80077,'phenotype_id',740388],['nd_experiment_phenotype_id',1487334,'nd_experiment_id',80078,'phenotype_id',740389],['nd_experiment_phenotype_id',1487335,'nd_experiment_id',80079,'phenotype_id',740390],['nd_experiment_phenotype_id',1487336,'nd_experiment_id',80080,'phenotype_id',740391],['nd_experiment_phenotype_id',1487337,'nd_experiment_id',80081,'phenotype_id',740392],['nd_experiment_phenotype_id',1487338,'nd_experiment_id',80082,'phenotype_id',740393],['nd_experiment_phenotype_id',1487339,'nd_experiment_id',80083,'phenotype_id',740394],['nd_experiment_phenotype_id',1487340,'nd_experiment_id',80084,'phenotype_id',740395],['nd_experiment_phenotype_id',1487341,'nd_experiment_id',80085,'phenotype_id',740396],['nd_experiment_phenotype_id',1487342,'nd_experiment_id',80086,'phenotype_id',740397],['nd_experiment_phenotype_id',1487343,'nd_experiment_id',80087,'phenotype_id',740398],['nd_experiment_phenotype_id',1487344,'nd_experiment_id',80088,'phenotype_id',740399],['nd_experiment_phenotype_id',1487345,'nd_experiment_id',80089,'phenotype_id',740400],['nd_experiment_phenotype_id',1487346,'nd_experiment_id',80090,'phenotype_id',740401],['nd_experiment_phenotype_id',1487347,'nd_experiment_id',80091,'phenotype_id',740402],['nd_experiment_phenotype_id',1487348,'nd_experiment_id',80092,'phenotype_id',740403],['nd_experiment_phenotype_id',1487349,'nd_experiment_id',80093,'phenotype_id',740404],['nd_experiment_phenotype_id',1487350,'nd_experiment_id',80094,'phenotype_id',740405],['nd_experiment_phenotype_id',1487351,'nd_experiment_id',80095,'phenotype_id',740406],['nd_experiment_phenotype_id',1487352,'nd_experiment_id',80096,'phenotype_id',740407],['nd_experiment_phenotype_id',1487353,'nd_experiment_id',80097,'phenotype_id',740408],['nd_experiment_phenotype_id',1487354,'nd_experiment_id',80098,'phenotype_id',740409],['nd_experiment_phenotype_id',1487355,'nd_experiment_id',80099,'phenotype_id',740410],['nd_experiment_phenotype_id',1487356,'nd_experiment_id',80100,'phenotype_id',740411],['nd_experiment_phenotype_id',1487357,'nd_experiment_id',80101,'phenotype_id',740412],['nd_experiment_phenotype_id',1487358,'nd_experiment_id',80102,'phenotype_id',740413],['nd_experiment_phenotype_id',1487359,'nd_experiment_id',80103,'phenotype_id',740414],['nd_experiment_phenotype_id',1487360,'nd_experiment_id',80104,'phenotype_id',740415],['nd_experiment_phenotype_id',1487361,'nd_experiment_id',80105,'phenotype_id',740416],['nd_experiment_phenotype_id',1487362,'nd_experiment_id',80106,'phenotype_id',740417],['nd_experiment_phenotype_id',1487363,'nd_experiment_id',80107,'phenotype_id',740418],['nd_experiment_phenotype_id',1487364,'nd_experiment_id',80108,'phenotype_id',740419],['nd_experiment_phenotype_id',1487365,'nd_experiment_id',80109,'phenotype_id',740420],['nd_experiment_phenotype_id',1487366,'nd_experiment_id',80110,'phenotype_id',740421],['nd_experiment_phenotype_id',1487367,'nd_experiment_id',80111,'phenotype_id',740422],['nd_experiment_phenotype_id',1487368,'nd_experiment_id',80112,'phenotype_id',740423],['nd_experiment_phenotype_id',1487369,'nd_experiment_id',80113,'phenotype_id',740424],['nd_experiment_phenotype_id',1487370,'nd_experiment_id',80114,'phenotype_id',740425],['nd_experiment_phenotype_id',1487371,'nd_experiment_id',80115,'phenotype_id',740426],['nd_experiment_phenotype_id',1487372,'nd_experiment_id',80116,'phenotype_id',740427],['nd_experiment_phenotype_id',1487373,'nd_experiment_id',80117,'phenotype_id',740428],['nd_experiment_phenotype_id',1487374,'nd_experiment_id',80118,'phenotype_id',740429],['nd_experiment_phenotype_id',1487375,'nd_experiment_id',80119,'phenotype_id',740430],['nd_experiment_phenotype_id',1487376,'nd_experiment_id',80120,'phenotype_id',740431],['nd_experiment_phenotype_id',1487377,'nd_experiment_id',80121,'phenotype_id',740432],['nd_experiment_phenotype_id',1487378,'nd_experiment_id',80122,'phenotype_id',740433],['nd_experiment_phenotype_id',1487379,'nd_experiment_id',80123,'phenotype_id',740434],['nd_experiment_phenotype_id',1487380,'nd_experiment_id',80124,'phenotype_id',740435],['nd_experiment_phenotype_id',1487381,'nd_experiment_id',80125,'phenotype_id',740436],['nd_experiment_phenotype_id',1487382,'nd_experiment_id',80126,'phenotype_id',740437],['nd_experiment_phenotype_id',1487383,'nd_experiment_id',80127,'phenotype_id',740438],['nd_experiment_phenotype_id',1487384,'nd_experiment_id',80128,'phenotype_id',740439],['nd_experiment_phenotype_id',1487385,'nd_experiment_id',80129,'phenotype_id',740440],['nd_experiment_phenotype_id',1487386,'nd_experiment_id',80130,'phenotype_id',740441],['nd_experiment_phenotype_id',1487387,'nd_experiment_id',80131,'phenotype_id',740442],['nd_experiment_phenotype_id',1487388,'nd_experiment_id',80132,'phenotype_id',740443],['nd_experiment_phenotype_id',1487389,'nd_experiment_id',80133,'phenotype_id',740444],['nd_experiment_phenotype_id',1487390,'nd_experiment_id',80134,'phenotype_id',740445],['nd_experiment_phenotype_id',1487391,'nd_experiment_id',80135,'phenotype_id',740446],['nd_experiment_phenotype_id',1487392,'nd_experiment_id',80136,'phenotype_id',740447],['nd_experiment_phenotype_id',1487393,'nd_experiment_id',80137,'phenotype_id',740448],['nd_experiment_phenotype_id',1487394,'nd_experiment_id',80138,'phenotype_id',740449],['nd_experiment_phenotype_id',1487395,'nd_experiment_id',80139,'phenotype_id',740450],['nd_experiment_phenotype_id',1487396,'nd_experiment_id',80140,'phenotype_id',740451],['nd_experiment_phenotype_id',1487397,'nd_experiment_id',80141,'phenotype_id',740452],['nd_experiment_phenotype_id',1487398,'nd_experiment_id',80142,'phenotype_id',740453],['nd_experiment_phenotype_id',1487399,'nd_experiment_id',80143,'phenotype_id',740454],['nd_experiment_phenotype_id',1487400,'nd_experiment_id',80144,'phenotype_id',740455],['nd_experiment_phenotype_id',1487401,'nd_experiment_id',80145,'phenotype_id',740456],['nd_experiment_phenotype_id',1487402,'nd_experiment_id',80146,'phenotype_id',740457],['nd_experiment_phenotype_id',1487403,'nd_experiment_id',80147,'phenotype_id',740458],['nd_experiment_phenotype_id',1487404,'nd_experiment_id',80148,'phenotype_id',740459],['nd_experiment_phenotype_id',1487405,'nd_experiment_id',80149,'phenotype_id',740460],['nd_experiment_phenotype_id',1487406,'nd_experiment_id',80150,'phenotype_id',740461],['nd_experiment_phenotype_id',1487407,'nd_experiment_id',80151,'phenotype_id',740462],['nd_experiment_phenotype_id',1487408,'nd_experiment_id',80152,'phenotype_id',740463],['nd_experiment_phenotype_id',1487409,'nd_experiment_id',80153,'phenotype_id',740464],['nd_experiment_phenotype_id',1487410,'nd_experiment_id',80154,'phenotype_id',740465],['nd_experiment_phenotype_id',1487411,'nd_experiment_id',80155,'phenotype_id',740466],['nd_experiment_phenotype_id',1487412,'nd_experiment_id',80156,'phenotype_id',740467],['nd_experiment_phenotype_id',1487413,'nd_experiment_id',80157,'phenotype_id',740468],['nd_experiment_phenotype_id',1487414,'nd_experiment_id',80158,'phenotype_id',740469],['nd_experiment_phenotype_id',1487415,'nd_experiment_id',80159,'phenotype_id',740470],['nd_experiment_phenotype_id',1487416,'nd_experiment_id',80160,'phenotype_id',740471],['nd_experiment_phenotype_id',1487417,'nd_experiment_id',80161,'phenotype_id',740472],['nd_experiment_phenotype_id',1487418,'nd_experiment_id',80162,'phenotype_id',740473],['nd_experiment_phenotype_id',1487419,'nd_experiment_id',80163,'phenotype_id',740474],['nd_experiment_phenotype_id',1487420,'nd_experiment_id',80164,'phenotype_id',740475],['nd_experiment_phenotype_id',1487421,'nd_experiment_id',80165,'phenotype_id',740476],['nd_experiment_phenotype_id',1487422,'nd_experiment_id',80166,'phenotype_id',740477],['nd_experiment_phenotype_id',1487423,'nd_experiment_id',80167,'phenotype_id',740478],['nd_experiment_phenotype_id',1487424,'nd_experiment_id',80168,'phenotype_id',740479],['nd_experiment_phenotype_id',1487425,'nd_experiment_id',80169,'phenotype_id',740480],['nd_experiment_phenotype_id',1487426,'nd_experiment_id',80170,'phenotype_id',740481],['nd_experiment_phenotype_id',1487427,'nd_experiment_id',80171,'phenotype_id',740482],['nd_experiment_phenotype_id',1487428,'nd_experiment_id',80172,'phenotype_id',740483],['nd_experiment_phenotype_id',1487429,'nd_experiment_id',80173,'phenotype_id',740484],['nd_experiment_phenotype_id',1487430,'nd_experiment_id',80174,'phenotype_id',740485],['nd_experiment_phenotype_id',1487431,'nd_experiment_id',80175,'phenotype_id',740486],['nd_experiment_phenotype_id',1487432,'nd_experiment_id',80176,'phenotype_id',740487],['nd_experiment_phenotype_id',1487433,'nd_experiment_id',80177,'phenotype_id',740488],['nd_experiment_phenotype_id',1487434,'nd_experiment_id',80178,'phenotype_id',740489],['nd_experiment_phenotype_id',1487435,'nd_experiment_id',80179,'phenotype_id',740490],['nd_experiment_phenotype_id',1487436,'nd_experiment_id',80180,'phenotype_id',740491],['nd_experiment_phenotype_id',1487437,'nd_experiment_id',80181,'phenotype_id',740492],['nd_experiment_phenotype_id',1487438,'nd_experiment_id',80182,'phenotype_id',740493],['nd_experiment_phenotype_id',1487439,'nd_experiment_id',80183,'phenotype_id',740494],['nd_experiment_phenotype_id',1487440,'nd_experiment_id',80184,'phenotype_id',740495],['nd_experiment_phenotype_id',1487441,'nd_experiment_id',80185,'phenotype_id',740496],['nd_experiment_phenotype_id',1487442,'nd_experiment_id',80186,'phenotype_id',740497],['nd_experiment_phenotype_id',1487443,'nd_experiment_id',80187,'phenotype_id',740498],['nd_experiment_phenotype_id',1487444,'nd_experiment_id',80188,'phenotype_id',740499],['nd_experiment_phenotype_id',1487445,'nd_experiment_id',80189,'phenotype_id',740500],['nd_experiment_phenotype_id',1487446,'nd_experiment_id',80190,'phenotype_id',740501],['nd_experiment_phenotype_id',1487447,'nd_experiment_id',80191,'phenotype_id',740502],['nd_experiment_phenotype_id',1487448,'nd_experiment_id',80192,'phenotype_id',740503],['nd_experiment_phenotype_id',1487449,'nd_experiment_id',80193,'phenotype_id',740504],['nd_experiment_phenotype_id',1487450,'nd_experiment_id',80194,'phenotype_id',740505],['nd_experiment_phenotype_id',1487451,'nd_experiment_id',80195,'phenotype_id',740506],['nd_experiment_phenotype_id',1487452,'nd_experiment_id',80196,'phenotype_id',740507],['nd_experiment_phenotype_id',1487453,'nd_experiment_id',80197,'phenotype_id',740508],['nd_experiment_phenotype_id',1487454,'nd_experiment_id',80198,'phenotype_id',740509],['nd_experiment_phenotype_id',1487455,'nd_experiment_id',80199,'phenotype_id',740510],['nd_experiment_phenotype_id',1487456,'nd_experiment_id',80200,'phenotype_id',740511],['nd_experiment_phenotype_id',1487457,'nd_experiment_id',80201,'phenotype_id',740512],['nd_experiment_phenotype_id',1487458,'nd_experiment_id',80202,'phenotype_id',740513],['nd_experiment_phenotype_id',1487459,'nd_experiment_id',80203,'phenotype_id',740514],['nd_experiment_phenotype_id',1487460,'nd_experiment_id',80204,'phenotype_id',740515],['nd_experiment_phenotype_id',1487461,'nd_experiment_id',80205,'phenotype_id',740516],['nd_experiment_phenotype_id',1487462,'nd_experiment_id',80206,'phenotype_id',740517],['nd_experiment_phenotype_id',1487463,'nd_experiment_id',80207,'phenotype_id',740518],['nd_experiment_phenotype_id',1487464,'nd_experiment_id',80208,'phenotype_id',740519],['nd_experiment_phenotype_id',1487465,'nd_experiment_id',80209,'phenotype_id',740520],['nd_experiment_phenotype_id',1487466,'nd_experiment_id',80210,'phenotype_id',740521],['nd_experiment_phenotype_id',1487467,'nd_experiment_id',80211,'phenotype_id',740522],['nd_experiment_phenotype_id',1487468,'nd_experiment_id',80212,'phenotype_id',740523],['nd_experiment_phenotype_id',1487469,'nd_experiment_id',80213,'phenotype_id',740524],['nd_experiment_phenotype_id',1487470,'nd_experiment_id',80214,'phenotype_id',740525],['nd_experiment_phenotype_id',1487471,'nd_experiment_id',80215,'phenotype_id',740526],['nd_experiment_phenotype_id',1487472,'nd_experiment_id',80216,'phenotype_id',740527],['nd_experiment_phenotype_id',1487473,'nd_experiment_id',80217,'phenotype_id',740528],['nd_experiment_phenotype_id',1487474,'nd_experiment_id',80218,'phenotype_id',740529],['nd_experiment_phenotype_id',1487475,'nd_experiment_id',80219,'phenotype_id',740530],['nd_experiment_phenotype_id',1487476,'nd_experiment_id',80220,'phenotype_id',740531],['nd_experiment_phenotype_id',1487477,'nd_experiment_id',80221,'phenotype_id',740532],['nd_experiment_phenotype_id',1487478,'nd_experiment_id',80222,'phenotype_id',740533],['nd_experiment_phenotype_id',1487479,'nd_experiment_id',80223,'phenotype_id',740534],['nd_experiment_phenotype_id',1487480,'nd_experiment_id',80224,'phenotype_id',740535],['nd_experiment_phenotype_id',1487481,'nd_experiment_id',80225,'phenotype_id',740536],['nd_experiment_phenotype_id',1487482,'nd_experiment_id',80226,'phenotype_id',740537],['nd_experiment_phenotype_id',1487483,'nd_experiment_id',80227,'phenotype_id',740538],['nd_experiment_phenotype_id',1487484,'nd_experiment_id',80228,'phenotype_id',740539],['nd_experiment_phenotype_id',1487485,'nd_experiment_id',80229,'phenotype_id',740540],['nd_experiment_phenotype_id',1487486,'nd_experiment_id',80230,'phenotype_id',740541],['nd_experiment_phenotype_id',1487487,'nd_experiment_id',80231,'phenotype_id',740542],['nd_experiment_phenotype_id',1487488,'nd_experiment_id',80232,'phenotype_id',740543],['nd_experiment_phenotype_id',1487489,'nd_experiment_id',80233,'phenotype_id',740544],['nd_experiment_phenotype_id',1487490,'nd_experiment_id',80234,'phenotype_id',740545],['nd_experiment_phenotype_id',1487491,'nd_experiment_id',80235,'phenotype_id',740546],['nd_experiment_phenotype_id',1487492,'nd_experiment_id',80236,'phenotype_id',740547],['nd_experiment_phenotype_id',1487493,'nd_experiment_id',80237,'phenotype_id',740548],['nd_experiment_phenotype_id',1487494,'nd_experiment_id',80238,'phenotype_id',740549],['nd_experiment_phenotype_id',1487495,'nd_experiment_id',80239,'phenotype_id',740550],['nd_experiment_phenotype_id',1487496,'nd_experiment_id',80240,'phenotype_id',740551],['nd_experiment_phenotype_id',1487497,'nd_experiment_id',80241,'phenotype_id',740552],['nd_experiment_phenotype_id',1487498,'nd_experiment_id',80242,'phenotype_id',740553],['nd_experiment_phenotype_id',1487499,'nd_experiment_id',80243,'phenotype_id',740554],['nd_experiment_phenotype_id',1487500,'nd_experiment_id',80244,'phenotype_id',740555],['nd_experiment_phenotype_id',1487501,'nd_experiment_id',80245,'phenotype_id',740556],['nd_experiment_phenotype_id',1487502,'nd_experiment_id',80246,'phenotype_id',740557],['nd_experiment_phenotype_id',1487503,'nd_experiment_id',80247,'phenotype_id',740558],['nd_experiment_phenotype_id',1487504,'nd_experiment_id',80248,'phenotype_id',740559],['nd_experiment_phenotype_id',1487505,'nd_experiment_id',80249,'phenotype_id',740560],['nd_experiment_phenotype_id',1487506,'nd_experiment_id',80250,'phenotype_id',740561],['nd_experiment_phenotype_id',1487507,'nd_experiment_id',80251,'phenotype_id',740562],['nd_experiment_phenotype_id',1487508,'nd_experiment_id',80252,'phenotype_id',740563],['nd_experiment_phenotype_id',1487509,'nd_experiment_id',80253,'phenotype_id',740564],['nd_experiment_phenotype_id',1487510,'nd_experiment_id',80254,'phenotype_id',740565],['nd_experiment_phenotype_id',1487511,'nd_experiment_id',80255,'phenotype_id',740566],['nd_experiment_phenotype_id',1487512,'nd_experiment_id',80256,'phenotype_id',740567],['nd_experiment_phenotype_id',1487513,'nd_experiment_id',80257,'phenotype_id',740568],['nd_experiment_phenotype_id',1487514,'nd_experiment_id',80258,'phenotype_id',740569],['nd_experiment_phenotype_id',1487515,'nd_experiment_id',80259,'phenotype_id',740570],['nd_experiment_phenotype_id',1487516,'nd_experiment_id',80260,'phenotype_id',740571],['nd_experiment_phenotype_id',1487517,'nd_experiment_id',80261,'phenotype_id',740572],['nd_experiment_phenotype_id',1487518,'nd_experiment_id',80262,'phenotype_id',740573],['nd_experiment_phenotype_id',1487519,'nd_experiment_id',80263,'phenotype_id',740574],['nd_experiment_phenotype_id',1487520,'nd_experiment_id',80264,'phenotype_id',740575],['nd_experiment_phenotype_id',1487521,'nd_experiment_id',80265,'phenotype_id',740576],['nd_experiment_phenotype_id',1487522,'nd_experiment_id',80266,'phenotype_id',740577],['nd_experiment_phenotype_id',1487523,'nd_experiment_id',80267,'phenotype_id',740578],['nd_experiment_phenotype_id',1487524,'nd_experiment_id',80268,'phenotype_id',740579],['nd_experiment_phenotype_id',1487525,'nd_experiment_id',80269,'phenotype_id',740580],['nd_experiment_phenotype_id',1487526,'nd_experiment_id',80270,'phenotype_id',740581],['nd_experiment_phenotype_id',1487527,'nd_experiment_id',80271,'phenotype_id',740582],['nd_experiment_phenotype_id',1487528,'nd_experiment_id',80272,'phenotype_id',740583],['nd_experiment_phenotype_id',1487529,'nd_experiment_id',80273,'phenotype_id',740584],['nd_experiment_phenotype_id',1487530,'nd_experiment_id',80274,'phenotype_id',740585],['nd_experiment_phenotype_id',1487531,'nd_experiment_id',80275,'phenotype_id',740586],['nd_experiment_phenotype_id',1487532,'nd_experiment_id',80276,'phenotype_id',740587],['nd_experiment_phenotype_id',1487533,'nd_experiment_id',80277,'phenotype_id',740588],['nd_experiment_phenotype_id',1487534,'nd_experiment_id',80278,'phenotype_id',740589],['nd_experiment_phenotype_id',1487535,'nd_experiment_id',80279,'phenotype_id',740590],['nd_experiment_phenotype_id',1487536,'nd_experiment_id',80280,'phenotype_id',740591],['nd_experiment_phenotype_id',1487537,'nd_experiment_id',80281,'phenotype_id',740592],['nd_experiment_phenotype_id',1487538,'nd_experiment_id',80282,'phenotype_id',740593],['nd_experiment_phenotype_id',1487539,'nd_experiment_id',80283,'phenotype_id',740594],['nd_experiment_phenotype_id',1487540,'nd_experiment_id',80284,'phenotype_id',740595],['nd_experiment_phenotype_id',1487541,'nd_experiment_id',80285,'phenotype_id',740596],['nd_experiment_phenotype_id',1487542,'nd_experiment_id',80286,'phenotype_id',740597],['nd_experiment_phenotype_id',1487543,'nd_experiment_id',80287,'phenotype_id',740598],['nd_experiment_phenotype_id',1487544,'nd_experiment_id',80288,'phenotype_id',740599],['nd_experiment_phenotype_id',1487545,'nd_experiment_id',80289,'phenotype_id',740600],['nd_experiment_phenotype_id',1487546,'nd_experiment_id',80290,'phenotype_id',740601],['nd_experiment_phenotype_id',1487547,'nd_experiment_id',80291,'phenotype_id',740602],['nd_experiment_phenotype_id',1487548,'nd_experiment_id',80292,'phenotype_id',740603],['nd_experiment_phenotype_id',1487549,'nd_experiment_id',80293,'phenotype_id',740604],['nd_experiment_phenotype_id',1487550,'nd_experiment_id',80294,'phenotype_id',740605],['nd_experiment_phenotype_id',1487551,'nd_experiment_id',80295,'phenotype_id',740606],['nd_experiment_phenotype_id',1487552,'nd_experiment_id',80296,'phenotype_id',740607],['nd_experiment_phenotype_id',1487553,'nd_experiment_id',80297,'phenotype_id',740608],['nd_experiment_phenotype_id',1487554,'nd_experiment_id',80298,'phenotype_id',740609],['nd_experiment_phenotype_id',1487555,'nd_experiment_id',80299,'phenotype_id',740610],['nd_experiment_phenotype_id',1487556,'nd_experiment_id',80300,'phenotype_id',740611],['nd_experiment_phenotype_id',1487557,'nd_experiment_id',80301,'phenotype_id',740612],['nd_experiment_phenotype_id',1487558,'nd_experiment_id',80302,'phenotype_id',740613],['nd_experiment_phenotype_id',1487559,'nd_experiment_id',80303,'phenotype_id',740614],['nd_experiment_phenotype_id',1487560,'nd_experiment_id',80304,'phenotype_id',740615],['nd_experiment_phenotype_id',1487561,'nd_experiment_id',80305,'phenotype_id',740616],['nd_experiment_phenotype_id',1487562,'nd_experiment_id',80306,'phenotype_id',740617],['nd_experiment_phenotype_id',1487563,'nd_experiment_id',80307,'phenotype_id',740618],['nd_experiment_phenotype_id',1487564,'nd_experiment_id',80308,'phenotype_id',740619],['nd_experiment_phenotype_id',1487565,'nd_experiment_id',80309,'phenotype_id',740620],['nd_experiment_phenotype_id',1487566,'nd_experiment_id',80310,'phenotype_id',740621],['nd_experiment_phenotype_id',1487567,'nd_experiment_id',80311,'phenotype_id',740622],['nd_experiment_phenotype_id',1487568,'nd_experiment_id',80312,'phenotype_id',740623],['nd_experiment_phenotype_id',1487569,'nd_experiment_id',80313,'phenotype_id',740624],['nd_experiment_phenotype_id',1487570,'nd_experiment_id',80314,'phenotype_id',740625],['nd_experiment_phenotype_id',1487571,'nd_experiment_id',80315,'phenotype_id',740626],['nd_experiment_phenotype_id',1487572,'nd_experiment_id',80316,'phenotype_id',740627],['nd_experiment_phenotype_id',1487573,'nd_experiment_id',80317,'phenotype_id',740628],['nd_experiment_phenotype_id',1487574,'nd_experiment_id',80318,'phenotype_id',740629],['nd_experiment_phenotype_id',1487575,'nd_experiment_id',80319,'phenotype_id',740630],['nd_experiment_phenotype_id',1487576,'nd_experiment_id',80320,'phenotype_id',740631],['nd_experiment_phenotype_id',1487577,'nd_experiment_id',80321,'phenotype_id',740632],['nd_experiment_phenotype_id',1487578,'nd_experiment_id',80322,'phenotype_id',740633],['nd_experiment_phenotype_id',1487579,'nd_experiment_id',80323,'phenotype_id',740634],['nd_experiment_phenotype_id',1487580,'nd_experiment_id',80324,'phenotype_id',740635],['nd_experiment_phenotype_id',1487581,'nd_experiment_id',80325,'phenotype_id',740636],['nd_experiment_phenotype_id',1487582,'nd_experiment_id',80326,'phenotype_id',740637],['nd_experiment_phenotype_id',1487583,'nd_experiment_id',80327,'phenotype_id',740638],['nd_experiment_phenotype_id',1487584,'nd_experiment_id',80328,'phenotype_id',740639],['nd_experiment_phenotype_id',1487585,'nd_experiment_id',80329,'phenotype_id',740640],['nd_experiment_phenotype_id',1487586,'nd_experiment_id',80330,'phenotype_id',740641],['nd_experiment_phenotype_id',1487587,'nd_experiment_id',80331,'phenotype_id',740642],['nd_experiment_phenotype_id',1487588,'nd_experiment_id',80332,'phenotype_id',740643],['nd_experiment_phenotype_id',1487589,'nd_experiment_id',80333,'phenotype_id',740644],['nd_experiment_phenotype_id',1487590,'nd_experiment_id',80334,'phenotype_id',740645],['nd_experiment_phenotype_id',1487591,'nd_experiment_id',80335,'phenotype_id',740646],['nd_experiment_phenotype_id',1487592,'nd_experiment_id',80336,'phenotype_id',740647],['nd_experiment_phenotype_id',1487593,'nd_experiment_id',80337,'phenotype_id',740648],['nd_experiment_phenotype_id',1487594,'nd_experiment_id',80338,'phenotype_id',740649],['nd_experiment_phenotype_id',1487595,'nd_experiment_id',80339,'phenotype_id',740650],['nd_experiment_phenotype_id',1487596,'nd_experiment_id',80340,'phenotype_id',740651],['nd_experiment_phenotype_id',1487597,'nd_experiment_id',80341,'phenotype_id',740652],['nd_experiment_phenotype_id',1487598,'nd_experiment_id',80342,'phenotype_id',740653],['nd_experiment_phenotype_id',1487599,'nd_experiment_id',80343,'phenotype_id',740654],['nd_experiment_phenotype_id',1487600,'nd_experiment_id',80344,'phenotype_id',740655],['nd_experiment_phenotype_id',1487601,'nd_experiment_id',80345,'phenotype_id',740656],['nd_experiment_phenotype_id',1487602,'nd_experiment_id',80346,'phenotype_id',740657],['nd_experiment_phenotype_id',1487603,'nd_experiment_id',80347,'phenotype_id',740658]];

#is_deeply(\@exp_pheno_table, $exp_pheno_table_check, 'check ndexperimentphenotype table data state' );



#my $md_table_check = [['metadata_id','37','create_person_id',41],['metadata_id','38','create_person_id',41],['metadata_id','39','create_person_id',41],['metadata_id','40','create_person_id',41],['metadata_id','41','create_person_id',41]];


#is_deeply(\@md_table, $md_table_check, 'check metadata table data state' );



#my $md_files_table_check = [['file_id',5,'basename','upload_phenotypin_spreadsheet.xls','dirname','t/data/trial','filetype','spreadsheet phenotype file','alt_filename',undef,'comment',undef,'urlsource',undef],['file_id',6,'basename','upload_phenotypin_spreadsheet.xls','dirname','t/data/trial','filetype','spreadsheet phenotype file','alt_filename',undef,'comment',undef,'urlsource',undef],['file_id',7,'basename','fieldbook_phenotype_file.csv','dirname','t/data/fieldbook','filetype','tablet phenotype file','alt_filename',undef,'comment',undef,'urlsource',undef],['file_id',8,'basename','data_collector_upload.xls','dirname','t/data/trial','filetype','tablet phenotype file','alt_filename',undef,'comment',undef,'urlsource',undef],['file_id',9,'basename','upload_phenotypin_spreadsheet_large.xls','dirname','t/data/trial','filetype','spreadsheet phenotype file','alt_filename',undef,'comment',undef,'urlsource',undef]];



#is_deeply(\@md_files_table, $md_files_table_check, 'check mdfiles table data state' );



#my $exp_md_files_table_check = [['nd_experiment_md_files_id',3305,'nd_experiment_id','79574','file_id','4'],['nd_experiment_md_files_id',3306,'nd_experiment_id','80042','file_id','5'],['nd_experiment_md_files_id',3307,'nd_experiment_id','80025','file_id','5'],['nd_experiment_md_files_id',3308,'nd_experiment_id','80059','file_id','5'],['nd_experiment_md_files_id',3309,'nd_experiment_id','80041','file_id','5'],['nd_experiment_md_files_id',3310,'nd_experiment_id','80040','file_id','5'],['nd_experiment_md_files_id',3311,'nd_experiment_id','80053','file_id','5'],['nd_experiment_md_files_id',3312,'nd_experiment_id','80050','file_id','5'],['nd_experiment_md_files_id',3313,'nd_experiment_id','80031','file_id','5'],['nd_experiment_md_files_id',3314,'nd_experiment_id','80043','file_id','5'],['nd_experiment_md_files_id',3315,'nd_experiment_id','80068','file_id','5'],['nd_experiment_md_files_id',3316,'nd_experiment_id','80084','file_id','5'],['nd_experiment_md_files_id',3317,'nd_experiment_id','80074','file_id','5'],['nd_experiment_md_files_id',3318,'nd_experiment_id','80055','file_id','5'],['nd_experiment_md_files_id',3319,'nd_experiment_id','80081','file_id','5'],['nd_experiment_md_files_id',3320,'nd_experiment_id','80062','file_id','5'],['nd_experiment_md_files_id',3321,'nd_experiment_id','80052','file_id','5'],['nd_experiment_md_files_id',3322,'nd_experiment_id','80079','file_id','5'],['nd_experiment_md_files_id',3323,'nd_experiment_id','80044','file_id','5'],['nd_experiment_md_files_id',3324,'nd_experiment_id','80075','file_id','5'],['nd_experiment_md_files_id',3325,'nd_experiment_id','80045','file_id','5'],['nd_experiment_md_files_id',3326,'nd_experiment_id','80069','file_id','5'],['nd_experiment_md_files_id',3327,'nd_experiment_id','80048','file_id','5'],['nd_experiment_md_files_id',3328,'nd_experiment_id','80034','file_id','5'],['nd_experiment_md_files_id',3329,'nd_experiment_id','80077','file_id','5'],['nd_experiment_md_files_id',3330,'nd_experiment_id','80067','file_id','5'],['nd_experiment_md_files_id',3331,'nd_experiment_id','80035','file_id','5'],['nd_experiment_md_files_id',3332,'nd_experiment_id','80066','file_id','5'],['nd_experiment_md_files_id',3333,'nd_experiment_id','80027','file_id','5'],['nd_experiment_md_files_id',3334,'nd_experiment_id','80071','file_id','5'],['nd_experiment_md_files_id',3335,'nd_experiment_id','80056','file_id','5'],['nd_experiment_md_files_id',3336,'nd_experiment_id','80070','file_id','5'],['nd_experiment_md_files_id',3337,'nd_experiment_id','80065','file_id','5'],['nd_experiment_md_files_id',3338,'nd_experiment_id','80028','file_id','5'],['nd_experiment_md_files_id',3339,'nd_experiment_id','80039','file_id','5'],['nd_experiment_md_files_id',3340,'nd_experiment_id','80060','file_id','5'],['nd_experiment_md_files_id',3341,'nd_experiment_id','80049','file_id','5'],['nd_experiment_md_files_id',3342,'nd_experiment_id','80063','file_id','5'],['nd_experiment_md_files_id',3343,'nd_experiment_id','80032','file_id','5'],['nd_experiment_md_files_id',3344,'nd_experiment_id','80054','file_id','5'],['nd_experiment_md_files_id',3345,'nd_experiment_id','80037','file_id','5'],['nd_experiment_md_files_id',3346,'nd_experiment_id','80038','file_id','5'],['nd_experiment_md_files_id',3347,'nd_experiment_id','80072','file_id','5'],['nd_experiment_md_files_id',3348,'nd_experiment_id','80047','file_id','5'],['nd_experiment_md_files_id',3349,'nd_experiment_id','80076','file_id','5'],['nd_experiment_md_files_id',3350,'nd_experiment_id','80061','file_id','5'],['nd_experiment_md_files_id',3351,'nd_experiment_id','80046','file_id','5'],['nd_experiment_md_files_id',3352,'nd_experiment_id','80030','file_id','5'],['nd_experiment_md_files_id',3353,'nd_experiment_id','80083','file_id','5'],['nd_experiment_md_files_id',3354,'nd_experiment_id','80078','file_id','5'],['nd_experiment_md_files_id',3355,'nd_experiment_id','80064','file_id','5'],['nd_experiment_md_files_id',3356,'nd_experiment_id','80033','file_id','5'],['nd_experiment_md_files_id',3357,'nd_experiment_id','80029','file_id','5'],['nd_experiment_md_files_id',3358,'nd_experiment_id','80051','file_id','5'],['nd_experiment_md_files_id',3359,'nd_experiment_id','80058','file_id','5'],['nd_experiment_md_files_id',3360,'nd_experiment_id','80036','file_id','5'],['nd_experiment_md_files_id',3361,'nd_experiment_id','80073','file_id','5'],['nd_experiment_md_files_id',3362,'nd_experiment_id','80082','file_id','5'],['nd_experiment_md_files_id',3363,'nd_experiment_id','80026','file_id','5'],['nd_experiment_md_files_id',3364,'nd_experiment_id','80057','file_id','5'],['nd_experiment_md_files_id',3365,'nd_experiment_id','80080','file_id','5'],['nd_experiment_md_files_id',3366,'nd_experiment_id','80135','file_id','6'],['nd_experiment_md_files_id',3367,'nd_experiment_id','80129','file_id','6'],['nd_experiment_md_files_id',3368,'nd_experiment_id','80109','file_id','6'],['nd_experiment_md_files_id',3369,'nd_experiment_id','80107','file_id','6'],['nd_experiment_md_files_id',3370,'nd_experiment_id','80118','file_id','6'],['nd_experiment_md_files_id',3371,'nd_experiment_id','80089','file_id','6'],['nd_experiment_md_files_id',3372,'nd_experiment_id','80130','file_id','6'],['nd_experiment_md_files_id',3373,'nd_experiment_id','80099','file_id','6'],['nd_experiment_md_files_id',3374,'nd_experiment_id','80092','file_id','6'],['nd_experiment_md_files_id',3375,'nd_experiment_id','80086','file_id','6'],['nd_experiment_md_files_id',3376,'nd_experiment_id','80143','file_id','6'],['nd_experiment_md_files_id',3377,'nd_experiment_id','80126','file_id','6'],['nd_experiment_md_files_id',3378,'nd_experiment_id','80120','file_id','6'],['nd_experiment_md_files_id',3379,'nd_experiment_id','80106','file_id','6'],['nd_experiment_md_files_id',3380,'nd_experiment_id','80133','file_id','6'],['nd_experiment_md_files_id',3381,'nd_experiment_id','80111','file_id','6'],['nd_experiment_md_files_id',3382,'nd_experiment_id','80094','file_id','6'],['nd_experiment_md_files_id',3383,'nd_experiment_id','80101','file_id','6'],['nd_experiment_md_files_id',3384,'nd_experiment_id','80141','file_id','6'],['nd_experiment_md_files_id',3385,'nd_experiment_id','80113','file_id','6'],['nd_experiment_md_files_id',3386,'nd_experiment_id','80117','file_id','6'],['nd_experiment_md_files_id',3387,'nd_experiment_id','80108','file_id','6'],['nd_experiment_md_files_id',3388,'nd_experiment_id','80103','file_id','6'],['nd_experiment_md_files_id',3389,'nd_experiment_id','80131','file_id','6'],['nd_experiment_md_files_id',3390,'nd_experiment_id','80123','file_id','6'],['nd_experiment_md_files_id',3391,'nd_experiment_id','80144','file_id','6'],['nd_experiment_md_files_id',3392,'nd_experiment_id','80105','file_id','6'],['nd_experiment_md_files_id',3393,'nd_experiment_id','80100','file_id','6'],['nd_experiment_md_files_id',3394,'nd_experiment_id','80125','file_id','6'],['nd_experiment_md_files_id',3395,'nd_experiment_id','80114','file_id','6'],['nd_experiment_md_files_id',3396,'nd_experiment_id','80090','file_id','6'],['nd_experiment_md_files_id',3397,'nd_experiment_id','80138','file_id','6'],['nd_experiment_md_files_id',3398,'nd_experiment_id','80134','file_id','6'],['nd_experiment_md_files_id',3399,'nd_experiment_id','80121','file_id','6'],['nd_experiment_md_files_id',3400,'nd_experiment_id','80136','file_id','6'],['nd_experiment_md_files_id',3401,'nd_experiment_id','80104','file_id','6'],['nd_experiment_md_files_id',3402,'nd_experiment_id','80137','file_id','6'],['nd_experiment_md_files_id',3403,'nd_experiment_id','80110','file_id','6'],['nd_experiment_md_files_id',3404,'nd_experiment_id','80096','file_id','6'],['nd_experiment_md_files_id',3405,'nd_experiment_id','80095','file_id','6'],['nd_experiment_md_files_id',3406,'nd_experiment_id','80102','file_id','6'],['nd_experiment_md_files_id',3407,'nd_experiment_id','80119','file_id','6'],['nd_experiment_md_files_id',3408,'nd_experiment_id','80093','file_id','6'],['nd_experiment_md_files_id',3409,'nd_experiment_id','80091','file_id','6'],['nd_experiment_md_files_id',3410,'nd_experiment_id','80140','file_id','6'],['nd_experiment_md_files_id',3411,'nd_experiment_id','80087','file_id','6'],['nd_experiment_md_files_id',3412,'nd_experiment_id','80142','file_id','6'],['nd_experiment_md_files_id',3413,'nd_experiment_id','80122','file_id','6'],['nd_experiment_md_files_id',3414,'nd_experiment_id','80085','file_id','6'],['nd_experiment_md_files_id',3415,'nd_experiment_id','80132','file_id','6'],['nd_experiment_md_files_id',3416,'nd_experiment_id','80139','file_id','6'],['nd_experiment_md_files_id',3417,'nd_experiment_id','80124','file_id','6'],['nd_experiment_md_files_id',3418,'nd_experiment_id','80127','file_id','6'],['nd_experiment_md_files_id',3419,'nd_experiment_id','80115','file_id','6'],['nd_experiment_md_files_id',3420,'nd_experiment_id','80098','file_id','6'],['nd_experiment_md_files_id',3421,'nd_experiment_id','80088','file_id','6'],['nd_experiment_md_files_id',3422,'nd_experiment_id','80116','file_id','6'],['nd_experiment_md_files_id',3423,'nd_experiment_id','80112','file_id','6'],['nd_experiment_md_files_id',3424,'nd_experiment_id','80097','file_id','6'],['nd_experiment_md_files_id',3425,'nd_experiment_id','80128','file_id','6'],['nd_experiment_md_files_id',3426,'nd_experiment_id','80161','file_id','7'],['nd_experiment_md_files_id',3427,'nd_experiment_id','80160','file_id','7'],['nd_experiment_md_files_id',3428,'nd_experiment_id','80158','file_id','7'],['nd_experiment_md_files_id',3429,'nd_experiment_id','80157','file_id','7'],['nd_experiment_md_files_id',3430,'nd_experiment_id','80154','file_id','7'],['nd_experiment_md_files_id',3431,'nd_experiment_id','80156','file_id','7'],['nd_experiment_md_files_id',3432,'nd_experiment_id','80172','file_id','7'],['nd_experiment_md_files_id',3433,'nd_experiment_id','80166','file_id','7'],['nd_experiment_md_files_id',3434,'nd_experiment_id','80145','file_id','7'],['nd_experiment_md_files_id',3435,'nd_experiment_id','80155','file_id','7'],['nd_experiment_md_files_id',3436,'nd_experiment_id','80170','file_id','7'],['nd_experiment_md_files_id',3437,'nd_experiment_id','80162','file_id','7'],['nd_experiment_md_files_id',3438,'nd_experiment_id','80153','file_id','7'],['nd_experiment_md_files_id',3439,'nd_experiment_id','80146','file_id','7'],['nd_experiment_md_files_id',3440,'nd_experiment_id','80151','file_id','7'],['nd_experiment_md_files_id',3441,'nd_experiment_id','80165','file_id','7'],['nd_experiment_md_files_id',3442,'nd_experiment_id','80159','file_id','7'],['nd_experiment_md_files_id',3443,'nd_experiment_id','80169','file_id','7'],['nd_experiment_md_files_id',3444,'nd_experiment_id','80171','file_id','7'],['nd_experiment_md_files_id',3445,'nd_experiment_id','80150','file_id','7'],['nd_experiment_md_files_id',3446,'nd_experiment_id','80147','file_id','7'],['nd_experiment_md_files_id',3447,'nd_experiment_id','80164','file_id','7'],['nd_experiment_md_files_id',3448,'nd_experiment_id','80149','file_id','7'],['nd_experiment_md_files_id',3449,'nd_experiment_id','80167','file_id','7'],['nd_experiment_md_files_id',3450,'nd_experiment_id','80163','file_id','7'],['nd_experiment_md_files_id',3451,'nd_experiment_id','80168','file_id','7'],['nd_experiment_md_files_id',3452,'nd_experiment_id','80152','file_id','7'],['nd_experiment_md_files_id',3453,'nd_experiment_id','80148','file_id','7'],['nd_experiment_md_files_id',3454,'nd_experiment_id','80214','file_id','8'],['nd_experiment_md_files_id',3455,'nd_experiment_id','80194','file_id','8'],['nd_experiment_md_files_id',3456,'nd_experiment_id','80196','file_id','8'],['nd_experiment_md_files_id',3457,'nd_experiment_id','80186','file_id','8'],['nd_experiment_md_files_id',3458,'nd_experiment_id','80192','file_id','8'],['nd_experiment_md_files_id',3459,'nd_experiment_id','80191','file_id','8'],['nd_experiment_md_files_id',3460,'nd_experiment_id','80176','file_id','8'],['nd_experiment_md_files_id',3461,'nd_experiment_id','80206','file_id','8'],['nd_experiment_md_files_id',3462,'nd_experiment_id','80215','file_id','8'],['nd_experiment_md_files_id',3463,'nd_experiment_id','80174','file_id','8'],['nd_experiment_md_files_id',3464,'nd_experiment_id','80224','file_id','8'],['nd_experiment_md_files_id',3465,'nd_experiment_id','80212','file_id','8'],['nd_experiment_md_files_id',3466,'nd_experiment_id','80193','file_id','8'],['nd_experiment_md_files_id',3467,'nd_experiment_id','80178','file_id','8'],['nd_experiment_md_files_id',3468,'nd_experiment_id','80184','file_id','8'],['nd_experiment_md_files_id',3469,'nd_experiment_id','80208','file_id','8'],['nd_experiment_md_files_id',3470,'nd_experiment_id','80226','file_id','8'],['nd_experiment_md_files_id',3471,'nd_experiment_id','80217','file_id','8'],['nd_experiment_md_files_id',3472,'nd_experiment_id','80181','file_id','8'],['nd_experiment_md_files_id',3473,'nd_experiment_id','80218','file_id','8'],['nd_experiment_md_files_id',3474,'nd_experiment_id','80185','file_id','8'],['nd_experiment_md_files_id',3475,'nd_experiment_id','80220','file_id','8'],['nd_experiment_md_files_id',3476,'nd_experiment_id','80216','file_id','8'],['nd_experiment_md_files_id',3477,'nd_experiment_id','80199','file_id','8'],['nd_experiment_md_files_id',3478,'nd_experiment_id','80228','file_id','8'],['nd_experiment_md_files_id',3479,'nd_experiment_id','80205','file_id','8'],['nd_experiment_md_files_id',3480,'nd_experiment_id','80200','file_id','8'],['nd_experiment_md_files_id',3481,'nd_experiment_id','80197','file_id','8'],['nd_experiment_md_files_id',3482,'nd_experiment_id','80219','file_id','8'],['nd_experiment_md_files_id',3483,'nd_experiment_id','80213','file_id','8'],['nd_experiment_md_files_id',3484,'nd_experiment_id','80180','file_id','8'],['nd_experiment_md_files_id',3485,'nd_experiment_id','80179','file_id','8'],['nd_experiment_md_files_id',3486,'nd_experiment_id','80201','file_id','8'],['nd_experiment_md_files_id',3487,'nd_experiment_id','80177','file_id','8'],['nd_experiment_md_files_id',3488,'nd_experiment_id','80189','file_id','8'],['nd_experiment_md_files_id',3489,'nd_experiment_id','80175','file_id','8'],['nd_experiment_md_files_id',3490,'nd_experiment_id','80202','file_id','8'],['nd_experiment_md_files_id',3491,'nd_experiment_id','80173','file_id','8'],['nd_experiment_md_files_id',3492,'nd_experiment_id','80225','file_id','8'],['nd_experiment_md_files_id',3493,'nd_experiment_id','80203','file_id','8'],['nd_experiment_md_files_id',3494,'nd_experiment_id','80227','file_id','8'],['nd_experiment_md_files_id',3495,'nd_experiment_id','80222','file_id','8'],['nd_experiment_md_files_id',3496,'nd_experiment_id','80204','file_id','8'],['nd_experiment_md_files_id',3497,'nd_experiment_id','80190','file_id','8'],['nd_experiment_md_files_id',3498,'nd_experiment_id','80188','file_id','8'],['nd_experiment_md_files_id',3499,'nd_experiment_id','80198','file_id','8'],['nd_experiment_md_files_id',3500,'nd_experiment_id','80187','file_id','8'],['nd_experiment_md_files_id',3501,'nd_experiment_id','80229','file_id','8'],['nd_experiment_md_files_id',3502,'nd_experiment_id','80209','file_id','8'],['nd_experiment_md_files_id',3503,'nd_experiment_id','80223','file_id','8'],['nd_experiment_md_files_id',3504,'nd_experiment_id','80207','file_id','8'],['nd_experiment_md_files_id',3505,'nd_experiment_id','80182','file_id','8'],['nd_experiment_md_files_id',3506,'nd_experiment_id','80195','file_id','8'],['nd_experiment_md_files_id',3507,'nd_experiment_id','80210','file_id','8'],['nd_experiment_md_files_id',3508,'nd_experiment_id','80221','file_id','8'],['nd_experiment_md_files_id',3509,'nd_experiment_id','80211','file_id','8'],['nd_experiment_md_files_id',3510,'nd_experiment_id','80183','file_id','8'],['nd_experiment_md_files_id',3511,'nd_experiment_id','80343','file_id','9'],['nd_experiment_md_files_id',3512,'nd_experiment_id','80291','file_id','9'],['nd_experiment_md_files_id',3513,'nd_experiment_id','80272','file_id','9'],['nd_experiment_md_files_id',3514,'nd_experiment_id','80342','file_id','9'],['nd_experiment_md_files_id',3515,'nd_experiment_id','80256','file_id','9'],['nd_experiment_md_files_id',3516,'nd_experiment_id','80231','file_id','9'],['nd_experiment_md_files_id',3517,'nd_experiment_id','80321','file_id','9'],['nd_experiment_md_files_id',3518,'nd_experiment_id','80323','file_id','9'],['nd_experiment_md_files_id',3519,'nd_experiment_id','80293','file_id','9'],['nd_experiment_md_files_id',3520,'nd_experiment_id','80336','file_id','9'],['nd_experiment_md_files_id',3521,'nd_experiment_id','80322','file_id','9'],['nd_experiment_md_files_id',3522,'nd_experiment_id','80266','file_id','9'],['nd_experiment_md_files_id',3523,'nd_experiment_id','80245','file_id','9'],['nd_experiment_md_files_id',3524,'nd_experiment_id','80230','file_id','9'],['nd_experiment_md_files_id',3525,'nd_experiment_id','80302','file_id','9'],['nd_experiment_md_files_id',3526,'nd_experiment_id','80308','file_id','9'],['nd_experiment_md_files_id',3527,'nd_experiment_id','80282','file_id','9'],['nd_experiment_md_files_id',3528,'nd_experiment_id','80248','file_id','9'],['nd_experiment_md_files_id',3529,'nd_experiment_id','80341','file_id','9'],['nd_experiment_md_files_id',3530,'nd_experiment_id','80337','file_id','9'],['nd_experiment_md_files_id',3531,'nd_experiment_id','80285','file_id','9'],['nd_experiment_md_files_id',3532,'nd_experiment_id','80287','file_id','9'],['nd_experiment_md_files_id',3533,'nd_experiment_id','80254','file_id','9'],['nd_experiment_md_files_id',3534,'nd_experiment_id','80290','file_id','9'],['nd_experiment_md_files_id',3535,'nd_experiment_id','80265','file_id','9'],['nd_experiment_md_files_id',3536,'nd_experiment_id','80255','file_id','9'],['nd_experiment_md_files_id',3537,'nd_experiment_id','80316','file_id','9'],['nd_experiment_md_files_id',3538,'nd_experiment_id','80318','file_id','9'],['nd_experiment_md_files_id',3539,'nd_experiment_id','80273','file_id','9'],['nd_experiment_md_files_id',3540,'nd_experiment_id','80251','file_id','9'],['nd_experiment_md_files_id',3541,'nd_experiment_id','80260','file_id','9'],['nd_experiment_md_files_id',3542,'nd_experiment_id','80335','file_id','9'],['nd_experiment_md_files_id',3543,'nd_experiment_id','80298','file_id','9'],['nd_experiment_md_files_id',3544,'nd_experiment_id','80235','file_id','9'],['nd_experiment_md_files_id',3545,'nd_experiment_id','80262','file_id','9'],['nd_experiment_md_files_id',3546,'nd_experiment_id','80299','file_id','9'],['nd_experiment_md_files_id',3547,'nd_experiment_id','80288','file_id','9'],['nd_experiment_md_files_id',3548,'nd_experiment_id','80270','file_id','9'],['nd_experiment_md_files_id',3549,'nd_experiment_id','80301','file_id','9'],['nd_experiment_md_files_id',3550,'nd_experiment_id','80279','file_id','9'],['nd_experiment_md_files_id',3551,'nd_experiment_id','80319','file_id','9'],['nd_experiment_md_files_id',3552,'nd_experiment_id','80325','file_id','9'],['nd_experiment_md_files_id',3553,'nd_experiment_id','80312','file_id','9'],['nd_experiment_md_files_id',3554,'nd_experiment_id','80284','file_id','9'],['nd_experiment_md_files_id',3555,'nd_experiment_id','80317','file_id','9'],['nd_experiment_md_files_id',3556,'nd_experiment_id','80233','file_id','9'],['nd_experiment_md_files_id',3557,'nd_experiment_id','80347','file_id','9'],['nd_experiment_md_files_id',3558,'nd_experiment_id','80292','file_id','9'],['nd_experiment_md_files_id',3559,'nd_experiment_id','80263','file_id','9'],['nd_experiment_md_files_id',3560,'nd_experiment_id','80320','file_id','9'],['nd_experiment_md_files_id',3561,'nd_experiment_id','80324','file_id','9'],['nd_experiment_md_files_id',3562,'nd_experiment_id','80305','file_id','9'],['nd_experiment_md_files_id',3563,'nd_experiment_id','80346','file_id','9'],['nd_experiment_md_files_id',3564,'nd_experiment_id','80313','file_id','9'],['nd_experiment_md_files_id',3565,'nd_experiment_id','80297','file_id','9'],['nd_experiment_md_files_id',3566,'nd_experiment_id','80234','file_id','9'],['nd_experiment_md_files_id',3567,'nd_experiment_id','80283','file_id','9'],['nd_experiment_md_files_id',3568,'nd_experiment_id','80333','file_id','9'],['nd_experiment_md_files_id',3569,'nd_experiment_id','80296','file_id','9'],['nd_experiment_md_files_id',3570,'nd_experiment_id','80331','file_id','9'],['nd_experiment_md_files_id',3571,'nd_experiment_id','80280','file_id','9'],['nd_experiment_md_files_id',3572,'nd_experiment_id','80315','file_id','9'],['nd_experiment_md_files_id',3573,'nd_experiment_id','80243','file_id','9'],['nd_experiment_md_files_id',3574,'nd_experiment_id','80268','file_id','9'],['nd_experiment_md_files_id',3575,'nd_experiment_id','80278','file_id','9'],['nd_experiment_md_files_id',3576,'nd_experiment_id','80242','file_id','9'],['nd_experiment_md_files_id',3577,'nd_experiment_id','80306','file_id','9'],['nd_experiment_md_files_id',3578,'nd_experiment_id','80249','file_id','9'],['nd_experiment_md_files_id',3579,'nd_experiment_id','80232','file_id','9'],['nd_experiment_md_files_id',3580,'nd_experiment_id','80294','file_id','9'],['nd_experiment_md_files_id',3581,'nd_experiment_id','80252','file_id','9'],['nd_experiment_md_files_id',3582,'nd_experiment_id','80314','file_id','9'],['nd_experiment_md_files_id',3583,'nd_experiment_id','80334','file_id','9'],['nd_experiment_md_files_id',3584,'nd_experiment_id','80326','file_id','9'],['nd_experiment_md_files_id',3585,'nd_experiment_id','80274','file_id','9'],['nd_experiment_md_files_id',3586,'nd_experiment_id','80261','file_id','9'],['nd_experiment_md_files_id',3587,'nd_experiment_id','80295','file_id','9'],['nd_experiment_md_files_id',3588,'nd_experiment_id','80327','file_id','9'],['nd_experiment_md_files_id',3589,'nd_experiment_id','80339','file_id','9'],['nd_experiment_md_files_id',3590,'nd_experiment_id','80271','file_id','9'],['nd_experiment_md_files_id',3591,'nd_experiment_id','80328','file_id','9'],['nd_experiment_md_files_id',3592,'nd_experiment_id','80276','file_id','9'],['nd_experiment_md_files_id',3593,'nd_experiment_id','80332','file_id','9'],['nd_experiment_md_files_id',3594,'nd_experiment_id','80329','file_id','9'],['nd_experiment_md_files_id',3595,'nd_experiment_id','80236','file_id','9'],['nd_experiment_md_files_id',3596,'nd_experiment_id','80300','file_id','9'],['nd_experiment_md_files_id',3597,'nd_experiment_id','80309','file_id','9'],['nd_experiment_md_files_id',3598,'nd_experiment_id','80237','file_id','9'],['nd_experiment_md_files_id',3599,'nd_experiment_id','80303','file_id','9'],['nd_experiment_md_files_id',3600,'nd_experiment_id','80258','file_id','9'],['nd_experiment_md_files_id',3601,'nd_experiment_id','80267','file_id','9'],['nd_experiment_md_files_id',3602,'nd_experiment_id','80286','file_id','9'],['nd_experiment_md_files_id',3603,'nd_experiment_id','80253','file_id','9'],['nd_experiment_md_files_id',3604,'nd_experiment_id','80340','file_id','9'],['nd_experiment_md_files_id',3605,'nd_experiment_id','80275','file_id','9'],['nd_experiment_md_files_id',3606,'nd_experiment_id','80330','file_id','9'],['nd_experiment_md_files_id',3607,'nd_experiment_id','80269','file_id','9'],['nd_experiment_md_files_id',3608,'nd_experiment_id','80239','file_id','9'],['nd_experiment_md_files_id',3609,'nd_experiment_id','80277','file_id','9'],['nd_experiment_md_files_id',3610,'nd_experiment_id','80338','file_id','9'],['nd_experiment_md_files_id',3611,'nd_experiment_id','80247','file_id','9'],['nd_experiment_md_files_id',3612,'nd_experiment_id','80281','file_id','9'],['nd_experiment_md_files_id',3613,'nd_experiment_id','80304','file_id','9'],['nd_experiment_md_files_id',3614,'nd_experiment_id','80238','file_id','9'],['nd_experiment_md_files_id',3615,'nd_experiment_id','80259','file_id','9'],['nd_experiment_md_files_id',3616,'nd_experiment_id','80240','file_id','9'],['nd_experiment_md_files_id',3617,'nd_experiment_id','80311','file_id','9'],['nd_experiment_md_files_id',3618,'nd_experiment_id','80257','file_id','9'],['nd_experiment_md_files_id',3619,'nd_experiment_id','80289','file_id','9'],['nd_experiment_md_files_id',3620,'nd_experiment_id','80344','file_id','9'],['nd_experiment_md_files_id',3621,'nd_experiment_id','80250','file_id','9'],['nd_experiment_md_files_id',3622,'nd_experiment_id','80345','file_id','9'],['nd_experiment_md_files_id',3623,'nd_experiment_id','80310','file_id','9'],['nd_experiment_md_files_id',3624,'nd_experiment_id','80246','file_id','9'],['nd_experiment_md_files_id',3625,'nd_experiment_id','80264','file_id','9'],['nd_experiment_md_files_id',3626,'nd_experiment_id','80307','file_id','9'],['nd_experiment_md_files_id',3627,'nd_experiment_id','80241','file_id','9'],['nd_experiment_md_files_id',3628,'nd_experiment_id','80244','file_id','9']];


#is_deeply(\@exp_md_files_table, $exp_md_files_table_check, 'check ndexperimentmdfiles table data state' );



done_testing();

