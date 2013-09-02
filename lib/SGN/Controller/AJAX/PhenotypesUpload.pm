
=head1 NAME

SGN::Controller::AJAX::PhenotypesUpload - a REST controller class to provide the
backend for uploading phenotype spreadsheets

=head1 DESCRIPTION

Uploading Phenotype Spreadsheets

=head1 AUTHOR

Jeremy Edwards <jde22@cornell.edu>
Naama Menda <nm249@cornell.edu>

=cut

package SGN::Controller::AJAX::PhenotypesUpload;

use Moose;
use Try::Tiny;
use DateTime;
use File::Slurp;
use File::Spec::Functions;
use File::Copy;
use List::MoreUtils qw /any /;
use SGN::View::ArrayElements qw/array_elements_simple_view/;
use CXGN::Stock::StockTemplate;
use JSON -support_by_pp;

BEGIN { extends 'Catalyst::Controller::REST' }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON', 'text/html' => 'JSON' },
   );


sub upload_phenotype_spreadsheet :  Path('/ajax/phenotype/upload_spreadsheet') : ActionClass('REST') { }

sub upload_phenotype_spreadsheet_POST : Args(0) {
  my ($self, $c) = @_;
  my $schema = $c->dbic_schema('Bio::Chado::Schema', 'sgn_chado');
  my $metadata_schema = $c->dbic_schema('CXGN::Metadata::Schema');
  my $error;
  my $stock_template = new CXGN::Stock::StockTemplate(schema => $schema, metadata_schema => $metadata_schema);
  my $upload = $c->req->upload('upload_phenotype_spreadsheet_file_input');
  my $upload_file_name;
  my $upload_file_temporary_directory;
  my $upload_file_temporary_full_path;
  my $operator_directory;
  my $upload_file_archive_full_path;
  my $time = DateTime->now();
  my $timestamp = $time->ymd()."_".$time->hms();
  my %parsed_header;


  print STDERR "Timestamp: $timestamp\n";

  my $archive_path = $c->config->{archive_path};
  if (!-d $archive_path) {
    mkdir $archive_path;
  }


  if (!$c->user()) {  #user must be logged in
    $c->stash->{rest} = {error => "You need to be logged in to upload a file." };
    return;
  }
  if (!any { $_ eq "curator" || $_ eq "submitter" } ($c->user()->roles)  ) {
    $c->stash->{rest} = {error =>  "You have insufficient privileges to upload a file." };
    return;
  }
  if (!$upload) { #upload file required
    $c->stash->{rest} = {error => "File upload failed: no file name received"};
    return;
  }
  $upload_file_name = $upload->tempname;
  my $upload_original_name = $upload->filename();
  $upload_file_name =~ s/\/tmp\///;

  my $user_id = $c->user()->get_object()->get_sp_person_id();
  my $user_name = $c->user()->get_object()->get_username();
  my $user_string = $user_name.'_'.$user_id;
  my $archived_file_name = catfile($user_string, $timestamp."_".$upload_original_name);
  


  if (! -d catfile($archive_path, $user_string)) { 
      mkdir (catfile($archive_path, $user_string));
  }
      
  $upload_file_temporary_directory = $archive_path.'/tmp/';
  if (!-d $upload_file_temporary_directory) {
    mkdir $upload_file_temporary_directory;
  }
  $upload_file_temporary_full_path = $upload_file_temporary_directory.$upload_file_name;
  print "full path: $upload_file_temporary_full_path\n";
  write_file($upload_file_temporary_full_path, $upload->slurp);
  print STDERR "Parsing\n";

  try {
    $stock_template->parse($upload_file_temporary_full_path);
  } catch {
    $c->stash->{rest} = {error => "Error parsing spreadsheet: $_"};
    $error=1;
  };
  if ($error) {
    return;
  }

  print STDERR "Parsing done\n";

  if ($stock_template->parse_errors()) {
    print STDERR "temp: ".$stock_template->parse_errors()."\n";
    my $parse_errors_html = array_elements_simple_view($stock_template->parse_errors());
    print STDERR "parse errors: $parse_errors_html\n";
    #$c->stash->{rest} = {error_list_html => $parse_errors_html };
    $c->stash->{rest} = {
			 error => "Error parsing spreadsheet",
			 error_list_html => $parse_errors_html,
			};
    return;
  }

  %parsed_header=%{$stock_template->parsed_header()};
  if (!$parsed_header{'operator'}) {
    $c->stash->{rest} = {error => "Cound not get operator name from spreadsheet"};
    return;
  }
  if (!$parsed_header{'trial_name'}) {
    $c->stash->{rest} = {error => "Cound not get trial name from spreadsheet"};
    return;
  }
  #$operator_directory = $archive_path.'/'.$parsed_header{'operator'};
  #if (!-d $operator_directory) {
  #  mkdir $operator_directory;
  #}
  #$upload_file_archive_full_path = $operator_directory.'/'.$parsed_header{'trial_name'}.$timestamp.".xls";

  #try {
  #  write_file($upload_file_archive_full_path, $upload->slurp);
  #} catch {
  #  $c->stash->{rest} = {error => "Could not save spreadsheet file: $_"};
  #  $error=1;
  #};
  if ($error) {
    return;
  }
  #unlink $upload_file_temporary_full_path;
  print STDERR "Verifying\n";

  try {
    $stock_template->verify();
  } catch {
    $c->stash->{rest} = {error => "Error verifying spreadsheet: $_"};
    $error=1;
  };
  if ($error) {
    #unlink $upload_file_archive_full_path;
    return;
  }
  if ($stock_template->verify_errors()) {
    my $verify_errors_html = array_elements_simple_view($stock_template->verify_errors());
    $c->stash->{rest} = {
			 error => "Spreadsheet did not pass verification",
			 error_list_html => $verify_errors_html, };
    #unlink $upload_file_archive_full_path;
    return;
  }

  my $file_destination =  catfile($archive_path, $archived_file_name);
  $stock_template->filename($file_destination);
  $stock_template->tmp_filename($upload_file_temporary_full_path);
  $stock_template->user_id($user_id);

  try {
    $stock_template->store();
  } catch {
    $c->stash->{rest} = {error => "Error storing spreadsheet: $_"};
    $error=1;
  };
  if ($error) {
    unlink $upload_file_archive_full_path;
    return;
  }
  if ($stock_template->store_error()) {
    #my $store_errors_html = array_elements_simple_view($stock_template->store_error());
    my $store_error;
    $store_error = $stock_template->store_error();
    if ($store_error) {
      $c->stash->{rest} = {error => $store_error };
    }
    #unlink $upload_file_archive_full_path;
    return;
  }

  

  print STDERR "from: $upload_file_temporary_full_path \nto: $file_destination \n";
  move($upload_file_temporary_full_path,$file_destination);
  $c->stash->{rest} = {success => 1 };

  print STDERR "Finishing\n";
}


#########
1;
#########
