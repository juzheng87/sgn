#Tests SGN::Controller::AJAX::Search::Stock

use strict;
use warnings;

use lib 't/lib';
use SGN::Test::Fixture;
use Test::More;
use Test::WWW::Mechanize;
use SGN::Model::Cvterm;
use Data::Dumper;
use JSON;
local $Data::Dumper::Indent = 0;

my $f = SGN::Test::Fixture->new();
my $schema = $f->bcs_schema;

my $mech = Test::WWW::Mechanize->new;
my $response;

$mech->post_ok('http://localhost:3010/ajax/search/stocks');
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'draw' => undef,'data' => [['<a href="/stock/40326/view">BLANK</a>','accession',undef,'','',''],['<a href="/stock/39944/view">combined</a>','training population','Manihot esculenta','','',''],['<a href="/stock/41248/view">cross_test1</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41252/view">cross_test2</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41253/view">cross_test3</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41249/view">cross_test4</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41250/view">cross_test5</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41251/view">cross_test6</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/39691/view">KASESE_TP2013_1000</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39493/view">KASESE_TP2013_1001</a>','plot','Solanum lycopersicum','','','']],'recordsFiltered' => 2436,'recordsTotal' => 2436}, 'test stock search 1');

my $accession_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'accession', 'stock_type')->cvterm_id();
my $plot_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'plot', 'stock_type')->cvterm_id();
my $cross_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'cross', 'stock_type')->cvterm_id();
my $population_type_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'population', 'stock_type')->cvterm_id();

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "test", "stock_type"=>$accession_type_id] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'data' => [['<a href="/stock/38846/view">new_test_crossP001</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/38847/view">new_test_crossP002</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/38848/view">new_test_crossP003</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/38849/view">new_test_crossP004</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/38850/view">new_test_crossP005</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/38851/view">new_test_crossP006</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/38852/view">new_test_crossP007</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/38853/view">new_test_crossP008</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/38854/view">new_test_crossP009</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/38855/view">new_test_crossP010</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>','']],'draw' => undef,'recordsTotal' => 25,'recordsFiltered' => 25}, 'test stock search 2');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "test", "stock_type"=>$plot_type_id] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'recordsTotal' => 937,'data' => [['<a href="/stock/40327/view">test_t1</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40328/view">test_t10</a>','plot','Manihot esculenta','','',''],['<a href="/stock/40329/view">test_t100</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40330/view">test_t101</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40331/view">test_t102</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40332/view">test_t103</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40333/view">test_t104</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40334/view">test_t105</a>','plot','Manihot esculenta','','',''],['<a href="/stock/40335/view">test_t106</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40336/view">test_t107</a>','plot','Solanum lycopersicum','','','']],'draw' => undef,'recordsFiltered' => 937}, 'test stock search 3');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "test", "stock_type"=>$cross_type_id] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'data' => [['<a href="/stock/41248/view">cross_test1</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41252/view">cross_test2</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41253/view">cross_test3</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41249/view">cross_test4</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41250/view">cross_test5</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41251/view">cross_test6</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38845/view">new_test_cross</a>','cross','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=40">johndoe</a>',''],['<a href="/stock/41264/view">TestCross1</a>','cross','Manihot esculenta','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41273/view">TestCross10</a>','cross','Manihot esculenta','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/41274/view">TestCross11</a>','cross','Manihot esculenta','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>','']],'recordsFiltered' => 21,'draw' => undef,'recordsTotal' => 21}, 'test stock search 4');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "test", "stock_type"=>$population_type_id] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'data' => [['<a href="/stock/41259/view">TestPopulation1</a>','population','Manihot esculenta','','',''],['<a href="/stock/41260/view">TestPopulation2</a>','population','Manihot esculenta','','',''],['<a href="/stock/41261/view">TestPopulation3</a>','population','Manihot esculenta','','',''],['<a href="/stock/41262/view">TestPopulation4</a>','population','Manihot esculenta','','',''],['<a href="/stock/41263/view">TestPopulation5</a>','population','Manihot esculenta','','','']],'recordsTotal' => 5,'draw' => undef,'recordsFiltered' => 5}, 'test stock search 5');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "test", "stock_type"=>$accession_type_id, "person"=>"Jane,Doe"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'data' => [['<a href="/stock/38873/view">test5P001</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38874/view">test5P002</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38875/view">test5P003</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38876/view">test5P004</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38877/view">test5P005</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>','']],'recordsTotal' => 5,'draw' => undef,'recordsFiltered' => 5}, 'test stock search 6');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "ends_with","any_name" => "001", "stock_type"=>$accession_type_id, "person"=>"Jane, Doe", "trait"=>"fresh root weight"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'recordsFiltered' => 2,'draw' => undef,'recordsTotal' => 2,'data' => [['<a href="/stock/38878/view">UG120001</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/39132/view">UG130001</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>','']]}, "test stock search 7");

my $test_bp_id = $schema->resultset("Project::Project")->find({name=>'test'})->project_id;

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "g", "stock_type"=>$accession_type_id, "person"=>"Jane, Doe", "breeding_program" => $test_bp_id] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'draw' => undef,'recordsTotal' => 427,'recordsFiltered' => 427,'data' => [['<a href="/stock/38878/view">UG120001</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38879/view">UG120002</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38880/view">UG120003</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38881/view">UG120004</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38882/view">UG120005</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38883/view">UG120006</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38884/view">UG120007</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38885/view">UG120008</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38886/view">UG120009</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38887/view">UG120010</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>','']]}, "test 8");

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "t", "stock_type"=>$accession_type_id, "project" => "test_trial"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'recordsFiltered' => 5,'recordsTotal' => 5,'data' => [['<a href="/stock/38840/view">test_accession1</a>','accession','Solanum lycopersicum','test_accession1_synonym1','',''],['<a href="/stock/38841/view">test_accession2</a>','accession','Solanum lycopersicum','test_accession2_synonym1, test_accession2_synonym2','',''],['<a href="/stock/38842/view">test_accession3</a>','accession','Solanum lycopersicum','test_accession3_synonym1','',''],['<a href="/stock/38843/view">test_accession4</a>','accession','Solanum lycopersicum','','',''],['<a href="/stock/38844/view">test_accession5</a>','accession','Solanum lycopersicum','','','']],'draw' => undef}, 'test stock search 9');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["stock_type"=>$accession_type_id, "year" => "2014"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'draw' => undef,'data' => [['<a href="/stock/38840/view">test_accession1</a>','accession','Solanum lycopersicum','test_accession1_synonym1','',''],['<a href="/stock/38841/view">test_accession2</a>','accession','Solanum lycopersicum','test_accession2_synonym1, test_accession2_synonym2','',''],['<a href="/stock/38842/view">test_accession3</a>','accession','Solanum lycopersicum','test_accession3_synonym1','',''],['<a href="/stock/38843/view">test_accession4</a>','accession','Solanum lycopersicum','','',''],['<a href="/stock/38844/view">test_accession5</a>','accession','Solanum lycopersicum','','',''],['<a href="/stock/38878/view">UG120001</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38879/view">UG120002</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38880/view">UG120003</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38881/view">UG120004</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38882/view">UG120005</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>','']],'recordsTotal' => 432,'recordsFiltered' => 432}, 'test stock search 10');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "g", "stock_type"=>$accession_type_id, "breeding_program" => $test_bp_id, "location"=>"test_location"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'recordsFiltered' => 427,'recordsTotal' => 427,'draw' => undef,'data' => [['<a href="/stock/38878/view">UG120001</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38879/view">UG120002</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38880/view">UG120003</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38881/view">UG120004</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38882/view">UG120005</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38883/view">UG120006</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38884/view">UG120007</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38885/view">UG120008</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38886/view">UG120009</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>',''],['<a href="/stock/38887/view">UG120010</a>','accession','Solanum lycopersicum','','<a href="/solpeople/personal-info.pl?sp_person_id=41">janedoe</a>','']]}, 'test stock search 11');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "t", "stock_type"=>$plot_type_id, "project" => "test_trial"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'recordsFiltered' => 15,'data' => [['<a href="/stock/38857/view">test_trial21</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/38866/view">test_trial210</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/38867/view">test_trial211</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/38868/view">test_trial212</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/38869/view">test_trial213</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/38870/view">test_trial214</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/38871/view">test_trial215</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/38858/view">test_trial22</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/38859/view">test_trial23</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/38860/view">test_trial24</a>','plot','Solanum lycopersicum','','','']],'draw' => undef,'recordsTotal' => 15}, 'test stock search 12');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["stock_type"=>$plot_type_id, "year" => "2014"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'recordsFiltered' => 1014,'data' => [['<a href="/stock/39691/view">KASESE_TP2013_1000</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39493/view">KASESE_TP2013_1001</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39819/view">KASESE_TP2013_1002</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39311/view">KASESE_TP2013_1003</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39632/view">KASESE_TP2013_1004</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39846/view">KASESE_TP2013_1005</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39919/view">KASESE_TP2013_1006</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39836/view">KASESE_TP2013_1007</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39350/view">KASESE_TP2013_1008</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39322/view">KASESE_TP2013_1009</a>','plot','Solanum lycopersicum','','','']],'draw' => undef,'recordsTotal' => 1014}, 'test stock search 13');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["any_name_matchtype" => "contains","any_name" => "g", "stock_type"=>$plot_type_id, "breeding_program" => $test_bp_id] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'recordsTotal' => 307,'draw' => undef,'data' => [['<a href="/stock/39998/view">UG120001_block:1_plot:TP1_2012_NaCRRI</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39999/view">UG120002_block:1_plot:TP2_2012_NaCRRI</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40000/view">UG120003_block:1_plot:TP3_2012_NaCRRI</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40001/view">UG120004_block:1_plot:TP4_2012_NaCRRI</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40002/view">UG120005_block:1_plot:TP5_2012_NaCRRI</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40003/view">UG120006_block:1_plot:TP6_2012_NaCRRI</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40004/view">UG120007_block:1_plot:TP7_2012_NaCRRI</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40005/view">UG120008_block:1_plot:TP8_2012_NaCRRI</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40006/view">UG120009_block:1_plot:TP9_2012_NaCRRI</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/40007/view">UG120010_block:1_plot:TP10_2012_NaCRRI</a>','plot','Solanum lycopersicum','','','']],'recordsFiltered' => 307}, 'test stock search 14');

$mech->post_ok('http://localhost:3010/ajax/search/stocks',["stock_type"=>$plot_type_id, "location"=>"test_location"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'data' => [['<a href="/stock/39691/view">KASESE_TP2013_1000</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39493/view">KASESE_TP2013_1001</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39819/view">KASESE_TP2013_1002</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39311/view">KASESE_TP2013_1003</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39632/view">KASESE_TP2013_1004</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39846/view">KASESE_TP2013_1005</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39919/view">KASESE_TP2013_1006</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39836/view">KASESE_TP2013_1007</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39350/view">KASESE_TP2013_1008</a>','plot','Solanum lycopersicum','','',''],['<a href="/stock/39322/view">KASESE_TP2013_1009</a>','plot','Solanum lycopersicum','','','']],'recordsTotal' => 1935,'recordsFiltered' => 1935,'draw' => undef}, 'test stock search 15');

#add an organization stockprop to an existing stockprop, then search for stocks with that stockprop. login required to add stockprops
$mech->post_ok('http://localhost:3010/brapi/v1/token', [ "username"=> "janedoe", "password"=> "secretpw", "grant_type"=> "password" ]);
$response = decode_json $mech->content;
#print STDERR Dumper $response;
is($response->{'metadata'}->{'status'}->[0]->{'message'}, 'Login Successfull');
$mech->post_ok('http://localhost:3010/stock/prop/add',["stock_id"=>"38842", "prop"=>"organization_name_1", "prop_type"=>"organization"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;
$mech->post_ok('http://localhost:3010/ajax/search/stocks',["organization"=>"organization_name_1"] );
$response = decode_json $mech->content;
#print STDERR Dumper $response;

is_deeply($response, {'recordsFiltered' => 1,'recordsTotal' => 1,'draw' => undef,'data' => [['<a href="/stock/38842/view">test_accession3</a>','accession','Solanum lycopersicum','test_accession3_synonym1','','organization_name_1']]}, 'test stock search 16');

done_testing();