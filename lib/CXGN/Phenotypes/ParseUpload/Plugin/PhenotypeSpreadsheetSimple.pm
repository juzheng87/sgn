package CXGN::Phenotypes::ParseUpload::Plugin::PhenotypeSpreadsheetSimple;

use Moose;
#use File::Slurp;
use Spreadsheet::ParseExcel;
use JSON;
use Data::Dumper;

sub name {
    return "phenotype spreadsheet simple";
}

sub validate {
    my $self = shift;
    my $filename = shift;
    my $timestamp_included = shift;
    my $data_level = shift;
    my $schema = shift;
    my @file_lines;
    my $delimiter = ',';
    my $header;
    my @header_row;
    my $parser   = Spreadsheet::ParseExcel->new();
    my $excel_obj;
    my $worksheet;
    my %parse_result;

    #try to open the excel file and report any errors
    $excel_obj = $parser->parse($filename);
    if ( !$excel_obj ) {
        $parse_result{'error'} = $parser->error();
        print STDERR "validate error: ".$parser->error()."\n";
        return \%parse_result;
    }

    $worksheet = ( $excel_obj->worksheets() )[0]; #support only one worksheet
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();
    if (($col_max - $col_min)  < 1 || ($row_max - $row_min) < 1 ) { #must have header with at least observationunit_name and one trait, as well as one row of phenotypes
        $parse_result{'error'} = "Spreadsheet is missing observationunit_name and atleast one trait in header.";
        print STDERR "Spreadsheet is missing header\n";
        return \%parse_result;
    }

    if ($worksheet->get_cell(0,0)->value() ne 'observationunit_name' ) {
        $parse_result{'error'} = "First column must be 'observationunit_name'. It may help to recreate your spreadsheet from the website.";
        print STDERR "Columns not correct\n";
        return \%parse_result;
    }
    my @fixed_columns = qw | observationunit_name |;
    my $num_fixed_col = scalar(@fixed_columns);

    for (my $row=1; $row<$row_max; $row++) {
        for (my $col=$num_fixed_col; $col<=$col_max; $col++) {
            my $value_string = '';
            my $value = '';
            if ($worksheet->get_cell($row,$col)) {
                $value_string = $worksheet->get_cell($row,$col)->value();
                #print STDERR $value_string."\n";
                my ($value, $timestamp) = split /,/, $value_string;
                if (!$timestamp_included) {
                    if ($timestamp) {
                        $parse_result{'error'} = "Timestamp found in value, but 'Timestamps Included' is not selected.";
                        print STDERR "Timestamp wrongly found in value.\n";
                        return \%parse_result;
                    }
                }
                if ($timestamp_included) {
                    if (!$timestamp) {
                        $parse_result{'error'} = "No timestamp found in value, but 'Timestamps Included' is selected.";
                        print STDERR "Timestamp not found in value.\n";
                        return \%parse_result;
                    } else {
                        if (!$timestamp =~ m/(\d{4})-(\d{2})-(\d{2}) (\d{2}):(\d{2}):(\d{2})(\S)(\d{4})/) {
                            $parse_result{'error'} = "Timestamp needs to be of form YYYY-MM-DD HH:MM:SS-0000 or YYYY-MM-DD HH:MM:SS+0000";
                            print STDERR "value: $timestamp\n";
                            return \%parse_result;
                        }
                    }
                }
            }
        }
    }

    #if the rest of the header rows are not two caps followed by colon followed by text then return

    return 1;
}

sub parse {
    my $self = shift;
    my $filename = shift;
    my $timestamp_included = shift;
    my $data_level = shift;
    my $schema = shift;
    my $composable_cvterm_format = shift // 'extended';
    my %parse_result;
    my @file_lines;
    my $delimiter = ',';
    my $header;
    my @header_row;
    my $header_column_number = 0;
    my %header_column_info; #column numbers of key info indexed from 0;
    my %observationunits_seen;
    my %traits_seen;
    my @observation_units;
    my @traits;
    my %data;
    my $parser   = Spreadsheet::ParseExcel->new();
    my $excel_obj;
    my $worksheet;

    #try to open the excel file and report any errors
    $excel_obj = $parser->parse($filename);
    if ( !$excel_obj ) {
        $parse_result{'error'} = $parser->error();
        print STDERR "validate error: ".$parser->error()."\n";
        return \%parse_result;
    }

    $worksheet = ( $excel_obj->worksheets() )[0]; #support only one worksheet
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();

    my @fixed_columns = qw | observationunit_name |;
    my $num_fixed_col = scalar(@fixed_columns);

    for my $row ( 1 .. $row_max ) {
        my $observationunit_name;

        if ($worksheet->get_cell($row,0)) {
            $observationunit_name = $worksheet->get_cell($row,0)->value();
            if (defined($observationunit_name)){
                if ($observationunit_name ne ''){
                    $observationunits_seen{$observationunit_name} = 1;

                    my @treatments;

                    for my $col ($num_fixed_col .. $col_max) {
                        my $trait_name;
                        if ($worksheet->get_cell(0,$col)) {
                            $trait_name = $worksheet->get_cell(0,$col)->value();
                            if (defined($trait_name)) {
                                if ($trait_name ne ''){

                                    $traits_seen{$trait_name} = 1;
                                    my $value_string = '';

                                    if ($worksheet->get_cell($row, $col)){
                                        $value_string = $worksheet->get_cell($row, $col)->value();
                                    }
                                    my ($trait_value, $timestamp) = split /,/, $value_string;
                                    if (!$timestamp) {
                                        $timestamp = '';
                                    }
                                    #print STDERR $trait_value." : ".$timestamp."\n";

                                    if ( defined($trait_value) && defined($timestamp) ) {
                                        if ($trait_value ne '.'){
                                            $data{$observationunit_name}->{$trait_name} = [$trait_value, $timestamp, \@treatments];
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    foreach my $obs (sort keys %observationunits_seen) {
        push @observation_units, $obs;
    }
    foreach my $trait (sort keys %traits_seen) {
        push @traits, $trait;
    }

    $parse_result{'data'} = \%data;
    $parse_result{'plots'} = \@observation_units;
    $parse_result{'traits'} = \@traits;
    #print STDERR Dumper \%parse_result;

    return \%parse_result;
}

1;
