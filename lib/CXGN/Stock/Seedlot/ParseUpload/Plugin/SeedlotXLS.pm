package CXGN::Stock::Seedlot::ParseUpload::Plugin::SeedlotXLS;

use Moose::Role;
use Spreadsheet::ParseExcel;
use CXGN::Stock::StockLookup;
use SGN::Model::Cvterm;
use Data::Dumper;
use CXGN::List::Validate;

sub _validate_with_plugin {
    my $self = shift;

    my $filename = $self->get_filename();
    my $schema = $self->get_chado_schema();
    my $parser = Spreadsheet::ParseExcel->new();
    my @error_messages;
    my %errors;
    my %missing_accessions;

    #try to open the excel file and report any errors
    my $excel_obj = $parser->parse($filename);
    if (!$excel_obj) {
        push @error_messages, $parser->error();
        $errors{'error_messages'} = \@error_messages;
        $self->_set_parse_errors(\%errors);
        return;
    }

    my $worksheet = ( $excel_obj->worksheets() )[0]; #support only one worksheet
    if (!$worksheet) {
        push @error_messages, "Spreadsheet must be on 1st tab in Excel (.xls) file";
        $errors{'error_messages'} = \@error_messages;
        $self->_set_parse_errors(\%errors);
        return;
    }
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();
    if (($col_max - $col_min)  < 2 || ($row_max - $row_min) < 1 ) { #must have header and at least one row of plot data
        push @error_messages, "Spreadsheet is missing header or contains no rows";
        $errors{'error_messages'} = \@error_messages;
        $self->_set_parse_errors(\%errors);
        return;
    }

    #get column headers
    my $seedlot_name_head;
    my $accession_name_head;
    my $cross_name_head;
    my $amount_head;
    my $description_head;

    if ($worksheet->get_cell(0,0)) {
        $seedlot_name_head  = $worksheet->get_cell(0,0)->value();
    }
    if ($worksheet->get_cell(0,1)) {
        $accession_name_head  = $worksheet->get_cell(0,1)->value();
    }
    if ($worksheet->get_cell(0,2)) {
        $cross_name_head  = $worksheet->get_cell(0,2)->value();
    }
    if ($worksheet->get_cell(0,3)) {
        $amount_head  = $worksheet->get_cell(0,3)->value();
    }
    if ($worksheet->get_cell(0,4)) {
        $description_head  = $worksheet->get_cell(0,4)->value();
    }

    if (!$seedlot_name_head || $seedlot_name_head ne 'seedlot_name' ) {
        push @error_messages, "Cell A1: seedlot_name is missing from the header";
    }
    if (!$accession_name_head || $accession_name_head ne 'accession_name') {
        push @error_messages, "Cell B1: accession_name is missing from the header";
    }
    if (!$cross_name_head || $cross_name_head ne 'cross_name') {
        push @error_messages, "Cell C1: cross_name is missing from the header";
    }
    if (!$amount_head || $amount_head ne 'amount') {
        push @error_messages, "Cell D1: amount is missing from the header";
    }
    if (!$description_head || $description_head ne 'description') {
        push @error_messages, "Cell E1: description is missing from the header";
    }

    my %seen_seedlot_names;
    my %seen_accession_names;
    my %seen_cross_names;
    for my $row ( 1 .. $row_max ) {
        my $row_name = $row+1;
        my $seedlot_name;
        my $accession_name;
        my $cross_name;
        my $amount = 0;
        my $description;

        if ($worksheet->get_cell($row,0)) {
            $seedlot_name = $worksheet->get_cell($row,0)->value();
        }
        if ($worksheet->get_cell($row,1)) {
            $accession_name = $worksheet->get_cell($row,1)->value();
        }
        if ($worksheet->get_cell($row,2)) {
            $cross_name = $worksheet->get_cell($row,2)->value();
        }
        if ($worksheet->get_cell($row,3)) {
            $amount =  $worksheet->get_cell($row,3)->value();
        }
        if ($worksheet->get_cell($row,4)) {
            $description =  $worksheet->get_cell($row,4)->value();
        }

        if (!$seedlot_name || $seedlot_name eq '' ) {
            push @error_messages, "Cell A$row_name: seedlot_name missing.";
        }
        elsif ($seedlot_name =~ /\s/ || $seedlot_name =~ /\// || $seedlot_name =~ /\\/ ) {
            push @error_messages, "Cell A$row_name: seedlot_name must not contain spaces or slashes.";
        }
        else {
            #file must not contain duplicate plot names
            if ($seen_seedlot_names{$seedlot_name}) {
                push @error_messages, "Cell A$row_name: duplicate seedlot_name at cell A".$seen_seedlot_names{$seedlot_name}.": $seedlot_name";
            }
            $seen_seedlot_names{$seedlot_name}=$row_name;
        }

        if ( (!$accession_name || $accession_name eq '') && (!$cross_name || $cross_name eq '') ) {
            push @error_messages, "In row:$row_name: you must provide either an accession_name or a cross_name for the contents of the seedlot.";
        } elsif ( ($accession_name && $accession_name ne '') && ($cross_name && $cross_name ne '') ) {
            push @error_messages, "In row:$row_name: you must provide either an accession_name or a cross_name for the contents of the seedlot and Not both.";
        } else {
            if ($accession_name){
                $seen_accession_names{$accession_name}++;
            }
            if ($cross_name){
                $seen_cross_names{$cross_name}++;
            }
        }

        if (!defined($amount) || $amount eq '') {
            push @error_messages, "Cell D$row_name: amount missing";
        }
    }

    my @accessions = keys %seen_accession_names;
    my $accession_validator = CXGN::List::Validate->new();
    my @accessions_missing = @{$accession_validator->validate($schema,'accessions',\@accessions)->{'missing'}};

    if (scalar(@accessions_missing) > 0) {
        push @error_messages, "The following accessions are not in the database as uniquenames or synonyms: ".join(',',@accessions_missing);
        $errors{'missing_accessions'} = \@accessions_missing;
    }

    my @crosses = keys %seen_cross_names;
    my $cross_validator = CXGN::List::Validate->new();
    my @crosses_missing = @{$cross_validator->validate($schema,'crosses',\@crosses)->{'missing'}};

    if (scalar(@accessions_missing) > 0) {
        push @error_messages, "The following accessions are not in the database as uniquenames or synonyms: ".join(',',@accessions_missing);
        $errors{'missing_crosses'} = \@accessions_missing;
    }

    my @seedlots = keys %seen_seedlot_names;
    my $rs = $schema->resultset("Stock::Stock")->search({
        'is_obsolete' => { '!=' => 't' },
        'uniquename' => { -in => \@seedlots }
    });
    while (my $r=$rs->next){
        push @error_messages, "Cell A".$seen_seedlot_names{$r->uniquename}.": seedlot name already exists in database: ".$r->uniquename;
    }

    #store any errors found in the parsed file to parse_errors accessor
    if (scalar(@error_messages) >= 1) {
        $errors{'error_messages'} = \@error_messages;
        $self->_set_parse_errors(\%errors);
        return;
    }

    return 1; #returns true if validation is passed
}


sub _parse_with_plugin {
    my $self = shift;
    my $filename = $self->get_filename();
    my $schema = $self->get_chado_schema();
    my $parser   = Spreadsheet::ParseExcel->new();
    my $excel_obj;
    my $worksheet;
    my %parsed_seedlots;

    $excel_obj = $parser->parse($filename);
    if ( !$excel_obj ) {
        return;
    }

    $worksheet = ( $excel_obj->worksheets() )[0];
    my ( $row_min, $row_max ) = $worksheet->row_range();
    my ( $col_min, $col_max ) = $worksheet->col_range();

    my %seen_accession_names;
    my %seen_cross_names;
    for my $row ( 1 .. $row_max ) {
        my $accession_name;
        my $cross_name;
        if ($worksheet->get_cell($row,1)) {
            $accession_name = $worksheet->get_cell($row,1)->value();
            $seen_accession_names{$accession_name}++;
        }
        if ($worksheet->get_cell($row,2)) {
            $cross_name = $worksheet->get_cell($row,2)->value();
            $seen_cross_names{$cross_name}++;
        }
    }
    my $accession_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'accession', 'stock_type')->cvterm_id();
    my $cross_cvterm_id = SGN::Model::Cvterm->get_cvterm_row($schema, 'cross', 'stock_type')->cvterm_id();
    my @accessions = keys %seen_accession_names;
    my $rs = $schema->resultset("Stock::Stock")->search({
        'is_obsolete' => { '!=' => 't' },
        'uniquename' => { -in => \@accessions },
        'type_id' => $accession_cvterm_id
    });
    my %accession_lookup;
    while (my $r=$rs->next){
        $accession_lookup{$r->uniquename} = $r->stock_id;
    }
    my @crosses = keys %seen_cross_names;
    my $rs = $schema->resultset("Stock::Stock")->search({
        'is_obsolete' => { '!=' => 't' },
        'uniquename' => { -in => \@crosses },
        'type_id' => $cross_cvterm_id
    });
    my %cross_lookup;
    while (my $r=$rs->next){
        $cross_lookup{$r->uniquename} = $r->stock_id;
    }

    for my $row ( 1 .. $row_max ) {
        my $seedlot_name;
        my $accession_name;
        my $cross_name;
        my $amount = 0;
        my $description;

        if ($worksheet->get_cell($row,0)) {
            $seedlot_name = $worksheet->get_cell($row,0)->value();
        }
        if ($worksheet->get_cell($row,1)) {
            $accession_name = $worksheet->get_cell($row,1)->value();
        }
        if ($worksheet->get_cell($row,2)) {
            $cross_name = $worksheet->get_cell($row,2)->value();
        }
        if ($worksheet->get_cell($row,3)) {
            $amount =  $worksheet->get_cell($row,3)->value();
        }
        if ($worksheet->get_cell($row,4)) {
            $description =  $worksheet->get_cell($row,4)->value();
        }

        #skip blank lines
        if (!$seedlot_name && !$accession_name && !$cross_name && !$description) {
            next;
        }

        $parsed_seedlots{$seedlot_name} = {
            accession => $accession_name,
            accession_stock_id => $accession_lookup{$accession_name},
            cross_name => $cross_name,
            cross_stock_id => $cross_lookup{$cross_name},
            amount => $amount,
            description => $description
        };
    }

    $self->_set_parsed_data(\%parsed_seedlots);
    return 1;
}


1;
